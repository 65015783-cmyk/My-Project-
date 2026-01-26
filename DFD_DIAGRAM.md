# Data Flow Diagram (DFD) - ระบบบริหารงานบุคคล (Hummans)

## ภาพที่ 3.1 Context Diagram (Level 0 DFD)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│                    ระบบบริหารงานบุคคล (HR Management System)              │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                                                                 │   │
│  │  • Authentication (Login/Register)                              │   │
│  │  • Attendance Management (Check-in/Check-out)                   │   │
│  │  • Leave Management (Request/Approve/Reject)                    │   │
│  │  • Overtime Management (Request/Approve/Reject)                  │   │
│  │  • Salary Management (View Salary, Payroll)                     │   │
│  │  • Employee Management (CRUD)                                    │   │
│  │  • Notification Management                                       │   │
│  │  • Profile Management                                            │   │
│  │                                                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
         │                    │                    │
         │                    │                    │
    ┌────▼────┐          ┌────▼────┐          ┌────▼────┐
    │พนักงาน  │          │ผู้บริหาร │          │Admin/HR │
    │(Employee)│          │(Manager)│          │         │
    └─────────┘          └─────────┘          └─────────┘
```

### Data Flows - พนักงาน (Employee)

**จาก Employee → HR System:**
- เข้าสู่ระบบ (Login Credentials)
- ข้อมูลการเช็คอิน/เช็คเอาท์ (Check-in/Check-out Data)
- ข้อมูลการขอลา (Leave Request Data)
- ข้อมูลการขอ OT (Overtime Request Data)
- ข้อมูลส่วนตัว (Profile Data)
- ข้อมูลการเปลี่ยนรหัสผ่าน (Password Change Data)

**จาก HR System → Employee:**
- รายละเอียดการเข้าสู่ระบบ (Login Response)
- รายละเอียดการเข้างาน (Attendance Details)
- รายละเอียดการลา (Leave Details & History)
- รายละเอียดการ OT (Overtime Details & History)
- รายละเอียดเงินเดือน (Salary Details)
- การแจ้งเตือน (Notifications)
- รายละเอียดโปรไฟล์ (Profile Details)

### Data Flows - ผู้บริหาร (Manager)

**จาก Manager → HR System:**
- เข้าสู่ระบบ (Login Credentials)
- การอนุมัติ/ปฏิเสธการลา (Leave Approval/Rejection)
- การอนุมัติ/ปฏิเสธการ OT (OT Approval/Rejection)
- ข้อมูลการดูรายงาน (Report View Request)

**จาก HR System → Manager:**
- รายละเอียดการเข้าสู่ระบบ (Login Response)
- รายการคำขอลารออนุมัติ (Pending Leave Requests)
- รายการคำขอ OT รออนุมัติ (Pending OT Requests)
- รายงานการเข้างาน (Attendance Reports)
- รายงานสรุปการลา (Leave Summary Reports)
- การแจ้งเตือน (Notifications)

### Data Flows - Admin/HR

**จาก Admin/HR → HR System:**
- เข้าสู่ระบบ (Login Credentials)
- ข้อมูลการจัดการพนักงาน (Employee Management Data)
- ข้อมูลการตั้งค่าเงินเดือน (Salary Configuration)
- ข้อมูลการดูรายงาน HR (HR Report Request)
- ข้อมูลการส่งออกรายงาน (Export Report Request)

**จาก HR System → Admin/HR:**
- รายละเอียดการเข้าสู่ระบบ (Login Response)
- รายละเอียดข้อมูลพนักงาน (Employee Details)
- รายงานสรุปการเข้างานรายวัน (Daily Attendance Report)
- รายงานภาพรวมเงินเดือน (Payroll Overview)
- รายงานสรุปการลา (Leave Summary)
- การแจ้งเตือน (Notifications)

---

## ภาพที่ 3.2 Level 1 DFD (Top Level)

```
                    ┌──────────────┐
                    │   E1:        │
                    │  พนักงาน      │
                    │ (Employee)   │
                    └──────┬───────┘
                           │
                           │ Login Credentials
                           │ Check-in/Check-out Data
                           │ Leave Request Data
                           │ OT Request Data
                           │ Profile Data
                           │
                    ┌──────▼────────────────────────────────────────────────────┐
                    │                                                          │
                    │  1.0 Authentication Management                            │
                    │     ┌──────────────────────┐                            │
                    │     │ Login/Register       │                            │
                    │     │ Token Generation     │                            │
                    │     └──────────┬───────────┘                            │
                    │                │                                         │
                    │                │ User Info                               │
                    │                │                                         │
                    │                ▼                                         │
                    │         ┌──────────┐                                     │
                    │         │   D1     │                                     │
                    │         │  User    │                                     │
                    │         │ Database │                                     │
                    │         └──────────┘                                     │
                    │                                                          │
                    │  2.0 Attendance Management                                │
                    │     ┌──────────────────────┐                            │
                    │     │ Record Check-in/out   │                            │
                    │     │ Calculate Work Hours │                            │
                    │     └──────────┬───────────┘                            │
                    │                │                                         │
                    │                │ Attendance Records                      │
                    │                │                                         │
                    │                ▼                                         │
                    │         ┌──────────┐                                     │
                    │         │   D2     │                                     │
                    │         │Attendance│                                     │
                    │         │ Database │                                     │
                    │         └──────────┘                                     │
                    │                                                          │
                    │  3.0 Leave Management                                     │
                    │     ┌──────────────────────┐                            │
                    │     │ Create Leave Request │                            │
                    │     │ Approve/Reject Leave │                            │
                    │     └──────────┬───────────┘                            │
                    │                │                                         │
                    │                │ Leave Data                              │
                    │                │                                         │
                    │                ▼                                         │
                    │         ┌──────────┐                                     │
                    │         │   D3     │                                     │
                    │         │  Leave   │                                     │
                    │         │ Database │                                     │
                    │         └──────────┘                                     │
                    │                │                                         │
                    │                │ Notification Trigger                     │
                    │                │                                         │
                    │                ▼                                         │
                    │  7.0 Notification Management                             │
                    │     ┌──────────────────────┐                            │
                    │     │ Create Notification   │                            │
                    │     └──────────┬───────────┘                            │
                    │                │                                         │
                    │                │ Notification Data                        │
                    │                │                                         │
                    │                ▼                                         │
                    │         ┌──────────┐                                     │
                    │         │   D6     │                                     │
                    │         │Notification│                                   │
                    │         │ Database │                                     │
                    │         └──────────┘                                     │
                    │                                                          │
                    │  4.0 Overtime Management                                  │
                    │     ┌──────────────────────┐                            │
                    │     │ Create OT Request     │                            │
                    │     │ Approve/Reject OT     │                            │
                    │     └──────────┬───────────┘                            │
                    │                │                                         │
                    │                │ OT Data                                 │
                    │                │                                         │
                    │                ▼                                         │
                    │         ┌──────────┐                                     │
                    │         │   D4     │                                     │
                    │         │Overtime  │                                     │
                    │         │ Database │                                     │
                    │         └──────────┘                                     │
                    │                │                                         │
                    │                │ Notification Trigger                     │
                    │                │                                         │
                    │                └──────────► 7.0 Notification             │
                    │                                                          │
                    │  5.0 Salary Management                                    │
                    │     ┌──────────────────────┐                            │
                    │     │ Calculate Salary     │                            │
                    │     │ Calculate Deductions │                            │
                    │     │ Calculate OT Pay     │                            │
                    │     └──────────┬───────────┘                            │
                    │                │                                         │
                    │                │ Read from D1, D2, D3, D4, D5            │
                    │                │                                         │
                    │                ▼                                         │
                    │         ┌──────────┐                                     │
                    │         │   D5     │                                     │
                    │         │ Salary   │                                     │
                    │         │ Database │                                     │
                    │         └──────────┘                                     │
                    │                                                          │
                    │  6.0 Employee Management                                  │
                    │     ┌──────────────────────┐                            │
                    │     │ CRUD Employees     │                            │
                    │     └──────────┬───────────┘                            │
                    │                │                                         │
                    │                │ Employee Data                           │
                    │                │                                         │
                    │                └──────────► D1: User Database            │
                    │                                                          │
                    │  8.0 Profile Management                                   │
                    │     ┌──────────────────────┐                            │
                    │     │ View/Update Profile   │                            │
                    │     │ Change Password       │                            │
                    │     └──────────┬───────────┘                            │
                    │                │                                         │
                    │                │ Profile Data                            │
                    │                │                                         │
                    │                └──────────► D1: User Database            │
                    │                                                          │
                    └──────────────────────────────────────────────────────────┘
                           │
                           │
                    ┌──────▼───────┐      ┌──────▼───────┐
                    │   E2:        │      │   E3:        │
                    │ ผู้บริหาร     │      │ Admin/HR      │
                    │ (Manager)    │      │              │
                    └──────────────┘      └──────────────┘
