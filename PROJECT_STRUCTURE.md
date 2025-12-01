# โครงสร้างโปรเจค Hummans

## ภาพรวม
ระบบบริหารงานบุคคล (HR Management System) ที่พัฒนาด้วย Flutter ตามแบบ Mobile Application

## โครงสร้างไฟล์

```
hummans/
├── lib/
│   ├── main.dart                 # จุดเริ่มต้นของแอป
│   ├── models/                   # Data Models
│   │   ├── user_model.dart       # ข้อมูลผู้ใช้
│   │   └── attendance_model.dart # ข้อมูลการเข้างาน
│   ├── screens/                  # หน้าจอต่างๆ
│   │   ├── home_screen.dart      # หน้าหลัก (Home)
│   │   ├── calendar_screen.dart  # หน้าปฏิทิน
│   │   ├── notifications_screen.dart # หน้าการแจ้งเตือน
│   │   └── profile_screen.dart   # หน้าโปรไฟล์
│   ├── widgets/                  # Widget ที่ใช้ซ้ำ
│   │   ├── daily_work_card.dart  # การ์ดแสดงข้อมูลงานรายวัน
│   │   └── action_button.dart    # ปุ่มสำหรับการดำเนินการ
│   ├── services/                 # Business Logic Services
│   │   ├── auth_service.dart     # บริการ Authentication
│   │   └── attendance_service.dart # บริการจัดการการเข้างาน
│   └── utils/                    # ฟังก์ชันช่วยเหลือ
│       └── date_formatter.dart   # จัดรูปแบบวันที่
├── assets/
│   └── images/                   # รูปภาพและ Asset ต่างๆ
├── android/                      # Configuration สำหรับ Android
├── pubspec.yaml                  # Dependencies และการตั้งค่า Flutter
└── README.md                     # เอกสารแนะนำ

```

## ฟีเจอร์หลัก

### 1. หน้าหลัก (Home Screen)
- แสดงข้อมูลผู้ใช้ (ชื่อ, ตำแหน่ง)
- การ์ดแสดงข้อมูลงานรายวัน (วันที่, เวลาทำงาน, เวลาเช็คอิน/เช็คเอาท์)
- ปุ่มการดำเนินการ 4 ปุ่ม:
  - เข้างาน (Check-in)
  - ออกงาน (Check-out)
  - ลางาน (Request Leave)
  - เงินเดือน (Salary)

### 2. หน้าปฏิทิน (Calendar Screen)
- แสดงปฏิทินรายเดือน
- สรุปจำนวนวันทำงาน, ลางาน, มาทำงาน

### 3. หน้าการแจ้งเตือน (Notifications Screen)
- รายการการแจ้งเตือนต่างๆ
- แสดงสถานะว่าอ่านแล้วหรือยัง

### 4. หน้าโปรไฟล์ (Profile Screen)
- แสดงข้อมูลส่วนตัว
- เมนูต่างๆ เช่น แก้ไขโปรไฟล์, เปลี่ยนรหัสผ่าน, ประวัติการทำงาน

## การใช้งาน

1. ติดตั้ง Dependencies:
```bash
flutter pub get
```

2. รันแอป:
```bash
flutter run
```

## เทคโนโลยีที่ใช้

- Flutter 3.0+
- Provider (State Management)
- Google Fonts (Typography)
- Material Design 3
- Intl (Internationalization)

## การปรับแต่ง

### เปลี่ยนสีธีม
แก้ไขใน `lib/main.dart` ที่ส่วน `ColorScheme.fromSeed()`

### เพิ่มหน้าจอใหม่
1. สร้างไฟล์ใน `lib/screens/`
2. เพิ่ม route ใน `lib/main.dart`
3. อัพเดท bottom navigation bar

### เชื่อมต่อ API
แก้ไขใน `lib/services/` เพื่อเชื่อมต่อกับ Backend API

