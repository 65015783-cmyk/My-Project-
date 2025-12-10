// ===========================
// Script สำหรับแก้ไข database schema ให้รองรับ role = 'manager'
// รัน: node fix_manager_role.js
// ===========================

const mysql = require('mysql2/promise');
const config = require('./config');

async function fixManagerRole() {
  let connection;
  try {
    console.log('🔧 กำลังเชื่อมต่อ database...');
    
    connection = await mysql.createConnection({
      host: config.db.host,
      user: config.db.user,
      password: config.db.password,
      database: config.db.database,
      multipleStatements: true
    });

    console.log('✅ เชื่อมต่อ database สำเร็จ');

    // ตรวจสอบโครงสร้างปัจจุบัน
    console.log('\n📋 ตรวจสอบโครงสร้าง role column...');
    const [columns] = await connection.execute(
      "SHOW COLUMNS FROM login WHERE Field = 'role'"
    );
    
    if (columns.length > 0) {
      console.log('โครงสร้างปัจจุบัน:', columns[0].Type);
    }

    // แก้ไข ENUM ให้รองรับ 'manager'
    console.log('\n🔨 กำลังแก้ไข role column...');
    await connection.execute(`
      ALTER TABLE login 
      MODIFY COLUMN role ENUM('admin', 'employee', 'manager') DEFAULT 'employee'
    `);

    console.log('✅ แก้ไขสำเร็จ!');

    // ตรวจสอบผลลัพธ์
    console.log('\n📋 ตรวจสอบโครงสร้างหลังแก้ไข...');
    const [updatedColumns] = await connection.execute(
      "SHOW COLUMNS FROM login WHERE Field = 'role'"
    );
    
    if (updatedColumns.length > 0) {
      console.log('โครงสร้างใหม่:', updatedColumns[0].Type);
      
      if (updatedColumns[0].Type.includes('manager')) {
        console.log('\n🎉 สำเร็จ! Database schema รองรับ role = "manager" แล้ว');
      } else {
        console.log('\n⚠️  ยังไม่พบ manager ใน ENUM');
      }
    }

    // ตรวจสอบข้อมูล user ทั้งหมด
    console.log('\n📊 ข้อมูล user ทั้งหมด:');
    const [users] = await connection.execute(
      'SELECT user_id, username, email, role FROM login ORDER BY user_id'
    );
    
    console.table(users);

    console.log('\n✅ เสร็จสิ้น! ตอนนี้สามารถใช้ role = "manager" ได้แล้ว');
    console.log('💡 Restart backend server แล้วลองเพิ่ม/แก้ไข role เป็น "Manager" อีกครั้ง');

  } catch (error) {
    console.error('\n❌ เกิดข้อผิดพลาด:');
    console.error('Error:', error.message);
    console.error('Code:', error.code);
    
    if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('\n💡 ตรวจสอบ username/password ใน config.js');
    } else if (error.code === 'ER_BAD_DB_ERROR') {
      console.error('\n💡 ตรวจสอบชื่อ database ใน config.js');
    } else {
      console.error('\n💡 ลองรัน SQL โดยตรง:');
      console.error("ALTER TABLE login MODIFY COLUMN role ENUM('admin', 'employee', 'manager') DEFAULT 'employee';");
    }
    
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\n🔌 ปิดการเชื่อมต่อ database');
    }
  }
}

// รัน script
fixManagerRole();

