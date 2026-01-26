const express = require('express');
const router = express.Router();
const { pool } = require('../db');
const { authenticateToken } = require('../middleware/auth');

// Middleware: ตรวจสอบว่าเป็น admin หรือ manager
const requireHR = (req, res, next) => {
  if (req.user.role !== 'admin' && req.user.role !== 'manager') {
    return res.status(403).json({ message: 'ไม่มีสิทธิ์เข้าถึง (ต้องเป็น Admin หรือ Manager)' });
  }
  next();
};

// ===========================
// GET /api/hr/salary/summary - สรุปภาพรวมเงินเดือน
// ===========================
router.get('/salary/summary', authenticateToken, requireHR, async (req, res) => {
  let connection;
  try {
    connection = await pool.getConnection();

    // ดึงข้อมูลสรุปภาพรวม
    const [summary] = await connection.execute(
      `SELECT 
        COUNT(DISTINCT sh.employee_id) as total_employees,
        COALESCE(AVG(current_salary.current_salary), 0) as average_salary,
        COALESCE(MAX(current_salary.current_salary), 0) as max_salary,
        COALESCE(MIN(current_salary.current_salary), 0) as min_salary,
        COALESCE(COUNT(CASE 
          WHEN sh.salary_type = 'ADJUST' 
          AND MONTH(sh.effective_date) = MONTH(CURDATE())
          AND YEAR(sh.effective_date) = YEAR(CURDATE())
          THEN 1 END), 0) as adjustments_this_month
      FROM salary_history sh
      LEFT JOIN (
        SELECT employee_id, salary_amount as current_salary
        FROM salary_history sh2
        WHERE (employee_id, effective_date) IN (
          SELECT employee_id, MAX(effective_date) as max_date
          FROM salary_history
          GROUP BY employee_id
        )
      ) current_salary ON sh.employee_id = current_salary.employee_id
      GROUP BY sh.employee_id
      LIMIT 1`
    );

    // Query ที่ถูกต้องกว่า - คำนวณจาก current salary ของแต่ละพนักงาน
    const [correctSummary] = await connection.execute(
      `SELECT 
        COUNT(DISTINCT e.employee_id) as total_employees,
        COALESCE(AVG(current_sal.salary_amount), 0) as average_salary,
        COALESCE(MAX(current_sal.salary_amount), 0) as max_salary,
        COALESCE(MIN(current_sal.salary_amount), 0) as min_salary,
        COALESCE(COUNT(CASE 
          WHEN sh.salary_type = 'ADJUST' 
          AND MONTH(sh.effective_date) = MONTH(CURDATE())
          AND YEAR(sh.effective_date) = YEAR(CURDATE())
          THEN 1 END), 0) as adjustments_this_month
      FROM employees e
      LEFT JOIN (
        SELECT sh1.employee_id, sh1.salary_amount
        FROM salary_history sh1
        INNER JOIN (
          SELECT employee_id, MAX(effective_date) as max_date
          FROM salary_history
          GROUP BY employee_id
        ) latest ON sh1.employee_id = latest.employee_id 
          AND sh1.effective_date = latest.max_date
      ) current_sal ON e.employee_id = current_sal.employee_id
      LEFT JOIN salary_history sh ON e.employee_id = sh.employee_id`
    );

    const result = correctSummary[0] || {
      total_employees: 0,
      average_salary: 0,
      max_salary: 0,
      min_salary: 0,
      adjustments_this_month: 0
    };

    res.json({
      total_employees: parseInt(result.total_employees) || 0,
      average_salary: parseFloat(result.average_salary) || 0,
      max_salary: parseFloat(result.max_salary) || 0,
      min_salary: parseFloat(result.min_salary) || 0,
      adjustments_this_month: parseInt(result.adjustments_this_month) || 0
    });
  } catch (error) {
    console.error('Get salary summary error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลสรุปเงินเดือน' });
  } finally {
    if (connection) connection.release();
  }
});

