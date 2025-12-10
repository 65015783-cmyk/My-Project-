-- ===========================
-- ตรวจสอบและแก้ไขปัญหาแจ้งเตือน
-- ===========================
USE humans;

-- 1. ตรวจสอบ user_id ของ montita
SELECT '=== Montita User Info ===' as '';
SELECT 
  l.user_id as login_user_id,
  l.username,
  e.employee_id,
  e.user_id as employee_user_id
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'montita';

-- 2. ตรวจสอบแจ้งเตือนทั้งหมด
SELECT '=== All Notifications ===' as '';
SELECT 
  n.id,
  n.user_id,
  l.username,
  n.title,
  n.message,
  n.type,
  n.is_read,
  n.created_at
FROM notifications n
LEFT JOIN login l ON n.user_id = l.user_id
ORDER BY n.created_at DESC;

-- 3. ตรวจสอบแจ้งเตือนของ montita (ใช้ user_id จาก login)
SELECT '=== Montita Notifications (by login.user_id) ===' as '';
SELECT 
  n.id,
  n.user_id,
  n.title,
  n.message,
  n.type,
  n.is_read,
  n.created_at
FROM notifications n
WHERE n.user_id = (SELECT user_id FROM login WHERE username = 'montita')
ORDER BY n.created_at DESC;

-- 4. ตรวจสอบการลาล่าสุดที่ถูกอนุมัติ
SELECT '=== Recent Approved Leaves ===' as '';
SELECT 
  lv.id,
  lv.user_id as leave_user_id,
  lv.status,
  lv.approved_by,
  lv.approved_at,
  -- หา user_id ของพนักงานที่ขอลา
  COALESCE(e1.user_id, e2.user_id) as employee_user_id,
  COALESCE(e1.employee_id, e2.employee_id) as employee_id
FROM leaves lv
LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
LEFT JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
WHERE lv.status IN ('approved', 'rejected')
ORDER BY lv.approved_at DESC
LIMIT 10;

-- 5. ตรวจสอบว่าแจ้งเตือนถูกสร้างสำหรับการลาที่อนุมัติแล้วหรือไม่
SELECT '=== Check if notifications exist for approved leaves ===' as '';
SELECT 
  lv.id as leave_id,
  lv.status,
  lv.approved_at,
  COALESCE(e1.user_id, e2.user_id) as employee_user_id,
  n.id as notification_id,
  n.title,
  n.created_at as notification_created_at
FROM leaves lv
LEFT JOIN employees e1 ON lv.user_id = e1.employee_id
LEFT JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
LEFT JOIN notifications n ON n.user_id = COALESCE(e1.user_id, e2.user_id) 
  AND n.title LIKE '%อนุมัติ%' 
  AND DATE(n.created_at) = DATE(lv.approved_at)
WHERE lv.status IN ('approved', 'rejected')
  AND lv.approved_at IS NOT NULL
ORDER BY lv.approved_at DESC
LIMIT 10;

