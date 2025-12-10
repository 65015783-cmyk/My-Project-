# 📊 สรุปการสร้างตารางฐานข้อมูล Humans HR System

## 🎯 ภาพรวม Database

**Database Name:** `humans`  
**Character Set:** `utf8mb4`  
**Collation:** `utf8mb4_unicode_ci`  
**จำนวนตารางทั้งหมด:** 8 ตาราง

---

## 📋 รายการตารางทั้งหมด

### **1. ตาราง `login`** (Authentication)
**จุดประสงค์:** เก็บข้อมูลการเข้าสู่ระบบและ authentication

| Field | Type | Key | Extra | Description |
|-------|------|-----|-------|-------------|
| `user_id` | INT | PRIMARY | AUTO_INCREMENT | รหัสผู้ใช้ |
| `username` | VARCHAR(50) | UNIQUE | NOT NULL | ชื่อผู้ใช้ |
| `email` | VARCHAR(100) | UNIQUE | NOT NULL | อีเมล |
| `password_hash` | VARCHAR(255) | - | NOT NULL | รหัสผ่าน (hash) |
| `role` | ENUM('admin','employee') | - | DEFAULT 'employee' | บทบาท |
| `created_at` | TIMESTAMP | - | DEFAULT CURRENT_TIMESTAMP | วันที่สร้าง |

**Indexes:**
- PRIMARY KEY: `user_id`
- UNIQUE: `username`, `email`
- INDEX: `idx_username`, `idx_email`

---

### **2. ตาราง `applicant`** (ผู้สมัครงาน)
**จุดประสงค์:** เก็บข้อมูลผู้สมัครงาน

| Field | Type | Key | Extra | Description |
|-------|------|-----|-------|-------------|
| `applicant_id` | INT | PRIMARY | AUTO_INCREMENT | รหัสผู้สมัคร |
| `name` | VARCHAR(100) | - | NOT NULL | ชื่อ |
| `surname` | VARCHAR(100) | - | NOT NULL | นามสกุล |
| `dob` | DATE | - | NULL | วันเกิด |
| `email` | VARCHAR(150) | UNIQUE | NOT NULL | อีเมล |
| `phone` | VARCHAR(20) | - | NULL | เบอร์โทรศัพท์ |
| `address` | TEXT | - | NULL | ที่อยู่ |
| `resume_file` | VARCHAR(255) | - | NULL | ไฟล์เรซูเม่ |
| `application_date` | DATE | - | DEFAULT CURRENT_DATE | วันที่สมัคร |
| `status` | ENUM | - | DEFAULT 'pending' | สถานะ |

**Status Values:** `pending`, `interviewed`, `accepted`, `rejected`

**Indexes:**
- PRIMARY KEY: `applicant_id`
- UNIQUE: `email`
- INDEX: `idx_email`, `idx_status`

---

### **3. ตาราง `employees`** (พนักงาน)
**จุดประสงค์:** เก็บข้อมูลพนักงาน

| Field | Type | Key | Extra | Description |
|-------|------|-----|-------|-------------|
| `employee_id` | INT(11) | PRIMARY | AUTO_INCREMENT | รหัสพนักงาน |
| `user_id` | INT(11) | - | NULL | รหัสผู้ใช้ (จาก login) |
| `first_name` | VARCHAR(50) | - | NOT NULL | ชื่อ |
| `last_name` | VARCHAR(50) | - | NOT NULL | นามสกุล |
| `phone_number` | VARCHAR(15) | - | NULL | เบอร์โทร |
| `date_of_birth` | DATE | - | NULL | วันเกิด |
| `position` | VARCHAR(50) | - | NULL | ตำแหน่ง |
| `department` | VARCHAR(50) | - | NULL | แผนก |

**Indexes:**
- PRIMARY KEY: `employee_id`
- INDEX: `idx_user_id`

---

### **4. ตาราง `human_resources`** (ข้อมูล HR)
**จุดประสงค์:** เก็บข้อมูลการจัดการทรัพยากรบุคคล

| Field | Type | Key | Extra | Description |
|-------|------|-----|-------|-------------|
| `hr_id` | INT | PRIMARY | AUTO_INCREMENT | รหัส HR |
| `user_id` | INT | FOREIGN | NOT NULL | รหัสพนักงาน |
| `recruitment_detail` | TEXT | - | NULL | รายละเอียดการสรรหา |
| `promotion_history` | TEXT | - | NULL | ประวัติการเลื่อนตำแหน่ง |
| `leave_record` | TEXT | - | NULL | ข้อมูลการลางาน |
| `training_record` | TEXT | - | NULL | ข้อมูลการฝึกอบรม |
| `evaluation_record` | TEXT | - | NULL | ข้อมูลการประเมินผลงาน |
| `resignation_detail` | TEXT | - | NULL | ข้อมูลการลาออก |