// ===========================
// GET /api/hr/salary/employees - รายชื่อพนักงานพร้อมข้อมูลเงินเดือน
// ===========================
router.get('/salary/employees', authenticateToken, requireHR, async (req, res) => {
  let connection;
  try {
    const search = req.query.search || '';
    const department = req.query.department || '';

    connection = await pool.getConnection();

    // Build WHERE clause
    let whereClause = 'WHERE 1=1';
    const params = [];

    if (search) {
      whereClause += ` AND (e.first_name LIKE ? OR e.last_name LIKE ? OR CONCAT(e.first_name, ' ', e.last_name) LIKE ?)`;
      const searchPattern = `%${search}%`;
      params.push(searchPattern, searchPattern, searchPattern);
    }

    if (department) {
      whereClause += ` AND e.department = ?`;
      params.push(department);
    }

    // ดึงข้อมูลพนักงานพร้อมเงินเดือนปัจจุบันและเงินเดือนแรก
    const [employees] = await connection.execute(
      `SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        CONCAT(COALESCE(e.first_name, ''), ' ', COALESCE(e.last_name, '')) as full_name,
        e.position,
        e.department,
        -- เงินเดือนปัจจุบัน (ล่าสุด)
        COALESCE(current_sal.salary_amount, 0) as current_salary,
        -- เงินเดือนแรก (record แรก)
        COALESCE(starting_sal.salary_amount, 0) as starting_salary,
        -- เงินฐานเงินเดือน (จากตาราง employees)
        COALESCE(e.base_salary, current_sal.salary_amount, 0) as base_salary,
        -- จำนวนครั้งที่ปรับ (ADJUST)
        COALESCE(adjustment_count.count, 0) as adjustment_count,
        -- วันที่ปรับล่าสุด
        current_sal.effective_date as last_adjustment_date
      FROM employees e
      LEFT JOIN (
        SELECT sh1.employee_id, sh1.salary_amount, sh1.effective_date
        FROM salary_history sh1
        INNER JOIN (
          SELECT employee_id, MAX(effective_date) as max_date
          FROM salary_history
          GROUP BY employee_id
        ) latest ON sh1.employee_id = latest.employee_id 
          AND sh1.effective_date = latest.max_date
      ) current_sal ON e.employee_id = current_sal.employee_id
      LEFT JOIN (
        SELECT sh2.employee_id, sh2.salary_amount
        FROM salary_history sh2
        INNER JOIN (
          SELECT employee_id, MIN(effective_date) as min_date
          FROM salary_history
          GROUP BY employee_id
        ) first ON sh2.employee_id = first.employee_id 
          AND sh2.effective_date = first.min_date
      ) starting_sal ON e.employee_id = starting_sal.employee_id
      LEFT JOIN (
        SELECT employee_id, COUNT(*) as count
        FROM salary_history
        WHERE salary_type = 'ADJUST'
        GROUP BY employee_id
      ) adjustment_count ON e.employee_id = adjustment_count.employee_id
      ${whereClause}
      ORDER BY e.first_name, e.last_name`,
      params
    );

    res.json(employees);
  } catch (error) {
    console.error('Get employees salary error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลพนักงาน' });
  } finally {
    if (connection) connection.release();
  }
});

// ===========================
// GET /api/hr/salary/recent-adjustments - การปรับเงินเดือนล่าสุด
// ===========================
router.get('/salary/recent-adjustments', authenticateToken, requireHR, async (req, res) => {
  let connection;
  try {
    const limit = parseInt(req.query.limit) || 10;

    connection = await pool.getConnection();

    const [adjustments] = await connection.execute(
      `SELECT 
        sh.salary_id,
        sh.employee_id,
        sh.salary_amount,
        sh.effective_date,
        sh.salary_type,
        sh.reason,
        sh.created_by,
        sh.created_at,
        sh.updated_at,
        CONCAT(COALESCE(e.first_name, ''), ' ', COALESCE(e.last_name, '')) as employee_name
      FROM salary_history sh
      LEFT JOIN employees e ON sh.employee_id = e.employee_id
      WHERE sh.salary_type = 'ADJUST'
      ORDER BY sh.effective_date DESC, sh.created_at DESC
      LIMIT ?`,
      [limit]
    );

    res.json(adjustments);
  } catch (error) {
    console.error('Get recent adjustments error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลการปรับเงินเดือนล่าสุด' });
  } finally {
    if (connection) connection.release();
  }
});

// ===========================
// GET /api/hr/salary/employee-history - ประวัติเงินเดือนของพนักงาน
// ===========================
router.get('/salary/employee-history', authenticateToken, requireHR, async (req, res) => {
  let connection;
  try {
    const employeeId = parseInt(req.query.employee_id);

    if (!employeeId) {
      return res.status(400).json({ message: 'กรุณาระบุ employee_id' });
    }

    connection = await pool.getConnection();

    const [history] = await connection.execute(
      `SELECT 
        salary_id,
        employee_id,
        salary_amount,
        effective_date,
        salary_type,
        reason,
        created_by,
        created_at,
        updated_at
      FROM salary_history
      WHERE employee_id = ?
      ORDER BY effective_date DESC, created_at DESC`,
      [employeeId]
    );

    res.json(history);
  } catch (error) {
    console.error('Get employee salary history error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงประวัติเงินเดือน' });
  } finally {
    if (connection) connection.release();
  }
});

