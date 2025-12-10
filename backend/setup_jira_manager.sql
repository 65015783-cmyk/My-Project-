-- ===========================
-- ตั้งค่า jira (manager) ให้อยู่ในแผนก Engineering
-- ===========================
USE humans;

-- ============================================
-- ขั้นตอนที่ 1: ตรวจสอบข้อมูลปัจจุบัน
-- ============================================
SELECT '=== Current Status ===' as '';

-- ตรวจสอบ jira
SELECT 
  'jira' as username,
  l.user_id as login_user_id,
  l.role,
  e.employee_id,
  e.department,
  e.position
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'jira';

-- ตรวจสอบ montita
SELECT 
  'montita' as username,
  l.user_id as login_user_id,
  l.role,
  e.employee_id,
  e.department,
  e.position
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'montita';

-- ============================================
-- ขั้นตอนที่ 2: สร้าง/อัปเดต employee record สำหรับ jira
-- ============================================

-- วิธีที่ 1: ถ้ามี employee record แล้ว ให้อัปเดต
UPDATE employees
SET 
  department = 'Engineering',
  position = COALESCE(NULLIF(position, ''), 'Manager'),
  first_name = COALESCE(NULLIF(first_name, ''), 'jira'),
  last_name = COALESCE(NULLIF(last_name, ''), '')
WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira')
  AND EXISTS (
    SELECT 1 FROM employees e2 
    WHERE e2.user_id = (SELECT user_id FROM login WHERE username = 'jira')
  );

-- วิธีที่ 2: ถ้าไม่มี employee record ให้สร้างใหม่
INSERT INTO employees (user_id, first_name, last_name, position, department)
SELECT 
  l.user_id,
  'jira' as first_name,
  '' as last_name,
  'Manager' as position,
  'Engineering' as department
FROM login l
WHERE l.username = 'jira'
  AND l.user_id NOT IN (
    SELECT user_id FROM employees WHERE user_id IS NOT NULL
  );

-- ============================================
-- ขั้นตอนที่ 3: ตรวจสอบผลลัพธ์
-- ============================================
SELECT '=== After Setup ===' as '';

-- ตรวจสอบ jira
SELECT 
  'jira (manager)' as user_type,
  l.user_id,
  l.username,
  l.role,
  e.employee_id,
  e.department,
  e.position,
  CONCAT(e.first_name, ' ', e.last_name) as name,
  CASE 
    WHEN e.department = 'Engineering' THEN '✅ อยู่ในแผนก Engineering'
    WHEN e.department IS NULL THEN '❌ ไม่มี department'
    ELSE CONCAT('⚠️ อยู่ในแผนก ', e.department)
  END as status
FROM login l
INNER JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'jira';

-- ตรวจสอบ montita
SELECT 
  'montita (employee)' as user_type,
  l.user_id,
  l.username,
  l.role,
  e.employee_id,
  e.department,
  e.position,
  CONCAT(e.first_name, ' ', e.last_name) as name,
  CASE 
    WHEN e.department = 'Engineering' THEN '✅ อยู่ในแผนก Engineering'
    WHEN e.department IS NULL THEN '❌ ไม่มี department'
    ELSE CONCAT('⚠️ อยู่ในแผนก ', e.department)
  END as status
FROM login l
INNER JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'montita';

-- ============================================
-- ขั้นตอนที่ 4: ตรวจสอบว่าทั้งสองคนอยู่ในแผนกเดียวกัน
-- ============================================
SELECT '=== Department Matching Check ===' as '';

SELECT 
  CASE 
    WHEN 
      (SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira')) = 
      (SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'montita'))
      AND (SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira')) = 'Engineering'
    THEN '✅ ทั้งสองคนอยู่ในแผนก Engineering แล้ว - jira จะเห็นการลาของ montita'
    WHEN 
      (SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira')) IS NULL
      OR (SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'montita')) IS NULL
    THEN '❌ ยังมีคนที่ไม่มี department'
    ELSE '⚠️ ทั้งสองคนไม่ได้อยู่ในแผนกเดียวกัน'
  END as matching_status;

-- ============================================
-- ขั้นตอนที่ 5: ตรวจสอบการลาที่ pending (ถ้ามี)
-- ============================================
SELECT '=== Pending Leaves Check ===' as '';

SELECT 
  lv.id,
  lv.status,
  lv.leave_type,
  lv.start_date,
  lv.end_date,
  e.department,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  CASE 
    WHEN e.department = 'Engineering' THEN '✅ jira จะเห็นการลานี้'
    ELSE '❌ jira จะไม่เห็นการลานี้'
  END as visibility_for_jira
FROM leaves lv
INNER JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending'
ORDER BY lv.id;

