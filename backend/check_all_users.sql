-- ===========================
-- ตรวจสอบข้อมูล User ทั้งหมดในระบบ
-- เพื่อดูว่า user ไหนสามารถตั้งเป็น Manager ได้
-- ===========================
USE humans;

-- ตรวจสอบข้อมูล User ทั้งหมด (รวม login และ employees)
SELECT '=== ข้อมูล User ทั้งหมด ===' as '';

SELECT 
  l.user_id,
  l.username,
  l.email,
  l.role,
  e.employee_id,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.position,
  e.department,
  COALESCE(e.is_manager, 0) as is_manager,
  CASE 
    WHEN e.employee_id IS NULL THEN '❌ ไม่มีข้อมูลใน employees table'
    WHEN e.is_manager = 1 THEN '✅ เป็น Manager'
    WHEN l.role = 'admin' THEN '👑 เป็น Admin'
    ELSE '👤 Employee ปกติ'
  END as status
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
ORDER BY l.user_id;

-- ตรวจสอบเฉพาะ User ที่มีข้อมูลใน employees table
SELECT '' as '';
SELECT '=== User ที่มีข้อมูลใน employees table ===' as '';

SELECT 
  e.employee_id,
  e.user_id,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.position,
  e.department,
  COALESCE(e.is_manager, 0) as is_manager,
  l.username,
  l.email,
  l.role,
  CASE 
    WHEN e.is_manager = 1 THEN '✅ Manager'
    WHEN l.role = 'admin' THEN '👑 Admin'
    ELSE '👤 Employee'
  END as current_role
FROM employees e
INNER JOIN login l ON e.user_id = l.user_id
ORDER BY e.is_manager DESC, e.department, e.employee_id;

-- ตรวจสอบ User ที่ยังไม่เป็น Manager และไม่ใช่ Admin
SELECT '' as '';
SELECT '=== User ที่สามารถตั้งเป็น Manager ได้ ===' as '';

SELECT 
  e.employee_id,
  e.user_id,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.position,
  e.department,
  l.username,
  l.email,
  'สามารถตั้งเป็น Manager ได้' as note
FROM employees e
INNER JOIN login l ON e.user_id = l.user_id
WHERE (e.is_manager = 0 OR e.is_manager IS NULL)
  AND l.role != 'admin'
ORDER BY e.department, e.employee_id;

-- ตรวจสอบว่ามี field is_manager หรือไม่
SELECT '' as '';
SELECT '=== ตรวจสอบ field is_manager ===' as '';

SHOW COLUMNS FROM employees LIKE 'is_manager';

-- ตรวจสอบข้อมูลวันลาที่รออนุมัติ (ถ้ามี)
SELECT '' as '';
SELECT '=== ข้อมูลวันลาที่รออนุมัติ ===' as '';

SELECT 
  lv.id,
  lv.user_id as employee_id,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.department,
  lv.leave_type,
  lv.start_date,
  lv.end_date,
  lv.status,
  lv.created_at
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending'
ORDER BY lv.created_at DESC;

