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

    // สร้างตาราง attendance ถ้ายังไม่มี
    try {
      await connection.execute(`
        CREATE TABLE IF NOT EXISTS attendance (
          id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT NOT NULL,
          date DATE NOT NULL,
          check_in_time DATETIME DEFAULT NULL,
          check_out_time DATETIME DEFAULT NULL,
          check_in_image_path VARCHAR(500) DEFAULT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          INDEX idx_user_id (user_id),
          INDEX idx_date (date),
          FOREIGN KEY (user_id) REFERENCES login(user_id) ON DELETE CASCADE,
          UNIQUE KEY unique_user_date (user_id, date)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      `);
    } catch (tableError) {
      console.log('[Check-in] Table may already exist');
    }

    // Check if already checked in today
    const [existing] = await connection.execute(
      'SELECT id, check_in_time FROM attendance WHERE user_id = ? AND date = ? LIMIT 1',
      [userId, dateStr]
    ).catch(() => [[]]);  // ถ้า error ให้คืน array ว่าง

    if (existing.length > 0 && existing[0].check_in_time) {
      return res.status(400).json({ 
        message: 'คุณได้เช็คอินวันนี้แล้ว' 
      });
    }

    const now = new Date();

    if (existing.length > 0) {
      // Update existing record
      const [updateResult] = await connection.execute(
        `UPDATE attendance 
         SET check_in_time = ?, check_in_image_path = ?, updated_at = NOW() 
         WHERE id = ?`,
        [now, imagePath || '', existing[0].id]
      );
      console.log(`[Check-in] Updated attendance record ID ${existing[0].id} for user_id ${userId} on ${dateStr}`);
    } else {
      // Insert new record
      const [insertResult] = await connection.execute(
        `INSERT INTO attendance (user_id, date, check_in_time, check_in_image_path) 
         VALUES (?, ?, ?, ?)`,
        [userId, dateStr, now, imagePath || '']
      );
      console.log(`[Check-in] Created attendance record ID ${insertResult.insertId} for user_id ${userId} on ${dateStr}`);
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

    // สร้างตาราง attendance ถ้ายังไม่มี
    try {
      await connection.execute(`
        CREATE TABLE IF NOT EXISTS attendance (
          id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT NOT NULL,
          date DATE NOT NULL,
          check_in_time DATETIME DEFAULT NULL,
          check_out_time DATETIME DEFAULT NULL,
          check_in_image_path VARCHAR(500) DEFAULT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          INDEX idx_user_id (user_id),
          INDEX idx_date (date),
          FOREIGN KEY (user_id) REFERENCES login(user_id) ON DELETE CASCADE,
          UNIQUE KEY unique_user_date (user_id, date)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      `);
    } catch (tableError) {
      console.log('[Check-out] Table may already exist');
    }

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
    const [updateResult] = await connection.execute(
      'UPDATE attendance SET check_out_time = ?, updated_at = NOW() WHERE id = ?',
      [now, attendance[0].id]
    );
    console.log(`[Check-out] Updated attendance record ID ${attendance[0].id} for user_id ${userId} on ${today}`);

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

// Get all attendance records for admin
router.get('/all', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userRole = req.user.role;
    const { startDate, endDate } = req.query;

    // ตรวจสอบสิทธิ์: ต้องเป็น admin
    if (userRole !== 'admin') {
      return res.status(403).json({ message: 'คุณไม่มีสิทธิ์เข้าถึงข้อมูลนี้' });
    }

    connection = await pool.getConnection();

    // สร้างตาราง attendance ถ้ายังไม่มี
    try {
      await connection.execute(`
        CREATE TABLE IF NOT EXISTS attendance (
          id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT NOT NULL,
          date DATE NOT NULL,
          check_in_time DATETIME DEFAULT NULL,
          check_out_time DATETIME DEFAULT NULL,
          check_in_image_path VARCHAR(500) DEFAULT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          INDEX idx_user_id (user_id),
          INDEX idx_date (date),
          FOREIGN KEY (user_id) REFERENCES login(user_id) ON DELETE CASCADE,
          UNIQUE KEY unique_user_date (user_id, date)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      `);
    } catch (tableError) {
      console.log('[Attendance All] Table may already exist');
    }

    // ตรวจสอบว่ามีข้อมูลในตาราง attendance หรือไม่
    const [countResult] = await connection.execute('SELECT COUNT(*) as count FROM attendance');
    console.log(`[Attendance All] Total attendance records in database: ${countResult[0]?.count || 0}`);

    // ดึงข้อมูล attendance ทั้งหมด (attendance.user_id = login.user_id)
    let query = `
      SELECT 
        a.id,
        a.user_id,
        a.date,
        a.check_in_time,
        a.check_out_time,
        a.check_in_image_path,
        a.created_at,
        a.updated_at,
        COALESCE(CONCAT(e.first_name, ' ', e.last_name), l.username, 'ไม่ระบุชื่อ') as employee_name,
        COALESCE(e.position, '-') as position,
        COALESCE(e.department, '-') as department,
        COALESCE(l.email, '') as employee_email
      FROM attendance a
      LEFT JOIN login l ON a.user_id = l.user_id
      LEFT JOIN employees e ON l.user_id = e.user_id
      WHERE 1=1
    `;
    const params = [];

    if (startDate && endDate) {
      query += ' AND a.date BETWEEN ? AND ?';
      params.push(startDate, endDate);
    }

    query += ' ORDER BY a.date DESC, a.check_in_time DESC LIMIT 500';

    console.log(`[Attendance All] Executing query...`);
    const [attendances] = await connection.execute(query, params);

    console.log(`[Attendance All] Admin found ${attendances.length} attendance records`);
    if (attendances.length > 0) {
      console.log(`[Attendance All] Sample attendance:`, {
        id: attendances[0].id,
        user_id: attendances[0].user_id,
        date: attendances[0].date,
        check_in_time: attendances[0].check_in_time,
        check_out_time: attendances[0].check_out_time,
        employee_name: attendances[0].employee_name,
      });
    } else if (countResult[0]?.count > 0) {
      // ถ้ามีข้อมูลใน attendance แต่ query ไม่เจอ แสดงว่าอาจมีปัญหา JOIN
      const [sampleData] = await connection.execute('SELECT * FROM attendance LIMIT 1');
      console.log(`[Attendance All] Sample raw attendance data:`, sampleData[0]);
    }

    res.json({ attendances });
  } catch (error) {
    console.error('Get all attendance error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;
