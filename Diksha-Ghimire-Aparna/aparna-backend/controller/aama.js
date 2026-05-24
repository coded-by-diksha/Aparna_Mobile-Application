const User = require('../model/User');
const Chat = require('../model/Chat');

const {  generateChatResponse, generateGreeting } = require('../utils/chatbot');

// Send message to Aama chatbot
const sendMessage = async (req, res) => {
    try {
        const { message, language = 'en' } = req.body;
        console.log("Received message:", message, "Language:", language);
        if (!message) {
            return res.status(400).json({ 
                error: 'Message is required',
                success: false 
            });
        }

        const uid = req.user?.uid || null;
        const responseText = await generateChatResponse(message, language, uid);

        try {
            const user_id = req.user.uid;
            const sender = req.user.username ? req.user.username.substring(0, 10) : 'user';
            await Chat.saveMessage({ 
                user_id, 
                message, 
                response: responseText, 
                sender 
            });
            console.log('Chat message auto-saved for user:', user_id);
        } catch (saveError) {
            console.error('Failed to auto-save chat message:', saveError.message);
            // Continue even if save fails - don't break the chat experience
        }

        return res.status(200).json({
            response: responseText,
            success: true
        });
    } catch (error) {
        // Log full error server-side
        console.error('Error communicating with Aama chatbot:', error.stack || error.message);
        
        // Return a generic fallback if the chatbot fails completely
        return res.status(200).json({
            response: "I'm having a little trouble right now, dear. Please try asking your question again. 💕",
            success: true
        });
    }
};

// Get greeting from Aama
const getGreeting = async (req, res) => {
    try {
        const { userName, language = 'en' } = req.body;

        if (!userName) {
            return res.status(400).json({
                error: 'userName is required',
                success: false
            });
        }

        const uid = req.user?.uid || null;
        const greetingText = await generateGreeting(userName, language, uid);

        return res.status(200).json({
            response: greetingText,
            success: true
        });
    } catch (error) {
        console.error('Error getting greeting from Aama:', error.stack || error.message);
        const name = req.body?.userName || 'dear';
        return res.status(200).json({
            response: `Hello ${name}! 💕 I'm Aama, here to help with your health questions. How can I support you today?`,
            success: true
        });
    }
};


const storeChatMessage = async (req, res) => {
    console.log("i am inside store chat message");
    try {
        const { user_id, message, response } = req.body;
        
        if (!user_id || !message || !response) {
            return res.status(400).json({ 
                error: 'user_id, message, and response are required',
                success: false 
            });
        }
        
        // Get user to verify they exist
        const user = await User.getUserByID(user_id);
        if (!user) {
            return res.status(404).json({ 
                error: 'User not found',
                success: false 
            });
        }

        
        // Save chat message to database
        const savedChat = await Chat.saveMessage({ 
          
            user_id:user.uid, 
            message, 
            response, 
            sender: user.username
        });
        console.log('Chat message saved:', savedChat);
        return res.status(200).json({
            message: 'Chat message stored successfully',
            chat: savedChat,
            success: true
        });
    } catch (error) {
        console.error('Error storing chat message:', error.message);
        return res.status(500).json({
            error: 'Failed to store chat message',
            details: error.message,
            success: false
        });
    }
};

const getChatHistory = async (req, res) => {
    try {
        const { user_id } = req.query;
        
        if (!user_id) {
            return res.status(400).json({ 
                error: 'user_id is required',
                success: false 
            });
        }
        
        // Verify user exists
        const user = await User.getUserByID(user_id);
        if (!user) {
            return res.status(404).json({ 
                error: 'User not found',
                success: false 
            });
        }
        
        // Get chat history from database
        const chatHistory = await Chat.getMessagesByUser(user_id);
        
        return res.status(200).json({
            chatHistory: chatHistory,
            success: true
        });
    } catch (error) {
        console.error('Error retrieving chat history:', error.message);
        return res.status(500).json({
            error: 'Failed to retrieve chat history',
            details: error.message,
            success: false
        });
    }
};

// Health check for chatbot service
const checkHealth = async (req, res) => {
    try {
        // Test if AI service is working
        await generateGreeting('Test');
        
        return res.status(200).json({
            status: 'Aama chatbot service is running',
            connected: true,
            success: true
        });
    } catch (error) {
        return res.status(503).json({
            status: 'Aama chatbot service is not responding',
            connected: false,
            error: error.message,
            success: false
        });
    }
};

module.exports = {
    sendMessage,
    getGreeting,
    checkHealth,
    storeChatMessage,
     getChatHistory
};
