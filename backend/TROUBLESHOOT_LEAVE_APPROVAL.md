# แก้ไขปัญหา: Manager อนุมัติการลาไม่ได้

## วิธีตรวจสอบปัญหา

### 1. ตรวจสอบ Log ใน Backend Console

เมื่อ manager กดอนุมัติการลา จะเห็น log ใน backend console:

```
[Leave Approval] Request received: leaveId=X, status=approved, approverId=Y, role=manager
[Leave Approval] Manager user_id Y info: [...]
[Leave Approval] Manager แผนก: Engineering
[Leave Approval] Leave ID X info: [...]
[Leave Approval] เปรียบเทียบแผนก - Manager: Engineering, Employee: Engineering
[Leave Approval] แผนกตรงกัน - อนุญาตให้อนุมัติ
[Leave Approval] อัปเดตสถานะการลา ID X เป็น approved โดย user_id Y
```

### 2. ตรวจสอบ Log ใน Flutter Console

เมื่อ manager กดอนุมัติการลา จะเห็น log ใน Flutter console:

```
[Leave Approval] User clicked approve for leaveId: X
[Leave Approval] Sending request: leaveId=X, status=approved
[Leave Approval] Response status: 200
[Leave Approval] Response body: {...}
```

### 3. ตรวจสอบข้อมูลใน Database

รัน SQL script เพื่อตรวจสอบ:

```bash
mysql -u root -p humans < backend/debug_leave_approval.sql
```

## ปัญหาที่เป็นไปได้และวิธีแก้ไข

### ปัญหา 1: Manager ไม่มี department

**ตรวจสอบ:**
```sql
SELECT l.user_id, l.username, e.department
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.role = 'manager';
```

**แก้ไข:**
```sql
UPDATE employees
SET department = 'Engineering'
WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira');
```

### ปัญหา 2: การลาไม่สามารถ join กับ employees ได้

**ตรวจสอบ:**
```sql
SELECT lv.id, lv.user_id, e.employee_id, e.department
FROM leaves lv
LEFT JOIN employees e ON lv.user_id = e.employee_id
WHERE lv.status = 'pending';
```

**แก้ไข:**
```sql
-- แก้ไขการลาที่ใช้ login.user_id แทน employee_id
UPDATE leaves lv
INNER JOIN login l_login ON lv.user_id = l_login.user_id
INNER JOIN employees e ON l_login.user_id = e.user_id
SET lv.user_id = e.employee_id
WHERE lv.user_id = l_login.user_id
  AND lv.user_id != e.employee_id;
```

### ปัญหา 3: แผนกไม่ตรงกัน (case sensitive หรือ whitespace)

**ตรวจสอบ:**
```sql
SELECT 
  m.department as manager_dept,
  e.department as employee_dept,
  m.department = e.department as exact_match,
  TRIM(m.department) = TRIM(e.department) as trimmed_match
FROM (
  SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'jira')
) m
CROSS JOIN (
  SELECT department FROM employees WHERE user_id = (SELECT user_id FROM login WHERE username = 'montita')
) e;
```

**แก้ไข:**
```sql
-- แก้ไข department ให้ตรงกัน (trim และ lowercase)
UPDATE employees
SET department = TRIM(department)
WHERE department IS NOT NULL;
```

## วิธีทดสอบ

1. **ตรวจสอบ Backend Log:**
   - ดู log ใน backend console เมื่อกดอนุมัติ
   - ตรวจสอบ error message

2. **ตรวจสอบ Frontend Log:**
   - ดู log ใน Flutter console
   - ตรวจสอบ response status และ body

3. **ทดสอบด้วย SQL:**
   - รัน `backend/debug_leave_approval.sql`
   - ตรวจสอบว่าข้อมูลถูกต้องหรือไม่

## สิ่งที่แก้ไขแล้ว

1. ✅ เพิ่ม logging ใน backend
2. ✅ เพิ่ม logging ใน frontend
3. ✅ ปรับปรุง error handling
4. ✅ แก้ไข query ให้รองรับทั้งสองกรณี (employee_id และ login.user_id)
5. ✅ เพิ่มการตรวจสอบแผนกที่ละเอียดขึ้น

ลองทดสอบอีกครั้งและดู log ใน console เพื่อหาสาเหตุที่แท้จริง