**Foreign Keys:**
- `user_id` → `employees(employee_id)` ON DELETE CASCADE

**Indexes:**
- PRIMARY KEY: `hr_id`
- INDEX: `idx_user_id`

---

### **5. ตาราง `executive`** (ผู้บริหาร)
**จุดประสงค์:** เก็บข้อมูลและการตัดสินใจของผู้บริหาร

| Field | Type | Key | Extra | Description |
|-------|------|-----|-------|-------------|
| `executive_id` | INT | PRIMARY | AUTO_INCREMENT | รหัสผู้บริหาร |
| `user_id` | INT | FOREIGN | NOT NULL | รหัสพนักงาน |
| `approval_email` | TEXT | - | NULL | ข้อมูลการอนุมัติ |
| `decision_record` | TEXT | - | NULL | บันทึกการตัดสินใจ |
| `salary_adjustment` | TEXT | - | NULL | การปรับเงินเดือน |
| `policy_memo` | TEXT | - | NULL | บันทึกนโยบาย |

**Foreign Keys:**
- `user_id` → `employees(employee_id)` ON DELETE CASCADE

**Indexes:**
- PRIMARY KEY: `executive_id`
- INDEX: `idx_user_id`

---

### **6. ตาราง `finance_department`** (แผนกการเงิน)
**จุดประสงค์:** เก็บข้อมูลทางการเงินของพนักงาน

| Field | Type | Key | Extra | Description |
|-------|------|-----|-------|-------------|
| `finance_id` | INT | PRIMARY | AUTO_INCREMENT | รหัสข้อมูลการเงิน |
| `user_id` | INT | FOREIGN | NOT NULL | รหัสพนักงาน |
| `salary_record` | DECIMAL(10,2) | - | NULL | บันทึกเงินเดือน |
| `allowance_record` | DECIMAL(10,2) | - | NULL | เบี้ยเลี้ยง |
| `deduction_record` | DECIMAL(10,2) | - | NULL | การหักเงิน |
| `payroll_slip_file` | VARCHAR(255) | - | NULL | ไฟล์สลิปเงินเดือน |
| `payment_date` | DATE | - | NULL | วันที่จ่ายเงิน |
| `report_to_executive` | TEXT | - | NULL | รายงานให้ผู้บริหาร |

**Foreign Keys:**
- `user_id` → `employees(employee_id)` ON DELETE CASCADE

**Indexes:**
- PRIMARY KEY: `finance_id`
- INDEX: `idx_user_id`, `idx_payment_date`

---

### **7. ตาราง `attendance`** (การเข้า-ออกงาน)
**จุดประสงค์:** บันทึกการเข้า-ออกงานของพนักงาน

| Field | Type | Key | Extra | Description |
|-------|------|-----|-------|-------------|
| `id` | INT | PRIMARY | AUTO_INCREMENT | รหัส |
| `user_id` | INT | FOREIGN | NOT NULL | รหัสพนักงาน |
| `date` | DATE | UNIQUE | NOT NULL | วันที่ |
| `check_in_time` | DATETIME | - | NULL | เวลาเข้างาน |
| `check_out_time` | DATETIME | - | NULL | เวลาออกงาน |
| `check_in_image_path` | VARCHAR(255) | - | DEFAULT '' | รูปภาพเข้างาน |
| `morning_start` | TIME | - | DEFAULT '08:30:00' | เริ่มงานเช้า |
| `morning_end` | TIME | - | DEFAULT '12:30:00' | เลิกงานเช้า |
| `afternoon_start` | TIME | - | DEFAULT '13:30:00' | เริ่มงานบ่าย |
| `afternoon_end` | TIME | - | DEFAULT '17:30:00' | เลิกงานบ่าย |
| `created_at` | TIMESTAMP | - | DEFAULT CURRENT_TIMESTAMP | วันที่สร้าง |
| `updated_at` | TIMESTAMP | - | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไข |

**Foreign Keys:**
- `user_id` → `employees(employee_id)` ON DELETE CASCADE

**Indexes:**
- PRIMARY KEY: `id`
- UNIQUE: `unique_user_date` (user_id, date)
- INDEX: `idx_user_date`

---

### **8. ตาราง `leaves`** (การลางาน)
**จุดประสงค์:** บันทึกการลางานของพนักงาน

| Field | Type | Key | Extra | Description |
|-------|------|-----|-------|-------------|
| `id` | INT | PRIMARY | AUTO_INCREMENT | รหัส |
| `user_id` | INT | FOREIGN | NOT NULL | รหัสพนักงาน |
| `leave_type` | ENUM | - | NOT NULL | ประเภทการลา |
| `start_date` | DATE | - | NOT NULL | วันที่เริ่ม |
| `end_date` | DATE | - | NOT NULL | วันที่สิ้นสุด |
| `reason` | TEXT | - | NOT NULL | เหตุผล |
| `status` | ENUM | - | DEFAULT 'pending' | สถานะ |
| `approved_by` | INT | FOREIGN | NULL | ผู้อนุมัติ |
| `approved_at` | DATETIME | - | NULL | วันที่อนุมัติ |
| `created_at` | TIMESTAMP | - | DEFAULT CURRENT_TIMESTAMP | วันที่สร้าง |
| `updated_at` | TIMESTAMP | - | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไข |

