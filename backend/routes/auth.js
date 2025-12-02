const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { pool } = require('../db');
const config = require('../config');

// Register
router.post('/register', async (req, res) => {
  let connection;
  try {
    const { username, email, password, role } = req.body;

    // Validate input
    if (!username || !email || !password) {
      return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }

    connection = await pool.getConnection();

    // Check if user already exists
    const [existingUsers] = await connection.execute(
      'SELECT user_id FROM login WHERE username = ? OR email = ?',
      [username, email]
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({ 
        message: 'ชื่อผู้ใช้หรืออีเมลนี้ถูกใช้งานแล้ว' 
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Insert new user
    const [result] = await connection.execute(
      `INSERT INTO login (username, email, password_hash, role) 
       VALUES (?, ?, ?, ?)`,
      [username, email, hashedPassword, role || 'employee']
    );

    res.status(201).json({ 
      message: 'ลงทะเบียนสำเร็จ! คุณสามารถเข้าสู่ระบบได้แล้ว',
      user: {
        id: result.insertId,
        username,
        email,
        role: role || 'employee',
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการลงทะเบียน' });
  } finally {
    if (connection) connection.release();
  }
});

// Login
router.post('/login', async (req, res) => {
  let connection;
  try {
    const { login_id, password } = req.body;

    if (!login_id || !password) {
      return res.status(400).json({ message: 'กรุณากรอก Username/Email และรหัสผ่าน' });
    }

    connection = await pool.getConnection();

    // Find user by username or email
    const [users] = await connection.execute(
      `SELECT user_id, username, email, password_hash, role 
       FROM login 
       WHERE username = ? OR email = ?`,
      [login_id.toLowerCase(), login_id.toLowerCase()]
    );

    if (users.length === 0) {
      return res.status(401).json({ message: 'Username หรือ Email ไม่ถูกต้อง' });
    }

    const user = users[0];

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'รหัสผ่านไม่ถูกต้อง' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        user_id: user.user_id, 
        username: user.username,
        role: user.role 
      },
      config.jwtSecret,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'เข้าสู่ระบบสำเร็จ',
      token,
      user_id: user.user_id,
      username: user.username,
      role: user.role,
      user: {
        id: user.user_id,
        username: user.username,
        email: user.email,
        firstName: user.username,
        lastName: '',
        position: 'Employee',
        role: user.role,
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ' });
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;
