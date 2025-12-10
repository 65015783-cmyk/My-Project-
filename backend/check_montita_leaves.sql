-- ===========================
-- ตรวจสอบว่าทำไมการลาของ montita ไม่ขึ้นในหน้า manager
-- ===========================
USE humans;

-- ============================================
-- 1. ตรวจสอบข้อมูล montita
-- ============================================
SELECT '=== 1. Montita Information ===' as '';
SELECT 
  l.user_id as login_user_id,
  l.username,
  l.role,
  e.employee_id,
  e.user_id as employee_user_id,
  e.department,
  e.position,
  CONCAT(e.first_name, ' ', e.last_name) as name
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'montita';

-- ============================================
-- 2. ตรวจสอบข้อมูล jira (manager)
-- ============================================
SELECT '=== 2. Jira (Manager) Information ===' as '';
SELECT 
  l.user_id as login_user_id,
  l.username,
  l.role,
  e.employee_id,
  e.user_id as employee_user_id,
  e.department,
  e.position,
  CONCAT(e.first_name, ' ', e.last_name) as name
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'jira';

-- ============================================
-- 3. ตรวจสอบการลาของ montita
-- ============================================
SELECT '=== 3. Montita Leaves ===' as '';
SELECT 
  lv.id,
  lv.user_id as leave_user_id,
  lv.leave_type,
  lv.start_date,
  lv.end_date,
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
  CONCAT(e2.first_name, ' ', e2.last_name) as name_via_login,
  -- สรุป
  CASE 
    WHEN e1.employee_id IS NOT NULL AND e1.employee_id = (SELECT employee_id FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'montita'))
      THEN '✅ ใช้ employee_id (ถูกต้อง)'
    WHEN e2.employee_id IS NOT NULL AND e2.user_id = (SELECT user_id FROM login WHERE username = 'montita')
      THEN '⚠️ ใช้ login.user_id (ต้องแก้ไข)'
    ELSE '❌ ไม่สามารถ join ได้'
  END as leave_status
FROM leaves lv
LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
LEFT JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
WHERE lv.status = 'pending'
  AND (
    e1.user_id = (SELECT user_id FROM login WHERE username = 'montita')
    OR e2.user_id = (SELECT user_id FROM login WHERE username = 'montita')
  )
ORDER BY lv.id;

-- ============================================
-- 4. ตรวจสอบว่าแผนกตรงกันหรือไม่
-- ============================================
SELECT '=== 4. Department Matching ===' as '';
SELECT 
  'jira department' as info,
  e.department
FROM login l
INNER JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'jira'

UNION ALL

SELECT 
  'montita department' as info,
  e.department
FROM login l
INNER JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'montita'

UNION ALL

SELECT 
  'leaves department (via employee_id)' as info,
  e.department
FROM leaves lv
INNER JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending'
  AND lv.user_id = (SELECT employee_id FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'montita'))
LIMIT 1;

-- ============================================
-- 5. ตรวจสอบ Query ที่ Manager จะเห็น
-- ============================================
SELECT '=== 5. What Manager Should See ===' as '';

-- Simulate query ที่ manager จะเห็น
SELECT 
  lv.id,
  lv.user_id as leave_user_id,
  lv.leave_type,
  lv.start_date,
  lv.end_date,
  lv.status,
  e.employee_id,
  e.department,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  CASE 
    WHEN e.department = (SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira'))
      THEN '✅ jira จะเห็นการลานี้'
    ELSE '❌ jira จะไม่เห็นการลานี้'
  END as visibility
FROM leaves lv
INNER JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending'
ORDER BY lv.id;

-- ============================================
-- 6. ตรวจสอบปัญหาที่เป็นไปได้
-- ============================================
SELECT '=== 6. Possible Issues ===' as '';

-- 6.1 การลาที่ใช้ login.user_id แทน employee_id
SELECT 
  'Leaves using login.user_id instead of employee_id' as issue,
  COUNT(*) as count,
  GROUP_CONCAT(lv.id ORDER BY lv.id) as leave_ids
FROM leaves lv
INNER JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending'
  AND l_login.user_id = (SELECT user_id FROM login WHERE username = 'montita')
  AND e.employee_id IS NULL;

-- 6.2 การลาที่ไม่สามารถ join กับ employees ได้
SELECT 
  'Leaves that cannot join with employees' as issue,
  COUNT(*) as count,
  GROUP_CONCAT(lv.id ORDER BY lv.id) as leave_ids
FROM leaves lv
LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
LEFT JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
WHERE lv.status = 'pending'
  AND e1.employee_id IS NULL
  AND e2.employee_id IS NULL;