**Leave Types:** `sick`, `personal`, `vacation`, `other`  
**Status Values:** `pending`, `approved`, `rejected`

**Foreign Keys:**
- `user_id` → `employees(employee_id)` ON DELETE CASCADE
- `approved_by` → `employees(employee_id)` ON DELETE SET NULL

**Indexes:**
- PRIMARY KEY: `id`
- INDEX: `idx_user_id`, `idx_start_date`, `idx_status`

---

## 🔗 ความสัมพันธ์ระหว่างตาราง (Foreign Keys)

```
login (user_id) ──┐
                  ├──> employees (employee_id)
                  │        │
                  │        ├──> human_resources (user_id)
                  │        ├──> executive (user_id)
                  │        ├──> finance_department (user_id)
                  │        ├──> attendance (user_id)
                  │        └──> leaves (user_id, approved_by)
                  │
applicant (independent)
```

---

## 🔐 ข้อมูลทดสอบ

### **Login Users** (รหัสผ่านทุกคน: `1234`)
| user_id | username | email | role |
|---------|----------|-------|------|
| 1 | admin | admin@humans.com | admin |
| 2 | montita | montita@humans.com | employee |
| 3 | somsak | somsak@humans.com | employee |

### **Employees**
| employee_id | user_id | first_name | last_name | position | department |
|-------------|---------|------------|-----------|----------|------------|
| 1 | 1 | Admin | User | System Administrator | IT |
| 2 | 2 | Montita | Hongloywong | Senior Product Engineering | Engineering |
| 3 | 3 | สมศักดิ์ | ใจดี | HR Manager | Human Resources |

### **Applicants**
| applicant_id | name | surname | email | status |
|--------------|------|---------|-------|--------|
| 1 | สมชาย | รักงาน | somchai@example.com | pending |
| 2 | สมหญิง | รักสงบ | somying@example.com | interviewed |
| 3 | ประยุทธ์ | ขยันเรียน | prayut@example.com | accepted |

---

## 📝 ไฟล์ SQL ที่สำคัญ

### **1. `database.sql`**
- Full schema พร้อมข้อมูลทดสอบ
- ใช้ `CREATE TABLE IF NOT EXISTS`
- เหมาะสำหรับ import ครั้งแรก

### **2. `create_all_tables.sql`**
- มี `DROP TABLE` ก่อนสร้างใหม่
- ใช้สำหรับ reset database
- เหมาะสำหรับ development

---

## 🚀 วิธีรัน SQL Script

### **ใน MySQL Workbench:**
1. เปิด MySQL Workbench
2. เชื่อมต่อด้วย connection **"Humans App"**
3. File → Open SQL Script...
4. เลือก `create_all_tables.sql`
5. กด Execute (⚡) หรือ Ctrl+Shift+Enter
6. Refresh schema (คลิกขวาที่ "humans" → Refresh All)

### **ใน Command Line:**
```bash
mysql -u humans_app -p humans < database.sql
```

---

## ✅ การตรวจสอบว่าสร้างสำเร็จ

```sql
-- ดูตารางทั้งหมด
USE humans;
SHOW TABLES;

-- ตรวจสอบข้อมูล
SELECT * FROM login;
SELECT * FROM employees;
SELECT * FROM applicant;
```

---

## 📌 หมายเหตุ

- ✅ ไม่มีตาราง `users` (ถูกเปลี่ยนเป็น `employees`)
- ✅ ตาราง `employees` ใช้ `employee_id` เป็น PRIMARY KEY
- ✅ Foreign Keys ทั้งหมดชี้ไปที่ `employees(employee_id)`
- ✅ รหัสผ่านทดสอบทั้งหมด hash ด้วย bcrypt (plaintext: `1234`)
- ✅ Backend code (`profile.js`, `auth.js`) ใช้ตาราง `login` และ `employees`

---

## 🔧 Backend Integration

### **Routes ที่ใช้:**
- `/api/auth/login` → ใช้ตาราง `login`
- `/api/auth/register` → ใช้ตาราง `login`
- `/api/profile` → ใช้ตาราง `employees`
- `/api/attendance` → ใช้ตาราง `attendance`
- `/api/leave` → ใช้ตาราง `leaves`

---

**สร้างเมื่อ:** December 5, 2025  
**Database Version:** 1.0  
**Last Updated:** December 5, 2025

