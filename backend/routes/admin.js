const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { pool } = require('../db');
const { authenticateToken } = require('../middleware/auth');

// Middleware: ตรวจสอบว่าเป็น admin เท่านั้น
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res
      .status(403)
      .json({ message: 'ไม่มีสิทธิ์เข้าถึง (ต้องเป็น Admin)' });
  }
  next();
};

// Middleware: ตรวจสอบว่าเป็น admin, HR หรือ manager
// ใช้กับ endpoint รายงาน/สรุป ที่ HR/Manager ต้องดูได้ด้วย
const requireAdminOrHR = (req, res, next) => {
  const role = req.user.role;
  if (role !== 'admin' && role !== 'hr' && role !== 'manager') {
    return res.status(403).json({
      message: 'ไม่มีสิทธิ์เข้าถึง (ต้องเป็น Admin, HR หรือ Manager)',
    });
  }
  next();
};

// ===========================
// GET /api/admin/users - ดึงรายการ users ทั้งหมด
// ===========================
router.get('/users', authenticateToken, requireAdmin, async (req, res) => {
  let connection;
  try {
    connection = await pool.getConnection();

    const [users] = await connection.execute(
      `SELECT l.user_id, l.username, l.email, l.role, l.created_at,
              e.employee_id, e.first_name, e.last_name, e.position, e.department
       FROM login l
       LEFT JOIN employees e ON l.user_id = e.user_id
       ORDER BY l.created_at DESC`
    );

    res.json({
      success: true,
      count: users.length,
      users: users
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้' });
  } finally {
    if (connection) connection.release();
  }
});

// ===========================
// GET /api/admin/users/:id - ดึงข้อมูล user เฉพาะ
// ===========================
router.get('/users/:id', authenticateToken, requireAdmin, async (req, res) => {
  let connection;
  try {
    const userId = parseInt(req.params.id);

    connection = await pool.getConnection();

    const [users] = await connection.execute(
      `SELECT l.user_id, l.username, l.email, l.role, l.created_at,
              e.employee_id, e.first_name, e.last_name, e.phone_number, 
              e.date_of_birth, e.position, e.department
       FROM login l
       LEFT JOIN employees e ON l.user_id = e.user_id
       WHERE l.user_id = ?`,
      [userId]
    );

    if (users.length === 0) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลผู้ใช้' });
    }

    res.json({
      success: true,
      user: users[0]
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้' });
  } finally {
    if (connection) connection.release();
  }
});

// ===========================
// POST /api/admin/users - สร้าง user ใหม่
// ===========================
router.post('/users', authenticateToken, requireAdmin, async (req, res) => {
  let connection;
  try {
    const { username, email, password, role, first_name, last_name, position, department } = req.body;

    // Validate input
    if (!username || !email || !password) {
      return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน (username, email, password)' });
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

    // Start transaction
    await connection.beginTransaction();

    try {
      // Insert into login table
      const [result] = await connection.execute(
        `INSERT INTO login (username, email, password_hash, role) 
         VALUES (?, ?, ?, ?)`,
        [username, email, hashedPassword, role || 'employee']
      );

      const userId = result.insertId;

      // Insert into employees table (if provided)
      if (first_name || last_name || position || department) {
        await connection.execute(
          `INSERT INTO employees (user_id, first_name, last_name, position, department) 
           VALUES (?, ?, ?, ?, ?)`,
          [userId, first_name || '', last_name || '', position || null, department || null]
        );
      }

      await connection.commit();

      res.status(201).json({
        success: true,
        message: 'สร้างผู้ใช้สำเร็จ',
        user: {
          user_id: userId,
          username,
          email,
          role: role || 'employee'
        }
      });
    } catch (error) {
      await connection.rollback();
      throw error;
    }
  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการสร้างผู้ใช้' });
  } finally {
    if (connection) connection.release();
  }
});

// ===========================
// PUT /api/admin/users/:id - อัปเดต user
// ===========================
router.put('/users/:id', authenticateToken, requireAdmin, async (req, res) => {
  let connection;
  try {
    const userId = parseInt(req.params.id);
    const { username, email, password, role, first_name, last_name, phone_number, date_of_birth, position, department } = req.body;

    connection = await pool.getConnection();

    // Check if user exists
    const [existingUsers] = await connection.execute(
      'SELECT user_id FROM login WHERE user_id = ?',
      [userId]
    );

    if (existingUsers.length === 0) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลผู้ใช้' });
    }

    await connection.beginTransaction();

    try {
      // Update login table
      if (username || email || role) {
        const updateFields = [];
        const updateValues = [];

        if (username) {
          updateFields.push('username = ?');
          updateValues.push(username);
        }
        if (email) {
          updateFields.push('email = ?');
          updateValues.push(email);
        }
        if (role) {
          updateFields.push('role = ?');
          updateValues.push(role);
        }
        if (password) {
          const salt = await bcrypt.genSalt(10);
          const hashedPassword = await bcrypt.hash(password, salt);
          updateFields.push('password_hash = ?');
          updateValues.push(hashedPassword);
        }

        if (updateFields.length > 0) {
          updateValues.push(userId);
          await connection.execute(
            `UPDATE login SET ${updateFields.join(', ')} WHERE user_id = ?`,
            updateValues
          );
        }
      }

      // Update employees table
      if (first_name || last_name || phone_number || date_of_birth || position || department) {
        // Check if employee record exists
        const [employees] = await connection.execute(
          'SELECT employee_id FROM employees WHERE user_id = ?',
          [userId]
        );

        if (employees.length > 0) {
          // Update existing
          const updateFields = [];
          const updateValues = [];

          if (first_name !== undefined) {
            updateFields.push('first_name = ?');
            updateValues.push(first_name);
          }
          if (last_name !== undefined) {
            updateFields.push('last_name = ?');
            updateValues.push(last_name);
          }
          if (phone_number !== undefined) {
            updateFields.push('phone_number = ?');
            updateValues.push(phone_number);
          }
          if (date_of_birth !== undefined) {
            updateFields.push('date_of_birth = ?');
            updateValues.push(date_of_birth || null);
          }
          if (position !== undefined) {
            updateFields.push('position = ?');
            updateValues.push(position);
          }
          if (department !== undefined) {
            updateFields.push('department = ?');
            updateValues.push(department);
          }

          if (updateFields.length > 0) {
            updateValues.push(userId);
            await connection.execute(
              `UPDATE employees SET ${updateFields.join(', ')} WHERE user_id = ?`,
              updateValues
            );
          }
        } else {
          // Create new employee record
          await connection.execute(
            `INSERT INTO employees (user_id, first_name, last_name, phone_number, date_of_birth, position, department) 
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [userId, first_name || '', last_name || '', phone_number || null, date_of_birth || null, position || null, department || null]
          );
        }
      }

      await connection.commit();

      res.json({
        success: true,
        message: 'อัปเดตผู้ใช้สำเร็จ'
      });
    } catch (error) {
      await connection.rollback();
      throw error;
    }
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการอัปเดตผู้ใช้' });
  } finally {
    if (connection) connection.release();
  }
});

// ===========================
// DELETE /api/admin/users/:id - ลบ user
// ===========================
router.delete('/users/:id', authenticateToken, requireAdmin, async (req, res) => {
  let connection;
  try {
    const userId = parseInt(req.params.id);

    // ไม่ให้ลบตัวเอง
    if (userId === req.user.user_id) {
      return res.status(400).json({ message: 'ไม่สามารถลบบัญชีของตัวเองได้' });
    }

    connection = await pool.getConnection();

    // Check if user exists
    const [existingUsers] = await connection.execute(
      'SELECT user_id, username FROM login WHERE user_id = ?',
      [userId]
    );

    if (existingUsers.length === 0) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลผู้ใช้' });
    }

    await connection.beginTransaction();

    try {
      // Delete from employees first (due to foreign key)
      await connection.execute('DELETE FROM employees WHERE user_id = ?', [userId]);

      // Delete from login
      await connection.execute('DELETE FROM login WHERE user_id = ?', [userId]);

      await connection.commit();

      res.json({
        success: true,
        message: 'ลบผู้ใช้สำเร็จ'
      });
    } catch (error) {
      await connection.rollback();
      throw error;
    }
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการลบผู้ใช้' });
  } finally {
    if (connection) connection.release();
  }
});

// ===========================
// GET /api/admin/leave-summary - สรุปข้อมูลวันลาของพนักงานทั้งหมด
// ===========================
router.get(
  '/leave-summary',
  authenticateToken,
  requireAdminOrHR,
  async (req, res) => {
  let connection;
  try {
    connection = await pool.getConnection();

    // ดึงปีปัจจุบันหรือจาก query parameter
    const currentYear = req.query.year ? parseInt(req.query.year) : new Date().getFullYear();
    const yearStart = `${currentYear}-01-01`;
    const yearEnd = `${currentYear}-12-31`;

    // ดึงข้อมูลสรุปวันลาของพนักงานทั้งหมด
    // total_leave_days, sick_leave_days, personal_leave_days = คำนวณทั้งหมดที่ลาไปแล้ว (ไม่จำกัดปี)
    // remaining_leave_days = คำนวณตามปีปัจจุบัน (30 วันต่อปี - วันลาที่ลาไปในปีปัจจุบัน)
    // หมายเหตุ: leaves.user_id อ้างอิงไปที่ employees.employee_id ไม่ใช่ login.user_id
    const [summary] = await connection.execute(
      `SELECT 
        e.employee_id,
        l.user_id,
        COALESCE(
          CONCAT(COALESCE(e.first_name, ''), ' ', COALESCE(e.last_name, '')),
          l.username,
          CONCAT('User ', l.user_id)
        ) as full_name,
        COALESCE(e.position, 'Employee') as position,
        COALESCE(e.department, '-') as department,
        COALESCE(l.email, '') as email,
        -- นับจำนวนวันลาที่อนุมัติแล้วทั้งหมด (ไม่จำกัดปี - เพื่อดูว่าลาไปแล้วทั้งหมดกี่วัน)
        COALESCE(SUM(CASE WHEN lv.status = 'approved' THEN 
          DATEDIFF(lv.end_date, lv.start_date) + 1 
        ELSE 0 END), 0) as total_leave_days,
        -- นับจำนวนวันลาป่วยทั้งหมด (ไม่จำกัดปี)
        COALESCE(SUM(CASE WHEN lv.status = 'approved' AND lv.leave_type = 'sick' THEN 
          DATEDIFF(lv.end_date, lv.start_date) + 1 
        ELSE 0 END), 0) as sick_leave_days,
        -- นับจำนวนวันลากิจส่วนตัวทั้งหมด (ไม่จำกัดปี)
        COALESCE(SUM(CASE WHEN lv.status = 'approved' AND lv.leave_type = 'personal' THEN 
          DATEDIFF(lv.end_date, lv.start_date) + 1 
        ELSE 0 END), 0) as personal_leave_days,
        -- นับจำนวนวันลาที่รออนุมัติ (ไม่จำกัดปี)
        COALESCE(SUM(CASE WHEN lv.status = 'pending' THEN 
          DATEDIFF(lv.end_date, lv.start_date) + 1 
        ELSE 0 END), 0) as pending_leave_days,
        -- จำนวนวันลาที่เหลือ (คำนวณตามปีปัจจุบัน: 30 วันต่อปี - วันลาที่ลาไปในปีปัจจุบัน)
        GREATEST(0, 30 - COALESCE(SUM(CASE WHEN lv.status = 'approved' AND YEAR(lv.start_date) = ? THEN 
          DATEDIFF(lv.end_date, lv.start_date) + 1 
        ELSE 0 END), 0)) as remaining_leave_days,
        -- วันลาที่ลาไปในปีปัจจุบัน (สำหรับแสดงแยก)
        COALESCE(SUM(CASE WHEN lv.status = 'approved' AND YEAR(lv.start_date) = ? THEN 
          DATEDIFF(lv.end_date, lv.start_date) + 1 
        ELSE 0 END), 0) as current_year_leave_days
      FROM login l
      LEFT JOIN employees e ON l.user_id = e.user_id
      LEFT JOIN leaves lv ON e.employee_id = lv.user_id
      WHERE l.role = 'employee'
      GROUP BY e.employee_id, l.user_id, e.first_name, e.last_name, e.position, e.department, l.email, l.username
      ORDER BY e.first_name, e.last_name, l.username`,
      [currentYear, currentYear]
    );

    // สรุปข้อมูลรวม (กรองตามปี)
    const [totalSummary] = await connection.execute(
      `SELECT 
        COUNT(DISTINCT l.user_id) as total_employees,
        COALESCE(SUM(CASE WHEN lv.status = 'approved' AND YEAR(lv.start_date) = ? THEN 
          DATEDIFF(lv.end_date, lv.start_date) + 1 
        ELSE 0 END), 0) as total_approved_days,
        COALESCE(SUM(CASE WHEN lv.status = 'pending' THEN 
          DATEDIFF(lv.end_date, lv.start_date) + 1 
        ELSE 0 END), 0) as total_pending_days,
        COALESCE(SUM(CASE WHEN lv.status = 'rejected' AND YEAR(lv.start_date) = ? THEN 
          DATEDIFF(lv.end_date, lv.start_date) + 1 
        ELSE 0 END), 0) as total_rejected_days
      FROM login l
      LEFT JOIN employees e ON l.user_id = e.user_id
      LEFT JOIN leaves lv ON e.employee_id = lv.user_id
      WHERE l.role = 'employee'`,
      [currentYear, currentYear]
    );
    
    console.log(`[Leave Summary] Year: ${currentYear}, Found employees:`, summary.length);
    console.log('[Leave Summary] Total summary:', totalSummary[0]);

    res.json({
      success: true,
      year: currentYear,
      summary: summary,
      totals: totalSummary[0] || {
        total_employees: 0,
        total_approved_days: 0,
        total_pending_days: 0,
        total_rejected_days: 0
      }
    });
  } catch (error) {
    console.error('Get leave summary error:', error);
    res
      .status(500)
      .json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลสรุปวันลา' });
  } finally {
    if (connection) connection.release();
  }
});

// ===========================
// GET /api/admin/leave-details - รายละเอียดวันลาของพนักงานทั้งหมด (รองรับ filter ตามวันที่)
// ===========================
router.get(
  '/leave-details',
  authenticateToken,
  requireAdminOrHR,
  async (req, res) => {
  let connection;
  try {
    connection = await pool.getConnection();

    // รองรับ query parameter date (YYYY-MM-DD) เพื่อดึงเฉพาะใบลาที่มีผลในวันนั้น
    const { date } = req.query;
    let whereClause = '1=1';
    const params = [];

    if (date) {
      // เลือกใบลาที่วันที่เลือกอยู่ในช่วง start_date - end_date
      whereClause += ' AND ? BETWEEN lv.start_date AND lv.end_date';
      params.push(date);
    }

    // ไม่ filter สถานะที่ backend แล้ว
    // ปล่อยให้ฝั่ง Flutter กรอง approved / pending / rejected เอง

    const [leaves] = await connection.execute(
      `SELECT 
        lv.id,
        lv.user_id as employee_id,
        CONCAT(e.first_name, ' ', e.last_name) as employee_name,
        e.position,
        e.department,
        lv.leave_type,
        lv.start_date,
        lv.end_date,
        DATEDIFF(lv.end_date, lv.start_date) + 1 as total_days,
        lv.reason,
        lv.status,
        lv.approved_by,
        lv.approved_at,
        lv.created_at
      FROM leaves lv
      LEFT JOIN employees e ON lv.user_id = e.employee_id
      WHERE ${whereClause}
      ORDER BY lv.created_at DESC
      LIMIT 200`,
      params
    );

    res.json({
      success: true,
      leaves
    });
  } catch (error) {
    console.error('Get leave details error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลวันลา' });
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;

