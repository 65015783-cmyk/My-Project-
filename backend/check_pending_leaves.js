// ตรวจสอบข้อมูล pending leaves
const mysql = require('mysql2/promise');
const config = require('./config');

async function checkPendingLeaves() {
  let connection;
  try {
    connection = await mysql.createConnection({
      host: config.db.host,
      user: config.db.user,
      password: config.db.password,
      database: config.db.database,
    });

    console.log('✅ เชื่อมต่อ database สำเร็จ\n');

    // ตรวจสอบข้อมูล leaves ทั้งหมด
    console.log('📋 ข้อมูล leaves ทั้งหมด:');
    const [allLeaves] = await connection.execute(
      'SELECT id, user_id, leave_type, start_date, end_date, reason, status FROM leaves ORDER BY created_at DESC'
    );
    console.table(allLeaves);

    // ตรวจสอบ pending leaves
    console.log('\n📋 ข้อมูล pending leaves:');
    const [pendingLeaves] = await connection.execute(
      'SELECT id, user_id, leave_type, start_date, end_date, reason, status FROM leaves WHERE status = "pending"'
    );
    console.table(pendingLeaves);

    // ตรวจสอบข้อมูล employees
    console.log('\n📋 ข้อมูล employees:');
    const [employees] = await connection.execute(
      'SELECT employee_id, user_id, first_name, last_name, department FROM employees'
    );
    console.table(employees);

    // ตรวจสอบ JOIN query (เหมือนที่ admin ใช้)
    console.log('\n📋 ข้อมูล pending leaves พร้อม employee info (เหมือน admin query):');
    const [joinedLeaves] = await connection.execute(`
      SELECT 
        lv.id,
        lv.user_id as employee_id,
        lv.leave_type,
        lv.start_date,
        lv.end_date,
        DATEDIFF(lv.end_date, lv.start_date) + 1 as total_days,
        lv.reason,
        lv.status,
        lv.created_at,
        CONCAT(e.first_name, ' ', e.last_name) as employee_name,
        e.position,
        e.department,
        l.email as employee_email
      FROM leaves lv
      LEFT JOIN employees e ON lv.user_id = e.employee_id
      LEFT JOIN login l ON e.user_id = l.user_id
      WHERE lv.status = 'pending'
      ORDER BY lv.created_at DESC
    `);
    console.table(joinedLeaves);

    if (joinedLeaves.length === 0) {
      console.log('\n⚠️  ไม่มีข้อมูล pending leaves');
      console.log('💡 ลองรัน: mysql -u root -p humans < backend/create_test_pending_leaves.sql');
    } else {
      console.log(`\n✅ พบ ${joinedLeaves.length} รายการ pending leaves`);
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    if (connection) await connection.end();
  }
}

checkPendingLeaves();

