-- ตรวจสอบข้อมูล neera ในระบบ
-- ============================

-- 1. ตรวจสอบข้อมูล neera ในตาราง login
SELECT 
  user_id,
  username,
  email,
  role
FROM login
WHERE LOWER(username) LIKE '%neera%' 
   OR LOWER(email) LIKE '%neera%';

-- 2. ตรวจสอบข้อมูล neera ในตาราง employees
SELECT 
  e.employee_id,
  e.user_id,
  e.first_name,
  e.last_name,
  e.position,
  e.department,
  l.username,
  l.email
FROM employees e
LEFT JOIN login l ON e.user_id = l.user_id
WHERE LOWER(e.first_name) LIKE '%neera%' 
   OR LOWER(e.last_name) LIKE '%neera%'
   OR LOWER(l.username) LIKE '%neera%'
   OR LOWER(l.email) LIKE '%neera%';

-- 3. ตรวจสอบใบลาของ neera (ใช้ employee_id)
SELECT 
  lv.id,
  lv.user_id as employee_id,
  lv.leave_type,
  lv.start_date,
  lv.end_date,
  lv.status,
  lv.reason,
  lv.created_at,
  lv.approved_by,
  lv.approved_at,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.department
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE LOWER(e.first_name) LIKE '%neera%' 
   OR LOWER(e.last_name) LIKE '%neera%'
   OR lv.user_id IN (
     SELECT employee_id 
     FROM employees e2
     LEFT JOIN login l2 ON e2.user_id = l2.user_id
     WHERE LOWER(l2.username) LIKE '%neera%'
        OR LOWER(l2.email) LIKE '%neera%'
   )
ORDER BY lv.created_at DESC;

-- 4. ตรวจสอบใบลาทั้งหมดที่อนุมัติแล้วหรือรออนุมัติ (สำหรับวันนี้)
SELECT 
  lv.id,
  lv.user_id as employee_id,
  lv.leave_type,
  lv.start_date,
  lv.end_date,
  lv.status,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.department,
  CASE 
    WHEN CURDATE() BETWEEN lv.start_date AND lv.end_date THEN 'YES'
    ELSE 'NO'
  END as is_today
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status IN ('approved', 'อนุมัติ', 'pending', 'รออนุมัติ', 'pending_approval')
  AND CURDATE() BETWEEN lv.start_date AND lv.end_date
ORDER BY lv.start_date DESC;
