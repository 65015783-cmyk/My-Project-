const express = require('express');
const router = express.Router();
const { pool } = require('../db');
const { authenticateToken } = require('../middleware/auth');

// Request leave
router.post('/request', authenticateToken, async (req, res) => {
  let connection;
  try {
    const { leaveType, startDate, endDate, reason } = req.body;
    const userId = req.user.user_id;

    if (!leaveType || !startDate || !endDate || !reason) {
      return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }

    connection = await pool.getConnection();

    const [result] = await connection.execute(
      `INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) 
       VALUES (?, ?, ?, ?, ?, 'pending')`,
      [userId, leaveType, startDate, endDate, reason]
    );

    res.status(201).json({
      message: 'ส่งคำขอลางานสำเร็จ',
      leaveId: result.insertId,
    });
  } catch (error) {
    console.error('Leave request error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการส่งคำขอลางาน' });
  } finally {
    if (connection) connection.release();
  }
});

// Get leave history
router.get('/history', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userId = req.user.user_id;

    connection = await pool.getConnection();

    const [leaves] = await connection.execute(
      `SELECT * FROM leaves 
       WHERE user_id = ? 
       ORDER BY created_at DESC 
       LIMIT 100`,
      [userId]
    );

    res.json({ leaves });
  } catch (error) {
    console.error('Get leave history error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

// Approve/Reject leave (Admin only)
router.patch('/:leaveId/status', authenticateToken, async (req, res) => {
  let connection;
  try {
    const { leaveId } = req.params;
    const { status } = req.body; // 'approved' or 'rejected'
    const adminId = req.user.user_id;

    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'คุณไม่มีสิทธิ์ในการอนุมัติ/ปฏิเสธ' });
    }

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'สถานะไม่ถูกต้อง' });
    }

    connection = await pool.getConnection();

    await connection.execute(
      `UPDATE leaves 
       SET status = ?, approved_by = ?, approved_at = NOW(), updated_at = NOW() 
       WHERE id = ?`,
      [status, adminId, leaveId]
    );

    res.json({ message: `${status === 'approved' ? 'อนุมัติ' : 'ปฏิเสธ'}คำขอลางานสำเร็จ` });
  } catch (error) {
    console.error('Update leave status error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;

