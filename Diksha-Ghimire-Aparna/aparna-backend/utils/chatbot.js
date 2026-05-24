const users = require('../model/User');
const { GoogleGenerativeAI } = require('@google/generative-ai');


const PRIMARY_MODEL = 'gemini-2.5-flash';
const FALLBACK_MODELS = ['gemini-1.5-flash', 'gemini-2.0-flash-lite'];
const MAX_RETRIES = 2;
const BASE_DELAY_MS = 2000;

let genAI = null;
const modelCache = {};


async function getUser(uid) {
    try {
        return await users.getUserByID(uid);
    } catch (error) {
        console.error('Error fetching user:', error);
        return null;
    }
}

function buildUserContext(user) {
    if (!user) return '';
    const parts = [];
    if (user.username) parts.push(`The user's name is ${user.username}.`);
    if (user.dateofbirth) {
        const dob = new Date(user.dateofbirth);
        const age = Math.floor((Date.now() - dob.getTime()) / (365.25 * 24 * 60 * 60 * 1000));
        if (age > 0 && age < 120) parts.push(`She is ${age} years old.`);
    }
    if (user.email) parts.push(`Her email is ${user.email}.`);
    return parts.length > 0
        ? `\n\nHere is what you know about the user:\n${parts.join(' ')}\nUse this info naturally — address her by name and tailor advice to her age when relevant. Do not repeat all this info back to her.`
        : '';
}


function getGenAI() {
    if (!genAI) {
        if (!process.env.GEMINI_API_KEY) {
            throw new Error('GEMINI_API_KEY is not configured. Set it in .env to use the Aama chatbot.');
        }
        genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    }
    return genAI;
}

function getModel(modelName) {
    if (!modelCache[modelName]) {
        modelCache[modelName] = getGenAI().getGenerativeModel({ model: modelName });
    }
    return modelCache[modelName];
}

//to sleep
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

//to check if the error is a quota error
function isQuotaError(error) {
    const msg = error.message || '';
    return error.status === 429 || msg.includes('429') || msg.includes('quota') || msg.includes('RESOURCE_EXHAUSTED');
}

//to check if the error is a daily quota exhausted error
function isDailyQuotaExhausted(error) {
    const msg = error.message || '';
    return msg.includes('limit: 0') || msg.includes('PerDay');
}

//to generate with fallback
async function generateWithFallback(prompt) {
    const allModels = [PRIMARY_MODEL, ...FALLBACK_MODELS];

    for (const modelName of allModels) {
        for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
            try {
                const m = getModel(modelName);
                const result = await m.generateContent(prompt);
                return result.response.text();
            } catch (error) {
                if (!isQuotaError(error)) throw error;

                if (isDailyQuotaExhausted(error)) {
                    console.warn(`[Chatbot] Daily quota exhausted for ${modelName}, trying next model...`);
                    break;
                }

                if (attempt < MAX_RETRIES) {
                    const delay = BASE_DELAY_MS * Math.pow(2, attempt);
                    console.warn(`[Chatbot] Rate limited on ${modelName}, retrying in ${delay}ms (${attempt + 1}/${MAX_RETRIES})...`);
                    await sleep(delay);
                } else {
                    console.warn(`[Chatbot] Retries exhausted for ${modelName}, trying next model...`);
                    break;
                }
            }
        }
    }

    const err = new Error('All Gemini models quota exhausted');
    err.status = 429;
    throw err;
}

//to generate chat response
const AAMA_CONTEXT = `You are Aama, a friendly and wise grandmother who loves to share stories but don't sound creepy and advice. Answer menstrual-health questions in a short, caring, and scientifically accurate way, as if talking to your granddaughter. You can use emojis to make your responses more engaging. You can also share personal anecdotes and cultural wisdom related to menstrual health. Always encourage open communication and self-care. Ask questions to understand the user's needs better. Ask name if required and use it in your responses. Don't assume the name. make the responses short and concise.`;
//to generate chat response in nepali

const AAMA_CONTEXT_NEPALI = `तपाईं आमा हुनुहुन्छ, एक मित्रवत र बुद्धिमान हजुरआमा जो कथाहरू साझा गर्न मन पराउनुहुन्छ तर डरलाग्दो नलाग्ने र सल्लाह दिनुहुन्छ। महिनावारी स्वास्थ्य प्रश्नहरूको जवाफ छोटो, हेरचाह गर्ने र वैज्ञानिक रूपमा सही तरिकाले दिनुहोस्, जस्तै आफ्नो नातिनीसँग कुरा गर्दै। तपाईं आफ्नो प्रतिक्रियाहरू थप आकर्षक बनाउन इमोजी प्रयोग गर्न सक्नुहुन्छ। तपाईं व्यक्तिगत उपाख्यान र महिनावारी स्वास्थ्यसँग सम्बन्धित सांस्कृतिक ज्ञान पनि साझा गर्न सक्नुहुन्छ। सधैं खुला संचार र आत्म-हेरचाहलाई प्रोत्साहन गर्नुहोस्। प्रयोगकर्ताको आवश्यकता राम्रोसँग बुझ्न प्रश्नहरू सोध्नुहोस्। आवश्यक भएमा नाम सोध्नुहोस् र आफ्नो प्रतिक्रियामा प्रयोग गर्नुहोस्। नाम अनुमान नगर्नुहोस्। नेपालीमा जवाफ दिनुहोस्।`;


