-- ===========================
-- สร้างฐานข้อมูล humans
-- ===========================
CREATE DATABASE IF NOT EXISTS humans CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE humans;

-- ===========================
-- ตารางที่ 1: login (สำหรับ Authentication)
-- ===========================
CREATE TABLE IF NOT EXISTS login (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin', 'employee') DEFAULT 'employee',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_username (username),
  INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===========================
-- ตารางที่ 2: Applicant (ผู้สมัครงาน)
-- ===========================
CREATE TABLE IF NOT EXISTS applicant (
  applicant_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  surname VARCHAR(100) NOT NULL,
  dob DATE,
  email VARCHAR(150) UNIQUE NOT NULL,
  phone VARCHAR(20),
  address TEXT,
  resume_file VARCHAR(255),
  application_date DATE DEFAULT (CURRENT_DATE),
  status ENUM('pending', 'interviewed', 'accepted', 'rejected') DEFAULT 'pending',
  INDEX idx_email (email),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===========================
-- ตารางที่ 3: Employees (พนักงาน) - ตามภาพ phpMyAdmin
-- ===========================
CREATE TABLE IF NOT EXISTS employees (
  employee_id INT(11) AUTO_INCREMENT PRIMARY KEY,
  user_id INT(11) NULL,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  phone_number VARCHAR(15) NULL,
  date_of_birth DATE NULL,
  position VARCHAR(50) NULL,
  department VARCHAR(50) NULL,
  INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ===========================
-- ตารางที่ 4: Human_Resources (ข้อมูล HR)
-- ===========================
CREATE TABLE IF NOT EXISTS human_resources (
  hr_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  recruitment_detail TEXT,
  promotion_history TEXT,
  leave_record TEXT,
  training_record TEXT,
  evaluation_record TEXT,
  resignation_detail TEXT,
  FOREIGN KEY (user_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===========================
-- ตารางที่ 5: Executive (ผู้บริหาร)
-- ===========================
CREATE TABLE IF NOT EXISTS executive (
  executive_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  approval_email TEXT,
  decision_record TEXT,
  salary_adjustment TEXT,
  policy_memo TEXT,
  FOREIGN KEY (user_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===========================
-- ตารางที่ 6: Finance_Department (แผนกการเงิน)
-- ===========================
CREATE TABLE IF NOT EXISTS finance_department (
  finance_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  salary_record DECIMAL(10, 2),
  allowance_record DECIMAL(10, 2),
  deduction_record DECIMAL(10, 2),
  payroll_slip_file VARCHAR(255),
  payment_date DATE,
  report_to_executive TEXT,
  FOREIGN KEY (user_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_payment_date (payment_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===========================
-- ตารางที่ 7: Attendance (การเข้า-ออกงาน)
-- ===========================
CREATE TABLE IF NOT EXISTS attendance (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  date DATE NOT NULL,
  check_in_time DATETIME DEFAULT NULL,
  check_out_time DATETIME DEFAULT NULL,
  check_in_image_path VARCHAR(255) DEFAULT '',
  morning_start TIME DEFAULT '08:30:00',
  morning_end TIME DEFAULT '12:30:00',
  afternoon_start TIME DEFAULT '13:30:00',
  afternoon_end TIME DEFAULT '17:30:00',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
  UNIQUE KEY unique_user_date (user_id, date),
  INDEX idx_user_date (user_id, date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===========================
-- ตารางที่ 8: Leaves (การลางาน)
-- ===========================
CREATE TABLE IF NOT EXISTS leaves (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  leave_type ENUM('sick', 'personal', 'vacation', 'other', 'early', 'half_day') NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  reason TEXT NOT NULL,
  status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
  approved_by INT DEFAULT NULL,
  approved_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
  FOREIGN KEY (approved_by) REFERENCES employees(employee_id) ON DELETE SET NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_start_date (start_date),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===========================
-- Insert ข้อมูลทดสอบ
-- ===========================

-- รหัสผ่าน '1234' hash ด้วย bcrypt
-- $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy

-- ใส่ข้อมูลใน login table
INSERT INTO login (username, email, password_hash, role) VALUES
('admin', 'admin@humans.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'admin'),
('montita', 'montita@humans.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'employee'),
('somsak', 'somsak@humans.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'employee')
ON DUPLICATE KEY UPDATE username=username;

-- ใส่ข้อมูลใน employees table
INSERT INTO employees (employee_id, user_id, first_name, last_name, phone_number, date_of_birth, position, department) VALUES
(1, 1, 'Admin', 'User', '0801234567', '1990-01-01', 'System Administrator', 'IT'),
(2, 2, 'Montita', 'Hongloywong', '0812345678', '1995-05-15', 'Senior Product Engineering', 'Engineering'),
(3, 3, 'สมศักดิ์', 'ใจดี', '0823456789', '1992-08-20', 'HR Manager', 'Human Resources')
ON DUPLICATE KEY UPDATE employee_id=employee_id;

-- ใส่ข้อมูลทดสอบวันลา (user_id ใน leaves table อ้างอิงไปที่ employee_id)
-- employee_id 2 = Montita, employee_id 3 = สมศักดิ์
INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES
(2, 'sick', DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_SUB(CURDATE(), INTERVAL 8 DAY), 'ไม่สบาย มีไข้', 'approved'),
(2, 'personal', DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_SUB(CURDATE(), INTERVAL 3 DAY), 'ธุระส่วนตัว', 'approved'),
(3, 'sick', DATE_SUB(CURDATE(), INTERVAL 7 DAY), DATE_SUB(CURDATE(), INTERVAL 6 DAY), 'ป่วย', 'approved'),
(2, 'personal', DATE_ADD(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'ลาพักผ่อน', 'pending'),
(3, 'personal', DATE_ADD(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 12 DAY), 'ลากิจ', 'pending');

-- ใส่ข้อมูลทดสอบ applicant
INSERT INTO applicant (name, surname, dob, email, phone, address, status) VALUES
('สมชาย', 'รักงาน', '1998-03-10', 'somchai@example.com', '0891234567', '123 ถนนสุขุมวิท กรุงเทพฯ', 'pending'),
('สมหญิง', 'รักสงบ', '1997-07-22', 'somying@example.com', '0892345678', '456 ถนนพหลโยธิน กรุงเทพฯ', 'interviewed'),
('ประยุทธ์', 'ขยันเรียน', '1999-11-05', 'prayut@example.com', '0893456789', '789 ถนนรามอินทรา กรุงเทพฯ', 'accepted')
ON DUPLICATE KEY UPDATE applicant_id=applicant_id;

-- ===========================
-- ตรวจสอบว่าสร้างสำเร็จ
-- ===========================
SHOW TABLES;

SELECT 'Login Users:' as '';
SELECT user_id, username, email, role FROM login;

SELECT 'Employees:' as '';
SELECT employee_id, user_id, first_name, last_name, position, department FROM employees;

SELECT 'Applicants:' as '';
SELECT applicant_id, name, surname, email, status FROM applicant;
