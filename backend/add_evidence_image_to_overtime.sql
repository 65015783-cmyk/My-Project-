-- เพิ่ม column evidence_image_path ในตาราง overtime_requests
-- สำหรับเก็บ path ของรูปภาพหลักฐานการขอ OT

-- ตรวจสอบว่ามีคอลัมน์อยู่แล้วหรือไม่
SET @dbname = DATABASE();
SET @tablename = 'overtime_requests';
SET @columnname = 'evidence_image_path';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN ', @columnname, ' VARCHAR(500) DEFAULT NULL AFTER reason')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- เพิ่ม index สำหรับค้นหา (ถ้าต้องการ)
-- CREATE INDEX IF NOT EXISTS idx_evidence_image ON overtime_requests(evidence_image_path);
