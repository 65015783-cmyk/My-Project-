# แก้ไขปัญหา: ไม่สามารถเพิ่ม role manager ได้

## ปัญหา
เมื่อพยายามเพิ่มหรือแก้ไข role เป็น "manager" ผ่านหน้า Admin Dashboard จะเกิด error

## สาเหตุ
Database schema ยังไม่ได้แก้ไขให้รองรับ `role = 'manager'` ในตาราง `login`

## วิธีแก้ไข

### ขั้นตอนที่ 1: แก้ไข Database Schema

รัน SQL script:
```bash
mysql -u root -p humans < backend/add_manager_role.sql
```

หรือรัน SQL โดยตรง:
```sql
USE humans;

-- แก้ไข ENUM ของ role ให้รองรับ 'manager'
ALTER TABLE login 
MODIFY COLUMN role ENUM('admin', 'employee', 'manager') DEFAULT 'employee';
```

### ขั้นตอนที่ 2: ตรวจสอบ

รัน SQL เพื่อตรวจสอบ:
```bash
mysql -u root -p humans < backend/check_and_fix_role.sql
```

หรือรัน SQL โดยตรง:
```sql
USE humans;

-- ตรวจสอบโครงสร้าง
SHOW COLUMNS FROM login WHERE Field = 'role';

-- ควรเห็น: Type = enum('admin','employee','manager')
```

### ขั้นตอนที่ 3: ทดสอบ

1. Restart backend server
2. Login ด้วย admin
3. ไปที่ Admin Dashboard → จัดการพนักงาน
4. กดแก้ไขพนักงาน
5. เลือก Role เป็น "Manager"
6. บันทึก

## ตรวจสอบ Error

ถ้ายังมี error ให้ดูที่:
1. **Backend console** - จะแสดง error message ที่ชัดเจน
2. **Frontend** - จะแสดง error message ใน SnackBar

Error ที่อาจเจอ:
- `ER_TRUNCATED_WRONG_VALUE_FOR_FIELD` - Database schema ยังไม่รองรับ
- `Unknown column` - Column ไม่มีในตาราง
- `Access denied` - ไม่มีสิทธิ์แก้ไข database

## หมายเหตุ

- ต้องแก้ไข database schema ก่อนใช้งาน
- หลังจากแก้ไข schema แล้ว ต้อง restart backend server
- ถ้ายังมีปัญหา ให้ตรวจสอบว่า MySQL user มีสิทธิ์ ALTER TABLE

