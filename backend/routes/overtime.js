const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { pool } = require('../db');
const { authenticateToken } = require('../middleware/auth');

// ตั้งค่า multer สำหรับอัปโหลดรูปภาพ
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // สร้างโฟลเดอร์ uploads/overtime ถ้ายังไม่มี
    const uploadDir = path.join(__dirname, '../uploads/overtime');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // สร้างชื่อไฟล์: ot_YYYYMMDD_HHMMSS_userId_originalname
    const userId = req.user?.user_id || 'unknown';
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    const ext = path.extname(file.originalname);
    const filename = `ot_${timestamp}_${userId}${ext}`;
    cb(null, filename);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB
  },
  fileFilter: (req, file, cb) => {
    // อนุญาตเฉพาะไฟล์รูปภาพ
    const allowedTypes = /jpeg|jpg|png|gif|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (extname && mimetype) {
      cb(null, true);
    } else {
      cb(new Error('กรุณาอัปโหลดไฟล์รูปภาพเท่านั้น (jpg, png, gif, webp)'));
    }
  }
});

// GET: ดึงคำขอ OT ทั้งหมดของพนักงาน (สำหรับพนักงาน)
router.get('/my-requests', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userId = req.user.user_id;
    const { status, month, year } = req.query;

    connection = await pool.getConnection();

    let query = `
      SELECT 
        ot.*,
        CONCAT(COALESCE(e.first_name, ''), ' ', COALESCE(e.last_name, '')) as employee_name,
        e.department,
        e.position,
        CONCAT(COALESCE(approver_emp.first_name, ''), ' ', COALESCE(approver_emp.last_name, '')) as approver_name
      FROM overtime_requests ot
      LEFT JOIN login u ON ot.user_id = u.user_id
      LEFT JOIN employees e ON u.user_id = e.user_id
      LEFT JOIN login approver_login ON ot.approved_by = approver_login.user_id
      LEFT JOIN employees approver_emp ON approver_login.user_id = approver_emp.user_id
      WHERE ot.user_id = ?
    `;
    const params = [userId];

    if (status) {
      query += ' AND ot.status = ?';
      params.push(status);
    }

    if (month && year) {
      query += ' AND MONTH(ot.date) = ? AND YEAR(ot.date) = ?';
      params.push(parseInt(month), parseInt(year));
    }

    query += ' ORDER BY ot.date DESC, ot.created_at DESC';

    const [rows] = await connection.execute(query, params);

    res.json(rows);
  } catch (error) {
    console.error('Error fetching OT requests:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูล' });
  } finally {
    if (connection) connection.release();
  }
});

// GET: ดึงคำขอ OT ทั้งหมด (สำหรับ Manager)
router.get('/all', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userRole = req.user.role;
    
    // ตรวจสอบสิทธิ์ (เฉพาะ manager)
    if (userRole !== 'manager') {
      return res.status(403).json({ message: 'ไม่มีสิทธิ์เข้าถึง (เฉพาะ Manager)' });
    }

    const { status, department, month, year } = req.query;

    connection = await pool.getConnection();

    let query = `
      SELECT 
        ot.*,
        CONCAT(COALESCE(e.first_name, ''), ' ', COALESCE(e.last_name, '')) as employee_name,
        e.department,
        e.position,
        CONCAT(COALESCE(approver_emp.first_name, ''), ' ', COALESCE(approver_emp.last_name, '')) as approver_name
      FROM overtime_requests ot
      LEFT JOIN login u ON ot.user_id = u.user_id
      LEFT JOIN employees e ON u.user_id = e.user_id
      LEFT JOIN login approver_login ON ot.approved_by = approver_login.user_id
      LEFT JOIN employees approver_emp ON approver_login.user_id = approver_emp.user_id
      WHERE 1=1
    `;
    const params = [];

    if (status) {
      query += ' AND ot.status = ?';
      params.push(status);
    }

    if (department) {
      query += ' AND e.department = ?';
      params.push(department);
    }

    if (month && year) {
      query += ' AND MONTH(ot.date) = ? AND YEAR(ot.date) = ?';
      params.push(parseInt(month), parseInt(year));
    }

    query += ' ORDER BY ot.date DESC, ot.created_at DESC';

    const [rows] = await connection.execute(query, params);

    res.json(rows);
  } catch (error) {
    console.error('Error fetching all OT requests:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูล' });
  } finally {
    if (connection) connection.release();
  }
});