```

### รายละเอียด Process แต่ละตัว

#### 1.0 Authentication Management
**Input:**
- Login Credentials (จาก Employee/Manager/Admin)
- Register Data (จาก Employee)

**Output:**
- Authentication Response
- User Information

**Data Stores:**
- D1: User Database (login, employees)

**Processes:**
- Login Verification
- User Registration
- Token Generation

---

#### 2.0 Attendance Management
**Input:**
- Check-in Data (เวลา, สถานที่, QR Code)
- Check-out Data (เวลา)

**Output:**
- Attendance Records
- Daily Attendance Summary
- Attendance Reports

**Data Stores:**
- D1: User Database
- D2: Attendance Database

**Processes:**
- Record Check-in/Check-out
- Calculate Work Hours
- Generate Attendance Reports

---

#### 3.0 Leave Management
**Input:**
- Leave Request Data (ประเภทลา, วันที่เริ่ม-สิ้นสุด, เหตุผล)
- Leave Approval/Rejection (จาก Manager/Admin)

**Output:**
- Leave Request Status
- Leave History
- Leave Summary Reports
- Notification (เมื่ออนุมัติ/ปฏิเสธ)

**Data Stores:**
- D1: User Database
- D3: Leave Database
- D6: Notification Database

**Processes:**
- Create Leave Request
- Approve/Reject Leave
- Calculate Leave Balance
- Generate Leave Reports
- Send Notification

---

#### 4.0 Overtime Management
**Input:**
- OT Request Data (วันที่, เวลาเริ่ม-สิ้นสุด, เหตุผล)
- OT Approval/Rejection (จาก Manager)

**Output:**
- OT Request Status
- OT History
- OT Summary
- Notification (เมื่ออนุมัติ/ปฏิเสธ)

**Data Stores:**
- D1: User Database
- D4: Overtime Database
- D6: Notification Database

**Processes:**
- Create OT Request
- Approve/Reject OT
- Calculate OT Hours
- Generate OT Reports
- Send Notification

---

#### 5.0 Salary Management
**Input:**
- Salary View Request (จาก Employee)
- Payroll Calculation Request (จาก Admin/HR)
- Salary Configuration (จาก Admin/HR)

**Output:**
- Salary Summary (เงินเดือน, เงินหัก, เงินสุทธิ, OT Hours, OT Amount)
- Payroll Overview (รวมเงินเดือนทั้งหมด, จำนวนพนักงาน, เงินหักรวม, เงินสุทธิรวม)
- Salary Reports

**Data Stores:**
- D1: User Database
- D2: Attendance Database
- D3: Leave Database
- D4: Overtime Database
- D5: Salary Database

**Processes:**
- Calculate Base Salary
- Calculate Deductions (Social Security, Tax)
- Calculate Overtime Pay
- Generate Payroll Overview
- Generate Salary Reports

---

#### 6.0 Employee Management
**Input:**
- Employee CRUD Data (จาก Admin/HR)
- Employee Search/Filter Request

**Output:**
- Employee List
- Employee Details
- Employee Reports

**Data Stores:**
- D1: User Database

**Processes:**
- Create Employee
- Update Employee
- Delete Employee
- Search/Filter Employees
- Generate Employee Reports

---

#### 7.0 Notification Management
**Input:**
- Notification Creation (จากระบบอื่นๆ)
- Notification Read Status Update

**Output:**
- Notification List
- Unread Notification Count
- Notification Details

**Data Stores:**
- D6: Notification Database

**Processes:**
- Create Notification
- Mark as Read
- Mark All as Read
- Get Notifications

---

#### 8.0 Profile Management
**Input:**
- Profile Update Data
- Password Change Data

**Output:**
- Profile Information
- Profile Update Status

**Data Stores:**
- D1: User Database

**Processes:**
- View Profile
- Update Profile
- Change Password

---

## ภาพที่ 3.3 Level 2 DFD - Leave Management (3.0)

```
                    ┌──────────────┐
                    │   E1:        │
                    │  พนักงาน      │
                    └──────┬───────┘
                           │
                           │ Leave Request Data
                           │
                    ┌──────▼──────────────────────────────────────┐
                    │                                               │
                    │  3.1 Create Leave Request                    │
                    │     ┌──────────────────────┐                │
                    │     │ Validate Leave Data   │                │
                    │     │ Check Leave Balance   │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Leave Record                │
                    │                │                             │
                    │                ▼                             │
                    │         ┌──────────┐                        │
                    │         │   D3     │                        │
                    │         │  Leave   │                        │
                    │         │ Database │                        │
                    │         └──────────┘                        │
                    │                │                             │
                    │                │ Notification Trigger        │
                    │                │                             │
                    │                ▼                             │
                    │  3.2 Send Notification to Manager            │
                    │     ┌──────────────────────┐                │
                    │     │ Create Notification │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Notification Data           │
                    │                │                             │
                    │                ▼                             │
                    │         ┌──────────┐                        │
                    │         │   D6     │                        │
                    │         │Notification│                      │
                    │         │ Database │                        │
                    │         └──────────┘                        │
                    │                                               │
                    │  3.3 Approve/Reject Leave                    │
                    │     ┌──────────────────────┐                │
                    │     │ Validate Permission  │                │
                    │     │ Update Leave Status   │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Updated Leave Record        │
                    │                │                             │
                    │                ▼                             │
                    │         ┌──────────┐                        │
                    │         │   D3     │                        │
                    │         │  Leave   │                        │
                    │         │ Database │                        │
                    │         └──────────┘                        │
                    │                │                             │
                    │                │ Notification Trigger        │
                    │                │                             │
                    │                └──────────► 3.2 Send Notification
                    │                                               │
                    │  3.4 Generate Leave Reports                   │
                    │     ┌──────────────────────┐                │
                    │     │ Calculate Leave Stats│                │
                    │     │ Generate Summary     │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Read from D3                │
                    │                │                             │
                    │                ▼                             │
                    │         ┌──────────┐                        │
                    │         │   D3     │                        │
                    │         │  Leave   │                        │
                    │         │ Database │                        │
                    │         └──────────┘                        │
                    │                                               │
                    └───────────────────────────────────────────────┘
                           │
                           │ Leave Summary Reports
                           │
                    ┌──────▼───────┐      ┌──────▼───────┐
                    │   E2:        │      │   E3:        │
                    │ ผู้บริหาร     │      │ Admin/HR      │
                    │ (Manager)    │      │              │
                    └──────────────┘      └──────────────┘