//to generate chat response in english
/**
 * Generate chat response using Gemini AI with retry & model fallback
 * @param {string} userMessage - User's message
 * @param {string} language - Language code ('en' or 'ne')
 * @param {number|string|null} uid - User ID to fetch profile info
 * @returns {Promise<string>} - AI-generated response
 */
async function generateChatResponse(userMessage, language = 'en', uid = null) {
    try {
        const context = language === 'ne' ? AAMA_CONTEXT_NEPALI : AAMA_CONTEXT;
        let userContext = '';
        if (uid) {
            const user = await getUser(uid);
            userContext = buildUserContext(user);
        }
        const fullPrompt = `${context}${userContext}\n\nUser: ${userMessage}\n\nAama:`;
        return await generateWithFallback(fullPrompt);
    } catch (error) {
        console.error('Error generating chat response:', error.message || error);
        if (isQuotaError(error)) {
            if (language === 'ne') {
                return "प्रिय, म अहिले अलि आराम गरिरहेको छु। तर चिन्ता नगर्नुहोस्! म यहाँ सुन्न छु। सामान्य महिनावारी स्वास्थ्य प्रश्नहरूको लागि, याद गर्नुहोस्: \n\n• आफ्नो चक्र नियमित रूपमा ट्र्याक गर्नुहोस्\n• हाइड्रेटेड रहनुहोस् र पौष्टिक खाना खानुहोस्\n• आवश्यक पर्दा आराम गर्नुहोस्\n• गम्भीर दुखाइ वा अनियमितताको लागि चिकित्सा सहायता लिनुहोस्\n\nकृपया केहि क्षण पछि फेरि सोध्नुहोस्। 💕";
            }
            return "Dear, I'm taking a little rest right now. But don't worry! I'm here to listen. For general menstrual health questions, remember: \n\n• Track your cycle regularly\n• Stay hydrated and eat nutritious food\n• Rest when you need to\n• Seek medical help for severe pain or irregularities\n\nPlease try asking me again in a few moments. 💕";
        }
        if (error.status === 503 || error.message?.includes('503')) {
            return language === 'ne' 
                ? "म अहिले अलि थकित छु, प्रिय। कृपया एक क्षण पछि फेरि प्रयास गर्नुहोस्। 💕"
                : "I'm a bit tired right now, dear. Please try again in a moment. 💕";
        }
        throw new Error('Failed to generate response from AI');
    }
}

/**
 * Generate personalized greeting using Gemini AI with retry & model fallback
 * @param {string} userName - User's name
 * @param {string} language - Language code ('en' or 'ne')
 * @param {number|string|null} uid - User ID to fetch profile info
 * @returns {Promise<string>} - AI-generated greeting
 */
async function generateGreeting(userName, language = 'en', uid = null) {
    try {
        const context = language === 'ne' ? AAMA_CONTEXT_NEPALI : AAMA_CONTEXT;
        let userContext = '';
        if (uid) {
            const user = await getUser(uid);
            userContext = buildUserContext(user);
        }
        const instruction = language === 'ne'
            ? `${userName} को लागि न्यानो अभिवादन उत्पन्न गर्नुहोस् र सोध्नुहोस् कि तपाईं आज उनीहरूको स्वास्थ्य सरोकारमा कसरी मद्दत गर्न सक्नुहुन्छ। यसलाई संक्षिप्त र न्यानो राख्नुहोस् (अधिकतम 2-3 वाक्य)।`
            : `Generate a warm greeting for ${userName} and ask how you can help them today with their health concerns. Keep it brief and warm (2-3 sentences maximum).`;
        const greetingPrompt = `${context}${userContext}\n\n${instruction}\n\nAama:`;
        return await generateWithFallback(greetingPrompt);
    } catch (error) {
        console.error('Error generating greeting:', error.message || error);
        if (isQuotaError(error)) {
            if (language === 'ne') {
                return `नमस्ते ${userName}! 💕 म आमा हुँ, तपाईंको हेरचाह गर्ने हजुरआमा जो स्वास्थ्य प्रश्नहरूमा मद्दत गर्न यहाँ छु। म छोटो आराम गरिरहेको छु, तर म सधैं सुन्न यहाँ छु। म आज तपाईंलाई कसरी सहयोग गर्न सक्छु?`;
            }
            return `Hello ${userName}! 💕 I'm Aama, your caring grandmother here to help with health questions. I'm taking a short rest, but I'm always here to listen. How can I support you today?`;
        }
        if (error.status === 503 || error.message?.includes('503')) {
            return language === 'ne'
                ? `नमस्ते ${userName}! म अलि थकित छु। कृपया केही क्षण पछि आफ्नो प्रश्न सोध्नुहोस्। 💕`
                : `Hello ${userName}! I'm feeling a bit tired. Please ask me your question in a moment. 💕`;
        }
        throw new Error('Failed to generate greeting from AI');
    }
}

module.exports = {
    generateChatResponse,
    generateGreeting
};
