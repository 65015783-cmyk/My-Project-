const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { pool } = require('../db');
const { authenticateToken } = require('../middleware/auth');

// Get all employees (Admin only)
router.get('/', authenticateToken, async (req, res) => {
  let connection;
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'คุณไม่มีสิทธิ์เข้าถึง' });
    }

    connection = await pool.getConnection();

    const [employees] = await connection.execute(
      'SELECT user_id, username, email, role, created_at FROM login ORDER BY created_at DESC'
    );

    res.json({ employees });
  } catch (error) {
    console.error('Get employees error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

// Create employee (Admin only)
router.post('/', authenticateToken, async (req, res) => {
  let connection;
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'คุณไม่มีสิทธิ์เข้าถึง' });
    }

    const { username, email, password, role } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }

    connection = await pool.getConnection();

    // Check if exists
    const [existing] = await connection.execute(
      'SELECT user_id FROM login WHERE username = ? OR email = ?',
      [username, email]
    );

    if (existing.length > 0) {
      return res.status(409).json({ message: 'ชื่อผู้ใช้หรืออีเมลนี้ถูกใช้งานแล้ว' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Insert
    const [result] = await connection.execute(
      'INSERT INTO login (username, email, password_hash, role) VALUES (?, ?, ?, ?)',
      [username, email, hashedPassword, role || 'employee']
    );

    res.status(201).json({
      message: 'เพิ่มพนักงานสำเร็จ',
      employeeId: result.insertId,
    });
  } catch (error) {
    console.error('Create employee error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

// Update employee (Admin only)
router.put('/:userId', authenticateToken, async (req, res) => {
  let connection;
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'คุณไม่มีสิทธิ์เข้าถึง' });
    }

    const { userId } = req.params;
    const { username, email, password, role } = req.body;

    connection = await pool.getConnection();

    // Check if username/email already used by others
    const [existing] = await connection.execute(
      'SELECT user_id FROM login WHERE (username = ? OR email = ?) AND user_id != ?',
      [username, email, userId]
    );

    if (existing.length > 0) {
      return res.status(409).json({ message: 'ชื่อผู้ใช้หรืออีเมลนี้ถูกใช้งานแล้ว' });
    }

    // Update
    if (password && password.length > 0) {
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(password, salt);
      
      await connection.execute(
        'UPDATE login SET username = ?, email = ?, password_hash = ?, role = ? WHERE user_id = ?',
        [username, email, hashedPassword, role, userId]
      );
    } else {
      await connection.execute(
        'UPDATE login SET username = ?, email = ?, role = ? WHERE user_id = ?',
        [username, email, role, userId]
      );
    }

    res.json({ message: 'แก้ไขพนักงานสำเร็จ' });
  } catch (error) {
    console.error('Update employee error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

// Delete employee (Admin only)
router.delete('/:userId', authenticateToken, async (req, res) => {
  let connection;
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'คุณไม่มีสิทธิ์เข้าถึง' });
    }

    const { userId } = req.params;

    connection = await pool.getConnection();

    await connection.execute(
      'DELETE FROM login WHERE user_id = ?',
      [userId]
    );

    res.json({ message: 'ลบพนักงานสำเร็จ' });
  } catch (error) {
    console.error('Delete employee error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;

