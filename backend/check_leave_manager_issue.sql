-- ===========================
-- ตรวจสอบปัญหาการลาไม่ขึ้นที่ Manager
-- ===========================
USE humans;

-- 1. ตรวจสอบ Manager ทั้งหมด
SELECT '=== Manager Information ===' as '';
SELECT 
  l.user_id as login_user_id,
  l.username,
  l.role,
  e.employee_id,
  e.department,
  CONCAT(e.first_name, ' ', e.last_name) as manager_name
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.role = 'manager';

-- 2. ตรวจสอบการลาที่ Pending ทั้งหมด
SELECT '=== Pending Leaves ===' as '';
SELECT 
  lv.id,
  lv.user_id as leave_user_id,
  lv.status,
  lv.created_at,
  -- ตรวจสอบว่า join กับ employees ผ่าน employee_id ได้หรือไม่
  e1.employee_id as employee_id_via_employee_id,
  e1.department as dept_via_employee_id,
  CONCAT(e1.first_name, ' ', e1.last_name) as name_via_employee_id,
  -- ตรวจสอบว่า join กับ employees ผ่าน login.user_id ได้หรือไม่
  l_login.user_id as login_user_id_from_leave,
  e2.employee_id as employee_id_via_login,
  e2.department as dept_via_login,
  CONCAT(e2.first_name, ' ', e2.last_name) as name_via_login
FROM leaves lv
LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
LEFT JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
WHERE lv.status = 'pending'
ORDER BY lv.id;

-- 3. ตรวจสอบว่ามีการลาที่ไม่สามารถ join กับ employees ได้หรือไม่
SELECT '=== Leaves that cannot join with employees ===' as '';
SELECT 
  lv.id,
  lv.user_id,
  lv.status,
  lv.created_at
FROM leaves lv
LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
LEFT JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
WHERE lv.status = 'pending'
  AND e1.employee_id IS NULL 
  AND e2.employee_id IS NULL;

-- 4. ตรวจสอบการลาตามแผนก (สำหรับ Manager)
SELECT '=== Leaves by Department (for Manager) ===' as '';
SELECT 
  e.department,
  COUNT(*) as pending_count
FROM leaves lv
LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
LEFT JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
LEFT JOIN employees e ON COALESCE(e1.employee_id, e2.employee_id) = e.employee_id
WHERE lv.status = 'pending'
  AND e.department IS NOT NULL
GROUP BY e.department;

-- 5. ตรวจสอบ Employee ทั้งหมดและแผนก
SELECT '=== All Employees with Department ===' as '';
SELECT 
  e.employee_id,
  e.user_id,
  CONCAT(e.first_name, ' ', e.last_name) as name,
  e.department,
  l.role
FROM employees e
LEFT JOIN login l ON e.user_id = l.user_id
WHERE e.department IS NOT NULL
ORDER BY e.department, e.employee_id;

