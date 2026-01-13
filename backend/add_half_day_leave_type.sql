-- ===========================
-- เพิ่ม leave_type 'half_day' ในตาราง leaves
-- สำหรับฐานข้อมูลที่มีอยู่แล้ว
-- ===========================
USE humans;

-- ตรวจสอบค่า leave_type ปัจจุบัน
SELECT COLUMN_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'humans' 
  AND TABLE_NAME = 'leaves' 
  AND COLUMN_NAME = 'leave_type';

-- แก้ไข ENUM เพื่อเพิ่ม 'half_day' (ถ้ายังไม่มี)
-- หมายเหตุ: ถ้ามี 'early' อยู่แล้ว จะเพิ่ม 'half_day' เข้าไป
-- ถ้ายังไม่มีทั้ง 'early' และ 'half_day' จะเพิ่มทั้งสอง

ALTER TABLE leaves 
MODIFY COLUMN leave_type ENUM('sick', 'personal', 'vacation', 'other', 'early', 'half_day') NOT NULL;

-- ตรวจสอบผลลัพธ์
SELECT COLUMN_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'humans' 
  AND TABLE_NAME = 'leaves' 
  AND COLUMN_NAME = 'leave_type';

SELECT '✅ Migration สำเร็จ! ตอนนี้สามารถใช้ leave_type "half_day" ได้แล้ว' as message;

