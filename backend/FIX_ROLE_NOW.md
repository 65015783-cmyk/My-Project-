# ⚠️ แก้ไขปัญหา Role Manager ทันที

## 🔴 Error ที่เจอ
```
Data truncated for column 'role' at row 1
```

## ✅ วิธีแก้ไข (ทำทันที)

### ขั้นตอนที่ 1: รัน SQL Script

เปิด Command Prompt หรือ Terminal แล้วรัน:

```bash
mysql -u root -p humans < backend/add_manager_role.sql
```

หรือถ้าไม่มี password:
```bash
mysql -u root humans < backend/add_manager_role.sql
```

### ขั้นตอนที่ 2: หรือรัน SQL โดยตรง

เปิด MySQL และรัน:

```sql
USE humans;

-- แก้ไข ENUM ให้รองรับ 'manager'
ALTER TABLE login 
MODIFY COLUMN role ENUM('admin', 'employee', 'manager') DEFAULT 'employee';
```

### ขั้นตอนที่ 3: ตรวจสอบ

```sql
-- ตรวจสอบว่าแก้ไขสำเร็จ
SHOW COLUMNS FROM login WHERE Field = 'role';

-- ควรเห็น: Type = enum('admin','employee','manager')
```

### ขั้นตอนที่ 4: Restart Backend

```bash
# หยุด server (Ctrl+C)
# แล้วรันใหม่
cd backend
npm start
```

### ขั้นตอนที่ 5: ทดสอบ

1. Login ด้วย admin
2. ไปที่ Admin Dashboard → จัดการพนักงาน
3. กดแก้ไขพนักงาน
4. เลือก Role เป็น "Manager"
5. บันทึก

## 🔍 ตรวจสอบว่าแก้ไขสำเร็จ

รัน SQL:
```sql
USE humans;
SHOW COLUMNS FROM login WHERE Field = 'role';
```

**ผลลัพธ์ที่ถูกต้อง:**
```
Field: role
Type: enum('admin','employee','manager')
Null: YES
Key: 
Default: employee
Extra: 
```

## ⚠️ ถ้ายังไม่ได้

1. ตรวจสอบว่า MySQL user มีสิทธิ์ ALTER TABLE
2. ตรวจสอบว่า database ชื่อ `humans` ถูกต้อง
3. ตรวจสอบว่า table `login` มีอยู่
4. ลองรัน SQL โดยตรงใน MySQL Workbench หรือ phpMyAdmin

