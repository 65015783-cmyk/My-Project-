-- ===========================
-- ตรวจสอบและแก้ไข role column ให้รองรับ manager
-- ===========================
USE humans;

-- 1. ตรวจสอบโครงสร้างปัจจุบัน
SELECT '=== ตรวจสอบโครงสร้าง role column ===' as '';
SHOW COLUMNS FROM login WHERE Field = 'role';

-- 2. ตรวจสอบข้อมูลปัจจุบัน
SELECT '=== ข้อมูล role ปัจจุบัน ===' as '';
SELECT DISTINCT role FROM login;

-- 3. แก้ไข ENUM ให้รองรับ 'manager'
-- ถ้ายังไม่มี 'manager' ใน ENUM
ALTER TABLE login 
MODIFY COLUMN role ENUM('admin', 'employee', 'manager') DEFAULT 'employee';

-- 4. ตรวจสอบผลลัพธ์
SELECT '=== โครงสร้าง role column หลังแก้ไข ===' as '';
SHOW COLUMNS FROM login WHERE Field = 'role';

-- 5. ทดสอบ insert role = 'manager'
-- SELECT '=== ทดสอบ insert manager role ===' as '';
-- INSERT INTO login (username, email, password_hash, role) 
-- VALUES ('test_manager', 'test_manager@test.com', '$2a$10$test', 'manager')
-- ON DUPLICATE KEY UPDATE role = 'manager';

-- 6. ตรวจสอบข้อมูลทั้งหมด
SELECT '=== ข้อมูล user ทั้งหมด ===' as '';
SELECT 
  user_id,
  username,
  email,
  role,
  created_at
FROM login
ORDER BY user_id;

