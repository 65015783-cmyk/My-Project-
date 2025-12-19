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
      `SELECT e.employee_id as id, e.user_id, e.first_name, e.last_name, e.phone_number, 
              e.date_of_birth, e.position, e.department,
              COALESCE(e.is_manager, 0) as is_manager,
              l.email, l.role
       FROM employees e
       LEFT JOIN login l ON e.user_id = l.user_id
       WHERE e.user_id = ?`,
      [userId]
    );

    if (users.length === 0) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลผู้ใช้' });
    }

    const user = users[0];
    // ส่งทั้ง role และ is_manager ไปให้ frontend
    const response = {
      ...user,
      role: user.role,
      isManager: user.is_manager === 1 || user.role === 'manager', // ใช้ทั้ง is_manager และ role
    };
    
    res.json({ user: response });
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
    const { firstName, lastName, position, phoneNumber, dateOfBirth, department } = req.body;

    connection = await pool.getConnection();

    await connection.execute(
      `UPDATE employees 
       SET first_name = ?, last_name = ?, position = ?, phone_number = ?, 
           date_of_birth = ?, department = ? 
       WHERE user_id = ?`,
      [firstName || '', lastName || '', position || '', phoneNumber || '', 
       dateOfBirth || null, department || '', userId]
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

