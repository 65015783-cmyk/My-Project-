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

    const { username, email, password, role, first_name, last_name, department } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }

    // Validate role
    const validRoles = ['admin', 'employee', 'manager'];
    const selectedRole = role || 'employee';
    if (!validRoles.includes(selectedRole)) {
      return res.status(400).json({ 
        message: `Role ไม่ถูกต้อง ต้องเป็น: ${validRoles.join(', ')}`,
        received: selectedRole
      });
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

    // Insert into login table
    const [result] = await connection.execute(
      'INSERT INTO login (username, email, password_hash, role) VALUES (?, ?, ?, ?)',
      [username, email, hashedPassword, selectedRole]
    );

    const userId = result.insertId;

    // สร้างข้อมูลในตาราง employees พร้อมชื่อ-นามสกุล
    // หมายเหตุ: department จะไม่ถูกกำหนดอัตโนมัติ (ให้เป็น null หรือค่าที่ส่งมา)
    await connection.execute(
      `INSERT INTO employees (user_id, first_name, last_name, position, department) 
       VALUES (?, ?, ?, ?, ?)`,
      [userId, first_name || '', last_name || '', null, department || null]
    );

    res.status(201).json({
      message: 'เพิ่มพนักงานสำเร็จ',
      employeeId: userId,
    });
  } catch (error) {
    console.error('Create employee error:', error);
    
    // ตรวจสอบ error ที่เกี่ยวข้องกับ role
    if (error.code === 'ER_TRUNCATED_WRONG_VALUE_FOR_FIELD' || 
        error.message?.includes('role') ||
        error.sqlMessage?.includes('role')) {
      return res.status(400).json({ 
        message: 'Role ไม่ถูกต้อง กรุณาแก้ไข database schema ให้รองรับ role = "manager"',
        error: error.message 
      });
    }
    
    res.status(500).json({ 
      message: 'เกิดข้อผิดพลาด',
      error: error.message 
    });
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

    // Validate role before update
    const validRoles = ['admin', 'employee', 'manager'];
    const selectedRole = role || 'employee';
    
    if (!validRoles.includes(selectedRole)) {
      return res.status(400).json({ 
        message: `Role ไม่ถูกต้อง ต้องเป็น: ${validRoles.join(', ')}`,
        received: selectedRole
      });
    }

    // Update
    if (password && password.length > 0) {
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(password, salt);
      
      await connection.execute(
        'UPDATE login SET username = ?, email = ?, password_hash = ?, role = ? WHERE user_id = ?',
        [username, email, hashedPassword, selectedRole, userId]
      );
    } else {
      await connection.execute(
        'UPDATE login SET username = ?, email = ?, role = ? WHERE user_id = ?',
        [username, email, selectedRole, userId]
      );
    }

    res.json({ message: 'แก้ไขพนักงานสำเร็จ' });
  } catch (error) {
    console.error('Update employee error:', error);
    console.error('Error details:', {
      code: error.code,
      errno: error.errno,
      sqlState: error.sqlState,
      sqlMessage: error.sqlMessage,
      sql: error.sql
    });
    
    // ตรวจสอบ error ที่เกี่ยวข้องกับ role
    if (error.code === 'WARN_DATA_TRUNCATED' || 
        error.code === 'ER_TRUNCATED_WRONG_VALUE_FOR_FIELD' || 
        error.code === 'ER_BAD_FIELD_ERROR' ||
        error.errno === 1265 ||
        error.message?.includes('role') ||
        error.message?.includes('truncated') ||
        error.sqlMessage?.includes('role') ||
        error.sqlMessage?.includes('truncated')) {
      return res.status(400).json({ 
        message: 'Database schema ยังไม่รองรับ role = "manager"',
        hint: 'กรุณารัน SQL: ALTER TABLE login MODIFY COLUMN role ENUM(\'admin\', \'employee\', \'manager\') DEFAULT \'employee\';',
        instruction: 'รันไฟล์: mysql -u root -p humans < backend/add_manager_role.sql',
        error: error.message,
        sqlMessage: error.sqlMessage,
        code: error.code
      });
    }
    
    res.status(500).json({ 
      message: 'เกิดข้อผิดพลาด',
      error: error.message,
      sqlMessage: error.sqlMessage
    });
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

