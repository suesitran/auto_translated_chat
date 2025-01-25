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

  // 1. Check conditions to skip
  if (!message || message.trim() === '') {
    console.log("Message is empty, skipping");
    return;
  }

  // 2. Skip if this message is the original
  if (message === original) {
    console.log("This is an original message that was already processed, skipping");
    return;
  }

  // Get list of languages from Firestore
  const db = admin.firestore();
  const languagesCollection = db.collection("languages");
  const languagesSnapshot = await languagesCollection.get();
  const languages = languagesSnapshot.docs.map((e) => e.data().code);
  
  console.log("Current languages in database:", languages);

  const chatSession = generativeModelPreview.startChat({
    toolConfig: {
        functionDeclarations: [{
            name: "processMessage",
            description: "Process message language and translations",
            parameters: {
                type: "object",
                properties: {
                    detectedLanguage: {
                        type: "string",
                        description: "ISO 639-1 language code of the detected language",
                        pattern: "^[a-z]{2}$"
                    },
                    translations: {
                        type: "array",
                        description: "Translations of the message to all existing languages",
                        items: {
                            type: "object",
                            properties: {
                                translation: { type: "string" },
                                code: { type: "string" }
                            }
                        }
                    }
                },
                required: ["detectedLanguage","translations"]
            }
        }],
        functionCallMode: "ANY"
    }
  });

  let translated = [];
  try {
    const result = await chatSession.sendMessage(`
      Translate this message: "${message}"
      Target languages: [${languages.join(',')}]
      
      Return result in this exact JSON format:
      {
        "language": "detected_language_code",
        "translations": {
          "language_code": "translated_text"
        }
      }
      
      Only return the JSON, no explanation or other text.
    `);
    console.log("Response:", JSON.stringify(result.response));

    // Find the start and end of the JSON in the text
    const responseText = result.response.candidates[0].content.parts[0].text;
    const jsonStart = responseText.indexOf('{');
    const jsonEnd = responseText.lastIndexOf('}') + 1;
    const jsonStr = responseText.slice(jsonStart, jsonEnd);
    
    // Parse JSON string
    const parsedResponse = JSON.parse(jsonStr);
    
    const detectedLanguage = parsedResponse.language;
    const translations = Object.entries(parsedResponse.translations).map(([code, translation]) => ({
      code,
      translation
    }));
    
    translated = translations;
    console.log(`Translations: ${JSON.stringify(translated)}`);
    console.log(`Detected language: ${detectedLanguage}`);

    if (detectedLanguage && !languages.includes(detectedLanguage)) {
      console.log(`Adding new language code: ${detectedLanguage}`);
      try {
        await languagesCollection.add({ code: detectedLanguage });
        console.log("Successfully added new language code to database");
      } catch (error) {
        console.error("Error adding new language code to database:", error);
      }
    }
  } catch (error) {
    console.error("Processing error:", error);
  }

  // Finally, save results with original and translations
  try {
    await event.data.after.ref.set({
      "original": message,
      "translations": translated,
    }, { merge: true });
    console.log("Successfully saved translations");
  } catch (error) {
    console.error("Error saving translations:", error);
  }
});