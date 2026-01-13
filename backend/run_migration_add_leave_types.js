const { pool } = require('./db');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  let connection;
  try {
    console.log('🔄 กำลังรัน migration: เพิ่ม leave_type "early" และ "half_day"...\n');
    
    connection = await pool.getConnection();
    
    // ตรวจสอบค่า leave_type ปัจจุบัน
    console.log('📋 ตรวจสอบค่า leave_type ปัจจุบัน...');
    const [currentType] = await connection.execute(`
      SELECT COLUMN_TYPE 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = 'humans' 
        AND TABLE_NAME = 'leaves' 
        AND COLUMN_NAME = 'leave_type'
    `);
    
    if (currentType.length > 0) {
      console.log('   ค่า leave_type ปัจจุบัน:', currentType[0].COLUMN_TYPE);
    }
    
    // แก้ไข ENUM เพื่อเพิ่ม 'early' และ 'half_day'
    console.log('\n🔧 กำลังแก้ไข ENUM เพื่อเพิ่ม "early" และ "half_day"...');
    await connection.execute(`
      ALTER TABLE leaves 
      MODIFY COLUMN leave_type ENUM('sick', 'personal', 'vacation', 'other', 'early', 'half_day') NOT NULL
    `);
    
    console.log('✅ แก้ไข ENUM สำเร็จ!');
    
    // ตรวจสอบค่า leave_type หลัง migration
    console.log('\n📋 ตรวจสอบค่า leave_type หลัง migration...');
    const [newType] = await connection.execute(`
      SELECT COLUMN_TYPE 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = 'humans' 
        AND TABLE_NAME = 'leaves' 
        AND COLUMN_NAME = 'leave_type'
    `);
    
    if (newType.length > 0) {
      console.log('   ค่า leave_type ใหม่:', newType[0].COLUMN_TYPE);
    }
    
    console.log('\n✅ Migration สำเร็จ! ตอนนี้สามารถใช้ leave_type "early" และ "half_day" ได้แล้ว');
    
  } catch (error) {
    console.error('\n❌ เกิดข้อผิดพลาดในการรัน migration:', error.message);
    if (error.code === 'ER_DUP_FIELDNAME') {
      console.log('   หมายเหตุ: ค่า leave_type อาจมีอยู่แล้ว');
    }
    process.exit(1);
  } finally {
    if (connection) connection.release();
    process.exit(0);
  }
}

runMigration();

