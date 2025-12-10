# คู่มือการตั้งค่าหัวหน้าแผนก (Manager Setup)

## ภาพรวม
ระบบใช้ field `is_manager` ในตาราง `employees` เพื่อระบุว่าใครเป็นหัวหน้าแผนก

## ขั้นตอนการตั้งค่า

### 1. รัน SQL Script เพื่อเพิ่ม field
```bash
# รันไฟล์ SQL
mysql -u root -p humans < backend/add_manager_field.sql
```

หรือรันคำสั่ง SQL โดยตรง:
```sql
USE humans;

-- เพิ่ม column is_manager
ALTER TABLE employees 
ADD COLUMN is_manager TINYINT(1) DEFAULT 0 
AFTER department;

-- เพิ่ม index
CREATE INDEX idx_is_manager ON employees(is_manager);
CREATE INDEX idx_department_manager ON employees(department, is_manager);
```

### 2. ตั้งค่าให้พนักงานเป็นหัวหน้าแผนก

#### วิธีที่ 1: ตั้งค่าผ่าน SQL
```sql
-- ตั้งให้พนักงานคนใดคนหนึ่งเป็นหัวหน้าแผนก
UPDATE employees 
SET is_manager = 1 
WHERE employee_id = 3;  -- เปลี่ยน employee_id ตามต้องการ

-- หรือตั้งตามตำแหน่ง
UPDATE employees 
SET is_manager = 1 
WHERE position LIKE '%Manager%' OR position LIKE '%หัวหน้า%';
```

#### วิธีที่ 2: ตั้งค่าผ่าน Admin Dashboard
(ต้องเพิ่มฟีเจอร์นี้ในอนาคต)

### 3. ตรวจสอบการตั้งค่า
```sql
SELECT 
  employee_id,
  first_name,
  last_name,
  position,
  department,
  is_manager
FROM employees
WHERE is_manager = 1;
```

## การทำงานของระบบ

### สำหรับ Admin:
- Role: `admin` (ในตาราง `login`)
- สามารถอนุมัติการลาของทุกคนได้
- เข้าถึง Admin Dashboard

### สำหรับหัวหน้าแผนก:
- Role: `employee` (ในตาราง `login`)
- `is_manager = 1` (ในตาราง `employees`)
- สามารถอนุมัติการลาของคนในแผนกเดียวกันเท่านั้น
- เห็นการ์ด "หัวหน้าแผนก" ใน Home Screen

### สำหรับพนักงานทั่วไป:
- Role: `employee` (ในตาราง `login`)
- `is_manager = 0` (ในตาราง `employees`)
- ไม่สามารถอนุมัติการลาได้
- ไม่เห็นการ์ด "หัวหน้าแผนก"

## ตัวอย่างข้อมูล

```sql
-- ตัวอย่าง: ตั้งให้ HR Manager เป็นหัวหน้าแผนก
UPDATE employees 
SET is_manager = 1 
WHERE employee_id = 3;  -- สมศักดิ์ (HR Manager)

-- ตรวจสอบ
SELECT 
  e.employee_id,
  e.first_name,
  e.last_name,
  e.position,
  e.department,
  e.is_manager,
  l.role
FROM employees e
INNER JOIN login l ON e.user_id = l.user_id
WHERE e.is_manager = 1;
```

## หมายเหตุ
- หัวหน้าแผนกต้องมี `department` ที่ถูกต้อง
- ระบบจะกรองการลาให้เห็นเฉพาะคนในแผนกเดียวกัน
- สามารถมีหัวหน้าแผนกได้หลายคนในแผนกเดียวกัน

