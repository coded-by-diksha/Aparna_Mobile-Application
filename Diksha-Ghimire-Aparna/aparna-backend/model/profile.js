const pool = require('../config/database');

class Profile {

    static async getUserProfile(user_id) {
        const query = 'SELECT uid, username, email, phone, dateofbirth, createdat, role, profilephoto FROM users WHERE uid = $1';
        try {
            const result = await pool.query(query, [user_id]);
            return result.rows[0];
        } catch (error) {
            console.error('Error fetching user profile:', error);
            throw error;
        }
    }
    static async updateUserProfile(user_id, profileData) {
        // First get existing user to preserve profilephoto if not provided
        const existingUser = await this.getUserProfile(user_id);
        
        const query = `UPDATE users SET 
            username = $1, 
            email = $2,
            phone = $3,
            dateofbirth = $4,
            profilephoto = $5
            WHERE uid = $6 RETURNING uid, username, email, phone, dateofbirth, createdat, role, profilephoto`;
        const values = [
            profileData.username, 
            profileData.email,
            profileData.phone,
            profileData.dateofbirth,
            profileData.profilephoto || existingUser?.profilephoto || null,
            user_id
        ];
        try {
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error updating user profile:', error);
            throw error;
        }
    }

    // to add moreprofile photo
    static async updateProfilePhoto(user_id, photoUrl) {
        const query = `UPDATE users SET 
            profilephoto = $1
            WHERE uid = $2 RETURNING uid, username, email, phone, dateofbirth, createdat, role, profilephoto`;
        const values = [
            photoUrl,
            user_id
        ];
        try {
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error updating profile photo:', error);
            throw error;
        }
    }

}

module.exports = Profile;