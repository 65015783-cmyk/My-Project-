// ===========================
// Script สำหรับ Reset Admin Password เป็น 6 ตัว
// รันด้วย: node reset_admin_password.js
// ===========================

const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
const config = require('./config');

async function resetAdminPassword() {
  let connection;
  try {
    // Connect to database
    connection = await mysql.createConnection({
      host: config.db.host,
      user: config.db.user,
      password: config.db.password,
      database: config.db.database,
      port: config.db.port
    });

    console.log('✅ Connected to database');

    // Hash password '123456' (6 ตัว)
    const password = '123456';
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    console.log('🔐 Password hash generated:', hashedPassword);

    // Update admin password
    const [result] = await connection.execute(
      `UPDATE login 
       SET password_hash = ? 
       WHERE username = 'admin'`,
      [hashedPassword]
    );

    if (result.affectedRows === 0) {
      // Create admin if doesn't exist
      await connection.execute(
        `INSERT INTO login (username, email, password_hash, role) 
         VALUES ('admin', 'admin@humans.com', ?, 'admin')`,
        [hashedPassword]
      );
      console.log('✅ Admin user created');
    } else {
      console.log('✅ Admin password updated');
    }

    // Verify
    const [users] = await connection.execute(
      `SELECT user_id, username, email, role 
       FROM login 
       WHERE username = 'admin'`
    );

    console.log('\n📋 Admin User Info:');
    console.log(users[0]);

    // Test password
    const testPassword = await bcrypt.compare('123456', hashedPassword);
    console.log('\n🧪 Password Test:');
    console.log('Password "123456" matches hash:', testPassword);

    console.log('\n✅ Done! You can now login with:');
    console.log('   Username: admin');
    console.log('   Password: 123456 (6 characters)');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

resetAdminPassword();
