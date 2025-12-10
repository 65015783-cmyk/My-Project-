-- ===========================
-- Debug: ตรวจสอบปัญหาการอนุมัติการลา
-- ===========================
USE humans;

-- 1. ตรวจสอบ Manager
SELECT '=== Manager Info ===' as '';
SELECT 
  l.user_id,
  l.username,
  l.role,
  e.employee_id,
  e.department,
  CONCAT(e.first_name, ' ', e.last_name) as name
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.role = 'manager';

-- 2. ตรวจสอบการลาที่ Pending
SELECT '=== Pending Leaves ===' as '';
SELECT 
  lv.id,
  lv.user_id as leave_user_id,
  lv.status,
  -- ตรวจสอบผ่าน employee_id
  e1.employee_id as employee_id_via_employee_id,
  e1.department as dept_via_employee_id,
  e1.user_id as employee_user_id_via_employee_id,
  -- ตรวจสอบผ่าน login.user_id
  l_login.user_id as login_user_id_from_leave,
  e2.employee_id as employee_id_via_login,
  e2.department as dept_via_login,
  e2.user_id as employee_user_id_via_login,
  -- สรุป
  COALESCE(e1.department, e2.department) as final_department,
  COALESCE(e1.user_id, e2.user_id) as final_employee_user_id
FROM leaves lv
LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
LEFT JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
WHERE lv.status = 'pending'
ORDER BY lv.id;

-- 3. ตรวจสอบการจับคู่แผนก
SELECT '=== Department Matching Test ===' as '';
SELECT 
  m.username as manager_username,
  m.manager_department,
  lv.id as leave_id,
  COALESCE(e1.department, e2.department) as employee_department,
  CASE 
    WHEN COALESCE(e1.department, e2.department) = m.manager_department THEN '✅ ตรงกัน'
    WHEN COALESCE(e1.department, e2.department) IS NULL THEN '❌ ไม่มี department'
    ELSE '❌ ไม่ตรงกัน'
  END as matching_status
FROM (
  SELECT 
    l.user_id,
    l.username,
    e.department as manager_department
  FROM login l
  INNER JOIN employees e ON l.user_id = e.user_id
  WHERE l.role = 'manager'
) m
CROSS JOIN leaves lv
LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
LEFT JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
WHERE lv.status = 'pending'
ORDER BY m.username, lv.id;

