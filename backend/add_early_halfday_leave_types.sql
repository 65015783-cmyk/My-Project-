-- ===========================
-- เพิ่ม leave_type 'early' และ 'half_day' ในตาราง leaves
-- ===========================
USE humans;

-- ตรวจสอบว่า leave_type มีค่าอะไรบ้าง
SELECT COLUMN_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'humans' 
  AND TABLE_NAME = 'leaves' 
  AND COLUMN_NAME = 'leave_type';

-- แก้ไข ENUM เพื่อเพิ่ม 'early' และ 'half_day'
-- หมายเหตุ: MySQL ไม่สามารถ ALTER ENUM โดยตรงได้ ต้องทำผ่านวิธีอื่น
-- วิธีที่ 1: ใช้ MODIFY COLUMN (ถ้าไม่มีข้อมูลที่ขัดแย้ง)

ALTER TABLE leaves 
MODIFY COLUMN leave_type ENUM('sick', 'personal', 'vacation', 'other', 'early', 'half_day') NOT NULL;

-- ตรวจสอบผลลัพธ์
SELECT COLUMN_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'humans' 
  AND TABLE_NAME = 'leaves' 
  AND COLUMN_NAME = 'leave_type';

SELECT 'Migration completed: Added early and half_day leave types' as message;

