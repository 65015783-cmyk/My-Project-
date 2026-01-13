# 🎨 ออกแบบหน้า Dashboard HR ด้านเงินเดือน

## 📋 ภาพรวม
หน้า Dashboard สำหรับ HR ในการจัดการและดูข้อมูลเงินเดือนของพนักงานทั้งหมดในองค์กร

---

## 🎯 ฟีเจอร์หลักที่ควรมี

### 1. **Summary Cards (การ์ดสรุป)**
แสดงข้อมูลสรุปภาพรวมด้านบนหน้า

#### 1.1 จำนวนพนักงานทั้งหมด
- **แสดง**: จำนวนพนักงานที่มีข้อมูลเงินเดือน
- **Icon**: 👥 `Icons.people`
- **Color**: 🔵 Blue
- **Action**: กดแล้วไปหน้ารายชื่อพนักงานทั้งหมด

#### 1.2 เงินเดือนเฉลี่ย
- **แสดง**: เงินเดือนเฉลี่ยของพนักงานทั้งหมด
- **Icon**: 💰 `Icons.attach_money`
- **Color**: 🟢 Green
- **Format**: ตัวเลขพร้อม Format (เช่น 35,000 บาท)

#### 1.3 เงินเดือนสูงสุด
- **แสดง**: เงินเดือนสูงสุดในองค์กร
- **Icon**: 📈 `Icons.trending_up`
- **Color**: 🟡 Orange

#### 1.4 เงินเดือนต่ำสุด
- **แสดง**: เงินเดือนต่ำสุดในองค์กร
- **Icon**: 📉 `Icons.trending_down`
- **Color**: 🔴 Red

#### 1.5 จำนวนการปรับเงินเดือน (เดือนนี้)
- **แสดง**: จำนวนครั้งที่ปรับเงินเดือนในเดือนปัจจุบัน
- **Icon**: 🔄 `Icons.swap_horiz`
- **Color**: 🟣 Purple
- **Action**: กดแล้วไปหน้ารายการปรับเงินเดือนล่าสุด

---

### 2. **Quick Actions (การดำเนินการด่วน)**
ปุ่มสำหรับการดำเนินการหลัก

- **➕ เพิ่มเงินเดือนแรก** (สำหรับพนักงานใหม่)
- **🔄 ปรับเงินเดือน** (สำหรับพนักงานที่มีอยู่)
- **📊 Export ข้อมูล** (PDF, Excel, CSV)
- **📈 ดูรายงาน** (สำหรับผู้บริหาร)

---

### 3. **Filter & Search (กรองและค้นหา)**
- **🔍 Search Bar**: ค้นหาพนักงานด้วยชื่อ/รหัส
- **🏢 Filter by Department**: กรองตามแผนก
- **📅 Filter by Date Range**: กรองตามช่วงวันที่ (effective_date)
- **💰 Filter by Salary Range**: กรองตามช่วงเงินเดือน

---

### 4. **Employee Salary List (รายชื่อพนักงานพร้อมเงินเดือน)**
แสดงรายชื่อพนักงานพร้อมข้อมูลเงินเดือน

#### ข้อมูลที่แสดงในแต่ละ Card:
- **ชื่อ-นามสกุล** + Avatar (ตัวอักษรแรก)
- **ตำแหน่ง** (Position)
- **แผนก** (Department)
- **เงินเดือนปัจจุบัน** (Current Salary) - จาก record ที่ effective_date ล่าสุด
- **เงินเดือนแรก** (Starting Salary) - จาก record แรก
- **จำนวนครั้งที่ปรับ** (Adjustment Count)
- **วันที่ปรับล่าสุด** (Last Adjustment Date)
- **สถานะ** (Badge):
  - 🟢 ปรับแล้ว (มี ADJUST record)
  - 🔵 ยังไม่ปรับ (มีแค่ START)
  - 🟡 ต้องการการตรวจสอบ (เงินเดือนต่ำกว่า average มาก)

#### Action Buttons:
- **👁️ ดูรายละเอียด**: ดูประวัติเงินเดือนทั้งหมดของพนักงาน
- **✏️ แก้ไข/ปรับเงินเดือน**: ไปหน้าปรับเงินเดือน

---

### 5. **Salary Statistics (สถิติเงินเดือน)**
กราฟและสถิติสำหรับวิเคราะห์

#### 5.1 Salary Distribution Chart
- **แสดง**: กราฟแถบ (Bar Chart) แสดงการกระจายเงินเดือนตามช่วง
- **ช่วง**: 
  - < 20,000
  - 20,000 - 30,000
  - 30,000 - 40,000
  - 40,000 - 50,000
  - > 50,000

#### 5.2 Salary by Department
- **แสดง**: กราฟวงกลม (Pie Chart) หรือ Bar Chart
- **แสดง**: เงินเดือนเฉลี่ยของแต่ละแผนก