```

---

## ภาพที่ 3.4 Level 2 DFD - Salary Management (5.0)

```
                    ┌──────────────┐
                    │   E1:        │
                    │  พนักงาน      │
                    └──────┬───────┘
                           │
                           │ Salary View Request
                           │
                    ┌──────▼──────────────────────────────────────┐
                    │                                               │
                    │  5.1 Get Employee Salary Data                 │
                    │     ┌──────────────────────┐                │
                    │     │ Read Employee Info    │                │
                    │     │ Read Base Salary      │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Read from D1                │
                    │                │                             │
                    │                ▼                             │
                    │         ┌──────────┐                        │
                    │         │   D1     │                        │
                    │         │  User    │                        │
                    │         │ Database │                        │
                    │         └──────────┘                        │
                    │                                               │
                    │  5.2 Calculate Attendance Data                │
                    │     ┌──────────────────────┐                │
                    │     │ Count Work Days      │                │
                    │     │ Count Leave Days     │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Read from D2, D3             │
                    │                │                             │
                    │                ▼                             │
                    │         ┌──────────┐                        │
                    │         │   D2     │    ┌──────────┐        │
                    │         │Attendance│    │   D3     │        │
                    │         │ Database │    │  Leave   │        │
                    │         └──────────┘    │ Database │        │
                    │                          └──────────┘        │
                    │                                               │
                    │  5.3 Calculate Overtime Pay                   │
                    │     ┌──────────────────────┐                │
                    │     │ Get Approved OT Hours│                │
                    │     │ Calculate OT Rate    │                │
                    │     │ Calculate OT Amount  │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Read from D4                │
                    │                │                             │
                    │                ▼                             │
                    │         ┌──────────┐                        │
                    │         │   D4     │                        │
                    │         │Overtime  │                        │
                    │         │ Database │                        │
                    │         └──────────┘                        │
                    │                                               │
                    │  5.4 Calculate Deductions                    │
                    │     ┌──────────────────────┐                │
                    │     │ Social Security (5%) │                │
                    │     │ Tax (5%)             │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Deduction Data              │
                    │                │                             │
                    │                ▼                             │
                    │         ┌──────────┐                        │
                    │         │   D5     │                        │
                    │         │ Salary   │                        │
                    │         │ Database │                        │
                    │         └──────────┘                        │
                    │                                               │
                    │  5.5 Calculate Net Pay                       │
                    │     ┌──────────────────────┐                │
                    │     │ Gross = Base + OT     │                │
                    │     │ Net = Gross - Deduct │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Salary Summary              │
                    │                │                             │
                    │                ▼                             │
                    │         Salary Summary Response               │
                    │                                               │
                    │  5.6 Generate Payroll Overview (Admin/HR)     │
                    │     ┌──────────────────────┐                │
                    │     │ Sum All Employees    │                │
                    │     │ Calculate Totals     │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Read from D1, D2, D3, D4, D5│
                    │                │                             │
                    │                ▼                             │
                    │         Payroll Overview Response             │
                    │                                               │
                    └───────────────────────────────────────────────┘
                           │
                           │ Salary Summary / Payroll Overview
                           │
                    ┌──────▼───────┐      ┌──────▼───────┐
                    │   E1:        │      │   E3:        │
                    │  พนักงาน      │      │ Admin/HR      │
                    └──────────────┘      └──────────────┘