// GET: ดึงคำขอ OT ที่รออนุมัติ (สำหรับ Manager)
router.get('/pending', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userRole = req.user.role;
    const userId = req.user.user_id;

    // ตรวจสอบสิทธิ์ (เฉพาะ manager)
    if (userRole !== 'manager') {
      return res.status(403).json({ message: 'ไม่มีสิทธิ์เข้าถึง (เฉพาะ Manager)' });
    }

    connection = await pool.getConnection();

    // ถ้าเป็น manager ให้แสดงเฉพาะคนในแผนกเดียวกัน
    let query = `
      SELECT 
        ot.*,
        CONCAT(COALESCE(e.first_name, ''), ' ', COALESCE(e.last_name, '')) as employee_name,
        e.department,
        e.position
      FROM overtime_requests ot
      LEFT JOIN login u ON ot.user_id = u.user_id
      LEFT JOIN employees e ON u.user_id = e.user_id
      WHERE ot.status = 'pending'
    `;
    const params = [];

    if (userRole === 'manager') {
      // ดึงแผนกของ manager
      const [managerInfo] = await connection.execute(
        'SELECT department FROM employees WHERE user_id = ?',
        [userId]
      );
      
      console.log(`[OT Pending] Manager user_id: ${userId}, managerInfo:`, managerInfo);
      
      if (managerInfo.length > 0 && managerInfo[0].department) {
        const managerDept = managerInfo[0].department.trim();
        console.log(`[OT Pending] Manager department: "${managerDept}"`);
        
        // ใช้ TRIM และ UPPER เพื่อเปรียบเทียบแบบไม่สนใจ case และ whitespace
        query += ' AND TRIM(UPPER(COALESCE(e.department, ""))) = TRIM(UPPER(?))';
        params.push(managerDept);
      } else {
        console.log(`[OT Pending] Manager has no department, showing all pending requests`);
        // ถ้า manager ไม่มี department ให้แสดงทั้งหมด
      }
    }

    query += ' ORDER BY ot.date DESC, ot.created_at DESC';

    console.log(`[OT Pending] Final query: ${query}`);
    console.log(`[OT Pending] Params:`, params);

    const [rows] = await connection.execute(query, params);

    console.log(`[OT Pending] Found ${rows.length} pending requests`);
    if (rows.length > 0) {
      rows.forEach((row, index) => {
        console.log(`[OT Pending] Request ${index + 1}:`, {
          id: row.id,
          user_id: row.user_id,
          employee_name: row.employee_name,
          department: row.department,
          date: row.date
        });
      });
    } else {
      // ถ้าไม่เจอคำขอ ให้ลองดูว่ามีคำขอ pending ทั้งหมดกี่คำขอ
      const [allPending] = await connection.execute(
        'SELECT COUNT(*) as count FROM overtime_requests WHERE status = "pending"'
      );
      console.log(`[OT Pending] Total pending requests in system: ${allPending[0]?.count || 0}`);
    }

    res.json(rows);
  } catch (error) {
    console.error('Error fetching pending OT requests:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูล' });
  } finally {
    if (connection) connection.release();
  }
});

