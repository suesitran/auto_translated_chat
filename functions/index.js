/* eslint-disable operator-linebreak */
/* eslint-disable key-spacing */
/* eslint-disable quotes */
/* eslint-disable no-trailing-spaces */
/* eslint-disable comma-dangle */
/* eslint-disable object-curly-spacing */
/* eslint-disable indent */
/* eslint-disable max-len */
const v2 = require("firebase-functions/v2");
const vertexAIApi = require("@google-cloud/vertexai");
const admin = require("firebase-admin");

admin.initializeApp();

const project = "proj-atc";
const location = "us-central1";
const textModel = "gemini-1.5-flash";
const visionModel = "gemini-1.0-pro-vision";

const vertexAI = new vertexAIApi.VertexAI({ project: project, location: location });

const generativeModelPreview = vertexAI.preview.getGenerativeModel({
  model: textModel,
});

// trigger when the chat data on public collection change to translate the message
exports.onChatWritten = v2.firestore.onDocumentWritten("/public/{messageId}", async (event) => {
  const document = event.data.after.data();
  const message = document["message"];
  const original = document["original"];
  const translations = document["translations"];

  console.log(`Processing message: ${message}`);
  console.log(`Original: ${original}`);
  console.log(`Has translations: ${translations != null}`);

  // 1. Kiểm tra điều kiện để skip
  if (!message || message.trim() === '') {
    console.log("Message is empty, skipping");
    return;
  }

  // 2. Skip nếu message này đã được xử lý (có original và translations)
  if (original && translations) {
    console.log("Message already processed (has original and translations), skipping");
    return;
  }

  // 3. Skip nếu message này là original
  if (message === original) {
    console.log("This is an original message that was already processed, skipping");
    return;
  }

  // Lấy danh sách ngôn ngữ từ Firestore
  const db = admin.firestore();
  const languagesCollection = db.collection("languages");
  const languagesSnapshot = await languagesCollection.get();
  const languages = languagesSnapshot.docs.map((e) => e.data().code);
  
  console.log("Current languages in database:", languages);

  if (languages.length == 0) {
    console.log("No languages in database, skipping");
    return;
  }
  const generationConfig = {
    temperature: 1,
    topP: 0.95,
    topK: 64,
    maxOutputTokens: 8192,
    responseMimeType: "application/json",
    responseSchema: {
      type: "array",
      items: {
        type: "object",
        properties: {
          translation: {
            type: "string",
          },
          code: {
            type: "string",
          },
        },
        required: ["translation", "code"],
      },
    },
  };

    const chatSession = generativeModelPreview.startChat({
      generationConfig: generationConfig,
    });

  let translated = [];
  try {
    const result = await chatSession.sendMessage(`
      Translate '${message}' to these languages: [${languages.join(',')}]. Only translate to the languages in that list.
      `);

    console.log("Translation response:", JSON.stringify(result.response));
    const response = result.response;
    console.log("Response:", JSON.stringify(response));

    const jsonTranslated = response.candidates[0].content.parts[0].text;
    console.log("translated json: ", jsonTranslated);
    // parse this json to get translated text out
    try {
      translated = Array.from(JSON.parse(jsonTranslated));
    } catch (e) {
      console.log("Error: ", e); // if error, maybe show the original json
    }

    console.log("final result: ", translated);
    console.log("translated LENGTH: ", translated.length);
  } catch (error) {
    console.error("Translation error:", error);
  }

  // 2. Phát hiện và thêm ngôn ngữ mới
  const detectSession = generativeModelPreview.startChat({
    tools: [{ 
      functionDeclarations: [{
        name: "code",
        description: "Detect and return only the ISO language code",
        parameters: {
          type: "object",
          properties: {
            code: {
              type: "string",
              description: "ISO 639-1 language code", // (2 letters)
              pattern: "^[a-z]{2}$",
              // examples: ["vi", "en", "ja", "ko", "zh", "fr", "de"]
            }
          },
          required: ["code"]
        }
      }]
    }]
  });

  try {
    // Lấy danh sách language codes hiện có
    const existingCodes = languagesSnapshot.docs.map((doc) => doc.data().code);
    console.log("Existing language codes:", existingCodes);

    const detectResult = await detectSession.sendMessage(`
        You are a language detection expert.
        Detect the language of this text: "${message}"
        Return only the ISO language code (e.g. vi, en, ja, ko, zh).
        If you're not confident about the detection, return "unknown".
      `
    );

    console.log("Detection response:", JSON.stringify(detectResult.response));

    if (detectResult.response.candidates[0].content.parts[0].functionCall) {
      const {code} = detectResult.response.candidates[0].content.parts[0].functionCall.args;
      console.log("Detected language code:", code);

      if (code && code !== "unknown" && !existingCodes.includes(code)) {
        console.log(`Adding new language code: ${code}`);
        try {
          await languagesCollection.add({ code: code });
          console.log("Successfully added new language code to database");
          
          // Cập nhật danh sách ngôn ngữ local
          languages.push(code);
        } catch (error) {
          console.error("Error adding new language code to database:", error);
        }
      } else {
        console.log(
          code === "unknown" 
            ? "Could not detect language with confidence" 
            : `Language code ${code} already exists in database`
        );
      }
    }
  } catch (error) {
    console.error("Language detection error:", error);
  }

  // Cuối cùng, lưu kết quả với original và translations
  try {
    await event.data.after.ref.set({
      "original": message,
      "translations": translated,
      // "processed_at": admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    console.log("Successfully saved translations");
  } catch (error) {
    console.error("Error saving translations:", error);
  }
});