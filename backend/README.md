# Humans HR Backend API

Backend API สำหรับระบบ Hummans HR Management ใช้ Node.js + Express + MySQL

## การติดตั้ง

### 1. ติดตั้ง Dependencies

```bash
cd backend
npm install
```

### 2. ตั้งค่า MySQL Database

เปิด MySQL Workbench แล้วรันไฟล์ `database.sql`:

```bash
mysql -u root -p < database.sql
```

หรือเปิดไฟล์ `database.sql` ใน MySQL Workbench แล้วกด Execute

### 3. ตั้งค่า Environment Variables (ถ้าต้องการ)

สร้างไฟล์ `.env` ในโฟลเดอร์ `backend`:

```env
PORT=3000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=humans
DB_PORT=3306
JWT_SECRET=your-secret-key-change-this
```

ถ้าไม่สร้างไฟล์ `.env` จะใช้ค่า default จาก `config.js`

### 4. รัน Backend Server

```bash
npm start
```

หรือใช้ nodemon สำหรับ development:

```bash
npm run dev
```

Server จะรันที่ `http://localhost:3000`

## API Endpoints

### Authentication
- `POST /api/register` - ลงทะเบียนผู้ใช้ใหม่
- `POST /api/login` - เข้าสู่ระบบ

### Attendance
- `POST /api/attendance/checkin` - เช็คอิน (ต้อง login)
- `POST /api/attendance/checkout` - เช็คเอาท์ (ต้อง login)
- `GET /api/attendance/today` - ดูข้อมูลเช็คอินวันนี้ (ต้อง login)
- `GET /api/attendance/history` - ดูประวัติการเข้างาน (ต้อง login)

### Leave
- `POST /api/leave/request` - ขอลางาน (ต้อง login)
- `GET /api/leave/history` - ดูประวัติการลางาน (ต้อง login)
- `PATCH /api/leave/:leaveId/status` - อนุมัติ/ปฏิเสธคำขอลา (Admin เท่านั้น)

### Profile
- `GET /api/profile` - ดูโปรไฟล์ (ต้อง login)
- `PUT /api/profile` - แก้ไขโปรไฟล์ (ต้อง login)

### Health Check
- `GET /api/health` - ตรวจสอบสถานะ server

## ข้อมูลทดสอบ

หลังจากรัน `database.sql` จะมี user ทดสอบ:

- **Admin**: username: `admin`, password: `1234`
- **Employee**: username: `montita`, password: `1234`

## โครงสร้างโฟลเดอร์

```
backend/
├── config.js           # การตั้งค่า
├── server.js           # Entry point
├── db.js              # MySQL connection pool
├── database.sql       # SQL schema และข้อมูลเริ่มต้น
├── middleware/
│   └── auth.js        # JWT authentication
├── routes/
│   ├── auth.js        # Login/Register
│   ├── attendance.js  # Check-in/out
│   ├── leave.js       # Leave requests
│   └── profile.js     # User profile
└── package.json
```

## การใช้งานกับ Flutter App

Flutter app จะเชื่อมต่อกับ backend ผ่าน:
- **Web**: `http://localhost:3000`
- **Android Emulator**: `http://10.0.2.2:3000`
- **Android Device**: `http://<your-computer-ip>:3000`

แก้ไข IP ใน `lib/config/api_config.dart` ถ้าจำเป็น