// ===========================
// POST /api/hr/salary/create - สร้างเงินเดือนแรก (START)
// ===========================
router.post('/salary/create', authenticateToken, requireHR, async (req, res) => {
  let connection;
  try {
    const { employee_id, salary_amount, effective_date } = req.body;
    const created_by = req.user.user_id || req.user.id;

    // Validate input
    if (!employee_id || !salary_amount || !effective_date) {
      return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน (employee_id, salary_amount, effective_date)' });
    }

    if (salary_amount <= 0) {
      return res.status(400).json({ message: 'เงินเดือนต้องมากกว่า 0' });
    }

    connection = await pool.getConnection();

    // ตรวจสอบว่าพนักงานมีเงินเดือน START แล้วหรือยัง
    const [existing] = await connection.execute(
      `SELECT salary_id FROM salary_history 
       WHERE employee_id = ? AND salary_type = 'START' 
       LIMIT 1`,
      [employee_id]
    );

    if (existing.length > 0) {
      return res.status(400).json({ message: 'พนักงานนี้มีเงินเดือน START อยู่แล้ว กรุณาใช้ ADJUST เพื่อปรับเงินเดือน' });
    }

    // เริ่ม transaction เพื่อให้ salary_history และ base_salary อัปเดตไปด้วยกัน
    await connection.beginTransaction();

    try {
      // สร้าง record ใหม่ใน salary_history
      const [result] = await connection.execute(
        `INSERT INTO salary_history 
         (employee_id, salary_amount, effective_date, salary_type, created_by)
         VALUES (?, ?, ?, 'START', ?)`,
        [employee_id, salary_amount, effective_date, created_by]
      );

      // อัปเดตฐานเงินเดือนในตาราง employees ให้ตรงกับเงินเดือน START
      await connection.execute(
        `UPDATE employees 
         SET base_salary = ? 
         WHERE employee_id = ?`,
        [salary_amount, employee_id]
      );

      await connection.commit();

      res.status(201).json({
        success: true,
        message: 'สร้างเงินเดือนแรกสำเร็จ และอัปเดตฐานเงินเดือนแล้ว',
        salary_id: result.insertId
      });
    } catch (txError) {
      await connection.rollback();
      throw txError;
    }
  } catch (error) {
    console.error('Create starting salary error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการสร้างเงินเดือนแรก' });
  } finally {
    if (connection) connection.release();
  }
});

// ===========================
// POST /api/hr/salary/adjust - ปรับเงินเดือน (ADJUST)
// ===========================
router.post('/salary/adjust', authenticateToken, requireHR, async (req, res) => {
  let connection;
  try {
    const { employee_id, salary_amount, effective_date, reason } = req.body;
    const created_by = req.user.user_id || req.user.id;

    // Validate input
    if (!employee_id || !salary_amount || !effective_date || !reason) {
      return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน (employee_id, salary_amount, effective_date, reason)' });
    }

    if (salary_amount <= 0) {
      return res.status(400).json({ message: 'เงินเดือนต้องมากกว่า 0' });
    }

    if (!reason.trim()) {
      return res.status(400).json({ message: 'กรุณากรอกเหตุผล' });
    }

    connection = await pool.getConnection();

    // ตรวจสอบว่าพนักงานมีเงินเดือน START หรือยัง
    const [existing] = await connection.execute(
      `SELECT salary_id FROM salary_history 
       WHERE employee_id = ? AND salary_type = 'START' 
       LIMIT 1`,
      [employee_id]
    );

    if (existing.length === 0) {
      return res.status(400).json({ message: 'พนักงานนี้ยังไม่มีเงินเดือน START กรุณาสร้างเงินเดือน START ก่อน' });
    }

    // เริ่ม transaction เพื่อให้ salary_history และ base_salary อัปเดตไปด้วยกัน
    await connection.beginTransaction();

    try {
      // สร้าง ADJUST record ใหม่
      const [result] = await connection.execute(
        `INSERT INTO salary_history 
         (employee_id, salary_amount, effective_date, salary_type, reason, created_by)
         VALUES (?, ?, ?, 'ADJUST', ?, ?)`,
        [employee_id, salary_amount, effective_date, reason, created_by]
      );

      // อัปเดตฐานเงินเดือนใน employees ให้เป็นเงินเดือนล่าสุด
      await connection.execute(
        `UPDATE employees 
         SET base_salary = ? 
         WHERE employee_id = ?`,
        [salary_amount, employee_id]
      );

      await connection.commit();

      res.status(201).json({
        success: true,
        message: 'ปรับเงินเดือนสำเร็จ และอัปเดตฐานเงินเดือนแล้ว',
        salary_id: result.insertId
      });
    } catch (txError) {
      await connection.rollback();
      throw txError;
    }
  } catch (error) {
    console.error('Adjust salary error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการปรับเงินเดือน' });
  } finally {
    if (connection) connection.release();
  }
});