```

---

## ภาพที่ 3.5 Level 2 DFD - Overtime Management (4.0)

```
                    ┌──────────────┐
                    │   E1:        │
                    │  พนักงาน      │
                    └──────┬───────┘
                           │
                           │ OT Request Data
                           │
                    ┌──────▼──────────────────────────────────────┐
                    │                                               │
                    │  4.1 Create OT Request                       │
                    │     ┌──────────────────────┐                │
                    │     │ Validate OT Data      │                │
                    │     │ Check Duplicate       │                │
                    │     │ Calculate Total Hours │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ OT Record                   │
                    │                │                             │
                    │                ▼                             │
                    │         ┌──────────┐                        │
                    │         │   D4     │                        │
                    │         │Overtime  │                        │
                    │         │ Database │                        │
                    │         └──────────┘                        │
                    │                │                             │
                    │                │ Notification Trigger        │
                    │                │                             │
                    │                ▼                             │
                    │  4.2 Send Notification to Manager            │
                    │     ┌──────────────────────┐                │
                    │     │ Create Notification │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Notification Data           │
                    │                │                             │
                    │                ▼                             │
                    │         ┌──────────┐                        │
                    │         │   D6     │                        │
                    │         │Notification│                      │
                    │         │ Database │                        │
                    │         └──────────┘                        │
                    │                                               │
                    │  4.3 Approve/Reject OT                        │
                    │     ┌──────────────────────┐                │
                    │     │ Validate Permission  │                │
                    │     │ Check Department     │                │
                    │     │ Update OT Status     │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Updated OT Record           │
                    │                │                             │
                    │                ▼                             │
                    │         ┌──────────┐                        │
                    │         │   D4     │                        │
                    │         │Overtime  │                        │
                    │         │ Database │                        │
                    │         └──────────┘                        │
                    │                │                             │
                    │                │ Notification Trigger        │
                    │                │                             │
                    │                └──────────► 4.2 Send Notification
                    │                                               │
                    │  4.4 Generate OT Summary                      │
                    │     ┌──────────────────────┐                │
                    │     │ Calculate OT Stats   │                │
                    │     │ Total Hours          │                │
                    │     └──────────┬───────────┘                │
                    │                │                             │
                    │                │ Read from D4                │
                    │                │                             │
                    │                ▼                             │
                    │         ┌──────────┐                        │
                    │         │   D4     │                        │
                    │         │Overtime  │                        │
                    │         │ Database │                        │
                    │         └──────────┘                        │
                    │                                               │
                    └───────────────────────────────────────────────┘
                           │
                           │ OT Summary / OT History
                           │
                    ┌──────▼───────┐      ┌──────▼───────┐
                    │   E1:        │      │   E2:        │
                    │  พนักงาน      │      │ ผู้บริหาร     │
                    │ (Employee)   │      │ (Manager)    │
                    └──────────────┘      └──────────────┘
