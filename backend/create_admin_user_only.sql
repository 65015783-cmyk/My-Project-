-- ===========================
-- สร้าง Admin User ใหม่ในตาราง login
-- ===========================
USE humans;

-- สร้าง admin user ใหม่
-- Username: admin_new
-- Password: 1234
-- Email: admin_new@humans.com
-- Role: admin

INSERT INTO login (username, email, password_hash, role) VALUES
('admin_new', 'admin_new@humans.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'admin')
ON DUPLICATE KEY UPDATE 
  password_hash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  role = 'admin';

-- หรือ Reset admin เดิม (ถ้ามีอยู่แล้ว)
UPDATE login 
SET password_hash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
    role = 'admin'
WHERE username = 'admin';

-- ตรวจสอบ admin users
SELECT user_id, username, email, role, created_at 
FROM login 
WHERE role = 'admin'
ORDER BY created_at DESC;

-- ===========================
-- ข้อมูลสำหรับ Login:
-- Username: admin_new (หรือ admin ถ้า reset)
-- Password: 1234
-- ===========================