// POST: สร้างคำขอ OT ใหม่ (รองรับการอัปโหลดรูปภาพหลักฐาน)
router.post('/request', authenticateToken, upload.single('evidence_image'), async (req, res) => {
  let connection;
  try {
    const userId = req.user.user_id;
    
    // รองรับทั้ง JSON และ multipart/form-data
    const date = req.body.date;
    const start_time = req.body.start_time;
    const end_time = req.body.end_time;
    const reason = req.body.reason || '';
    
    // ตรวจสอบไฟล์รูปภาพ (ถ้ามี)
    let evidenceImagePath = null;
    if (req.file) {
      // เก็บ path ของไฟล์ที่อัปโหลด (relative path จาก uploads/overtime)
      evidenceImagePath = `uploads/overtime/${req.file.filename}`;
      console.log(`[OT Request] Evidence image uploaded: ${evidenceImagePath}`);
    }

    // Validate input
    if (!date || !start_time || !end_time) {
      // ถ้ามีไฟล์อัปโหลดแล้วแต่ข้อมูลไม่ครบ ให้ลบไฟล์
      if (req.file) {
        try {
          fs.unlinkSync(req.file.path);
        } catch (e) {
          console.error('Error deleting uploaded file:', e);
        }
      }
      return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }

    // คำนวณชั่วโมง OT
    const start = new Date(`2000-01-01 ${start_time}`);
    const end = new Date(`2000-01-01 ${end_time}`);
    
    if (end <= start) {
      // ถ้ามีไฟล์อัปโหลดแล้วแต่ข้อมูลไม่ถูกต้อง ให้ลบไฟล์
      if (req.file) {
        try {
          fs.unlinkSync(req.file.path);
        } catch (e) {
          console.error('Error deleting uploaded file:', e);
        }
      }
      return res.status(400).json({ message: 'เวลาเริ่มต้นต้องน้อยกว่าเวลาสิ้นสุด' });
    }

    const diffMs = end - start;
    const totalHours = (diffMs / (1000 * 60 * 60)).toFixed(2);

    connection = await pool.getConnection();

    // ตรวจสอบว่ามีคำขอซ้ำในวันเดียวกันหรือไม่
    const [existing] = await connection.execute(
      'SELECT id FROM overtime_requests WHERE user_id = ? AND date = ? AND status != "rejected"',
      [userId, date]
    );

    if (existing.length > 0) {
      // ถ้ามีไฟล์อัปโหลดแล้วแต่มีคำขอซ้ำ ให้ลบไฟล์
      if (req.file) {
        try {
          fs.unlinkSync(req.file.path);
        } catch (e) {
          console.error('Error deleting uploaded file:', e);
        }
      }
      return res.status(400).json({ message: 'คุณมีคำขอ OT ในวันนี้อยู่แล้ว' });
    }

    // สร้างคำขอ OT (รวม evidence_image_path ถ้ามี)
    const [result] = await connection.execute(
      `INSERT INTO overtime_requests 
       (user_id, date, start_time, end_time, total_hours, reason, evidence_image_path, status) 
       VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')`,
      [userId, date, start_time, end_time, totalHours, reason, evidenceImagePath]
    );

    res.json({
      message: 'ส่งคำขอ OT สำเร็จ',
      id: result.insertId,
      total_hours: parseFloat(totalHours),
      evidence_image_path: evidenceImagePath
    });
  } catch (error) {
    console.error('Error creating OT request:', error);
    
    // ถ้ามีไฟล์อัปโหลดแล้วแต่เกิด error ให้ลบไฟล์
    if (req.file) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (e) {
        console.error('Error deleting uploaded file:', e);
      }
    }
    
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการสร้างคำขอ' });
  } finally {
    if (connection) connection.release();
  }
});

