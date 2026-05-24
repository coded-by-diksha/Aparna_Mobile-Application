const pool = require('./config/database');
const bcrypt = require('bcrypt');

async function createAdmin() {
    const password = await bcrypt.hash('doremon123', 10); // Change 'admin123' to your desired password
    
    const query = `INSERT INTO users("username", "email", "phone", "dateofbirth", "password", "createdat", "role") 
                   VALUES ($1, $2, $3, $4, $5, NOW(), $6) RETURNING *`;
    
    const values = ['doremon', 'doremon@aparna.com', '9800000000', '2006-04-28', password, 'admin'];
    
    try {
        const result = await pool.query(query, values);
        console.log('Admin created:', result.rows[0]);
        process.exit(0);
    } catch (error) {
        console.error('Error creating admin:', error);
        process.exit(1);
    }
}

createAdmin();
