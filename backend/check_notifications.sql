-- ===========================
-- ตรวจสอบแจ้งเตือน
-- ===========================
USE humans;

-- 1. ตรวจสอบว่ามีตาราง notifications หรือไม่
SELECT '=== Check notifications table ===' as '';
SHOW TABLES LIKE 'notifications';

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

-- 3. ตรวจสอบแจ้งเตือนของ montita
SELECT '=== Montita Notifications ===' as '';
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

-- 4. ตรวจสอบ user_id ของ montita
SELECT '=== Montita User Info ===' as '';
SELECT 
  l.user_id,
  l.username,
  e.employee_id,
  e.user_id as employee_user_id
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.username = 'montita';

