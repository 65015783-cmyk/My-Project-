-- สร้างตารางสำหรับระบบ OT (Overtime)
-- รันไฟล์นี้ใน MySQL เพื่อสร้างตารางที่จำเป็น

-- ตาราง overtime_requests: เก็บคำขอ OT
CREATE TABLE IF NOT EXISTS overtime_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  total_hours DECIMAL(4,2) NOT NULL,
  reason TEXT,
  status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
  approved_by INT DEFAULT NULL,
  approved_at DATETIME DEFAULT NULL,
  rejection_reason TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES login(user_id) ON DELETE CASCADE,
  FOREIGN KEY (approved_by) REFERENCES login(user_id) ON DELETE SET NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_date (date),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ตาราง overtime_rates: ตั้งค่าอัตราค่าล่วงเวลา
CREATE TABLE IF NOT EXISTS overtime_rates (
  id INT AUTO_INCREMENT PRIMARY KEY,
  rate_type ENUM('weekday', 'weekend', 'holiday') NOT NULL,
  multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.5, -- 1.5x, 2x, 3x
  description VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_rate_type (rate_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ใส่ข้อมูลเริ่มต้นสำหรับอัตราค่าล่วงเวลา
INSERT INTO overtime_rates (rate_type, multiplier, description) VALUES
  ('weekday', 1.5, 'OT วันธรรมดา (1.5 เท่า)'),
  ('weekend', 2.0, 'OT วันหยุดสุดสัปดาห์ (2 เท่า)'),
  ('holiday', 3.0, 'OT วันหยุดนักขัตฤกษ์ (3 เท่า)')
ON DUPLICATE KEY UPDATE 
  multiplier = VALUES(multiplier),
  description = VALUES(description);

-- สร้าง View สำหรับสรุป OT รายเดือน
CREATE OR REPLACE VIEW overtime_monthly_summary AS
SELECT 
  user_id,
  YEAR(date) AS year,
  MONTH(date) AS month,
  COUNT(*) AS total_requests,
  SUM(CASE WHEN status = 'approved' THEN total_hours ELSE 0 END) AS approved_hours,
  SUM(CASE WHEN status = 'pending' THEN total_hours ELSE 0 END) AS pending_hours,
  SUM(CASE WHEN status = 'rejected' THEN total_hours ELSE 0 END) AS rejected_hours
FROM overtime_requests
GROUP BY user_id, YEAR(date), MONTH(date);
