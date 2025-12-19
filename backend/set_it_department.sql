-- ===========================
-- ตั้งให้ 3 คนอยู่แผนก IT
-- manut, patcha, supada
-- ===========================
USE humans;

-- ขั้นตอนที่ 1: ตรวจสอบข้อมูลปัจจุบัน
SELECT '=== ข้อมูลปัจจุบัน ===' as '';
SELECT 
  l.user_id,
  l.username,
  l.email,
  e.employee_id,
  CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) as employee_name,
  e.position,
  e.department as current_department
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username IN ('manut', 'patcha', 'supada')
ORDER BY l.username;

-- ขั้นตอนที่ 2: ตั้ง department = 'IT' สำหรับ 3 คนนี้
UPDATE employees e
INNER JOIN login l ON e.user_id = l.user_id
SET e.department = 'IT'
WHERE l.username IN ('manut', 'patcha', 'supada');

-- ขั้นตอนที่ 3: ตรวจสอบผลลัพธ์
SELECT '=== ผลลัพธ์หลังอัพเดท ===' as '';
SELECT 
  l.user_id,
  l.username,
  l.email,
  e.employee_id,
  CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) as employee_name,
  e.position,
  e.department,
  COALESCE(e.is_manager, 0) as is_manager
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username IN ('manut', 'patcha', 'supada')
ORDER BY l.username;


