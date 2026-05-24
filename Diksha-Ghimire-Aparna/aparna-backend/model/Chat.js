const pool = require('../config/database');

class Chat {
    static async saveMessage(chatData) {
        const query = `
            INSERT INTO chat_messages(user_id, message, response, sender, created_at) 
            VALUES ($1, $2, $3, $4, NOW()) 
            RETURNING *
        `;
        const values = [chatData.user_id, chatData.message, chatData.response, chatData.sender];
        const result = await pool.query(query, values);
        return result.rows[0];
    }
    
    static async getMessagesByUser(user_id) {
        const query = 'SELECT * FROM chat_messages WHERE user_id = $1 ORDER BY created_at ASC';
        const values = [user_id];
        const result = await pool.query(query, values);
        return result.rows;
    }


     
}

module.exports = Chat;