```

---

## Data Stores (D)

### D1: User Database
- **Tables:**
  - `login` (user_id, username, password, role, email)
  - `employees` (employee_id, user_id, first_name, last_name, department, position, base_salary, manager_id)
  - `salary_history` (id, employee_id, salary_amount, effective_date)

### D2: Attendance Database
- **Tables:**
  - `attendance` (id, user_id, date, check_in_time, check_out_time, work_hours, status, location)

### D3: Leave Database
- **Tables:**
  - `leaves` (id, user_id, leave_type, start_date, end_date, reason, status, approved_by, approved_at, rejection_reason)

### D4: Overtime Database
- **Tables:**
  - `overtime_requests` (id, user_id, date, start_time, end_time, total_hours, reason, status, approved_by, approved_at, rejection_reason)
  - `overtime_rates` (id, rate_type, multiplier, description)

### D5: Salary Database
- **Tables:**
  - `salary_history` (id, employee_id, salary_amount, effective_date)
  - (ใช้ร่วมกับ D1)

### D6: Notification Database
- **Tables:**
  - `notifications` (id, user_id, title, message, type, leave_id, overtime_request_id, is_read, created_at)

---

## External Entities

### E1: พนักงาน (Employee)
- **Role:** employee
- **Functions:**
  - Check-in/Check-out
  - Request Leave
  - Request Overtime
  - View Salary
  - View Profile
  - View Notifications

### E2: ผู้บริหาร (Manager)
- **Role:** manager
- **Functions:**
  - Approve/Reject Leave (เฉพาะแผนกเดียวกัน)
  - Approve/Reject OT (เฉพาะแผนกเดียวกัน)
  - View Reports (แผนกเดียวกัน)
  - View Notifications

### E3: Admin/HR
- **Role:** admin
- **Functions:**
  - Employee Management (CRUD)
  - Salary Management
  - View All Reports
  - Export Reports (Excel, PDF, CSV)
  - Approve/Reject Leave (ทุกคน)
  - View Notifications

---

## Data Flow Summary

### Employee Flows:
1. **Login** → 1.0 Authentication → D1 → Response
2. **Check-in** → 2.0 Attendance → D2 → Notification → 7.0 Notification → D6
3. **Request Leave** → 3.0 Leave → D3 → Notification (to Manager) → 7.0 Notification → D6
4. **Request OT** → 4.0 Overtime → D4 → Notification (to Manager) → 7.0 Notification → D6
5. **View Salary** → 5.0 Salary → D1, D2, D3, D4, D5 → Salary Summary
6. **View Profile** → 8.0 Profile → D1 → Profile Info
7. **View Notifications** → 7.0 Notification → D6 → Notification List

### Manager Flows:
1. **Login** → 1.0 Authentication → D1 → Response
2. **Approve/Reject Leave** → 3.0 Leave → D3 → Notification (to Employee) → 7.0 Notification → D6
3. **Approve/Reject OT** → 4.0 Overtime → D4 → Notification (to Employee) → 7.0 Notification → D6
4. **View Reports** → 2.0 Attendance, 3.0 Leave, 4.0 Overtime → Reports

### Admin/HR Flows:
1. **Login** → 1.0 Authentication → D1 → Response
2. **Employee Management** → 6.0 Employee → D1 → Employee List/Details
3. **Salary Management** → 5.0 Salary → D1, D2, D3, D4, D5 → Payroll Overview
4. **Export Reports** → 2.0 Attendance, 3.0 Leave → Excel/PDF/CSV Reports
5. **View All Reports** → All Processes → Comprehensive Reports

---

## ตารางสรุป Data Flows

| From | To | Data Flow | Description |
|------|-----|-----------|-------------|
| E1 (Employee) | 1.0 Authentication | Login Credentials | Username, Password |
| 1.0 Authentication | E1 | Authentication Response | Token, User Info |
| E1 | 2.0 Attendance | Check-in/Check-out Data | Time, Location, QR Code |
| 2.0 Attendance | D2 | Attendance Records | Check-in/out times, Work hours |
| E1 | 3.0 Leave | Leave Request Data | Leave type, Dates, Reason |
| 3.0 Leave | D3 | Leave Records | Leave request details |
| 3.0 Leave | 7.0 Notification | Notification Trigger | When leave is approved/rejected |
| E1 | 4.0 Overtime | OT Request Data | Date, Time range, Reason |
| 4.0 Overtime | D4 | OT Records | OT request details |
| 4.0 Overtime | 7.0 Notification | Notification Trigger | When OT is approved/rejected |
| E1 | 5.0 Salary | Salary View Request | Month, Year |
| 5.0 Salary | D1, D2, D3, D4, D5 | Read Salary Data | Employee info, Attendance, Leave, OT, Salary history |
| E1 | 8.0 Profile | Profile Update Data | Name, Email, etc. |
| 8.0 Profile | D1 | Profile Data | Updated profile information |
| E2 (Manager) | 3.0 Leave | Leave Approval/Rejection | Action, Rejection reason |
| E2 | 4.0 Overtime | OT Approval/Rejection | Action, Rejection reason |
| E3 (Admin/HR) | 6.0 Employee | Employee CRUD Data | Create, Update, Delete employee |
| E3 | 5.0 Salary | Payroll Calculation Request | Month, Year |
| 7.0 Notification | D6 | Notification Data | Title, Message, Type, User ID |
| D6 | E1, E2, E3 | Notification List | Unread notifications |

---

## การแมปกับระบบจริง (System Mapping)

### Backend Routes → Processes

| Process | Backend Route File | Main Endpoints |
|---------|-------------------|----------------|
| 1.0 Authentication | `backend/routes/auth.js` | POST /api/auth/login, POST /api/auth/register |
| 2.0 Attendance | `backend/routes/attendance.js` | POST /api/attendance/check-in, POST /api/attendance/check-out, GET /api/attendance/today |
| 3.0 Leave | `backend/routes/leave.js` | POST /api/leave/request, PUT /api/leave/:id/status, GET /api/leave/summary |
| 4.0 Overtime | `backend/routes/overtime.js` | POST /api/overtime/request, PUT /api/overtime/approve/:id, GET /api/overtime/pending |
| 5.0 Salary | `backend/routes/salary.js`, `backend/routes/hr.js` | GET /api/salary/summary, GET /api/hr/payroll/overview |
| 6.0 Employee | `backend/routes/employees.js`, `backend/routes/admin.js` | GET /api/employees, POST /api/admin/employees, PUT /api/admin/employees/:id |
| 7.0 Notification | `backend/routes/notifications.js` | GET /api/notifications, PATCH /api/notifications/:id/read |
| 8.0 Profile | `backend/routes/profile.js` | GET /api/profile, PUT /api/profile, PUT /api/profile/password |

### Frontend Screens → Processes

| Process | Frontend Screen Files |
|---------|----------------------|
| 1.0 Authentication | `lib/login/login_screen.dart`, `lib/register/register_screen.dart` |
| 2.0 Attendance | `lib/screens/check_in_screen.dart`, `lib/screens/qr_scanner_screen.dart`, `lib/screens/qr_check_in_form_screen.dart` |
| 3.0 Leave | `lib/screens/request_leave_screen.dart`, `lib/screens/leave_history_screen.dart`, `lib/screens/admin/leave_management_screen.dart` |
| 4.0 Overtime | `lib/screens/request_overtime_screen.dart`, `lib/screens/overtime_history_screen.dart`, `lib/screens/admin/overtime_approval_screen.dart` |
| 5.0 Salary | `lib/screens/salary_screen.dart`, `lib/screens/admin/hr_salary_dashboard_screen.dart` |
| 6.0 Employee | `lib/screens/admin/employee_management_screen.dart`, `lib/screens/admin/admin_dashboard.dart` |
| 7.0 Notification | `lib/screens/notifications_screen.dart` |
| 8.0 Profile | `lib/screens/profile_screen.dart`, `lib/screens/edit_profile_screen.dart`, `lib/screens/change_password_screen.dart` |

### Database Tables → Data Stores

| Data Store | Database Tables |
|-----------|----------------|
| D1: User Database | `login`, `employees`, `salary_history` |
| D2: Attendance Database | `attendance` |
| D3: Leave Database | `leaves` |
| D4: Overtime Database | `overtime_requests`, `overtime_rates` |
| D5: Salary Database | `salary_history` (shared with D1) |
| D6: Notification Database | `notifications` |

---

## สรุป

DFD นี้แสดงให้เห็นถึง:
1. **Context Diagram (Level 0):** แสดงความสัมพันธ์ระหว่างระบบกับ External Entities (พนักงาน, ผู้บริหาร, Admin/HR)
2. **Level 1 DFD:** แสดงกระบวนการหลัก 8 กระบวนการและ Data Stores ที่เกี่ยวข้อง พร้อม Data Flows ระหว่าง Processes
3. **Data Flows:** แสดงการไหลของข้อมูลระหว่าง Processes, Data Stores, และ External Entities
4. **Real System Mapping:** DFD นี้สอดคล้องกับระบบจริงที่มี:
   - **Backend Routes:** auth.js, attendance.js, leave.js, overtime.js, salary.js, hr.js, admin.js, employees.js, notifications.js, profile.js
   - **Frontend Screens:** home_screen, check_in_screen, request_leave_screen, request_overtime_screen, salary_screen, admin_dashboard, notifications_screen, profile_screen, etc.
   - **Database Tables:** login, employees, attendance, leaves, overtime_requests, notifications, salary_history
   - **Services:** AuthService, AttendanceService, LeaveService, OvertimeService, SalaryService, NotificationService, etc.

### ฟีเจอร์หลักที่ครอบคลุม:
- ✅ Authentication & Authorization (Login, Register)
- ✅ Attendance Management (Check-in/Check-out, QR Scanner)
- ✅ Leave Management (Request, Approve/Reject, History)
- ✅ Overtime Management (Request, Approve/Reject, History)
- ✅ Salary Management (View Salary, Payroll Overview, Calculations)
- ✅ Employee Management (CRUD Operations)
- ✅ Notification System (Real-time notifications for approvals/rejections)
- ✅ Profile Management (View, Update, Change Password)
- ✅ Report Generation (Excel, PDF, CSV exports)
