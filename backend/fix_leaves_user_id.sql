-- ===========================
-- แก้ไขข้อมูลการลาที่ใช้ login.user_id แทน employees.employee_id
-- ===========================
USE humans;

-- ตรวจสอบข้อมูลการลาที่มีปัญหา (user_id ใน leaves ไม่ตรงกับ employee_id)
SELECT 
  lv.id,
  lv.user_id as leave_user_id,
  lv.status,
  e.employee_id,
  e.user_id as employee_user_id,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.department
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.user_id NOT IN (SELECT employee_id FROM employees)
ORDER BY lv.id;

-- แก้ไขข้อมูลการลาที่ใช้ login.user_id แทน employees.employee_id
-- อัปเดต leaves.user_id จาก login.user_id เป็น employees.employee_id
UPDATE leaves lv
INNER JOIN login l ON lv.user_id = l.user_id
INNER JOIN employees e ON l.user_id = e.user_id
SET lv.user_id = e.employee_id
WHERE lv.user_id = l.user_id 
  AND lv.user_id != e.employee_id
  AND EXISTS (
    SELECT 1 FROM employees e2 
    WHERE e2.user_id = l.user_id
  );

-- ตรวจสอบผลลัพธ์
SELECT 
  'หลังแก้ไข - ข้อมูลการลาที่ pending:' as info;
  
SELECT 
  lv.id,
  lv.user_id as leave_user_id,
  lv.status,
  e.employee_id,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.department
FROM leaves lv
INNER JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending'
ORDER BY lv.id;

-- ตรวจสอบว่ามีการลาที่ยังไม่สามารถ join กับ employees ได้หรือไม่
SELECT 
  'การลาที่ยังมีปัญหา (ไม่สามารถ join กับ employees):' as info;
  
SELECT 
  lv.id,
  lv.user_id,
  lv.status,
  lv.created_at
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE e.employee_id IS NULL
ORDER BY lv.id;

