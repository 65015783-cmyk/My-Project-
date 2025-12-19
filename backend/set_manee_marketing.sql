-- ===========================
-- ตั้งให้ manee อยู่แผนก Marketing
-- ===========================
USE humans;

-- ขั้นตอนที่ 1: ตรวจสอบข้อมูลปัจจุบัน
SELECT '=== ข้อมูล manee ก่อนอัพเดท ===' as '';
SELECT 
  l.user_id,
  l.username,
  l.email,
  l.role,
  e.employee_id,
  CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) as employee_name,
  e.position,
  e.department as current_department,
  COALESCE(e.is_manager, 0) as is_manager
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'manee';

-- ขั้นตอนที่ 2: ตั้ง department = 'Marketing' สำหรับ manee
UPDATE employees e
INNER JOIN login l ON e.user_id = l.user_id
SET e.department = 'Marketing'
WHERE l.username = 'manee';

-- ขั้นตอนที่ 3: ตรวจสอบผลลัพธ์
SELECT '=== ผลลัพธ์หลังอัพเดท ===' as '';
SELECT 
  l.user_id,
  l.username,
  l.email,
  l.role,
  e.employee_id,
  CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) as employee_name,
  e.position,
  e.department,
  COALESCE(e.is_manager, 0) as is_manager
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'manee';


