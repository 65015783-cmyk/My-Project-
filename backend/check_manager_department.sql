-- ===========================
-- ตรวจสอบ Manager และ Department
-- ===========================
USE humans;

-- 1. ตรวจสอบ Manager ทั้งหมดและแผนก
SELECT '=== All Managers and Their Departments ===' as '';
SELECT 
  l.user_id as login_user_id,
  l.username,
  l.role,
  e.employee_id,
  e.user_id as employee_user_id,
  e.department,
  CONCAT(e.first_name, ' ', e.last_name) as manager_name,
  CASE 
    WHEN e.employee_id IS NULL THEN '❌ ไม่มีข้อมูลใน employees table'
    WHEN e.department IS NULL THEN '❌ ไม่มี department'
    WHEN e.department = '' THEN '❌ department เป็นค่าว่าง'
    ELSE '✅ มี department'
  END as status
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.role = 'manager'
ORDER BY l.user_id;

-- 2. ตรวจสอบ Manager ที่ไม่มี department
SELECT '=== Managers WITHOUT Department (NEEDS FIX) ===' as '';
SELECT 
  l.user_id,
  l.username,
  e.employee_id,
  CONCAT(e.first_name, ' ', e.last_name) as manager_name,
  e.department
FROM login l
INNER JOIN employees e ON l.user_id = e.user_id
WHERE l.role = 'manager'
  AND (e.department IS NULL OR e.department = '');

-- 3. ตรวจสอบ Manager ที่ไม่มีข้อมูลใน employees table
SELECT '=== Managers WITHOUT Employee Record (NEEDS FIX) ===' as '';
SELECT 
  l.user_id,
  l.username,
  l.role
FROM login l
WHERE l.role = 'manager'
  AND l.user_id NOT IN (SELECT user_id FROM employees WHERE user_id IS NOT NULL);

-- 4. แสดงแผนกทั้งหมดที่มีในระบบ
SELECT '=== All Departments in System ===' as '';
SELECT DISTINCT 
  department,
  COUNT(*) as employee_count
FROM employees
WHERE department IS NOT NULL AND department != ''
GROUP BY department
ORDER BY department;

