-- ===========================
-- แก้ไข Manager ที่ไม่มี Department
-- ===========================
USE humans;

-- ขั้นตอนที่ 1: ตรวจสอบก่อนแก้ไข
SELECT '=== BEFORE FIX: Managers without department ===' as '';
SELECT 
  l.user_id,
  l.username,
  e.employee_id,
  CONCAT(e.first_name, ' ', e.last_name) as manager_name,
  e.department
FROM login l
INNER JOIN employees e ON l.user_id = e.user_id
WHERE l.role = 'manager'
  AND (e.department IS NULL OR e.department = '');

-- ขั้นตอนที่ 2: แก้ไข Manager ที่ไม่มี department
-- ตัวอย่าง: ตั้งค่า department ตามแผนกที่มีพนักงานอยู่
-- หรือตั้งค่าเป็นแผนกที่ต้องการ

-- วิธีที่ 1: ตั้งค่า department ให้ Manager ตามแผนกที่มีพนักงานมากที่สุดในแผนกนั้น
-- (ถ้า Manager มีพนักงานในแผนกเดียวกัน ให้ใช้แผนกนั้น)

-- วิธีที่ 2: ตั้งค่า department ให้ Manager ตามที่ต้องการ
-- แก้ไข user_id และ department ตามต้องการ
-- ตัวอย่าง:
-- UPDATE employees 
-- SET department = 'Engineering' 
-- WHERE employee_id = (SELECT employee_id FROM employees WHERE user_id = ?);

-- ขั้นตอนที่ 3: ตรวจสอบ Manager ที่ไม่มีข้อมูลใน employees table
SELECT '=== Managers without employee record ===' as '';
SELECT 
  l.user_id,
  l.username
FROM login l
WHERE l.role = 'manager'
  AND l.user_id NOT IN (SELECT user_id FROM employees WHERE user_id IS NOT NULL);

-- ถ้ามี Manager ที่ไม่มีข้อมูลใน employees table ต้องสร้าง record
-- ตัวอย่าง:
-- INSERT INTO employees (user_id, first_name, last_name, position, department)
-- SELECT 
--   l.user_id,
--   l.username as first_name,
--   '' as last_name,
--   'Manager' as position,
--   'Engineering' as department  -- เปลี่ยนเป็นแผนกที่ต้องการ
-- FROM login l
-- WHERE l.role = 'manager'
--   AND l.user_id NOT IN (SELECT user_id FROM employees WHERE user_id IS NOT NULL);

-- ขั้นตอนที่ 4: ตรวจสอบผลลัพธ์หลังแก้ไข
SELECT '=== AFTER FIX: All Managers with Department ===' as '';
SELECT 
  l.user_id,
  l.username,
  e.employee_id,
  CONCAT(e.first_name, ' ', e.last_name) as manager_name,
  e.department,
  CASE 
    WHEN e.department IS NULL OR e.department = '' THEN '❌ ยังไม่มี department'
    ELSE '✅ มี department'
  END as status
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.role = 'manager'
ORDER BY l.user_id;

