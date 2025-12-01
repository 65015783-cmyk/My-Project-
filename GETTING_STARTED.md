# คู่มือเริ่มต้นใช้งาน Hummans

## ความต้องการของระบบ

- Flutter SDK (เวอร์ชัน 3.0 ขึ้นไป)
- Dart SDK
- Android Studio หรือ VS Code พร้อม Flutter extension
- อีมูเลเตอร์ Android/iOS หรืออุปกรณ์จริง

## ขั้นตอนการติดตั้งและรัน

### 1. ตรวจสอบว่า Flutter ติดตั้งแล้ว
```bash
flutter doctor
```

### 2. ติดตั้ง Dependencies
```bash
flutter pub get
```

### 3. รันแอปพลิเคชัน
```bash
flutter run
```

## ฟีเจอร์ที่พร้อมใช้งาน

### ✅ หน้าหลัก (Home)
- แสดงข้อมูลผู้ใช้
- การ์ดแสดงข้อมูลงานรายวัน
- ปุ่มเช็คอิน/เช็คเอาท์
- ปุ่มลางานและเงินเดือน

### ✅ หน้าปฏิทิน (Calendar)
- แสดงปฏิทินรายเดือน
- สรุปจำนวนวันทำงาน

### ✅ หน้าการแจ้งเตือน (Notifications)
- รายการการแจ้งเตือน
- แสดงสถานะการอ่าน

### ✅ หน้าโปรไฟล์ (Profile)
- ข้อมูลส่วนตัว
- เมนูการตั้งค่า

## การปรับแต่ง

### เปลี่ยนข้อมูลผู้ใช้
แก้ไขใน `lib/services/auth_service.dart`

### เปลี่ยนเวลาทำงานเริ่มต้น
แก้ไขใน `lib/models/attendance_model.dart` ที่ `WorkSchedule.defaultSchedule()`

### เปลี่ยนสีธีม
แก้ไขใน `lib/main.dart` ที่ส่วน `ColorScheme.fromSeed()`

## โครงสร้างโค้ด

- `lib/models/` - Data models
- `lib/screens/` - หน้าจอต่างๆ
- `lib/widgets/` - Widget ที่ใช้ซ้ำ
- `lib/services/` - Business logic และ state management
- `lib/utils/` - ฟังก์ชันช่วยเหลือ

## การพัฒนาต่อ

1. เชื่อมต่อ Backend API - แก้ไขใน `lib/services/`
2. เพิ่มการตรวจสอบสิทธิ์ - ปรับปรุง `AuthService`
3. เพิ่มฟีเจอร์ใหม่ - สร้างหน้าจอใหม่ใน `lib/screens/`
4. เพิ่ม Unit Tests - สร้างใน `test/` directory

## การแก้ปัญหา

### ถ้าเจอ error เกี่ยวกับ dependencies
```bash
flutter clean
flutter pub get
```

### ถ้าเจอปัญหาเกี่ยวกับ build
```bash
flutter clean
flutter pub get
flutter run
```

## สนับสนุน

หากพบปัญหาหรือมีคำถาม สามารถดูเอกสารเพิ่มเติมใน:
- `README.md` - ข้อมูลทั่วไป
- `PROJECT_STRUCTURE.md` - โครงสร้างโปรเจค

