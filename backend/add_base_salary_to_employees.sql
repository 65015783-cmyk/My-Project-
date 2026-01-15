-- ===========================
-- เพิ่มฟิลด์ base_salary (เงินฐานเงินเดือน) ในตาราง employees
-- ===========================
USE humans;

-- เพิ่มคอลัมน์ base_salary ในตาราง employees
ALTER TABLE employees 
ADD COLUMN base_salary DECIMAL(10, 2) DEFAULT 0.00 AFTER department;

-- อัปเดต base_salary ให้พนักงานทุกคนโดยใช้เงินเดือนปัจจุบันจาก salary_history
-- ถ้ายังไม่มีข้อมูลใน salary_history จะใช้ค่า 0
UPDATE employees e
LEFT JOIN (
  SELECT sh.employee_id, sh.salary_amount
  FROM salary_history sh
  INNER JOIN (
    SELECT employee_id, MAX(effective_date) as max_date
    FROM salary_history
    GROUP BY employee_id
  ) latest ON sh.employee_id = latest.employee_id 
    AND sh.effective_date = latest.max_date
) current_sal ON e.employee_id = current_sal.employee_id
SET e.base_salary = COALESCE(current_sal.salary_amount, 0.00);

-- แสดงผลลัพธ์
SELECT 
  employee_id,
  first_name,
  last_name,
  position,
  department,
  base_salary
FROM employees
ORDER BY employee_id;

