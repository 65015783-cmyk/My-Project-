const express = require('express');
const router = express.Router();
const { pool } = require('../db');
const { authenticateToken } = require('../middleware/auth');

// GET /api/salary/summary?year=YYYY&month=MM
// สรุปเงินเดือนของพนักงาน (ฝั่ง employee ดูของตัวเอง)
router.get('/summary', authenticateToken, async (req, res) => {
  let connection;
  try {
    const loginUserId = req.user.user_id;
    const year = req.query.year ? parseInt(req.query.year, 10) : new Date().getFullYear();
    const month = req.query.month ? parseInt(req.query.month, 10) : new Date().getMonth() + 1;

    if (!loginUserId) {
      return res.status(400).json({ message: 'ไม่พบข้อมูลผู้ใช้' });
    }

    connection = await pool.getConnection();

    // หา employee_id และ base_salary ของผู้ใช้งานปัจจุบัน
    const [employeeRows] = await connection.execute(
      `SELECT 
        e.employee_id,
        COALESCE(e.base_salary, 0) as base_salary
       FROM employees e
       INNER JOIN login l ON e.user_id = l.user_id
       WHERE l.user_id = ?
       LIMIT 1`,
      [loginUserId]
    );

    if (employeeRows.length === 0) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลพนักงาน' });
    }

    const employeeId = employeeRows[0].employee_id;
    const baseSalary = parseFloat(employeeRows[0].base_salary) || 0;

    // ช่วงวันที่ของเดือนที่เลือก
    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    const lastDay = new Date(year, month, 0).getDate(); // day 0 of next month = last day of current
    const endDate = `${year}-${String(month).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;

    // ถ้าเป็นเดือนปัจจุบัน ให้คำนวณถึง "วันนี้" เท่านั้น ไม่ใช่สิ้นเดือน
    const today = new Date();
    let effectiveEndDate = endDate;
    if (today.getFullYear() === year && today.getMonth() + 1 === month) {
      const todayStr = `${year}-${String(month).padStart(2, '0')}-${String(
        today.getDate()
      ).padStart(2, '0')}`;
      effectiveEndDate = todayStr;
    }

    // ดึงจำนวนวันทำงานจริงจาก attendance (ตามวันที่ในเดือนนั้น)
    let workDays = 0;
    // เก็บข้อมูล attendance รายวัน เพื่อใช้ตรวจมาสาย
    let attendanceRows = [];
    try {
      const [attendanceSummary] = await connection.execute(
        `SELECT 
          COUNT(DISTINCT date) as work_days
         FROM attendance
         WHERE user_id = ?
           AND date >= ?
           AND date <= ?`,
        [loginUserId, startDate, effectiveEndDate]
      );

      workDays = attendanceSummary[0]?.work_days || 0;

      // ดึงข้อมูลละเอียดสำหรับคำนวณมาสาย
      const [rows] = await connection.execute(
        `SELECT date, check_in_time 
         FROM attendance
         WHERE user_id = ?
           AND date >= ?
           AND date <= ?`,
        [loginUserId, startDate, effectiveEndDate]
      );

      attendanceRows = rows || [];
    } catch (attendanceError) {
      console.log('[Salary Summary] Attendance table may not exist or query failed:', attendanceError.message);
      workDays = 0;
      attendanceRows = [];
    }

    // นับวันลาที่อนุมัติในเดือนนี้ (optional)
    let leaveDays = 0;
    try {
      const [leaveSummary] = await connection.execute(
        `SELECT 
          COALESCE(SUM(
            CASE 
              WHEN status = 'approved' THEN DATEDIFF(end_date, start_date) + 1
              ELSE 0
            END
          ), 0) as leave_days
         FROM leaves
         WHERE user_id = ?
           AND start_date >= ?
           AND end_date <= ?`,
        [employeeId, startDate, effectiveEndDate]
      );

      leaveDays = leaveSummary[0]?.leave_days || 0;
    } catch (leaveError) {
      console.log('[Salary Summary] Leaves table query failed:', leaveError.message);
      leaveDays = 0;
    }

    // ===========================
    // คำนวณเงินเดือนตามกติกาที่กำหนด
    // เงินเดือนใช้ฐานตรงๆ ไม่ลดตามวัน
    // ประกันสังคม 5% แต่ไม่เกิน 750
    // ภาษี 5% ของ (ฐาน − ประกันสังคม)
    // อื่นๆ = 0
    // ===========================

    const bonus = 0;
    const overtimeAmount = 0;
    const allowance = 0;
    const transportAllowance = 0;
    const otherIncome = 0;

    // ประกันสังคม 5% ของฐาน แต่ไม่เกิน 750
    const socialSecurity = Math.min(baseSalary * 0.05, 750);

    // ฐานภาษี = ฐานเงินเดือน - ประกันสังคม (ไม่ให้ติดลบ)
    const taxableIncome = Math.max(baseSalary - socialSecurity, 0);

    // ภาษี 5% ของฐานภาษี
    const tax = taxableIncome * 0.05;

    const providentFund = 0;
    const loan = 0;
    // ตอนนี้ยังไม่คิดค่าปรับจากการขาด/มาสาย เพราะข้อมูลในระบบยังไม่ชัดเจน
    const fine = 0;
    const otherDeductions = 0;

    const response = {
      month: month,
      year: year,
      payment_date: `${year}-${String(month).padStart(2, '0')}-${String(
        Math.min(25, lastDay)
      ).padStart(2, '0')}`,
      base_salary: baseSalary,
      bonus,
      overtime: overtimeAmount,
      allowance,
      transport_allowance: transportAllowance,
      other_income: otherIncome,
      tax,
      social_security: socialSecurity,
      provident_fund: providentFund,
      loan,
      fine,
      other_deductions: otherDeductions,
      work_days: workDays,
      leave_days: leaveDays,
      overtime_hours: 0,
    };

    return res.json(response);
  } catch (error) {
    console.error('Get salary summary error:', error);
    return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลเงินเดือน' });
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;

