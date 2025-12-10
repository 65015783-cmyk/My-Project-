-- ===========================
-- แก้ไขการลาของ montita ให้ขึ้นในหน้า manager
-- ===========================
USE humans;

-- ============================================
-- ขั้นตอนที่ 1: ตรวจสอบข้อมูลก่อนแก้ไข
-- ============================================
SELECT '=== BEFORE FIX ===' as '';

-- ตรวจสอบการลาของ montita
SELECT 
  lv.id,
  lv.user_id as current_leave_user_id,
  lv.status,
  'via employee_id' as join_method,
  e1.employee_id,
  e1.department
FROM leaves lv
LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
LEFT JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
WHERE lv.status = 'pending'
  AND (e1.user_id = (SELECT user_id FROM login WHERE username = 'montita')
       OR e2.user_id = (SELECT user_id FROM login WHERE username = 'montita'));

-- ============================================
-- ขั้นตอนที่ 2: แก้ไขการลาที่ใช้ login.user_id แทน employee_id
-- ============================================
SELECT '=== FIXING: Convert login.user_id to employee_id ===' as '';

-- หา employee_id ของ montita
SELECT 
  'Montita employee_id' as info,
  e.employee_id
FROM login l
INNER JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'montita';

-- แก้ไขการลาที่ใช้ login.user_id (user_id = 2) ให้เป็น employee_id
UPDATE leaves lv
INNER JOIN login l_login ON lv.user_id = l_login.user_id
INNER JOIN employees e ON l_login.user_id = e.user_id
LEFT JOIN employees e_check ON lv.user_id = e_check.employee_id
SET lv.user_id = e.employee_id
WHERE lv.status = 'pending'
  AND l_login.user_id = (SELECT user_id FROM login WHERE username = 'montita')
  AND e_check.employee_id IS NULL  -- ยังไม่ใช่ employee_id
  AND e.employee_id IS NOT NULL;

-- ============================================
-- ขั้นตอนที่ 3: ตรวจสอบผลลัพธ์หลังแก้ไข
-- ============================================
SELECT '=== AFTER FIX ===' as '';

-- ตรวจสอบการลาของ montita หลังแก้ไข
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
    ELSE '❌ jira จะไม่เห็นการลานี้ (แผนกไม่ตรง)'
  END as visibility_for_jira
FROM leaves lv
INNER JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending'
  AND e.user_id = (SELECT user_id FROM login WHERE username = 'montita')
ORDER BY lv.id;

-- ============================================
-- ขั้นตอนที่ 4: ตรวจสอบว่าทั้งสองคนอยู่ในแผนกเดียวกัน
-- ============================================
SELECT '=== Department Check ===' as '';

SELECT 
  l.username,
  l.role,
  e.department,
  CASE 
    WHEN e.department = (SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira'))
      THEN '✅ อยู่ในแผนกเดียวกันกับ jira'
    ELSE '❌ ไม่ได้อยู่ในแผนกเดียวกัน'
  END as matching_status
FROM login l
INNER JOIN employees e ON l.user_id = e.user_id
WHERE l.username IN ('jira', 'montita')
ORDER BY l.role DESC;

-- ============================================
-- ขั้นตอนที่ 5: ตรวจสอบการลาที่ jira จะเห็น
-- ============================================
SELECT '=== What Jira Should See ===' as '';

-- Simulate query ที่ jira จะเห็น (ตาม backend/routes/leave.js)
SELECT 
  lv.id,
  lv.leave_type,
  lv.start_date,
  lv.end_date,
  DATEDIFF(lv.end_date, lv.start_date) + 1 as total_days,
  lv.reason,
  lv.status,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.position,
  e.department
FROM leaves lv
INNER JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending' 
  AND e.department = (SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira'))
ORDER BY lv.created_at DESC;

