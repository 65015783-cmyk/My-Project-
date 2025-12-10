# 🚀 วิธีแก้ไข Database Schema ให้รองรับ Manager Role

## ⚠️ ปัญหา
Error: `Data truncated for column 'role'` หรือ `Database schema ยังไม่รองรับ role = "manager"`

## ✅ วิธีแก้ไข (เลือกวิธีใดวิธีหนึ่ง)

### วิธีที่ 1: ใช้ Node.js Script (แนะนำ - ง่ายที่สุด)

```bash
cd backend
node fix_manager_role.js
```

Script นี้จะ:
- เชื่อมต่อ database อัตโนมัติ
- แก้ไข schema ให้รองรับ 'manager'
- แสดงผลลัพธ์และตรวจสอบให้

### วิธีที่ 2: ใช้ SQL Script

```bash
mysql -u root -p humans < backend/add_manager_role.sql
```

หรือถ้าไม่มี password:
```bash
mysql -u root humans < backend/add_manager_role.sql
```

### วิธีที่ 3: รัน SQL โดยตรง

เปิด MySQL (phpMyAdmin, MySQL Workbench, หรือ Command Line) แล้วรัน:

```sql
USE humans;

ALTER TABLE login 
MODIFY COLUMN role ENUM('admin', 'employee', 'manager') DEFAULT 'employee';
```

### วิธีที่ 4: ใช้ QUICK_FIX Script

```bash
mysql -u root -p humans < backend/QUICK_FIX_MANAGER_ROLE.sql
```

## 🔍 ตรวจสอบว่าแก้ไขสำเร็จ

รัน SQL:
```sql
USE humans;
SHOW COLUMNS FROM login WHERE Field = 'role';
```

**ผลลัพธ์ที่ถูกต้อง:**
```
Type: enum('admin','employee','manager')
```

## 📝 หลังจากแก้ไข

1. **Restart Backend Server**
   ```bash
   # หยุด server (Ctrl+C)
   npm start
   ```

2. **ทดสอบ**
   - Login ด้วย admin
   - ไปที่ Admin Dashboard → จัดการพนักงาน
   - กดแก้ไขพนักงาน
   - เลือก Role เป็น "Manager"
   - บันทึก

## ⚠️ ถ้ายังไม่ได้

1. ตรวจสอบว่า MySQL user มีสิทธิ์ ALTER TABLE
2. ตรวจสอบว่า database ชื่อ `humans` ถูกต้อง
3. ตรวจสอบว่า table `login` มีอยู่
4. ลองรัน SQL โดยตรงใน MySQL Workbench หรือ phpMyAdmin

