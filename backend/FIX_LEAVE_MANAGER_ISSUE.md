# แก้ไขปัญหา: Manager ไม่เห็นข้อมูลการลาของพนักงาน

## ปัญหาที่พบ
Manager ไม่เห็นข้อมูลการลาของพนักงานในแผนกตัวเอง แม้ว่าพนักงานจะส่งคำขอลาแล้ว

## สาเหตุ
1. **ข้อมูลการลาที่มีอยู่แล้วใช้ `login.user_id` แทน `employees.employee_id`**
   - ตาราง `leaves` มี `user_id` ที่อ้างอิงไปที่ `employees.employee_id`
   - แต่ข้อมูลเดิมอาจใช้ `login.user_id` แทน

2. **Query ไม่รองรับทั้งสองกรณี**
   - Query เดิมใช้ `INNER JOIN employees e ON lv.user_id = e.employee_id` เท่านั้น
   - ถ้า `leaves.user_id` เป็น `login.user_id` จะไม่สามารถ join ได้

## วิธีแก้ไข

### ขั้นตอนที่ 1: แก้ไขข้อมูลการลาที่มีอยู่แล้ว

รัน SQL script เพื่อแก้ไขข้อมูล:

```bash
mysql -u root -p humans < backend/fix_leaves_user_id.sql
```

หรือรันใน MySQL client:
```sql
USE humans;
SOURCE backend/fix_leaves_user_id.sql;
```

Script นี้จะ:
- ตรวจสอบข้อมูลการลาที่มีปัญหา
- แก้ไข `leaves.user_id` จาก `login.user_id` เป็น `employees.employee_id`
- ตรวจสอบผลลัพธ์หลังแก้ไข

### ขั้นตอนที่ 2: Restart Backend Server

```bash
# หยุด server (ถ้ากำลังรันอยู่)
# แล้วรันใหม่
npm start
# หรือ
node server.js
```

### ขั้นตอนที่ 3: ทดสอบ

1. **Login เป็น Manager**
   - ตรวจสอบว่า manager มี `role = 'manager'` ในตาราง `login`
   - ตรวจสอบว่า manager มี `department` ในตาราง `employees`

2. **ส่งคำขอลาเป็น Employee**
   - Login เป็น employee
   - ส่งคำขอลาใหม่ (คำขอลาใหม่จะใช้ `employee_id` ถูกต้องแล้ว)

3. **ตรวจสอบใน Manager**
   - Login เป็น manager
   - ไปที่หน้า "อนุมัติการลา"
   - ควรเห็นการลาของพนักงานในแผนกเดียวกัน

## การตรวจสอบปัญหา

### ตรวจสอบข้อมูล Manager
```sql
SELECT 
  l.user_id,
  l.username,
  l.role,
  e.employee_id,
  e.department,
  CONCAT(e.first_name, ' ', e.last_name) as name
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.role = 'manager';
```

### ตรวจสอบข้อมูลการลาที่ Pending
```sql
SELECT 
  lv.id,
  lv.user_id as leave_user_id,
  lv.status,
  e.employee_id,
  e.department,
  CONCAT(e.first_name, ' ', e.last_name) as employee_name
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
LEFT JOIN login l_login ON lv.user_id = l_login.user_id
LEFT JOIN employees e2 ON l_login.user_id = e2.user_id
WHERE lv.status = 'pending';
```

### ตรวจสอบ Log ใน Backend
เมื่อ Manager เข้าดูหน้า "อนุมัติการลา" จะเห็น log ใน console:
```
[Leave Pending] Manager user_id X แผนก: Engineering
[Leave Pending] Manager user_id X พบ Y รายการการลารออนุมัติ
```

## สิ่งที่แก้ไขในโค้ด

1. **แก้ไข `/api/leave/request`**: แปลง `login.user_id` เป็น `employees.employee_id` ก่อนบันทึก
2. **แก้ไข `/api/leave/history`**: ใช้ `employees.employee_id` แทน `login.user_id`
3. **แก้ไข `/api/leave/pending`**: Query รองรับทั้งกรณีที่ `leaves.user_id` เป็น `employee_id` หรือ `login.user_id`
4. **เพิ่ม Debug Logging**: เพื่อช่วยในการ debug ปัญหา

## หมายเหตุ

- การลาที่สร้างใหม่จะใช้ `employee_id` ถูกต้องแล้ว
- การลาที่มีอยู่แล้วต้องรัน migration script เพื่อแก้ไข
- ถ้ายังมีปัญหา ให้ตรวจสอบ log ใน backend console

