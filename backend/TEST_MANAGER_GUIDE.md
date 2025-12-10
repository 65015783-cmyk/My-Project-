# คู่มือทดสอบหน้า "อนุมัติวันลา" สำหรับ Manager

## ขั้นตอนการทดสอบ

### 0. ตรวจสอบข้อมูล User ทั้งหมด (ทำก่อน)

รัน SQL script เพื่อดูข้อมูล user ทั้งหมด:
```bash
mysql -u root -p humans < backend/check_all_users.sql
```

หรือรัน SQL โดยตรง:
```sql
USE humans;

-- ดูข้อมูล user ทั้งหมด
SELECT 
  l.user_id,
  l.username,
  l.email,
  l.role,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.position,
  e.department,
  COALESCE(e.is_manager, 0) as is_manager
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
ORDER BY l.user_id;
```

จากผลลัพธ์ คุณจะเห็น:
- `user_id`: หมายเลข user
- `username`: ชื่อ login
- `employee_name`: ชื่อพนักงาน
- `position`: ตำแหน่ง
- `department`: แผนก
- `is_manager`: 0 = ไม่ใช่ manager, 1 = เป็น manager
- `role`: 'admin' หรือ 'employee'

### 1. ตั้งค่าให้ User เป็น Manager

#### วิธีที่ 1: ใช้ Quick Set Script (แนะนำ)
```bash
# 1. ตรวจสอบข้อมูล user ก่อน
mysql -u root -p humans < backend/check_all_users.sql

# 2. แก้ไขไฟล์ quick_set_manager.sql เลือก user_id ที่ต้องการ
# 3. รัน script
mysql -u root -p humans < backend/quick_set_manager.sql
```

#### วิธีที่ 2: รัน SQL โดยตรง
```sql
USE humans;

-- ตรวจสอบว่ามี field is_manager หรือไม่
SHOW COLUMNS FROM employees LIKE 'is_manager';

-- ถ้ายังไม่มี ให้เพิ่ม field ก่อน
ALTER TABLE employees 
ADD COLUMN is_manager TINYINT(1) DEFAULT 0 
AFTER department;

-- ตั้งค่าให้ user เป็น manager
-- ตัวอย่าง: ตั้งให้ jira (user_id = 5) เป็น manager
UPDATE employees 
SET is_manager = 1 
WHERE user_id = 5;  -- เปลี่ยน user_id ตามต้องการ

-- หรือตั้งให้ somsak (HR Manager) เป็น manager
UPDATE employees 
SET is_manager = 1 
WHERE user_id = 3;  -- somsak

-- หรือตั้งตามแผนก
UPDATE employees 
SET is_manager = 1 
WHERE department = 'Human Resources';
```

### 2. สร้างข้อมูลวันลาที่รออนุมัติ

```bash
# รัน SQL script เพื่อสร้างข้อมูลทดสอบ
mysql -u root -p humans < backend/create_test_pending_leaves.sql
```

หรือรัน SQL โดยตรง:
```sql
USE humans;

-- เพิ่มข้อมูลวันลาที่รออนุมัติ
INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES
(2, 'sick', DATE_ADD(CURDATE(), INTERVAL 2 DAY), DATE_ADD(CURDATE(), INTERVAL 3 DAY), 'ไม่สบาย มีไข้', 'pending'),
(3, 'personal', DATE_ADD(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 6 DAY), 'ลากิจส่วนตัว', 'pending')
ON DUPLICATE KEY UPDATE id=id;
```

### 3. ทดสอบการ Login

#### สำหรับ Manager:
1. Login ด้วย user ที่ตั้งค่า `is_manager = 1` (เช่น jira หรือ somsak)
2. หลังจาก login สำเร็จ จะเห็นหน้า **Home Screen**
3. ควรเห็นการ์ด **"หัวหน้าแผนก"** ด้านล่างของหน้า
4. กดปุ่ม **"อนุมัติการลา"** ในการ์ดนั้น
5. จะเข้าสู่หน้า **"อนุมัติการลา"** และเห็นรายการวันลาที่รออนุมัติ

#### สำหรับ Employee (ไม่ใช่ Manager):
1. Login ด้วย user ที่ `is_manager = 0` (เช่น montita)
2. จะไม่เห็นการ์ด "หัวหน้าแผนก" ในหน้า Home
3. ไม่สามารถเข้าถึงหน้า "อนุมัติการลา" ได้

#### สำหรับ Admin:
1. Login ด้วย user ที่ `role = 'admin'` (เช่น admin หรือ pupa)
2. จะไม่เห็นการ์ด "หัวหน้าแผนก" ในหน้า Home (เพราะใช้ Admin Dashboard)
3. สามารถเข้าถึงหน้า "อนุมัติการลา" ผ่าน Admin Dashboard ได้

### 4. ตรวจสอบข้อมูล

```sql
-- ตรวจสอบว่า user ไหนเป็น manager
SELECT 
  e.employee_id,
  CONCAT(e.first_name, ' ', e.last_name) as name,
  e.department,
  e.is_manager,
  l.username,
  l.role
FROM employees e
LEFT JOIN login l ON e.user_id = l.user_id
WHERE e.is_manager = 1;

-- ตรวจสอบว่ามีวันลาที่รออนุมัติหรือไม่
SELECT 
  lv.id,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name,
  e.department,
  lv.leave_type,
  lv.start_date,
  lv.end_date,
  lv.status
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending';
```

## สรุปการทดสอบ

### User ที่ควรทดสอบ:

1. **Manager (is_manager = 1, role = 'employee')**
   - ✅ เห็นการ์ด "หัวหน้าแผนก" ในหน้า Home
   - ✅ สามารถเข้าถึงหน้า "อนุมัติการลา" ได้
   - ✅ เห็นเฉพาะวันลาของคนในแผนกเดียวกัน

2. **Employee (is_manager = 0, role = 'employee')**
   - ❌ ไม่เห็นการ์ด "หัวหน้าแผนก"
   - ❌ ไม่สามารถเข้าถึงหน้า "อนุมัติการลา" ได้

3. **Admin (role = 'admin')**
   - ❌ ไม่เห็นการ์ด "หัวหน้าแผนก" ในหน้า Home
   - ✅ สามารถเข้าถึงหน้า "อนุมัติการลา" ผ่าน Admin Dashboard ได้
   - ✅ เห็นวันลาของทุกคน

## หมายเหตุ

- Manager ต้องมี `department` ที่ถูกต้อง
- ระบบจะกรองวันลาให้เห็นเฉพาะคนในแผนกเดียวกัน
- ถ้า Manager ไม่มี `department` จะไม่เห็นวันลาใดๆ

