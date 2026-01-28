-- เพิ่ม column evidence_image_path ในตาราง overtime_requests
-- สำหรับเก็บ path ของรูปภาพหลักฐานการขอ OT
-- วิธีง่าย: รันคำสั่งนี้ได้เลย (ถ้ามีคอลัมน์อยู่แล้วจะ error แต่ไม่เป็นไร)

ALTER TABLE overtime_requests 
ADD COLUMN evidence_image_path VARCHAR(500) DEFAULT NULL 
AFTER reason;
