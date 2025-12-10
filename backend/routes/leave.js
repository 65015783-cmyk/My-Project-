const express = require('express');
const router = express.Router();
const { pool } = require('../db');
const { authenticateToken } = require('../middleware/auth');

// Request leave
router.post('/request', authenticateToken, async (req, res) => {
  let connection;
  try {
    const { leaveType, startDate, endDate, reason } = req.body;
    const loginUserId = req.user.user_id; // login.user_id จาก JWT

    if (!leaveType || !startDate || !endDate || !reason) {
      return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }

    connection = await pool.getConnection();

    // หา employee_id จาก login.user_id
    // เพราะ leaves.user_id อ้างอิงไปที่ employees.employee_id (ไม่ใช่ login.user_id)
    const [employeeRows] = await connection.execute(
      `SELECT employee_id 
       FROM employees 
       WHERE user_id = ?`,
      [loginUserId]
    );

    if (employeeRows.length === 0) {
      return res.status(404).json({ 
        message: 'ไม่พบข้อมูลพนักงาน กรุณาติดต่อผู้ดูแลระบบ' 
      });
    }

    const employeeId = employeeRows[0].employee_id;

    const [result] = await connection.execute(
      `INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) 
       VALUES (?, ?, ?, ?, ?, 'pending')`,
      [employeeId, leaveType, startDate, endDate, reason]
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
    const loginUserId = req.user.user_id; // login.user_id จาก JWT

    connection = await pool.getConnection();

    // หา employee_id จาก login.user_id
    // เพราะ leaves.user_id อ้างอิงไปที่ employees.employee_id (ไม่ใช่ login.user_id)
    const [employeeRows] = await connection.execute(
      `SELECT employee_id 
       FROM employees 
       WHERE user_id = ?`,
      [loginUserId]
    );

    if (employeeRows.length === 0) {
      return res.json({ leaves: [] });
    }

    const employeeId = employeeRows[0].employee_id;

    const [leaves] = await connection.execute(
      `SELECT * FROM leaves 
       WHERE user_id = ? 
       ORDER BY created_at DESC 
       LIMIT 100`,
      [employeeId]
    );

    res.json({ leaves });
  } catch (error) {
    console.error('Get leave history error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

// Get pending leave requests for manager (by department)
router.get('/pending', authenticateToken, async (req, res) => {
  let connection;
  try {
    const userId = req.user.user_id;
    const userRole = req.user.role;

    connection = await pool.getConnection();

    let query;
    let params;

    if (userRole === 'admin') {
      // Admin เห็นทั้งหมด
      query = `
        SELECT 
          lv.id,
          lv.user_id as employee_id,
          lv.leave_type,
          lv.start_date,
          lv.end_date,
          DATEDIFF(lv.end_date, lv.start_date) + 1 as total_days,
          lv.reason,
          lv.status,
          lv.created_at,
          CONCAT(e.first_name, ' ', e.last_name) as employee_name,
          e.position,
          e.department,
          l.email as employee_email
        FROM leaves lv
        LEFT JOIN employees e ON lv.user_id = e.employee_id
        LEFT JOIN login l ON e.user_id = l.user_id
        WHERE lv.status = 'pending'
        ORDER BY lv.created_at DESC
      `;
      params = [];
    } else if (userRole === 'manager') {
      // Manager เห็นเฉพาะคนในแผนกตัวเอง
      // หาแผนกของ manager
      const [managerInfo] = await connection.execute(
        `SELECT e.department
         FROM employees e
         INNER JOIN login l ON e.user_id = l.user_id
         WHERE l.user_id = ?`,
        [userId]
      );

      if (managerInfo.length === 0 || !managerInfo[0].department) {
        console.log(`[Leave Pending] Manager user_id ${userId} ไม่มีแผนกหรือไม่พบข้อมูลใน employees table`);
        return res.json({ leaves: [] });
      }

      const managerDept = managerInfo[0].department;
      console.log(`[Leave Pending] Manager user_id ${userId} แผนก: ${managerDept}`);

      // Query ที่รองรับทั้งกรณีที่ leaves.user_id เป็น employee_id หรือ login.user_id
      // ใช้ UNION เพื่อรวมทั้งสองกรณี
      query = `
        (
          -- กรณีที่ leaves.user_id = employees.employee_id (ถูกต้อง)
          SELECT 
            lv.id,
            e.employee_id,
            lv.leave_type,
            lv.start_date,
            lv.end_date,
            DATEDIFF(lv.end_date, lv.start_date) + 1 as total_days,
            lv.reason,
            lv.status,
            lv.created_at,
            CONCAT(e.first_name, ' ', e.last_name) as employee_name,
            e.position,
            e.department,
            l.email as employee_email
          FROM leaves lv
          INNER JOIN employees e ON lv.user_id = e.employee_id
          LEFT JOIN login l ON e.user_id = l.user_id
          WHERE lv.status = 'pending' 
            AND e.department = ?
        )
        UNION
        (
          -- กรณีที่ leaves.user_id = login.user_id (ต้องแปลงผ่าน login)
          SELECT 
            lv.id,
            e.employee_id,
            lv.leave_type,
            lv.start_date,
            lv.end_date,
            DATEDIFF(lv.end_date, lv.start_date) + 1 as total_days,
            lv.reason,
            lv.status,
            lv.created_at,
            CONCAT(e.first_name, ' ', e.last_name) as employee_name,
            e.position,
            e.department,
            l.email as employee_email
          FROM leaves lv
          INNER JOIN login l_login ON lv.user_id = l_login.user_id
          INNER JOIN employees e ON l_login.user_id = e.user_id
          LEFT JOIN login l ON e.user_id = l.user_id
          WHERE lv.status = 'pending' 
            AND e.department = ?
            AND lv.user_id NOT IN (SELECT employee_id FROM employees)
        )
        ORDER BY created_at DESC
      `;
      params = [managerDept, managerDept];
    } else {
      // Employee ปกติไม่มีสิทธิ์
      return res.status(403).json({ 
        message: 'คุณไม่มีสิทธิ์ในการอนุมัติการลา' 
      });
    }

    const [leaves] = await connection.execute(query, params);

    // Debug logging
    if (userRole === 'manager') {
      console.log(`[Leave Pending] Manager user_id ${userId} พบ ${leaves.length} รายการการลารออนุมัติ`);
      if (leaves.length === 0) {
        // ตรวจสอบว่ามีการลาที่ pending อยู่หรือไม่ (ไม่กรองตามแผนก)
        const [allPending] = await connection.execute(
          `SELECT COUNT(*) as count FROM leaves WHERE status = 'pending'`
        );
        console.log(`[Leave Pending] มีการลารออนุมัติทั้งหมด ${allPending[0]?.count || 0} รายการ`);
        
        // ตรวจสอบว่ามีการลาที่สามารถ join กับ employees ได้หรือไม่
        const [joinablePending] = await connection.execute(
          `SELECT COUNT(*) as count 
           FROM leaves lv
           LEFT JOIN employees e ON lv.user_id = e.employee_id
           LEFT JOIN login l_login ON lv.user_id = l_login.user_id
           LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
           WHERE lv.status = 'pending' 
             AND (e.employee_id IS NOT NULL OR e2.employee_id IS NOT NULL)`
        );
        console.log(`[Leave Pending] การลาที่สามารถ join กับ employees ได้: ${joinablePending[0]?.count || 0} รายการ`);
        
        // ตรวจสอบว่ามีการลาของพนักงานในแผนกเดียวกันหรือไม่
        if (managerInfo.length > 0 && managerInfo[0].department) {
          const managerDept = managerInfo[0].department;
          const [deptPending] = await connection.execute(
            `SELECT COUNT(*) as count 
             FROM leaves lv
             LEFT JOIN employees e ON lv.user_id = e.employee_id
             LEFT JOIN login l_login ON lv.user_id = l_login.user_id
             LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
             WHERE lv.status = 'pending' 
               AND COALESCE(e.department, e2.department) = ?`,
            [managerDept]
          );
          console.log(`[Leave Pending] การลาของพนักงานในแผนก ${managerDept}: ${deptPending[0]?.count || 0} รายการ`);
        }
      }
    }

    res.json({ leaves });
  } catch (error) {
    console.error('Get pending leaves error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

// Approve/Reject leave (Admin or Manager)
router.patch('/:leaveId/status', authenticateToken, async (req, res) => {
  let connection;
  try {
    const { leaveId } = req.params;
    const { status, rejectionReason } = req.body; // 'approved' or 'rejected'
    const approverId = req.user.user_id;
    const userRole = req.user.role;

    console.log(`[Leave Approval] Request received: leaveId=${leaveId}, status=${status}, approverId=${approverId}, role=${userRole}`);

    if (!status || !['approved', 'rejected'].includes(status)) {
      console.log(`[Leave Approval] Invalid status: ${status}`);
      return res.status(400).json({ message: 'สถานะไม่ถูกต้อง' });
    }

    connection = await pool.getConnection();

    // ตรวจสอบสิทธิ์: Admin หรือ Manager
    if (userRole !== 'admin' && userRole !== 'manager') {
      return res.status(403).json({ message: 'คุณไม่มีสิทธิ์ในการอนุมัติ/ปฏิเสธ' });
    }

    if (userRole === 'manager') {
      // Manager ต้องตรวจสอบว่าเป็นแผนกเดียวกัน
      const [managerInfo] = await connection.execute(
        `SELECT e.department
         FROM employees e
         INNER JOIN login l ON e.user_id = l.user_id
         WHERE l.user_id = ?`,
        [approverId]
      );

      console.log(`[Leave Approval] Manager user_id ${approverId} info:`, managerInfo);

      if (managerInfo.length === 0 || !managerInfo[0].department) {
        console.log(`[Leave Approval] Manager user_id ${approverId} ไม่มีแผนกหรือไม่พบข้อมูล`);
        return res.status(403).json({ message: 'คุณไม่มีสิทธิ์ในการอนุมัติ/ปฏิเสธ - ไม่พบข้อมูลแผนก' });
      }

      const managerDept = managerInfo[0].department;
      console.log(`[Leave Approval] Manager แผนก: ${managerDept}`);

      // ตรวจสอบว่าพนักงานที่ขอลาอยู่ในแผนกเดียวกันหรือไม่
      // รองรับทั้งกรณีที่ leaves.user_id เป็น employee_id หรือ login.user_id
      const [leaveInfo] = await connection.execute(
        `SELECT 
          COALESCE(e1.department, e2.department) as department,
          COALESCE(e1.employee_id, e2.employee_id) as employee_id,
          COALESCE(e1.user_id, e2.user_id) as employee_user_id,
          lv.user_id as leave_user_id
         FROM leaves lv
         LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
         LEFT JOIN login l_login ON lv.user_id = l_login.user_id
         LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
         WHERE lv.id = ?`,
        [leaveId]
      );

      console.log(`[Leave Approval] Leave ID ${leaveId} info:`, leaveInfo);

      if (leaveInfo.length === 0) {
        console.log(`[Leave Approval] ไม่พบข้อมูลการลา ID: ${leaveId}`);
        return res.status(404).json({ message: 'ไม่พบข้อมูลการลา' });
      }

      const leaveDept = leaveInfo[0].department;
      if (!leaveDept) {
        console.log(`[Leave Approval] การลา ID ${leaveId} ไม่มี department`);
        return res.status(404).json({ message: 'ไม่พบข้อมูลแผนกของพนักงานที่ขอลา' });
      }

      console.log(`[Leave Approval] เปรียบเทียบแผนก - Manager: ${managerDept}, Employee: ${leaveDept}`);

      if (leaveDept !== managerDept) {
        console.log(`[Leave Approval] แผนกไม่ตรงกัน - Manager: ${managerDept}, Employee: ${leaveDept}`);
        return res.status(403).json({ 
          message: `คุณสามารถอนุมัติได้เฉพาะคนในแผนกของคุณเท่านั้น (แผนกของคุณ: ${managerDept}, แผนกของพนักงาน: ${leaveDept})` 
        });
      }

      console.log(`[Leave Approval] แผนกตรงกัน - อนุญาตให้อนุมัติ`);
    }

    // หา employee_id ของคนอนุมัติ (เพราะ approved_by อ้างอิงไปที่ employees.employee_id)
    const [approverInfo] = await connection.execute(
      `SELECT e.employee_id
       FROM employees e
       INNER JOIN login l ON e.user_id = l.user_id
       WHERE l.user_id = ?`,
      [approverId]
    );

    if (approverInfo.length === 0 || !approverInfo[0].employee_id) {
      console.log(`[Leave Approval] ไม่พบ employee_id ของคนอนุมัติ user_id ${approverId}`);
      return res.status(404).json({ message: 'ไม่พบข้อมูลพนักงานของคนอนุมัติ' });
    }

    const approverEmployeeId = approverInfo[0].employee_id;
    console.log(`[Leave Approval] คนอนุมัติ user_id ${approverId} -> employee_id ${approverEmployeeId}`);

    // อัปเดตสถานะการลา (ใช้ employee_id แทน login.user_id)
    const [updateResult] = await connection.execute(
      `UPDATE leaves 
       SET status = ?, approved_by = ?, approved_at = NOW(), updated_at = NOW() 
       WHERE id = ?`,
      [status, approverEmployeeId, leaveId]
    );

    console.log(`[Leave Approval] อัปเดตสถานะการลา ID ${leaveId} เป็น ${status} โดย user_id ${approverId}`);
    console.log(`[Leave Approval] Update result:`, updateResult);

    // ส่งแจ้งเตือนไปยังพนักงานที่ขอลา
    try {
      // หา employee_id และ user_id ของพนักงานที่ขอลา
      const [employeeInfo] = await connection.execute(
        `SELECT 
          COALESCE(e1.employee_id, e2.employee_id) as employee_id,
          COALESCE(e1.user_id, e2.user_id) as employee_user_id,
          CONCAT(COALESCE(e1.first_name, e2.first_name), ' ', COALESCE(e1.last_name, e2.last_name)) as employee_name
         FROM leaves lv
         LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
         LEFT JOIN login l_login ON lv.user_id = l_login.user_id
         LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
         WHERE lv.id = ?`,
        [leaveId]
      );

      console.log(`[Leave Approval] Employee info:`, employeeInfo);
      
      if (employeeInfo.length > 0 && employeeInfo[0].employee_user_id) {
        const employeeUserId = employeeInfo[0].employee_user_id;
        const employeeName = employeeInfo[0].employee_name || 'พนักงาน';
        
        console.log(`[Leave Approval] Creating notification for user_id ${employeeUserId} (${employeeName})`);
        
        // สร้างตาราง notifications ถ้ายังไม่มี (เพิ่ม leave_id)
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
            await connection.execute(`
              ALTER TABLE notifications 
              ADD COLUMN IF NOT EXISTS leave_id INT DEFAULT NULL,
              ADD INDEX IF NOT EXISTS idx_leave_id (leave_id),
              ADD FOREIGN KEY IF NOT EXISTS (leave_id) REFERENCES leaves(id) ON DELETE SET NULL
            `);
          } catch (alterError) {
            // Ignore error if column already exists
            console.log(`[Leave Approval] Column leave_id may already exist`);
          }
          
          console.log(`[Leave Approval] Notifications table created/verified`);
        } catch (tableError) {
          console.error(`[Leave Approval] Error creating notifications table:`, tableError);
        }

        // สร้างแจ้งเตือน (เก็บ leave_id ด้วย)
        const notificationTitle = status === 'approved' 
          ? 'อนุมัติการลางาน' 
          : 'ปฏิเสธการลางาน';
        const notificationMessage = status === 'approved'
          ? `การขอลางานของคุณได้รับการอนุมัติแล้ว`
          : `การขอลางานของคุณถูกปฏิเสธ${rejectionReason ? `: ${rejectionReason}` : ''}`;

        try {
          const [notifResult] = await connection.execute(
            `INSERT INTO notifications (user_id, title, message, type, leave_id, is_read)
             VALUES (?, ?, ?, ?, ?, FALSE)`,
            [employeeUserId, notificationTitle, notificationMessage, status === 'approved' ? 'success' : 'warning', leaveId]
          );

          console.log(`[Leave Approval] ✅ ส่งแจ้งเตือนสำเร็จไปยัง user_id ${employeeUserId} (${employeeName})`);
          console.log(`[Leave Approval] Notification ID: ${notifResult.insertId}`);
        } catch (notifError) {
          console.error(`[Leave Approval] ❌ Error creating notification:`, notifError);
        }
      } else {
        console.log(`[Leave Approval] ⚠️ ไม่พบ employee_user_id สำหรับการลา ID ${leaveId}`);
        console.log(`[Leave Approval] Employee info:`, employeeInfo);
      }
    } catch (notifError) {
      // Log error แต่ไม่ทำให้การอนุมัติล้มเหลว
      console.error('Error creating notification:', notifError);
    }

    res.json({ 
      message: `${status === 'approved' ? 'อนุมัติ' : 'ปฏิเสธ'}คำขอลางานสำเร็จ`,
      status: status
    });
  } catch (error) {
    console.error('Update leave status error:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;

