const { pool } = require('./db');

async function insertTestLeaves() {
  let connection;
  try {
    console.log('🔄 กำลังเชื่อมต่อฐานข้อมูล...');
    connection = await pool.getConnection();
    
    console.log('📝 กำลังใส่ข้อมูลทดสอบวันลา...');
    
    await connection.execute(`
      INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES
      (2, 'sick', DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_SUB(CURDATE(), INTERVAL 8 DAY), 'ไม่สบาย มีไข้', 'approved'),
      (2, 'personal', DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_SUB(CURDATE(), INTERVAL 3 DAY), 'ธุระส่วนตัว', 'approved'),
      (3, 'sick', DATE_SUB(CURDATE(), INTERVAL 7 DAY), DATE_SUB(CURDATE(), INTERVAL 6 DAY), 'ป่วย', 'approved'),
      (2, 'personal', DATE_ADD(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'ลาพักผ่อน', 'pending'),
      (3, 'personal', DATE_ADD(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 12 DAY), 'ลากิจ', 'pending')
    `);
    
    console.log('✅ ใส่ข้อมูลทดสอบวันลาสำเร็จ!');
    
    // ตรวจสอบข้อมูล
    const [leaves] = await connection.execute(`
      SELECT id, user_id, leave_type, start_date, end_date, reason, status 
      FROM leaves 
      ORDER BY created_at DESC
      LIMIT 10
    `);
    
    console.log('\n📊 ข้อมูลวันลาที่มีในระบบ:');
    console.table(leaves);
    
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      console.log('⚠️  ข้อมูลบางส่วนมีอยู่แล้ว (อาจจะรัน script นี้ไปแล้ว)');
      console.log('💡 ถ้าต้องการใส่ใหม่ ให้ลบข้อมูลเก่าก่อน: DELETE FROM leaves;');
    } else {
      console.error('❌ เกิดข้อผิดพลาด:', error.message);
      console.error('รายละเอียด:', error);
    }
  } finally {
    if (connection) connection.release();
    process.exit();
  }
}

insertTestLeaves();