// PUT: อนุมัติ/ปฏิเสธคำขอ OT
router.put('/approve/:id', authenticateToken, async (req, res) => {
  let connection;
  try {
    const approverId = req.user.user_id;
    const userRole = req.user.role;
    const { id } = req.params;
    const { action, rejection_reason } = req.body; // action: 'approve' or 'reject'

    // ตรวจสอบสิทธิ์ (เฉพาะ manager เท่านั้นที่อนุมัติได้)
    if (userRole !== 'manager') {
      return res.status(403).json({ message: 'ไม่มีสิทธิ์อนุมัติ (เฉพาะ Manager)' });
    }

    if (!action || (action !== 'approve' && action !== 'reject')) {
      return res.status(400).json({ message: 'กรุณาระบุ action (approve/reject)' });
    }

    connection = await pool.getConnection();

    // ดึงข้อมูลคำขอ
    const [requests] = await connection.execute(
      'SELECT * FROM overtime_requests WHERE id = ?',
      [id]
    );

    if (requests.length === 0) {
      return res.status(404).json({ message: 'ไม่พบคำขอ OT' });
    }

    const request = requests[0];

    if (request.status !== 'pending') {
      return res.status(400).json({ message: 'คำขอนี้ได้รับการอนุมัติ/ปฏิเสธแล้ว' });
    }

    // ตรวจสอบว่า manager สามารถอนุมัติได้เฉพาะคนในแผนกเดียวกัน
    if (userRole === 'manager') {
      const [managerInfo] = await connection.execute(
        'SELECT department FROM employees WHERE user_id = ?',
        [approverId]
      );
      
      const [employeeInfo] = await connection.execute(
        'SELECT department FROM employees WHERE user_id = ?',
        [request.user_id]
      );

      console.log(`[OT Approve] Manager (${approverId}) department:`, managerInfo[0]?.department);
      console.log(`[OT Approve] Employee (${request.user_id}) department:`, employeeInfo[0]?.department);

      if (managerInfo.length === 0 || employeeInfo.length === 0) {
        console.log(`[OT Approve] Missing department info - manager: ${managerInfo.length}, employee: ${employeeInfo.length}`);
        return res.status(403).json({ message: 'ไม่พบข้อมูลแผนก กรุณาติดต่อผู้ดูแลระบบ' });
      }

      const managerDept = (managerInfo[0].department || '').trim().toUpperCase();
      const employeeDept = (employeeInfo[0].department || '').trim().toUpperCase();

      console.log(`[OT Approve] Department comparison - manager: "${managerDept}", employee: "${employeeDept}"`);

      if (managerDept !== employeeDept) {
        console.log(`[OT Approve] Department mismatch`);
        return res.status(403).json({ message: 'คุณสามารถอนุมัติได้เฉพาะคนในแผนกเดียวกัน' });
      }
    }

    // อัปเดตสถานะ
    const status = action === 'approve' ? 'approved' : 'rejected';
    const approvedAt = action === 'approve' ? new Date() : null;

    await connection.execute(
      `UPDATE overtime_requests 
       SET status = ?, 
           approved_by = ?, 
           approved_at = ?,
           rejection_reason = ?,
           updated_at = NOW()
       WHERE id = ?`,
      [status, approverId, approvedAt, rejection_reason || null, id]
    );

    res.json({
      message: action === 'approve' ? 'อนุมัติคำขอ OT สำเร็จ' : 'ปฏิเสธคำขอ OT สำเร็จ',
      status: status
    });
  } catch (error) {
    console.error('Error approving OT request:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการอนุมัติ' });
  } finally {
    if (connection) connection.release();
  }
});

// GET: สรุป OT รายเดือน
router.get('/summary', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userId = req.user.user_id;
    const { month, year } = req.query;
    const currentMonth = month || new Date().getMonth() + 1;
    const currentYear = year || new Date().getFullYear();

    connection = await pool.getConnection();

    const [rows] = await connection.execute(
      `SELECT 
        COUNT(*) as total_requests,
        COALESCE(SUM(CASE WHEN status = 'approved' THEN total_hours ELSE 0 END), 0) as approved_hours,
        COALESCE(SUM(CASE WHEN status = 'pending' THEN total_hours ELSE 0 END), 0) as pending_hours,
        COALESCE(SUM(CASE WHEN status = 'rejected' THEN total_hours ELSE 0 END), 0) as rejected_hours
       FROM overtime_requests
       WHERE user_id = ? AND MONTH(date) = ? AND YEAR(date) = ?`,
      [userId, currentMonth, currentYear]
    );

    const result = rows[0] || {
      total_requests: 0,
      approved_hours: 0,
      pending_hours: 0,
      rejected_hours: 0
    };

    // แปลงค่าให้เป็น number
    res.json({
      total_requests: parseInt(result.total_requests) || 0,
      approved_hours: parseFloat(result.approved_hours) || 0,
      pending_hours: parseFloat(result.pending_hours) || 0,
      rejected_hours: parseFloat(result.rejected_hours) || 0
    });
  } catch (error) {
    console.error('Error fetching OT summary:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูล' });
  } finally {
    if (connection) connection.release();
  }
});

// GET: ดึงอัตราค่าล่วงเวลา
router.get('/rates', authenticateToken, async (req, res) => {
  let connection;
  try {
    connection = await pool.getConnection();

    const [rows] = await connection.execute(
      'SELECT * FROM overtime_rates ORDER BY rate_type'
    );

    res.json(rows);
  } catch (error) {
    console.error('Error fetching OT rates:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูล' });
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;
