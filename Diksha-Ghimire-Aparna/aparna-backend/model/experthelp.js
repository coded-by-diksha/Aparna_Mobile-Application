const pool = require('../config/database');

class ExpertHelp {
    static async createTable() {
        const query = `
            CREATE TABLE IF NOT EXISTS "ExpertHelp" (
                exid SERIAL PRIMARY KEY,
                userid INTEGER,
                associatename VARCHAR(255) NOT NULL,
                address TEXT,
                longitude DECIMAL(12, 9),
                latitude DECIMAL(12, 9),
                description TEXT,
                contactinfo VARCHAR(255),
                clinic_image TEXT,
                createdat TIMESTAMP DEFAULT NOW(),
                updatedat TIMESTAMP DEFAULT NOW()
            );
            
            -- Ensure existing columns have enough precision and remove strict constraints
            DO $$ 
            BEGIN 
                ALTER TABLE "ExpertHelp" ALTER COLUMN longitude TYPE DECIMAL(12, 9);
                ALTER TABLE "ExpertHelp" ALTER COLUMN latitude TYPE DECIMAL(12, 9);
                
                -- Add address column if it doesn't exist
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name='ExpertHelp' AND column_name='address') THEN
                    ALTER TABLE "ExpertHelp" ADD COLUMN address TEXT;
                END IF;

                -- Add clinic_image column if it doesn't exist
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name='ExpertHelp' AND column_name='clinic_image') THEN
                    ALTER TABLE "ExpertHelp" ADD COLUMN clinic_image TEXT;
                END IF;

                -- Remove the foreign key constraint if it exists to prevent creation blockers
                ALTER TABLE "ExpertHelp" DROP CONSTRAINT IF EXISTS "ExpertHelp_userid_fkey";
            EXCEPTION WHEN OTHERS THEN 
                -- Handle cases where table might be locked or other issues
            END $$;
        `;
        try {
            await pool.query(query);
            console.log('ExpertHelp table ensuring exists without foreign key constraints...');
        } catch (error) {
            console.error('Error creating/altering ExpertHelp table:', error);
            throw error;
        }
    }

    static async createExpert(data) {
        await this.createTable();
        const query = `
            INSERT INTO "ExpertHelp" (userid, associatename, address, longitude, latitude, description, contactinfo, clinic_image, createdat, updatedat)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
            RETURNING *
        `;
        const values = [data.userid || null, data.associatename, data.address, data.longitude, data.latitude, data.description, data.contactinfo, data.clinic_image || null];
        try {
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error creating expert help record:', error);
            throw error;
        }
    }

    static async getAllExperts() {
        await this.createTable();
        const query = 'SELECT * FROM "ExpertHelp" ORDER BY createdat DESC';
        try {
            const result = await pool.query(query);
            return result.rows;
        } catch (error) {
            console.error('Error fetching all expert help records:', error);
            throw error;
        }
    }

    static async getExpertById(id) {
        await this.createTable();
        const query = 'SELECT * FROM "ExpertHelp" WHERE exid = $1';
        try {
            const result = await pool.query(query, [id]);
            return result.rows[0];
        } catch (error) {
            console.error('Error fetching expert help record by ID:', error);
            throw error;
        }
    }

    static async updateExpert(id, data) {
        await this.createTable();
        const query = `
            UPDATE "ExpertHelp" 
            SET associatename = $1, address = $2, longitude = $3, latitude = $4, description = $5, contactinfo = $6, clinic_image = $7, updatedat = NOW()
            WHERE exid = $8
            RETURNING *
        `;
        const values = [data.associatename, data.address, data.longitude, data.latitude, data.description, data.contactinfo, data.clinic_image, id];
        try {
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error updating expert help record:', error);
            throw error;
        }
    }

    static async deleteExpert(id) {
        await this.createTable();
        const query = 'DELETE FROM "ExpertHelp" WHERE exid = $1 RETURNING *';
        try {
            const result = await pool.query(query, [id]);
            return result.rows[0];
        } catch (error) {
            console.error('Error deleting expert help record:', error);
            throw error;
        }
    }

    static async countExperts() {
        await this.createTable();
        const query = 'SELECT COUNT(*) FROM "ExpertHelp"';
        try {
            const result = await pool.query(query);
            return result.rows[0].count;
        } catch (error) {
            console.error('Error counting experts:', error);
            throw error;
        }
    }
}

module.exports = ExpertHelp;