// ===========================
// GET /api/hr/payroll/overview - ภาพรวมเงินเดือนประจำเดือน
// ===========================
router.get('/payroll/overview', authenticateToken, requireHR, async (req, res) => {
  let connection;
  try {
    const { month, year } = req.query;
    const selectedMonth = month ? parseInt(month, 10) : new Date().getMonth() + 1;
    const selectedYear = year ? parseInt(year, 10) : new Date().getFullYear();

    connection = await pool.getConnection();

    // ดึงข้อมูลพนักงานทั้งหมดพร้อมเงินเดือนปัจจุบัน
    const [employees] = await connection.execute(
      `SELECT 
        e.employee_id,
        e.user_id,
        COALESCE(current_sal.salary_amount, e.base_salary, 0) as current_salary,
        e.base_salary
      FROM employees e
      LEFT JOIN (
        SELECT sh1.employee_id, sh1.salary_amount
        FROM salary_history sh1
        INNER JOIN (
          SELECT employee_id, MAX(effective_date) as max_date
          FROM salary_history
          GROUP BY employee_id
        ) latest ON sh1.employee_id = latest.employee_id 
          AND sh1.effective_date = latest.max_date
      ) current_sal ON e.employee_id = current_sal.employee_id`
    );

    let totalGrossSalary = 0.0;
    let totalDeductions = 0.0;
    let totalEmployees = 0;

    // คำนวณเงินเดือนและหักของแต่ละพนักงาน
    for (const emp of employees) {
      const baseSalary = parseFloat(emp.current_salary || emp.base_salary || 0);
      if (baseSalary <= 0) continue; // ข้ามพนักงานที่ไม่มีเงินเดือน

      totalEmployees++;

      // คำนวณรายได้รวม (เงินเดือน + OT + อื่นๆ)
      let grossSalary = baseSalary;

      // ดึงชั่วโมง OT ที่อนุมัติแล้วในเดือนนี้
      try {
        const [otSummary] = await connection.execute(
          `SELECT COALESCE(SUM(total_hours), 0) as total_ot_hours
           FROM overtime_requests
           WHERE user_id = ?
             AND status = 'approved'
             AND MONTH(date) = ?
             AND YEAR(date) = ?`,
          [emp.user_id, selectedMonth, selectedYear]
        );

        const otHours = parseFloat(otSummary[0]?.total_ot_hours || 0);
        if (otHours > 0) {
          // คำนวณค่าล่วงเวลา (1.5 เท่าของเงินเดือนต่อชั่วโมง)
          const hourlyRate = baseSalary / 176; // 22 วัน * 8 ชั่วโมง
          const otAmount = otHours * hourlyRate * 1.5;
          grossSalary += otAmount;
        }
      } catch (otError) {
        console.log(`[Payroll Overview] Error calculating OT for employee ${emp.employee_id}:`, otError.message);
      }

      totalGrossSalary += grossSalary;

      // คำนวณยอดหัก
      // ประกันสังคม: 5% ของเงินเดือน (สูงสุด 750 บาท)
      const socialSecurity = Math.min(baseSalary * 0.05, 750);

      // ฐานภาษี = เงินเดือน - ประกันสังคม
      const taxableIncome = Math.max(baseSalary - socialSecurity, 0);
      
      // ภาษี: 5% ของฐานภาษี
      const tax = taxableIncome * 0.05;

      totalDeductions += socialSecurity + tax;
    }

    const netPay = totalGrossSalary - totalDeductions;

    console.log(`[Payroll Overview] Month: ${selectedMonth}, Year: ${selectedYear}`);
    console.log(`[Payroll Overview] Employees: ${totalEmployees}, Gross: ${totalGrossSalary}, Deductions: ${totalDeductions}, Net: ${netPay}`);

    res.json({
      total_gross_salary: totalGrossSalary,
      total_employees: totalEmployees,
      total_deductions: totalDeductions,
      net_pay: netPay,
      status: 'CALCULATED',
      month: selectedMonth,
      year: selectedYear,
    });
  } catch (error) {
    console.error('Get payroll overview error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการคำนวณภาพรวมเงินเดือน' });
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;

