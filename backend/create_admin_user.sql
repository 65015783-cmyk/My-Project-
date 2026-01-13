-- ===========================
-- สร้าง Admin User ใหม่ (ไม่ต้องแก้โค้ด)
-- ===========================
USE humans;

-- วิธีที่ 1: Reset password ของ admin เดิมเป็น '1234'
UPDATE login 
SET password_hash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
WHERE username = 'admin';

-- วิธีที่ 2: สร้าง admin user ใหม่ (ถ้าต้องการ)
-- Username: admin_new
-- Password: 1234
-- Email: admin_new@humans.com
INSERT INTO login (username, email, password_hash, role) VALUES
('admin_new', 'admin_new@humans.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'admin')
ON DUPLICATE KEY UPDATE username=username;

-- ตรวจสอบ admin users
SELECT user_id, username, email, role, created_at 
FROM login 
WHERE role = 'admin'
ORDER BY created_at DESC;









