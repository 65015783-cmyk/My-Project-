# วิธีรัน SQL Script

## วิธีที่ 1: MySQL Command Line (แนะนำ)

### Windows (Command Prompt หรือ PowerShell)

1. เปิด Command Prompt หรือ PowerShell
2. ไปที่โฟลเดอร์ backend:
   ```bash
   cd C:\src_flutter\hummans\backend
   ```

3. รันคำสั่ง:
   ```bash
   mysql -u root -p humans < insert_test_leaves.sql
   ```
   หรือ
   ```bash
   mysql -u root -p < insert_test_leaves.sql
   ```

4. ใส่รหัสผ่าน MySQL เมื่อถูกถาม

### หรือรันทีละคำสั่ง:

```bash
mysql -u root -p
```

จากนั้นพิมพ์คำสั่ง:
```sql
USE humans;

INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES
(2, 'sick', DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_SUB(CURDATE(), INTERVAL 8 DAY), 'ไม่สบาย มีไข้', 'approved'),
(2, 'personal', DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_SUB(CURDATE(), INTERVAL 3 DAY), 'ธุระส่วนตัว', 'approved'),
(3, 'sick', DATE_SUB(CURDATE(), INTERVAL 7 DAY), DATE_SUB(CURDATE(), INTERVAL 6 DAY), 'ป่วย', 'approved'),
(2, 'personal', DATE_ADD(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'ลาพักผ่อน', 'pending'),
(3, 'personal', DATE_ADD(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 12 DAY), 'ลากิจ', 'pending');
```

---

## วิธีที่ 2: phpMyAdmin (สำหรับ XAMPP/WAMP)

1. เปิดเว็บเบราว์เซอร์ไปที่: `http://localhost/phpmyadmin`
2. เลือก database `humans` จากเมนูด้านซ้าย
3. คลิกแท็บ "SQL" ด้านบน
4. Copy และวาง SQL script ด้านล่าง:
   ```sql
   INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES
   (2, 'sick', DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_SUB(CURDATE(), INTERVAL 8 DAY), 'ไม่สบาย มีไข้', 'approved'),
   (2, 'personal', DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_SUB(CURDATE(), INTERVAL 3 DAY), 'ธุระส่วนตัว', 'approved'),
   (3, 'sick', DATE_SUB(CURDATE(), INTERVAL 7 DAY), DATE_SUB(CURDATE(), INTERVAL 6 DAY), 'ป่วย', 'approved'),
   (2, 'personal', DATE_ADD(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'ลาพักผ่อน', 'pending'),
   (3, 'personal', DATE_ADD(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 12 DAY), 'ลากิจ', 'pending');
   ```
5. คลิกปุ่ม "Go" หรือ "ดำเนินการ"

---

## วิธีที่ 3: MySQL Workbench

1. เปิด MySQL Workbench
2. เชื่อมต่อกับ MySQL server
3. คลิกที่ database `humans` ในส่วน Navigator
4. คลิกปุ่ม "SQL" หรือกด `Ctrl+Shift+Enter`
5. Copy และวาง SQL script
6. กด `Ctrl+Enter` เพื่อรัน

---

## วิธีที่ 4: ใช้ Node.js Script (สำหรับผู้ที่ใช้ backend)

สร้างไฟล์ `insert_test_data.js` ในโฟลเดอร์ backend:

```javascript
const { pool } = require('./db');

async function insertTestLeaves() {
  let connection;
  try {
    connection = await pool.getConnection();
    
    await connection.execute(`
      INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES
      (2, 'sick', DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_SUB(CURDATE(), INTERVAL 8 DAY), 'ไม่สบาย มีไข้', 'approved'),
      (2, 'personal', DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_SUB(CURDATE(), INTERVAL 3 DAY), 'ธุระส่วนตัว', 'approved'),
      (3, 'sick', DATE_SUB(CURDATE(), INTERVAL 7 DAY), DATE_SUB(CURDATE(), INTERVAL 6 DAY), 'ป่วย', 'approved'),
      (2, 'personal', DATE_ADD(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'ลาพักผ่อน', 'pending'),
      (3, 'personal', DATE_ADD(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 12 DAY), 'ลากิจ', 'pending')
    `);
    
    console.log('✅ ใส่ข้อมูลทดสอบวันลาสำเร็จ');
  } catch (error) {
    console.error('❌ เกิดข้อผิดพลาด:', error);
  } finally {
    if (connection) connection.release();
    process.exit();
  }
}

insertTestLeaves();
```

จากนั้นรัน:
```bash
cd backend
node insert_test_data.js
```

---

## ตรวจสอบว่าข้อมูลถูกใส่แล้ว

รันคำสั่ง SQL นี้เพื่อตรวจสอบ:

```sql
SELECT id, user_id, leave_type, start_date, end_date, reason, status 
FROM leaves 
ORDER BY created_at DESC;
```

---

## หมายเหตุ

- ถ้า MySQL ไม่ได้อยู่ใน PATH ให้ใช้ full path เช่น: `C:\xampp\mysql\bin\mysql.exe`
- ถ้าใช้ XAMPP/WAMP อาจต้องใช้ username `root` และ password เป็นค่าว่าง `""`
- ถ้าเคยใส่ข้อมูลแล้ว อาจต้องลบข้อมูลเก่าก่อน:
  ```sql
  DELETE FROM leaves;
  ```

