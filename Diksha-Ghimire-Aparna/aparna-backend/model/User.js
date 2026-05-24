const pool= require('../config/database');

function isTransientDbError(error) {
    if (!error) return false;
    const transientCodes = ['ECONNRESET', 'ECONNREFUSED', '57P01', '57P02', '57P03'];
    return transientCodes.includes(error.code) || transientCodes.includes(error.errno);
}

async function queryWithRetry(query, values = [], maxRetries = 1) {
    let lastError;
    for (let attempt = 0; attempt <= maxRetries; attempt += 1) {
        try {
            return await pool.query(query, values);
        } catch (error) {
            lastError = error;
            if (!isTransientDbError(error) || attempt === maxRetries) {
                throw error;
            }
        }
    }
    throw lastError;
}

class User {
    static async createUser(userData) {
        const emailVerified = userData.emailVerified !== undefined ? userData.emailVerified : true;
        const query = 'INSERT INTO users("username", "email", "phone", "dateofbirth", "password", "createdat", "role", "email_verified") VALUES ($1, $2, $3, $4, $5, NOW(), $6, $7) RETURNING *';
        const values = [userData.username, userData.email, userData.phone, userData.dateofbirth, userData.password, userData.role, emailVerified];
        try{
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error creating user:', error);
            throw error;
        }
    }
    static async getUserByUsername(username) {
        const query = 'SELECT * FROM users WHERE "username" = $1';
        try {
            const result = await queryWithRetry(query, [username], 1);
            return result.rows[0];
        } catch (error) {
            if (isTransientDbError(error)) {
                error.isDbConnectionIssue = true;
            }
            console.error('Error fetching user by username:', error);
            throw error;
        }
    }

    static async getUserByEmail(email) {
        const query = 'SELECT * FROM users WHERE "email" = $1';
        try {
            const result = await queryWithRetry(query, [email], 1);
            return result.rows[0];
        } catch (error) {
            if (isTransientDbError(error)) {
                error.isDbConnectionIssue = true;
            }
            console.error('Error fetching user by email:', error);
            throw error;
        }
    }
    static async getUserByID(uid) {
        const query = 'SELECT * FROM users WHERE uid = $1';
        try {
            const result = await queryWithRetry(query, [uid], 1);
            return result.rows[0];
        } catch (error) {
            if (isTransientDbError(error)) {
                error.isDbConnectionIssue = true;
            }
            console.error('Error fetching user by ID:', error);
            throw error;
        }
    }

    
    static async getAllUsers() {
        const query = `
            SELECT 
                u.uid,
                u.username,
                u.email,
                u.phone,
                u.dateofbirth,
                u.createdat,
                u.role,
                u.profilephoto,
                COALESCE(COUNT(DISTINCT uc.id), 0)::int as cycle_count,
                COALESCE(COUNT(DISTINCT b.id), 0)::int as blog_count,
                COALESCE(COUNT(DISTINCT eh.exid), 0)::int as clinic_count
            FROM users u
            LEFT JOIN user_cycles uc ON u.uid = uc.uid
            LEFT JOIN "Blog" b ON b.userid = u.uid
            LEFT JOIN "ExpertHelp" eh ON eh.userid = u.uid
            GROUP BY u.uid, u.username, u.email, u.phone, u.dateofbirth, u.createdat, u.role, u.profilephoto
            ORDER BY u.createdat DESC
        `;
        try {
            const result = await pool.query(query);
            return result.rows;
        } catch (error) {
            console.error('Error fetching all users:', error);
            throw error;
        }
    }


