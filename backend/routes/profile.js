const express = require('express');
const router = express.Router();
const { pool } = require('../db');
const { authenticateToken } = require('../middleware/auth');

// Get user profile
router.get('/', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userId = req.user.user_id;

    connection = await pool.getConnection();

    const [users] = await connection.execute(
      `SELECT id, username, email, first_name, last_name, position, role, avatar_url, created_at 
       FROM users 
       WHERE id = ?`,
      [userId]
    );

    if (users.length === 0) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลผู้ใช้' });
    }

    res.json({ user: users[0] });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

// Update user profile
router.put('/', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userId = req.user.user_id;
    const { firstName, lastName, position, avatarUrl } = req.body;

    connection = await pool.getConnection();

    await connection.execute(
      `UPDATE users 
       SET first_name = ?, last_name = ?, position = ?, avatar_url = ?, updated_at = NOW() 
       WHERE id = ?`,
      [firstName || '', lastName || '', position || '', avatarUrl || '', userId]
    );

    res.json({ message: 'อัปเดตโปรไฟล์สำเร็จ' });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;

