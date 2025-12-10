-- ===========================
-- ตั้งค่า Manager อย่างรวดเร็ว
-- เลือก user_id ที่ต้องการตั้งเป็น manager
-- ===========================
USE humans;

-- ตรวจสอบข้อมูล user ทั้งหมดก่อน
SELECT '=== ข้อมูล User ทั้งหมด ===' as '';
SELECT 
  l.user_id,
  l.username,
  l.email,
  l.role,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.position,
  e.department,
  COALESCE(e.is_manager, 0) as is_manager
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
ORDER BY l.user_id;

-- ===========================
-- เลือก user_id ที่ต้องการตั้งเป็น Manager
-- แก้ไข user_id ด้านล่างตามต้องการ
-- ===========================

-- ตัวอย่าง: ตั้งให้ jira (user_id = 5) เป็น manager
-- UPDATE employees 
-- SET is_manager = 1 
-- WHERE user_id = 5;

-- ตัวอย่าง: ตั้งให้ somsak (user_id = 3, HR Manager) เป็น manager
-- UPDATE employees 
-- SET is_manager = 1 
-- WHERE user_id = 3;

-- ตัวอย่าง: ตั้งให้ montita (user_id = 2) เป็น manager
-- UPDATE employees 
-- SET is_manager = 1 
-- WHERE user_id = 2;

-- ===========================
-- หรือตั้งตามแผนก
-- ===========================

-- ตั้งให้ทุกคนในแผนก Human Resources เป็น manager
-- UPDATE employees 
-- SET is_manager = 1 
-- WHERE department = 'Human Resources';

-- ตั้งให้ทุกคนในแผนก Engineering เป็น manager
-- UPDATE employees 
-- SET is_manager = 1 
-- WHERE department = 'Engineering';

-- ===========================
-- ตรวจสอบผลลัพธ์
-- ===========================
SELECT '=== Manager ทั้งหมด ===' as '';
SELECT 
  e.employee_id,
  e.user_id,
  l.username,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.position,
  e.department,
  e.is_manager
FROM employees e
INNER JOIN login l ON e.user_id = l.user_id
WHERE e.is_manager = 1
ORDER BY e.department, e.employee_id;

