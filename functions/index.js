/* eslint-disable spaced-comment */
/* eslint-disable comma-spacing */
/* eslint-disable object-curly-spacing */
/* eslint-disable require-jsdoc */
/* eslint-disable no-trailing-spaces */
/* eslint-disable comma-dangle */
/* eslint-disable key-spacing */
/* eslint-disable quotes */
/* eslint-disable indent */
/* eslint-disable max-len */

const v2 = require("firebase-functions/v2");
const vertexAIApi = require("@google-cloud/vertexai");
const admin = require("firebase-admin");

admin.initializeApp();

const project = 'proj-atc';
const location = 'us-central1';
const textModel = 'gemini-1.5-flash';
// const visionModel = 'gemini-1.0-pro-vision';
async function saveNewLanguageCode(languagesCollection, detectedLanguage, languages) {
  if (detectedLanguage && !languages.includes(detectedLanguage)) {
    console.log(`Adding new language code: ${detectedLanguage}`);
    try {
      await languagesCollection.add({ code: detectedLanguage });
      console.log("Successfully added new language code to database");
      return true;
    } catch (error) {
      console.error("Error adding new language code to database:", error);
      return false;
    }
  }
  return false;
}
const vertexAI = new vertexAIApi.VertexAI({ project: project, location: location });

// const generativeVisionModel = vertexAI.getGenerativeModel({
//     model: visionModel,
// });

const generativeModelPreview = vertexAI.preview.getGenerativeModel({
  model: textModel,
});

// use onDocumentWritten here to prepare to "edit message" feature later
exports.onChatWritten = v2.firestore.onDocumentWritten("/public/{messageId}", async (event) => {
  const document = event.data.after.data();
  const message = document["message"];
  console.log(`message: ${message}`);

  // no message? do nothing
  if (message == undefined) {
    return;
  }
  const curTranslated = document["translated"];

  // check if message is translated
  if (curTranslated != undefined) {
    // message is translated before, 
    // check the original message
    const original = curTranslated["original"];

    console.log('Original: ', original);
    // message is same as original, meaning it's already translated. Do nothing
    if (message == original) {
      return;
    }
  }
    // Get list of languages from Firestore
    const db = admin.firestore();
    const languagesCollection = db.collection("languages");
    const languagesSnapshot = await languagesCollection.get();
    const languages = languagesSnapshot.docs.map((e) => e.data().code);
    console.log("Current languages in database:", languages);

  const generationConfig = {
    temperature: 1,
    topP: 0.95,
    topK: 64,
    maxOutputTokens: 8192,
    responseMimeType: "application/json",
    responseSchema: {
      type: "object",
      properties:
      {
        "detectedLanguage": {
          type: "string",
          description: "The ISO 639-1 language code that was detected",
          pattern: "^[a-z]{2}$"
        },
        "translation": languages.reduce((acc, lang) => {
          acc[lang] = { type: "string" };
          return acc;
        }, {}),
      },
      required: ["detectedLanguage", "translation"]
    },
  };
  const translateSession = generativeModelPreview.startChat({
    generateContentConfig: generationConfig,
  });

  const result = await translateSession.sendMessage(`
    The target languages: ${languages.join(", ")}.
    The input text: "${message}". You must do:
    1. detect language of the input text. Only return the language code that is in ISO 639-1 format. If you can't detect the language, return "und" as value of "detectedLanguage" field.
    2. If the target languages are not empty and the detected language is not "und", translate the input text to target languages, ignore language that is identical to the detected language. Else, return null as value of "translation" field.
        Example: Translate "Chào" to ["ja", "en", "vi"]:
        {
          "detectedLanguage": "vi",
          "translation": {"ja": "こんにちは", "en": "Hello"},
        }
        `
  );

  const response = result.response;
  console.log('Response:', JSON.stringify(response));

  const responseContent = response.candidates[0].content;
  let translationData = null;
  let detectedLanguage = null;

    try {
      // Trích xuất JSON từ phần text (bỏ qua các ký tự markdown ```)
      const jsonText = responseContent.parts[0].text.replace(/```json\n|\n```/g, '');
      translationData = JSON.parse(jsonText);
      detectedLanguage = translationData.detectedLanguage;
      console.log('Detected language:', detectedLanguage);
      console.log('Translation data:', translationData.translation);
    } catch (error) {
      console.error('Error parsing translation response:', error);
    }

  // Lưu ngôn ngữ mới nếu được phát hiện
  if (detectedLanguage && detectedLanguage !== "und") {
    await saveNewLanguageCode(languagesCollection, detectedLanguage, languages);
  }

  // Cập nhật document với bản dịch
  return event.data.after.ref.set({
    'translated': {
      'original': message,
      ...translationData.translation
    }
  }, { merge: true });
});
