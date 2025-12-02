const express = require('express');
const router = express.Router();
const { pool } = require('../db');
const { authenticateToken } = require('../middleware/auth');

// Check-in
router.post('/checkin', authenticateToken, async (req, res) => {
  let connection;
  try {
    const { date, imagePath } = req.body;
    const userId = req.user.user_id;

    const checkInDate = date ? new Date(date) : new Date();
    const dateStr = checkInDate.toISOString().split('T')[0]; // YYYY-MM-DD

    connection = await pool.getConnection();

    // Check if already checked in today
    // ถ้าไม่มีตาราง attendance ให้สร้างก่อน หรือใช้ตารางอื่นที่มีอยู่
    const [existing] = await connection.execute(
      'SELECT id, check_in_time FROM attendance WHERE user_id = ? AND date = ? LIMIT 1',
      [userId, dateStr]
    ).catch(() => [[]]);  // ถ้า error (ไม่มีตาราง) ให้คืน array ว่าง

    if (existing.length > 0 && existing[0].check_in_time) {
      return res.status(400).json({ 
        message: 'คุณได้เช็คอินวันนี้แล้ว' 
      });
    }

    const now = new Date();

    if (existing.length > 0) {
      // Update existing record
      await connection.execute(
        `UPDATE attendance 
         SET check_in_time = ?, check_in_image_path = ?, updated_at = NOW() 
         WHERE id = ?`,
        [now, imagePath || '', existing[0].id]
      );
    } else {
      // Insert new record
      await connection.execute(
        `INSERT INTO attendance (user_id, date, check_in_time, check_in_image_path) 
         VALUES (?, ?, ?, ?)`,
        [userId, dateStr, now, imagePath || '']
      );
    }

    res.json({
      message: 'เช็คอินสำเร็จ',
      checkInTime: now,
    });
  } catch (error) {
    console.error('Check-in error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการเช็คอิน' });
  } finally {
    if (connection) connection.release();
  }
});

// Check-out
router.post('/checkout', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userId = req.user.user_id;
    const today = new Date().toISOString().split('T')[0];

    connection = await pool.getConnection();

    const [attendance] = await connection.execute(
      'SELECT id, check_in_time, check_out_time FROM attendance WHERE user_id = ? AND date = ?',
      [userId, today]
    );

    if (attendance.length === 0 || !attendance[0].check_in_time) {
      return res.status(400).json({ 
        message: 'คุณยังไม่ได้เช็คอินวันนี้' 
      });
    }

    if (attendance[0].check_out_time) {
      return res.status(400).json({ 
        message: 'คุณได้เช็คเอาท์แล้ว' 
      });
    }

    const now = new Date();
    await connection.execute(
      'UPDATE attendance SET check_out_time = ?, updated_at = NOW() WHERE id = ?',
      [now, attendance[0].id]
    );

    res.json({
      message: 'เช็คเอาท์สำเร็จ',
      checkOutTime: now,
    });
  } catch (error) {
    console.error('Check-out error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการเช็คเอาท์' });
  } finally {
    if (connection) connection.release();
  }
});

// Get today's attendance
router.get('/today', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userId = req.user.user_id;
    const today = new Date().toISOString().split('T')[0];

    connection = await pool.getConnection();

    const [attendance] = await connection.execute(
      'SELECT * FROM attendance WHERE user_id = ? AND date = ?',
      [userId, today]
    );

    res.json({ attendance: attendance[0] || null });
  } catch (error) {
    console.error('Get attendance error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

// Get attendance history
router.get('/history', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userId = req.user.user_id;
    const { startDate, endDate } = req.query;

    connection = await pool.getConnection();

    let query = 'SELECT * FROM attendance WHERE user_id = ?';
    const params = [userId];

    if (startDate && endDate) {
      query += ' AND date BETWEEN ? AND ?';
      params.push(startDate, endDate);
    }

    query += ' ORDER BY date DESC LIMIT 100';

    const [attendances] = await connection.execute(query, params);

    res.json({ attendances });
  } catch (error) {
    console.error('Get history error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;
