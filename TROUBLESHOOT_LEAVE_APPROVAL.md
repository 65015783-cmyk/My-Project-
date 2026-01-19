# คู่มือแก้ปัญหา: อนุมัติการลาไม่ได้

## ขั้นตอนการตรวจสอบ

### 1. ตรวจสอบว่า Backend ทำงานอยู่

เปิด Terminal และรัน:
```bash
cd backend
npm start
```

**ตรวจสอบว่าเห็น:**
```
🚀 Humans HR Backend running on http://localhost:3000
📊 Database: humans@localhost:3306
```

### 2. ทดสอบ Health Check

เปิดเบราว์เซอร์ไปที่:
```
http://localhost:3000/api/health
```

**ควรเห็น:**
```json
{
  "status": "OK",
  "message": "Humans HR Backend is running",
  "timestamp": "..."
}
```

### 3. ตรวจสอบ Console Logs ใน Flutter

เมื่อกดปุ่ม "อนุมัติ" ดูใน **Debug Console** ของ Flutter ควรเห็น:

```
[Leave Approval] Sending request: leaveId=1, status=approved
[Leave Approval] URL: http://10.0.2.2:3000/api/leave/1/status
[Leave Approval] Base URL: http://10.0.2.2:3000/api/leave
[Leave Approval] Token exists: true
[Leave Approval] Response status: 200
```

### 4. ตรวจสอบ Backend Logs

ใน Terminal ของ Backend ควรเห็น:

```
[Leave Approval] Request received: leaveId=1, status=approved, approverId=1, role=admin
[Leave Approval] อัปเดตสถานะการลา ID 1 เป็น approved โดย user_id 1
```

## ปัญหาที่พบบ่อยและวิธีแก้ไข

### ปัญหา 1: Connection Timeout / SocketException

**สาเหตุ:**
- Backend ไม่ทำงาน
- IP address ไม่ถูกต้อง
- Firewall บล็อกการเชื่อมต่อ

**วิธีแก้:**
1. ตรวจสอบว่า Backend ทำงาน: `npm start` ในโฟลเดอร์ `backend`
2. ตรวจสอบ IP ใน `lib/config/api_config.dart`:
   - **Android Emulator**: `http://10.0.2.2:3000`
   - **Android Device**: `http://<your-computer-ip>:3000`
   - **iOS Simulator**: `http://localhost:3000`

### ปัญหา 2: 401 Unauthorized

**สาเหตุ:**
- Token หมดอายุ
- Token ไม่ถูกต้อง

**วิธีแก้:**
1. Logout แล้ว Login ใหม่
2. ตรวจสอบว่า Token ถูกเก็บไว้ใน SharedPreferences

### ปัญหา 3: 403 Forbidden - คุณไม่มีสิทธิ์

**สาเหตุ:**
- User ไม่ใช่ Admin หรือ Manager
- Manager พยายามอนุมัติคนต่างแผนก

**วิธีแก้:**
1. ตรวจสอบ Role ของ User ว่าเป็น `admin` หรือ `manager`
2. สำหรับ Manager: ตรวจสอบว่าแผนกตรงกัน

### ปัญหา 4: 404 Not Found

**สาเหตุ:**
- API endpoint ไม่ถูกต้อง
- leaveId ไม่มีในฐานข้อมูล

**วิธีแก้:**
1. ตรวจสอบ URL: ควรเป็น `http://10.0.2.2:3000/api/leave/{leaveId}/status`
2. ตรวจสอบว่า leaveId ถูกต้อง (ดูจาก console log)

### ปัญหา 5: 500 Internal Server Error

**สาเหตุ:**
- Database connection error
- SQL query error

**วิธีแก้:**
1. ตรวจสอบ MySQL ทำงานอยู่
2. ตรวจสอบ Backend logs เพื่อดู error message
3. ตรวจสอบว่า database `humans` มีอยู่

## การทดสอบด้วย cURL

ทดสอบ API โดยตรงด้วย cURL:

```bash
# 1. Login เพื่อรับ Token
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"1234"}'

# 2. ใช้ Token ที่ได้จากข้อ 1 อนุมัติการลา (เปลี่ยน TOKEN และ LEAVE_ID)
curl -X PATCH http://localhost:3000/api/leave/1/status \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"status":"approved"}'
```

## การ Debug เพิ่มเติม

### เพิ่ม Log ใน Flutter

ดู Console logs เมื่อกดปุ่มอนุมัติ:
- `[Leave Approval] Sending request: ...`
- `[Leave Approval] URL: ...`
- `[Leave Approval] Response status: ...`

### เพิ่ม Log ใน Backend

ดู Terminal logs ของ Backend:
- `[Leave Approval] Request received: ...`
- `[Leave Approval] อัปเดตสถานะการลา ID ...`

## ตรวจสอบ Database

ตรวจสอบข้อมูลใน MySQL:

```sql
-- ดูข้อมูลการลาทั้งหมด
SELECT id, user_id, leave_type, start_date, end_date, reason, status, approved_by, approved_at 
FROM leaves 
ORDER BY created_at DESC;

-- ดูข้อมูลการลาที่รออนุมัติ
SELECT * FROM leaves WHERE status = 'pending';

-- ตรวจสอบ role ของ user
SELECT l.user_id, l.username, l.role, e.employee_id, e.department
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id;
```

## Contact

หากยังแก้ไม่ได้ ให้ตรวจสอบ:
1. Backend logs (Terminal)
2. Flutter console logs (Debug Console)
3. Database data (MySQL)
4. Network connection
