-- ===========================
-- ตั้งค่าให้ user เป็น Manager สำหรับทดสอบ
-- ===========================
USE humans;

-- ตรวจสอบข้อมูลพนักงานปัจจุบัน
SELECT 'Current Employees:' as '';
SELECT 
  e.employee_id,
  e.user_id,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.position,
  e.department,
  e.is_manager,
  l.username,
  l.email,
  l.role
FROM employees e
LEFT JOIN login l ON e.user_id = l.user_id
ORDER BY e.employee_id;

-- ตรวจสอบว่ามี field is_manager หรือไม่
SELECT 'Checking is_manager field...' as '';
SHOW COLUMNS FROM employees LIKE 'is_manager';

-- ถ้ายังไม่มี field is_manager ให้เพิ่มก่อน
-- ALTER TABLE employees ADD COLUMN is_manager TINYINT(1) DEFAULT 0 AFTER department;

-- ตั้งค่าให้ user เป็น manager
-- ตัวอย่าง: ตั้งให้ jira (user_id = 5) เป็น manager
-- หรือตั้งให้ somsak (user_id = 3, HR Manager) เป็น manager

-- วิธีที่ 1: ตั้งตาม user_id
UPDATE employees 
SET is_manager = 1 
WHERE user_id = 5;  -- jira

-- หรือตั้งให้ somsak (HR Manager) เป็น manager
-- UPDATE employees 
-- SET is_manager = 1 
-- WHERE user_id = 3;  -- somsak

-- วิธีที่ 2: ตั้งตามตำแหน่ง (ถ้ามีคำว่า Manager)
-- UPDATE employees 
-- SET is_manager = 1 
-- WHERE position LIKE '%Manager%' OR position LIKE '%หัวหน้า%';

-- วิธีที่ 3: ตั้งตามแผนก (ตั้งให้หัวหน้าแผนก Engineering)
-- UPDATE employees 
-- SET is_manager = 1 
-- WHERE department = 'Engineering';

-- ตรวจสอบผลลัพธ์
SELECT 'Updated Employees (Managers):' as '';
SELECT 
  e.employee_id,
  e.user_id,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.position,
  e.department,
  e.is_manager,
  l.username,
  l.email,
  l.role
FROM employees e
LEFT JOIN login l ON e.user_id = l.user_id
WHERE e.is_manager = 1;

-- ตรวจสอบว่ามีข้อมูลวันลาที่รออนุมัติหรือไม่
SELECT 'Pending Leave Requests:' as '';
SELECT 
  lv.id,
  lv.user_id as employee_id,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.department,
  lv.leave_type,
  lv.start_date,
  lv.end_date,
  lv.status
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending'
ORDER BY lv.created_at DESC;

