-- 🚀 Quick Fix สำหรับปัญหา MySQL Connection
-- รันไฟล์นี้ใน MySQL Workbench

-- 1. สร้าง database (ถ้ายังไม่มี)
CREATE DATABASE IF NOT EXISTS humans;

-- 2. สร้าง user ใหม่สำหรับแอป
CREATE USER IF NOT EXISTS 'humans_app'@'localhost' IDENTIFIED BY '12345678';

-- 3. ให้สิทธิ์เต็มกับ database humans
GRANT ALL PRIVILEGES ON humans.* TO 'humans_app'@'localhost';

-- 4. รีเฟรชสิทธิ์
FLUSH PRIVILEGES;

-- 5. ตรวจสอบว่าสร้าง user สำเร็จ
SELECT user, host FROM mysql.user WHERE user = 'humans_app';

-- 6. ตรวจสอบสิทธิ์
SHOW GRANTS FOR 'humans_app'@'localhost';

-- ✅ เสร็จแล้ว! ตอนนี้แก้ไขใน backend/config.js:
-- 
-- db: {
--   host: 'localhost',
--   user: 'humans_app',      // เปลี่ยนเป็น user ใหม่
--   password: '12345678',
--   database: 'humans',
--   port: 3306,
-- }
--
-- แล้ว restart backend ด้วย: npm start

