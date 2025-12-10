# Backend Setup Guide

## 🔧 การตั้งค่า Backend

### 1. ติดตั้ง Dependencies

```bash
cd backend
npm install
```

### 2. ตั้งค่า MySQL Database

#### วิธีที่ 1: แก้ไขใน config.js โดยตรง

เปิดไฟล์ `backend/config.js` และแก้ไขรหัสผ่าน:

```javascript
db: {
  host: 'localhost',
  user: 'root',
  password: 'YOUR_MYSQL_PASSWORD_HERE', // ⚠️ ใส่รหัสผ่าน MySQL ของคุณที่นี่
  database: 'humans',
  port: 3306,
}
```

#### วิธีที่ 2: ใช้ Environment Variables (แนะนำ)

สร้างไฟล์ `.env` ใน folder `backend/`:

```env
PORT=3000
JWT_SECRET=your-secret-key-change-this-in-production

DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your-mysql-password-here
DB_NAME=humans
DB_PORT=3306
```

**หมายเหตุ:** ต้องติดตั้ง `dotenv` package ก่อน:

```bash
npm install dotenv
```

แล้วเพิ่มในไฟล์ `server.js` บรรทัดแรก:

```javascript
require('dotenv').config();
```

### 3. สร้าง Database

เข้า MySQL Workbench หรือ Terminal แล้วรันคำสั่ง:

```sql
CREATE DATABASE humans;
```

หรือใช้ไฟล์ `database.sql` ที่มีอยู่:

```bash
mysql -u root -p < database.sql
```

### 4. เริ่มต้น Backend Server

```bash
npm start
```

ควรเห็นข้อความ:
```
🚀 Humans HR Backend running on http://localhost:3000
📊 Database: humans@localhost:3306
✅ Connected to MySQL Database
```

## ❗ การแก้ปัญหา

### ปัญหา: Access denied for user 'root'@'localhost'

**สาเหตุ:** รหัสผ่าน MySQL ไม่ถูกต้อง

**วิธีแก้:**
1. ตรวจสอบรหัสผ่าน MySQL ของคุณ
2. แก้ไขในไฟล์ `config.js` หรือ `.env`
3. Restart backend server

### ปัญหา: Database 'humans' doesn't exist

**วิธีแก้:**
```sql
CREATE DATABASE humans;
```

### ปัญหา: Can't connect to MySQL server

**วิธีแก้:**
1. ตรวจสอบว่า MySQL Server กำลังทำงานอยู่หรือไม่
2. ตรวจสอบ port (default: 3306)

```bash
# Windows - ตรวจสอบ MySQL Service
Get-Service MySQL*

# Windows - Start MySQL Service (ต้อง run as Administrator)
Start-Service MySQL80
```

## 🧪 ทดสอบ Backend

เปิดเบราว์เซอร์หรือใช้ Postman:

```
GET http://localhost:3000/api/health
```

ควรได้ response:
```json
{
  "status": "OK",
  "message": "Humans HR Backend is running",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## 📚 API Endpoints

- `POST /api/login` - เข้าสู่ระบบ
- `POST /api/register` - ลงทะเบียน
- `GET /api/profile` - ดูข้อมูลโปรไฟล์
- `POST /api/attendance/checkin` - เช็คอิน
- `POST /api/attendance/checkout` - เช็คเอาท์
- `POST /api/leave/request` - ขอลางาน

## 🔐 ความปลอดภัย

**สำคัญ!** ในการใช้งานจริง (Production):

1. ✅ เปลี่ยน `JWT_SECRET` ให้เป็นค่าที่ปลอดภัย
2. ✅ ใช้ Environment Variables แทนการเก็บรหัสผ่านในโค้ด
3. ✅ เปิดใช้ HTTPS
4. ✅ ตั้งค่า CORS ให้เฉพาะเจาะจง
5. ✅ เพิ่ม Rate Limiting

