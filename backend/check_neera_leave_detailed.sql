-- ตรวจสอบข้อมูล neera และใบลาอย่างละเอียด
-- ============================

-- 1. ตรวจสอบข้อมูล neera ในตาราง employees (employee_id = 9)
SELECT 
  e.employee_id,
  e.user_id,
  e.first_name,
  e.last_name,
  e.position,
  e.department,
  l.username,
  l.email,
  l.role
FROM employees e
LEFT JOIN login l ON e.user_id = l.user_id
WHERE e.employee_id = 9;

-- 2. ตรวจสอบใบลาทั้งหมดของ neera (employee_id = 9)
SELECT 
  lv.id,
  lv.user_id as employee_id_in_leaves,
  lv.leave_type,
  lv.start_date,
  lv.end_date,
  lv.status,
  lv.reason,
  lv.created_at,
  lv.approved_by,
  lv.approved_at,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.department,
  CASE 
    WHEN lv.status IN ('approved', 'อนุมัติ') THEN 'อนุมัติแล้ว'
    WHEN lv.status IN ('pending', 'รออนุมัติ', 'pending_approval') THEN 'รออนุมัติ'
    WHEN lv.status IN ('rejected', 'ปฏิเสธ') THEN 'ปฏิเสธ'
    ELSE lv.status
  END as status_thai
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.user_id = 9
ORDER BY lv.created_at DESC;

-- 3. ตรวจสอบใบลาของ neera ที่อนุมัติแล้วหรือรออนุมัติ (สำหรับวันนี้)
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
    WHEN CURDATE() BETWEEN lv.start_date AND lv.end_date THEN 'YES - วันนี้อยู่ในช่วงลา'
    ELSE 'NO'
  END as is_today_in_range
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.user_id = 9
  AND lv.status IN ('approved', 'อนุมัติ', 'pending', 'รออนุมัติ', 'pending_approval')
  AND CURDATE() BETWEEN lv.start_date AND lv.end_date
ORDER BY lv.start_date DESC;

-- 4. ตรวจสอบใบลาทั้งหมดที่อนุมัติแล้วหรือรออนุมัติสำหรับวันนี้ (เพื่อเปรียบเทียบ)
SELECT 
  lv.id,
  lv.user_id as employee_id,
  lv.leave_type,
  lv.start_date,
  lv.end_date,
  lv.status,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.department
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status IN ('approved', 'อนุมัติ', 'pending', 'รออนุมัติ', 'pending_approval')
  AND CURDATE() BETWEEN lv.start_date AND lv.end_date
ORDER BY e.first_name, e.last_name, lv.start_date DESC;

-- 5. ตรวจสอบว่า neera มีใบลาที่ user_id ไม่ตรงกับ employee_id หรือไม่
SELECT 
  lv.id,
  lv.user_id as user_id_in_leaves,
  e.employee_id,
  e.user_id as user_id_in_employees,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  lv.status,
  lv.start_date,
  lv.end_date
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE (e.first_name LIKE '%neera%' OR e.last_name LIKE '%neera%')
   OR lv.user_id = 9
ORDER BY lv.created_at DESC;
