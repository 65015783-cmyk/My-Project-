-- ===========================
-- แก้ไข Admin User ให้ Login ได้
-- ===========================
USE humans;

-- ตรวจสอบ admin users ที่มีอยู่
SELECT '=== Admin Users Before Fix ===' as '';
SELECT user_id, username, email, role, 
       LEFT(password_hash, 30) as hash_preview,
       created_at 
FROM login 
WHERE role = 'admin';

-- ===========================
-- Reset Password ของ admin เป็น '1234'
-- Hash: $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
-- ===========================

-- วิธีที่ 1: Update admin เดิม
UPDATE login 
SET password_hash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
WHERE username = 'admin';

-- วิธีที่ 2: ถ้า admin ไม่มี ให้สร้างใหม่
INSERT INTO login (username, email, password_hash, role) 
SELECT 'admin', 'admin@humans.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'admin'
WHERE NOT EXISTS (SELECT 1 FROM login WHERE username = 'admin');

-- ===========================
-- ตรวจสอบผลลัพธ์
-- ===========================
SELECT '=== Admin Users After Fix ===' as '';
SELECT user_id, username, email, role, created_at 
FROM login 
WHERE role = 'admin';

-- ===========================
-- ข้อมูลสำหรับ Login:
-- Username: admin
-- Password: 1234
-- ===========================














