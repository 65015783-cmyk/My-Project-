# 🔧 แก้ปัญหา Root User เข้า MySQL ไม่ได้

## วิธีที่ 1: รีเซ็ต Root Password (แนะนำ)

### ขั้นตอน:

#### 1. หยุด MySQL Service

เปิด **Command Prompt as Administrator** (คลิกขวา > Run as Administrator)

```cmd
net stop MySQL80
```

หรือถ้าชื่อ service ต่างกัน ให้หาชื่อจาก Services:
- กด `Win + R` พิมพ์ `services.msc`
- หา MySQL service
- จดชื่อ service (เช่น MySQL80, MySQL, MySQL Server)

#### 2. เริ่ม MySQL แบบ Skip Grant Tables

ใน Command Prompt (as Administrator):

```cmd
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld.exe" --skip-grant-tables --shared-memory
```

⚠️ **หมายเหตุ:** ถ้า path ไม่ถูกต้อง ให้หา path ที่ติดตั้ง MySQL จริงๆ

**อาจจะเป็น:**
- `C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld.exe`
- `C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqld.exe`
- `C:\MySQL\bin\mysqld.exe`

หน้าต่างนี้ **ปล่อยทิ้งไว้** (อย่าปิด)

#### 3. เปิด Command Prompt หน้าต่างใหม่ (as Administrator)

```cmd
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root
```

#### 4. รันคำสั่ง SQL

```sql
FLUSH PRIVILEGES;

-- รีเซ็ตรหัสผ่าน root
ALTER USER 'root'@'localhost' IDENTIFIED BY '12345678';

-- สร้าง database
CREATE DATABASE IF NOT EXISTS humans;

-- สร้าง user ใหม่สำหรับแอป
CREATE USER IF NOT EXISTS 'humans_app'@'localhost' IDENTIFIED BY '12345678';

-- ให้สิทธิ์
GRANT ALL PRIVILEGES ON *.* TO 'humans_app'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON humans.* TO 'humans_app'@'localhost';

FLUSH PRIVILEGES;

EXIT;
```

#### 5. ปิด MySQL และเปิดใหม่แบบปกติ

ปิดหน้าต่าง Command Prompt ทั้ง 2 หน้าต่าง

เปิด Command Prompt as Administrator ใหม่:

```cmd
net start MySQL80
```

---

## วิธีที่ 2: ใช้ mysqld init-file (ง่ายกว่า)

### ขั้นตอน:

#### 1. สร้างไฟล์ init.sql

สร้างไฟล์ `C:\mysql-init.txt` ด้วย Notepad

ใส่เนื้อหา:

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '12345678';
CREATE DATABASE IF NOT EXISTS humans;
CREATE USER IF NOT EXISTS 'humans_app'@'localhost' IDENTIFIED BY '12345678';
GRANT ALL PRIVILEGES ON *.* TO 'humans_app'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON humans.* TO 'humans_app'@'localhost';
FLUSH PRIVILEGES;
```

#### 2. หยุด MySQL Service

Command Prompt as Administrator:

```cmd
net stop MySQL80
```

#### 3. รัน MySQL ด้วย init-file

```cmd
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld.exe" --init-file=C:\mysql-init.txt --console
```

รอจนเห็นข้อความ "ready for connections" แล้วกด `Ctrl+C`

#### 4. เริ่ม MySQL แบบปกติ

```cmd
net start MySQL80
```

#### 5. ลบไฟล์ init.sql

```cmd
del C:\mysql-init.txt
```

---

## วิธีที่ 3: ถ้ายังไม่ได้ - ติดตั้ง MySQL ใหม่

### ขั้นตอน:

1. **Backup Database** (ถ้ามีข้อมูลสำคัญ):
   - ถ้าเข้า MySQL ไม่ได้ ข้อมูลอาจสูญหาย
   - แต่ถ้าไม่มีข้อมูลสำคัญ ข้ามขั้นตอนนี้ได้

2. **ถอนการติดตั้ง MySQL:**
   - Settings > Apps > MySQL > Uninstall
   - ลบโฟลเดอร์ `C:\ProgramData\MySQL\` (ถ้ามี)

3. **ติดตั้ง MySQL ใหม่:**
   - ดาวน์โหลดจาก: https://dev.mysql.com/downloads/installer/
   - ติดตั้งใหม่และตั้งรหัสผ่าน root เป็น `12345678`

4. **สร้าง Database และ User:**

```sql
CREATE DATABASE humans;
CREATE USER 'humans_app'@'localhost' IDENTIFIED BY '12345678';
GRANT ALL PRIVILEGES ON humans.* TO 'humans_app'@'localhost';
FLUSH PRIVILEGES;
```

---

## ✅ หลังจากแก้ไขเสร็จแล้ว

### 1. ทดสอบเข้า MySQL Workbench

ใช้:
- User: `root`
- Password: `12345678`

หรือ

- User: `humans_app`
- Password: `12345678`

### 2. Restart Backend

```bash
cd backend
npm start
```

ควรเห็น:

```
🚀 Humans HR Backend running on http://localhost:3000
📊 Database: humans@localhost:3306
✅ Connected to MySQL Database
```

---

## 🆘 ถ้ายังไม่ได้

บอกขั้นตอนที่ติดมาได้เลยครับ จะช่วยแก้ให้







