-- ===========================
-- ตั้งค่า jira (manager) และ montita (employee) ให้อยู่ในแผนก Engineering
-- ===========================
USE humans;

-- ============================================
-- ขั้นตอนที่ 1: ตรวจสอบข้อมูลปัจจุบัน
-- ============================================
SELECT '=== Current Data ===' as '';

-- ตรวจสอบ jira (manager)
SELECT 
  'jira (manager)' as user_type,
  l.user_id,
  l.username,
  l.role,
  e.employee_id,
  e.department,
  CONCAT(e.first_name, ' ', e.last_name) as name,
  e.position
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'jira';

-- ตรวจสอบ montita (employee)
SELECT 
  'montita (employee)' as user_type,
  l.user_id,
  l.username,
  l.role,
  e.employee_id,
  e.department,
  CONCAT(e.first_name, ' ', e.last_name) as name,
  e.position
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'montita';

-- ============================================
-- ขั้นตอนที่ 2: สร้าง/อัปเดต employee record สำหรับ jira (manager)
-- ============================================
SELECT '=== Step 2: Setup jira (manager) ===' as '';

-- ตรวจสอบว่ามี employee record หรือไม่
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira'))
    THEN 'มี employee record แล้ว'
    ELSE 'ไม่มี employee record - ต้องสร้างใหม่'
  END as jira_status;

-- ถ้ามี employee record แล้ว ให้อัปเดต
UPDATE employees
SET 
  department = 'Engineering',
  position = COALESCE(position, 'Manager'),
  first_name = COALESCE(first_name, 'jira'),
  last_name = COALESCE(last_name, '')
WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira')
  AND EXISTS (SELECT 1 FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira'));

-- ถ้าไม่มี employee record ให้สร้างใหม่
INSERT INTO employees (user_id, first_name, last_name, position, department)
SELECT 
  l.user_id,
  l.username as first_name,
  '' as last_name,
  'Manager' as position,
  'Engineering' as department
FROM login l
WHERE l.username = 'jira'
  AND l.user_id NOT IN (SELECT user_id FROM employees WHERE user_id IS NOT NULL);

-- ตรวจสอบผลลัพธ์
SELECT 
  'AFTER UPDATE' as status,
  l.user_id,
  l.username,
  e.employee_id,
  e.department,
  e.position,
  CONCAT(e.first_name, ' ', e.last_name) as name
FROM login l
INNER JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'jira';

-- ============================================
-- ขั้นตอนที่ 3: อัปเดต montita (employee) ให้อยู่ในแผนก Engineering
-- ============================================
SELECT '=== Step 3: Setup montita (employee) ===' as '';

-- ตรวจสอบว่ามี employee record หรือไม่
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'montita'))
    THEN 'มี employee record แล้ว'
    ELSE 'ไม่มี employee record - ต้องสร้างใหม่'
  END as montita_status;

-- ถ้ามี employee record แล้ว ให้อัปเดต
UPDATE employees
SET 
  department = 'Engineering',
  position = COALESCE(position, 'Engineer'),
  first_name = COALESCE(first_name, 'Montita'),
  last_name = COALESCE(last_name, 'Hongloywong')
WHERE user_id = (SELECT user_id FROM login WHERE username = 'montita')
  AND EXISTS (SELECT 1 FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'montita'));

-- ถ้าไม่มี employee record ให้สร้างใหม่
INSERT INTO employees (user_id, first_name, last_name, position, department)
SELECT 
  l.user_id,
  'Montita' as first_name,
  'Hongloywong' as last_name,
  'Engineer' as position,
  'Engineering' as department
FROM login l
WHERE l.username = 'montita'
  AND l.user_id NOT IN (SELECT user_id FROM employees WHERE user_id IS NOT NULL);

-- ตรวจสอบผลลัพธ์
SELECT 
  'AFTER UPDATE' as status,
  l.user_id,
  l.username,
  e.employee_id,
  e.department,
  e.position,
  CONCAT(e.first_name, ' ', e.last_name) as name
FROM login l
INNER JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'montita';

-- ============================================
-- ขั้นตอนที่ 4: ตรวจสอบผลลัพธ์สุดท้าย
-- ============================================
SELECT '=== Final Result ===' as '';

-- ตรวจสอบทั้งสองคน
SELECT 
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
WHERE l.username IN ('jira', 'montita')
ORDER BY l.role DESC, l.username;

-- ตรวจสอบว่าทั้งสองคนอยู่ในแผนกเดียวกันหรือไม่
SELECT 
  CASE 
    WHEN 
      (SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira')) = 
      (SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'montita'))
      AND (SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira')) = 'Engineering'
    THEN '✅ ทั้งสองคนอยู่ในแผนก Engineering แล้ว'
    ELSE '❌ ยังไม่ได้อยู่ในแผนกเดียวกัน'
  END as matching_status;

-- ตรวจสอบการลาที่ pending ของ montita (ถ้ามี)
SELECT 
  'Pending leaves for montita' as info,
  lv.id,
  lv.status,
  lv.leave_type,
  lv.start_date,
  lv.end_date,
  e.department,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name
FROM leaves lv
INNER JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending'
  AND e.user_id = (SELECT user_id FROM login WHERE username = 'montita');

