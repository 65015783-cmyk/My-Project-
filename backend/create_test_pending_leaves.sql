-- ===========================
-- สร้างข้อมูลทดสอบวันลาที่รออนุมัติ (Pending Leaves)
-- สำหรับทดสอบหน้า Leave Management
-- ===========================
USE humans;

-- ตรวจสอบว่ามีข้อมูลพนักงานหรือไม่
SELECT 'Employees:' as '';
SELECT employee_id, first_name, last_name, position, department FROM employees;

-- เพิ่มข้อมูลวันลาที่รออนุมัติ (pending)
-- ใช้ employee_id จากตาราง employees
INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES
-- Montita (employee_id = 2, Engineering)
(2, 'sick', DATE_ADD(CURDATE(), INTERVAL 2 DAY), DATE_ADD(CURDATE(), INTERVAL 3 DAY), 'ไม่สบาย มีไข้ ต้องพักผ่อน', 'pending'),
(2, 'personal', DATE_ADD(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 12 DAY), 'ลาพักผ่อน ไปเที่ยวกับครอบครัว', 'pending'),

-- สมศักดิ์ (employee_id = 3, Human Resources)
(3, 'sick', DATE_ADD(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 6 DAY), 'ป่วย ต้องไปพบแพทย์', 'pending'),
(3, 'personal', DATE_ADD(CURDATE(), INTERVAL 15 DAY), DATE_ADD(CURDATE(), INTERVAL 16 DAY), 'ลากิจส่วนตัว มีธุระสำคัญ', 'pending')

ON DUPLICATE KEY UPDATE id=id;

-- ตรวจสอบข้อมูลวันลาที่รออนุมัติ
SELECT 'Pending Leaves:' as '';
SELECT 
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
  lv.created_at
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending'
ORDER BY lv.created_at DESC;

-- หมายเหตุ: 
-- - user_id ใน leaves table อ้างอิงไปที่ employee_id ใน employees table
-- - ตรวจสอบว่า employee_id ตรงกับข้อมูลใน employees table
-- - ถ้ามีข้อมูล pending อยู่แล้ว อาจจะต้องลบออกก่อน หรือใช้ INSERT IGNORE

