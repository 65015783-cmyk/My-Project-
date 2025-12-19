-- ===========================
-- ตั้งค่า amm (user_id = 8) เป็น Manager แผนก Accounting
-- Script นี้จะสร้างคอลัมน์ is_manager และตั้งค่าทั้งหมด
-- ===========================
USE humans;

-- ขั้นตอนที่ 1: ตรวจสอบว่ามีคอลัมน์ is_manager หรือไม่
SELECT '=== ตรวจสอบคอลัมน์ is_manager ===' as '';
SHOW COLUMNS FROM employees LIKE 'is_manager';

-- ขั้นตอนที่ 2: เพิ่มคอลัมน์ is_manager (ถ้ายังไม่มี)
-- หมายเหตุ: ถ้ามีอยู่แล้วจะ error แต่ไม่เป็นไร
ALTER TABLE employees 
ADD COLUMN is_manager TINYINT(1) DEFAULT 0 
AFTER department;

-- ขั้นตอนที่ 3: เพิ่ม index (ถ้ายังไม่มี)
-- หมายเหตุ: ถ้ามีอยู่แล้วจะ error แต่ไม่เป็นไร
CREATE INDEX idx_is_manager ON employees(is_manager);
CREATE INDEX idx_department_manager ON employees(department, is_manager);

-- ขั้นตอนที่ 4: ตั้ง role ใน login table
UPDATE login
SET role = 'manager'
WHERE user_id = 8;

-- ขั้นตอนที่ 5: ตั้ง is_manager และ department ใน employees table
UPDATE employees
SET 
  department = 'Accounting',
  is_manager = 1,
  position = COALESCE(position, 'Manager')  -- ตั้ง position ถ้ายังเป็น NULL
WHERE user_id = 8;

-- ขั้นตอนที่ 6: ตรวจสอบผลลัพธ์
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

-- ขั้นตอนที่ 7: แสดงโครงสร้างตาราง employees (เพื่อยืนยันว่ามีคอลัมน์ is_manager)
SELECT '=== โครงสร้างตาราง employees ===' as '';
SHOW COLUMNS FROM employees;