#### 5.3 Salary Trend (ถ้ามีข้อมูลหลายเดือน)
- **แสดง**: Line Chart แสดงแนวโน้มการปรับเงินเดือน
- **แกน X**: เดือน
- **แกน Y**: จำนวนครั้งที่ปรับ/จำนวนเงินที่ปรับเพิ่ม

---

### 6. **Recent Adjustments (การปรับเงินเดือนล่าสุด)**
แสดงรายการปรับเงินเดือนล่าสุด (ADJUST records)

#### ข้อมูลที่แสดง:
- **ชื่อพนักงาน**
- **เงินเดือนเดิม** → **เงินเดือนใหม่**
- **เหตุผล** (Reason)
- **วันที่ปรับ** (Effective Date)
- **ผู้ปรับ** (Created By)

---

### 7. **Salary Management (การจัดการเงินเดือน)**

#### 7.1 หน้าเพิ่มเงินเดือนแรก (START)
- **Form Fields**:
  - เลือกพนักงาน (Dropdown/Search)
  - จำนวนเงินเดือน (Number Input)
  - วันที่มีผล (Date Picker)
  - หมายเหตุ (Optional)

#### 7.2 หน้าการปรับเงินเดือน (ADJUST)
- **Form Fields**:
  - เลือกพนักงาน (Dropdown/Search)
  - เงินเดือนปัจจุบัน (แสดงเท่านั้น - Auto fill)
  - เงินเดือนใหม่ (Number Input)
  - วันที่มีผล (Date Picker)
  - **เหตุผล** (Text Area - Required)
  - หมายเหตุ (Optional)

---

## 📱 Layout Design

### Desktop/Tablet View:
```
┌─────────────────────────────────────────┐
│  Header: HR Salary Dashboard            │
│  [Refresh] [Export] [Report]            │
├─────────────────────────────────────────┤
│  Summary Cards (5 cards in a row)       │
│  [Total] [Avg] [Max] [Min] [Adjustments]│
├─────────────────────────────────────────┤
│  Quick Actions                          │
│  [+ เพิ่ม] [🔄 ปรับ] [📊 Export] [📈 Report]│
├─────────────────────────────────────────┤
│  Filters                                 │
│  [🔍 Search] [🏢 Dept] [📅 Date] [💰 Range] │
├─────────────────────────────────────────┤
│  Statistics Charts                       │
│  [Distribution] [By Dept] [Trend]       │
├─────────────────────────────────────────┤
│  Employee List                           │
│  [Employee Cards...]                     │
└─────────────────────────────────────────┘
```

### Mobile View:
```
┌─────────────────┐
│  Header         │
│  [☰] [🔄] [📊]  │
├─────────────────┤
│  Summary Cards  │
│  (2 columns)    │
│  [Total] [Avg]  │
│  [Max] [Min]    │
│  [Adjustments]  │
├─────────────────┤
│  Quick Actions  │
│  (Grid 2x2)     │
├─────────────────┤
│  Filters        │
│  (Accordion)    │
├─────────────────┤
│  Charts         │
│  (Full width)   │
├─────────────────┤
│  Employee List  │
│  (Cards stack)  │
└─────────────────┘
```

---

## 🎨 UI/UX Guidelines

