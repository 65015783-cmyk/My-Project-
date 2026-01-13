-- ===========================
-- สร้างตาราง salary_history
-- สำหรับเก็บประวัติเงินเดือนของพนักงาน
-- ===========================
USE humans;

-- ===========================
-- ตาราง salary_history (ประวัติเงินเดือน)
-- ===========================
CREATE TABLE IF NOT EXISTS salary_history (
  salary_id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  salary_amount DECIMAL(10, 2) NOT NULL,
  effective_date DATE NOT NULL,
  salary_type ENUM('START', 'ADJUST') NOT NULL,
  reason TEXT NULL COMMENT 'เหตุผลการปรับเงินเดือน (สำหรับ ADJUST)',
  created_by INT NULL COMMENT 'ผู้สร้าง record (employee_id)',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES employees(employee_id) ON DELETE SET NULL,
  INDEX idx_employee_id (employee_id),
  INDEX idx_effective_date (effective_date),
  INDEX idx_employee_effective_date (employee_id, effective_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===========================
-- คำอธิบายตาราง
-- ===========================
-- 📌 เงินเดือนแรก = record แรกในตารางนี้ (เรียงตาม effective_date)
-- 📌 เงินเดือนปัจจุบัน = record ที่ effective_date ล่าสุด

-- ===========================
-- ตัวอย่างการใช้งาน
-- ===========================
-- 1. เงินเดือนแรก (START)
-- INSERT INTO salary_history (employee_id, salary_amount, effective_date, salary_type, created_by)
-- VALUES (2, 30000.00, '2024-01-01', 'START', 1);

-- 2. ปรับเงินเดือน (ADJUST)
-- INSERT INTO salary_history (employee_id, salary_amount, effective_date, salary_type, reason, created_by)
-- VALUES (2, 35000.00, '2024-06-01', 'ADJUST', 'ปรับเงินเดือนประจำปี', 1);

-- 3. Query เงินเดือนปัจจุบัน (ล่าสุด)
-- SELECT * FROM salary_history 
-- WHERE employee_id = 2 
-- ORDER BY effective_date DESC 
-- LIMIT 1;

-- 4. Query เงินเดือนแรก
-- SELECT * FROM salary_history 
-- WHERE employee_id = 2 
-- ORDER BY effective_date ASC 
-- LIMIT 1;

-- ===========================
-- ตรวจสอบว่าสร้างสำเร็จ
-- ===========================
SELECT 'Salary History Table Created:' as message;
SHOW CREATE TABLE salary_history;

