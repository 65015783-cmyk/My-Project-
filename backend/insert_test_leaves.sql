-- ===========================
-- ใส่ข้อมูลทดสอบวันลา
-- ===========================
-- หมายเหตุ: user_id ใน leaves table อ้างอิงไปที่ employee_id
-- employee_id 2 = Montita, employee_id 3 = สมศักดิ์

USE humans;

-- ใส่ข้อมูลทดสอบวันลา
INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES
(2, 'sick', DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_SUB(CURDATE(), INTERVAL 8 DAY), 'ไม่สบาย มีไข้', 'approved'),
(2, 'personal', DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_SUB(CURDATE(), INTERVAL 3 DAY), 'ธุระส่วนตัว', 'approved'),
(3, 'sick', DATE_SUB(CURDATE(), INTERVAL 7 DAY), DATE_SUB(CURDATE(), INTERVAL 6 DAY), 'ป่วย', 'approved'),
(2, 'personal', DATE_ADD(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'ลาพักผ่อน', 'pending'),
(3, 'personal', DATE_ADD(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 12 DAY), 'ลากิจ', 'pending');

-- ตรวจสอบข้อมูล
SELECT 'Leaves Data:' as '';
SELECT id, user_id, leave_type, start_date, end_date, reason, status FROM leaves;