### Color Scheme:
- **Primary**: Blue (#2196F3) - สำหรับข้อมูลหลัก
- **Success**: Green (#4CAF50) - สำหรับเงินเดือน/ข้อมูลบวก
- **Warning**: Orange (#FF9800) - สำหรับการแจ้งเตือน
- **Error**: Red (#F44336) - สำหรับข้อมูลที่ต้องระวัง
- **Info**: Purple (#9C27B0) - สำหรับการปรับเงินเดือน

### Card Design:
- **Background**: White
- **Border Radius**: 16px
- **Shadow**: Subtle shadow for depth
- **Padding**: 20px
- **Hover Effect**: Slight elevation on hover (Desktop)

### Typography:
- **Title**: Bold, 24px
- **Subtitle**: Medium, 16px
- **Body**: Regular, 14px
- **Caption**: Regular, 12px
- **Number (Large)**: Bold, 32-36px

---

## 🔄 User Flow

### Flow 1: ดูข้อมูลเงินเดือนทั้งหมด
1. เปิดหน้า Dashboard
2. เห็น Summary Cards
3. Scroll ดู Employee List
4. กดดูรายละเอียดพนักงาน
5. เห็นประวัติเงินเดือนทั้งหมด

### Flow 2: ปรับเงินเดือน
1. เปิดหน้า Dashboard
2. กดปุ่ม "ปรับเงินเดือน" หรือกดที่ Card พนักงาน
3. กรอกแบบฟอร์ม (เงินเดือนใหม่, เหตุผล, วันที่มีผล)
4. ยืนยัน
5. ระบบบันทึกเป็น ADJUST record
6. Dashboard refresh แสดงข้อมูลใหม่

### Flow 3: เพิ่มเงินเดือนแรก (พนักงานใหม่)
1. เปิดหน้า Dashboard
2. กดปุ่ม "เพิ่มเงินเดือนแรก"
3. เลือกพนักงาน
4. กรอกจำนวนเงินเดือนและวันที่มีผล
5. ยืนยัน
6. ระบบบันทึกเป็น START record
7. Dashboard refresh

### Flow 4: Export ข้อมูล
1. เปิดหน้า Dashboard
2. กดปุ่ม "Export"
3. เลือกรูปแบบ (PDF/Excel/CSV)
4. เลือกข้อมูลที่จะ Export (ทั้งหมด/ตาม Filter)
5. ดาวน์โหลดไฟล์

---

## 📊 Data Requirements

### API Endpoints ที่ต้องมี:

1. **GET /api/hr/salary/summary**
   - ส่งคืน Summary statistics
   ```json
   {
     "total_employees": 50,
     "average_salary": 35000,
     "max_salary": 80000,
     "min_salary": 20000,
     "adjustments_this_month": 5
   }
   ```

2. **GET /api/hr/salary/employees**
   - ส่งคืนรายชื่อพนักงานพร้อมเงินเดือน
   ```json
   {
     "employees": [
       {
         "employee_id": 1,
         "full_name": "สมชาย ใจดี",
         "position": "Developer",
         "department": "IT",
         "current_salary": 40000,
         "starting_salary": 30000,
         "adjustment_count": 2,
         "last_adjustment_date": "2024-06-01"
       }
     ]
   }
   ```

3. **GET /api/hr/salary/recent-adjustments**
   - ส่งคืนการปรับเงินเดือนล่าสุด

4. **GET /api/hr/salary/statistics**
   - ส่งคืนสถิติสำหรับกราฟ

5. **POST /api/hr/salary/create**
   - สร้าง START record

6. **POST /api/hr/salary/adjust**
   - สร้าง ADJUST record

---

## ✅ Checklist การพัฒนา

### Phase 1: Core Features
- [ ] สร้างหน้า Dashboard พื้นฐาน
- [ ] Summary Cards (5 cards)
- [ ] Employee List (แสดงข้อมูลพื้นฐาน)
- [ ] Search & Filter (ชื่อ, แผนก)
- [ ] หน้ารายละเอียดพนักงาน

### Phase 2: Management Features
- [ ] หน้าเพิ่มเงินเดือนแรก (START)
- [ ] หน้าการปรับเงินเดือน (ADJUST)
- [ ] Form Validation
- [ ] Success/Error Messages

### Phase 3: Analytics & Reports
- [ ] Salary Distribution Chart
- [ ] Salary by Department Chart
- [ ] Recent Adjustments Section
- [ ] Export Functions (PDF, Excel, CSV)

### Phase 4: Advanced Features
- [ ] Salary Trend Chart
- [ ] Filter by Date Range
- [ ] Filter by Salary Range
- [ ] Report for Executives
- [ ] Notifications for Adjustments

---

## 🎯 Key Points

1. **Performance**: ใช้ Pagination หรือ Virtual Scrolling สำหรับ Employee List หากมีพนักงานจำนวนมาก

2. **Data Freshness**: มี Refresh button และ Auto-refresh option

3. **Responsive**: รองรับทั้ง Mobile, Tablet, Desktop

4. **Accessibility**: ใช้สีที่ contrast ดี, รองรับ Screen Reader

5. **Security**: ตรวจสอบ Permission (เฉพาะ HR/Admin เท่านั้นที่เข้าถึงได้)

6. **Audit Trail**: บันทึกข้อมูล created_by สำหรับการตรวจสอบ

7. **Validation**: 
   - เงินเดือนใหม่ต้องมากกว่าเงินเดือนเดิม (สำหรับ ADJUST)
   - Effective Date ต้องไม่เป็นอดีตมากเกินไป
   - ไม่สามารถแก้ไข START record เดิมได้ (ต้องสร้าง ADJUST แทน)

---

## 📝 Notes

- **เงินเดือนปัจจุบัน**: Query จาก `salary_history` โดยใช้ `ORDER BY effective_date DESC LIMIT 1`
- **เงินเดือนแรก**: Query จาก `salary_history` โดยใช้ `ORDER BY effective_date ASC LIMIT 1`
- **การปรับเงินเดือน**: ต้องสร้าง ADJUST record ใหม่เสมอ ไม่แก้ไข record เดิม
- **Reason**: จำเป็นต้องกรอกสำหรับ ADJUST แต่ไม่จำเป็นสำหรับ START

