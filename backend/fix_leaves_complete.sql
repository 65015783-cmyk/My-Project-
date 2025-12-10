-- ===========================
-- แก้ไขปัญหาการลาไม่ขึ้นที่ Manager (Complete Fix)
-- ===========================
USE humans;

-- ขั้นตอนที่ 1: ตรวจสอบข้อมูลก่อนแก้ไข
SELECT '=== BEFORE FIX: Leaves with issues ===' as '';
SELECT 
  lv.id,
  lv.user_id as current_leave_user_id,
  lv.status,
  'via employee_id' as join_method,
  e1.employee_id,
  e1.department,
  CONCAT(e1.first_name, ' ', e1.last_name) as employee_name
FROM leaves lv
LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
WHERE lv.status = 'pending' AND e1.employee_id IS NOT NULL

UNION ALL

SELECT 
  lv.id,
  lv.user_id as current_leave_user_id,
  lv.status,
  'via login.user_id (NEEDS FIX)' as join_method,
  e2.employee_id,
  e2.department,
  CONCAT(e2.first_name, ' ', e2.last_name) as employee_name
FROM leaves lv
LEFT JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
WHERE lv.status = 'pending' 
  AND l_login.user_id IS NOT NULL
  AND e2.employee_id IS NOT NULL
  AND lv.user_id NOT IN (SELECT employee_id FROM employees);

-- ขั้นตอนที่ 2: แก้ไขข้อมูลการลาที่ใช้ login.user_id แทน employee_id
SELECT '=== FIXING: Converting login.user_id to employee_id ===' as '';

UPDATE leaves lv
INNER JOIN login l_login ON lv.user_id = l_login.user_id
INNER JOIN employees e ON l_login.user_id = e.user_id
SET lv.user_id = e.employee_id
WHERE lv.user_id = l_login.user_id 
  AND lv.user_id != e.employee_id
  AND EXISTS (
    SELECT 1 FROM employees e2 
    WHERE e2.user_id = l_login.user_id
  );

-- ขั้นตอนที่ 3: ตรวจสอบผลลัพธ์หลังแก้ไข
SELECT '=== AFTER FIX: All pending leaves ===' as '';
SELECT 
  lv.id,
  lv.user_id as leave_user_id,
  lv.status,
  e.employee_id,
  e.department,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  l.role as employee_role
FROM leaves lv
INNER JOIN employees e ON lv.user_id = e.employee_id
LEFT JOIN login l ON e.user_id = l.user_id
WHERE lv.status = 'pending'
ORDER BY e.department, lv.id;

-- ขั้นตอนที่ 4: ตรวจสอบ Manager และการลาตามแผนก
SELECT '=== Manager and Leaves by Department ===' as '';
SELECT 
  m.department as manager_department,
  m.manager_name,
  COUNT(lv.id) as pending_leaves_count
FROM (
  SELECT 
    e.department,
    CONCAT(e.first_name, ' ', e.last_name) as manager_name,
    l.user_id
  FROM login l
  INNER JOIN employees e ON l.user_id = e.user_id
  WHERE l.role = 'manager'
) m
LEFT JOIN leaves lv ON lv.status = 'pending'
LEFT JOIN employees e ON lv.user_id = e.employee_id AND e.department = m.department
GROUP BY m.department, m.manager_name
ORDER BY m.department;

-- ขั้นตอนที่ 5: ตรวจสอบการลาที่ยังไม่สามารถ join ได้ (ถ้ามี)
SELECT '=== Leaves that still cannot join (if any) ===' as '';
SELECT 
  lv.id,
  lv.user_id,
  lv.status,
  lv.created_at
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending'
  AND e.employee_id IS NULL;

-- ขั้นตอนที่ 6: สรุป
SELECT '=== SUMMARY ===' as '';
SELECT 
  (SELECT COUNT(*) FROM leaves WHERE status = 'pending') as total_pending_leaves,
  (SELECT COUNT(*) 
   FROM leaves lv
   INNER JOIN employees e ON lv.user_id = e.employee_id
   WHERE lv.status = 'pending') as joinable_pending_leaves,
  (SELECT COUNT(DISTINCT e.department) 
   FROM leaves lv
   INNER JOIN employees e ON lv.user_id = e.employee_id
   WHERE lv.status = 'pending' AND e.department IS NOT NULL) as departments_with_pending_leaves;

