-- ===========================
-- ตั้งค่า amm (user_id = 8) เป็น Manager แผนก Accounting
-- ===========================
USE humans;

-- ขั้นตอนที่ 1: เพิ่มคอลัมน์ is_manager ถ้ายังไม่มี
-- (ถ้ามีแล้วจะ error แต่ไม่เป็นไร - ข้ามไปได้)
SET @col_exists = (
  SELECT COUNT(*) 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = 'humans' 
    AND TABLE_NAME = 'employees' 
    AND COLUMN_NAME = 'is_manager'
);

SET @sql = IF(@col_exists = 0,
  'ALTER TABLE employees ADD COLUMN is_manager TINYINT(1) DEFAULT 0 AFTER department',
  'SELECT "Column is_manager already exists, skipping..." as message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- เพิ่ม index เพื่อเพิ่มประสิทธิภาพ (ถ้ายังไม่มี)
-- หมายเหตุ: ถ้า index มีอยู่แล้วจะ error แต่ไม่เป็นไร
SET @idx_exists = (
  SELECT COUNT(*) 
  FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = 'humans' 
    AND TABLE_NAME = 'employees' 
    AND INDEX_NAME = 'idx_is_manager'
);

SET @sql_idx = IF(@idx_exists = 0,
  'CREATE INDEX idx_is_manager ON employees(is_manager)',
  'SELECT "Index idx_is_manager already exists, skipping..." as message'
);

PREPARE stmt_idx FROM @sql_idx;
EXECUTE stmt_idx;
DEALLOCATE PREPARE stmt_idx;

-- ขั้นตอนที่ 2: ตั้ง role ใน login table
UPDATE login
SET role = 'manager'
WHERE user_id = 8;

-- ขั้นตอนที่ 3: ตั้ง is_manager และ department ใน employees table
UPDATE employees
SET 
  department = 'Accounting',
  is_manager = 1
WHERE user_id = 8;

-- ขั้นตอนที่ 4: ตรวจสอบผลลัพธ์
SELECT 
  '=== ผลลัพธ์การตั้งค่า amm (user_id = 8) ===' as '';
  
SELECT 
  l.user_id,
  l.username,
  l.role,
  e.employee_id,
  CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) as employee_name,
  e.position,
  e.department,
  e.is_manager,
  CASE 
    WHEN l.role = 'manager' AND e.is_manager = 1 AND e.department = 'Accounting' 
    THEN '✅ ตั้งค่าเรียบร้อยแล้ว'
    ELSE '❌ ยังไม่ครบถ้วน'
  END as status
FROM login l
LEFT JOIN employees e ON l.user_id = e.user_id
WHERE l.user_id = 8;

