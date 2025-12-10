-- ===========================
-- เพิ่ม role 'manager' ใน login table
-- ===========================
USE humans;

-- ตรวจสอบโครงสร้างตาราง login ปัจจุบัน
SELECT 'Current login table structure:' as '';
SHOW COLUMNS FROM login;

-- แก้ไข ENUM ของ role ให้รองรับ 'manager'
ALTER TABLE login 
MODIFY COLUMN role ENUM('admin', 'employee', 'manager') DEFAULT 'employee';

-- ตรวจสอบผลลัพธ์
SELECT 'Updated login table structure:' as '';
SHOW COLUMNS FROM login;

-- ตรวจสอบข้อมูล user ทั้งหมด
SELECT 'All users:' as '';
SELECT 
  user_id,
  username,
  email,
  role,
  created_at
FROM login
ORDER BY user_id;

-- ตัวอย่าง: ตั้งค่าให้ user เป็น manager
-- UPDATE login 
-- SET role = 'manager' 
-- WHERE user_id = 5;  -- เปลี่ยน user_id ตามต้องการ

