-- ===========================
-- ตั้งค่า amm (user_id = 8) เป็น Manager แผนก Accounting
-- เวอร์ชันง่าย (สำหรับกรณีที่คอลัมน์ is_manager มีอยู่แล้ว)
-- ===========================
USE humans;

-- ขั้นตอนที่ 1: ตั้ง role ใน login table
UPDATE login
SET role = 'manager'
WHERE user_id = 8;

-- ขั้นตอนที่ 2: ตั้ง is_manager และ department ใน employees table
UPDATE employees
SET 
  department = 'Accounting',
  is_manager = 1
WHERE user_id = 8;

-- ขั้นตอนที่ 3: ตรวจสอบผลลัพธ์
SELECT 
  '=== ผลลัพธ์การตั้งค่า amm (user_id = 8) ===' as '';
  
SELECT 
  l.user_id,
  l.username,
  l.role,
  e.employee_id,
  CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) as employee_name,
  e.position,
  e.department,
  e.is_manager,
  CASE 
    WHEN l.role = 'manager' AND e.is_manager = 1 AND e.department = 'Accounting' 
    THEN '✅ ตั้งค่าเรียบร้อยแล้ว'
    ELSE '❌ ยังไม่ครบถ้วน'
  END as status
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.user_id = 8;