    static async deleteUser(uid) {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            await client.query('DELETE FROM chat_messages WHERE user_id = $1', [uid]);
            await client.query('DELETE FROM "Blog" WHERE userid = $1', [uid]);
            await client.query('DELETE FROM blog_views WHERE user_id = $1', [uid]);
            await client.query('DELETE FROM user_cycles WHERE uid = $1', [uid]);
            await client.query('DELETE FROM daily_logs WHERE uid = $1', [uid]);
            await client.query('DELETE FROM user_stories WHERE user_id = $1', [uid]);
            await client.query('DELETE FROM notifications WHERE user_id = $1', [uid]);
            await client.query('DELETE FROM user_devices WHERE user_id = $1', [uid]);
            await client.query('DELETE FROM expert_help WHERE userid = $1', [uid]);
            await client.query('DELETE FROM health WHERE user_id = $1', [uid]);

            const result = await client.query('DELETE FROM users WHERE uid = $1', [uid]);

            await client.query('COMMIT');
            return result.rowCount > 0;
        } catch (error) {
            await client.query('ROLLBACK');
            console.error('Error deleting user:', error);
            throw error;
        } finally {
            client.release();
        }
    }

    static async updateUsername(UID, userData) {
        const query = 'UPDATE users SET "username" = $1 WHERE "UID" = $2 RETURNING *';
        const values = [userData.username, UID];
        try {
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error updating user:', error);
            throw error;
        }
    }


    static async getUsernameByID(UID) {
        const query = 'SELECT "username" FROM users WHERE "UID" = $1';
        try {
            const result = await pool.query(query, [UID]);
            return result.rows[0];
        } catch (error) {
            console.error('Error fetching username by ID:', error);
            throw error;
        }   
    }

    static async setEmailVerified(uid, verified = true) {
        const query = 'UPDATE users SET email_verified = $1 WHERE uid = $2 RETURNING *';
        try {
            const result = await pool.query(query, [verified, uid]);
            return result.rows[0];
        } catch (error) {
            console.error('Error setting email verified:', error);
            throw error;
        }
    }

    static async updatePassword(uid, hashedPassword) {
        const query = 'UPDATE users SET "password" = $1 WHERE "uid" = $2 RETURNING *';
        const values = [hashedPassword, uid];
        try {
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error updating password:', error);
            throw error;
        }
    }
    static async updateEmail(uid, email) {
        const query = 'UPDATE users SET "email" = $1 WHERE "uid" = $2 RETURNING *';
        const values = [email, uid];
        try {
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error updating email:', error);
            throw error;
        }
    }
    static async getEmailByID(uid) {
        const query = 'SELECT "email" FROM users WHERE "uid" = $1';
        try {
            const result = await pool.query(query, [uid]);
            return result.rows[0];
        } catch (error) {
            console.error('Error fetching email by ID:', error);
            throw error;
        }   
    }
    static async updatePhone(uid, phone) {
        const query = 'UPDATE users SET "phone" = $1 WHERE "uid" = $2 RETURNING *';
        const values = [phone, uid];
        try {
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error updating phone:', error);
            throw error;
        }
    }
    static async getPhoneByID(uid) {
        const query = 'SELECT "phone" FROM users WHERE "uid" = $1';
        try {
            const result = await pool.query(query, [uid]);
            return result.rows[0];
        } catch (error) {
            console.error('Error fetching phone by ID:', error);
            throw error;
        }   
    }
    static async updateDateOfBirth(uid, dateofbirth) {
        const query = 'UPDATE users SET "dateofbirth" = $1 WHERE "uid" = $2 RETURNING *';
        const values = [dateofbirth, uid];
        try {
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error updating date of birth:', error);
            throw error;
        }
    }
    static async getDateOfBirthByID(uid) {
        const query = 'SELECT "dateofbirth" FROM users WHERE "uid" = $1';
        try {
            const result = await pool.query(query, [uid]);
            return result.rows[0];
        } catch (error) {
            console.error('Error fetching date of birth by ID:', error);
            throw error;
        }   
    }

    static async countUsers() {
        const query = 'SELECT COUNT(*) FROM users';
        try {
            const result = await pool.query(query);
            return result.rows[0].count;
        } catch (error) {
            console.error('Error counting users:', error);
            throw error;
        }
    }   
}
module.exports = User;