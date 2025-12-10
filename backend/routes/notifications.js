const express = require('express');
const router = express.Router();
const { pool } = require('../db');
const { authenticateToken } = require('../middleware/auth');

// Get notifications for current user
router.get('/', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userId = req.user.user_id;

    console.log(`[Notifications] Fetching notifications for user_id ${userId}`);

    connection = await pool.getConnection();

    // สร้างตาราง notifications ถ้ายังไม่มี (รองรับ leave_id)
    try {
      await connection.execute(`
        CREATE TABLE IF NOT EXISTS notifications (
          id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT NOT NULL,
          title VARCHAR(255) NOT NULL,
          message TEXT NOT NULL,
          type VARCHAR(50) DEFAULT 'info',
          leave_id INT DEFAULT NULL,
          is_read BOOLEAN DEFAULT FALSE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          INDEX idx_user_id (user_id),
          INDEX idx_is_read (is_read),
          INDEX idx_leave_id (leave_id),
          FOREIGN KEY (user_id) REFERENCES login(user_id) ON DELETE CASCADE,
          FOREIGN KEY (leave_id) REFERENCES leaves(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      `);
      
      // เพิ่มคอลัมน์ leave_id ถ้ายังไม่มี (สำหรับตารางที่มีอยู่แล้ว)
      try {
        // ตรวจสอบว่ามีคอลัมน์ leave_id หรือไม่
        const [columns] = await connection.execute(`
          SELECT COLUMN_NAME 
          FROM INFORMATION_SCHEMA.COLUMNS 
          WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'notifications' 
            AND COLUMN_NAME = 'leave_id'
        `);
        
        if (columns.length === 0) {
          // ไม่มีคอลัมน์ leave_id ให้เพิ่ม
          await connection.execute(`
            ALTER TABLE notifications 
            ADD COLUMN leave_id INT DEFAULT NULL,
            ADD INDEX idx_leave_id (leave_id),
            ADD FOREIGN KEY (leave_id) REFERENCES leaves(id) ON DELETE SET NULL
          `);
          console.log('[Notifications] Added leave_id column to notifications table');
        }
      } catch (alterError) {
        // Ignore error if column already exists or foreign key already exists
        console.log('[Notifications] Column leave_id may already exist or foreign key issue:', alterError.message);
      }
    } catch (tableError) {
      console.error('[Notifications] Error creating notifications table:', tableError);
      // Continue anyway - table might already exist
    }

    const [notifications] = await connection.execute(
      `SELECT id, title, message, type, leave_id, is_read, created_at
       FROM notifications
       WHERE user_id = ?
       ORDER BY created_at DESC
       LIMIT 100`,
      [userId]
    );

    console.log(`[Notifications] Found ${notifications.length} notifications for user_id ${userId}`);

    res.json({ notifications });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

// Mark notification as read
router.patch('/:notificationId/read', authenticateToken, async (req, res) => {
  let connection;
  try {
    const { notificationId } = req.params;
    const userId = req.user.user_id;

    connection = await pool.getConnection();

    await connection.execute(
      `UPDATE notifications 
       SET is_read = TRUE 
       WHERE id = ? AND user_id = ?`,
      [notificationId, userId]
    );

    res.json({ message: 'อัปเดตสถานะแล้ว' });
  } catch (error) {
    console.error('Mark notification as read error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

// Mark all notifications as read
router.patch('/read-all', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userId = req.user.user_id;

    connection = await pool.getConnection();

    await connection.execute(
      `UPDATE notifications 
       SET is_read = TRUE 
       WHERE user_id = ? AND is_read = FALSE`,
      [userId]
    );

    res.json({ message: 'อัปเดตสถานะทั้งหมดแล้ว' });
  } catch (error) {
    console.error('Mark all notifications as read error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;

