const pool = require('../config/database');

class Stories {
    static async getAllStories() {
        try {
            const query = 'SELECT * FROM user_stories ORDER BY created_at DESC';
            const result = await pool.query(query);
            return result.rows;
        } catch (error) {
            console.error('Error fetching stories:', error);
            throw error;
        }
    }

    static async createStory(userData) {
        const { user_id, title, content, is_anonymous, author_name } = userData;
        try {
            const query = `
                INSERT INTO user_stories (user_id, title, content, is_anonymous, author_name)
                VALUES ($1, $2, $3, $4, $5)
                RETURNING *
            `;
            const values = [user_id, title, content, is_anonymous, author_name];
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error creating story:', error);
            throw error;
        }
    }

    static async deleteStory(id, uid) {
        try {
            const query = 'DELETE FROM user_stories WHERE id = $1 RETURNING *';
            const result = await pool.query(query, [id]);
            return result.rowCount > 0;
        } catch (error) {
            console.error('Error deleting story:', error);
            throw error;
        }
    }


}

module.exports = Stories;
