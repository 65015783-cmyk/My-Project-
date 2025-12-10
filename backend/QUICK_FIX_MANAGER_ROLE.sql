-- ===========================
-- แก้ไขปัญหา role manager อย่างรวดเร็ว
-- ===========================
USE humans;

-- 1. ตรวจสอบโครงสร้างปัจจุบัน
SELECT '=== ตรวจสอบโครงสร้าง role column ===' as '';
SHOW COLUMNS FROM login WHERE Field = 'role';

-- 2. แก้ไข ENUM ให้รองรับ 'manager'
-- ถ้ายังไม่มี 'manager' ใน ENUM ให้รันคำสั่งนี้
ALTER TABLE login 
MODIFY COLUMN role ENUM('admin', 'employee', 'manager') DEFAULT 'employee';

-- 3. ตรวจสอบผลลัพธ์
SELECT '=== โครงสร้าง role column หลังแก้ไข ===' as '';
SHOW COLUMNS FROM login WHERE Field = 'role';

-- 4. ทดสอบว่า insert manager ได้หรือไม่
-- (ไม่ต้องรันจริง แค่ตรวจสอบ syntax)
-- INSERT INTO login (username, email, password_hash, role) 
-- VALUES ('test', 'test@test.com', '$2a$10$test', 'manager');

-- 5. ตรวจสอบข้อมูลปัจจุบัน
SELECT '=== ข้อมูล user ทั้งหมด ===' as '';
SELECT 
  user_id,
  username,
  email,
  role,
  created_at
FROM login
ORDER BY user_id;

