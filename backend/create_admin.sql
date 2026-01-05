-- ===========================
-- สร้าง Admin User ใหม่
-- ===========================
USE humans;

-- สร้าง admin user ใหม่
-- Username: admin_new
-- Password: admin1234
-- Email: admin_new@humans.com

-- Hash password 'admin1234' ด้วย bcrypt
-- $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy = '1234'
-- ต้อง hash 'admin1234' ใหม่

-- วิธีที่ 1: ใช้ bcrypt hash ที่มีอยู่ (ถ้า backend รันอยู่)
-- หรือใช้วิธีที่ 2: สร้างผ่าน Register API

-- วิธีที่ 2: Insert โดยตรง (ใช้ hash ของ 'admin1234')
-- สำหรับทดสอบ: ใช้ hash ของ '1234' ก่อน แล้วเปลี่ยนรหัสผ่านทีหลัง

INSERT INTO login (username, email, password_hash, role) VALUES
('admin_new', 'admin_new@humans.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'admin')
ON DUPLICATE KEY UPDATE username=username;

-- หรือ Reset admin เดิม
UPDATE login 
SET password_hash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
WHERE username = 'admin';

-- ตรวจสอบ
SELECT user_id, username, email, role, created_at 
FROM login 
WHERE role = 'admin';








