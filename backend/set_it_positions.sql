-- ===========================
-- ตั้งตำแหน่งให้ 3 คนในแผนก IT
-- supada → IT Officer
-- patcha → Network Administrator
-- manut → Software Developer
-- ===========================
USE humans;

-- ขั้นตอนที่ 1: ตรวจสอบข้อมูลปัจจุบัน
SELECT '=== ข้อมูลปัจจุบัน ===' as '';
SELECT 
  l.user_id,
  l.username,
  e.employee_id,
  CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) as employee_name,
  e.position as current_position,
  e.department
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username IN ('manut', 'patcha', 'supada')
ORDER BY l.username;

-- ขั้นตอนที่ 2: ตั้งตำแหน่งให้ทั้ง 3 คน
UPDATE employees e
INNER JOIN login l ON e.user_id = l.user_id
SET e.position = CASE 
  WHEN l.username = 'supada' THEN 'IT Officer'
  WHEN l.username = 'patcha' THEN 'Network Administrator'
  WHEN l.username = 'manut' THEN 'Software Developer'
  ELSE e.position
END
WHERE l.username IN ('manut', 'patcha', 'supada');

-- ขั้นตอนที่ 3: ตรวจสอบผลลัพธ์
SELECT '=== ผลลัพธ์หลังอัพเดท ===' as '';
SELECT 
  l.user_id,
  l.username,
  e.employee_id,
  CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) as employee_name,
  e.position,
  e.department
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username IN ('manut', 'patcha', 'supada')
ORDER BY l.username;


