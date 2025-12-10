-- ===========================
-- เพิ่ม field is_manager ใน employees table
-- ===========================
USE humans;

-- เพิ่ม column is_manager (TINYINT(1) = BOOLEAN)
ALTER TABLE employees 
ADD COLUMN is_manager TINYINT(1) DEFAULT 0 
AFTER department;

-- เพิ่ม index เพื่อเพิ่มประสิทธิภาพการค้นหา
CREATE INDEX idx_is_manager ON employees(is_manager);
CREATE INDEX idx_department_manager ON employees(department, is_manager);

-- อัพเดทข้อมูลตัวอย่าง: ตั้งให้ HR Manager เป็นหัวหน้าแผนก
UPDATE employees 
SET is_manager = 1 
WHERE position LIKE '%Manager%' OR position LIKE '%หัวหน้า%';

-- ตรวจสอบผลลัพธ์
SELECT 
  employee_id,
  first_name,
  last_name,
  position,
  department,
  is_manager
FROM employees
ORDER BY is_manager DESC, department;

