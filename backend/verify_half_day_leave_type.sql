-- ===========================
-- ตรวจสอบว่า leave_type มี 'half_day' แล้วหรือยัง
-- ===========================
USE humans;

-- ตรวจสอบค่า leave_type ปัจจุบัน
SELECT COLUMN_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'humans' 
  AND TABLE_NAME = 'leaves' 
  AND COLUMN_NAME = 'leave_type';

-- ตรวจสอบข้อมูล leaves ที่มีอยู่
SELECT id, user_id, leave_type, start_date, end_date, reason, status 
FROM leaves 
ORDER BY created_at DESC 
LIMIT 10;

-- ทดสอบสร้างข้อมูล leaves ใหม่ด้วย half_day (ถ้าต้องการ)
-- INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) 
-- VALUES (2, 'half_day', CURDATE(), CURDATE(), 'ทดสอบลาครึ่งวัน', 'pending');

SELECT '✅ ตรวจสอบเสร็จสิ้น' as message;

