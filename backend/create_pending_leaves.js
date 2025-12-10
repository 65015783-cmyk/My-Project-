// สร้างข้อมูล pending leaves สำหรับทดสอบ
const mysql = require('mysql2/promise');
const config = require('./config');

async function createPendingLeaves() {
  let connection;
  try {
    connection = await mysql.createConnection({
      host: config.db.host,
      user: config.db.user,
      password: config.db.password,
      database: config.db.database,
    });

    console.log('✅ เชื่อมต่อ database สำเร็จ\n');

    // ตรวจสอบข้อมูล employees
    const [employees] = await connection.execute(
      'SELECT employee_id, user_id, first_name, last_name, department FROM employees'
    );
    console.log('📋 ข้อมูล employees:');
    console.table(employees);

    // สร้างข้อมูล pending leaves
    console.log('\n🔨 กำลังสร้างข้อมูล pending leaves...\n');

    const today = new Date();
    const insertQueries = [
      // Montita (employee_id = 2, Engineering)
      [
        'INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES (?, ?, ?, ?, ?, ?)',
        [2, 'sick', new Date(today.getTime() + 2 * 24 * 60 * 60 * 1000), new Date(today.getTime() + 3 * 24 * 60 * 60 * 1000), 'ไม่สบาย มีไข้ ต้องพักผ่อน', 'pending']
      ],
      [
        'INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES (?, ?, ?, ?, ?, ?)',
        [2, 'personal', new Date(today.getTime() + 10 * 24 * 60 * 60 * 1000), new Date(today.getTime() + 12 * 24 * 60 * 60 * 1000), 'ลาพักผ่อน ไปเที่ยวกับครอบครัว', 'pending']
      ],
      // สมศักดิ์ (employee_id = 3, Human Resources)
      [
        'INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES (?, ?, ?, ?, ?, ?)',
        [3, 'sick', new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000), new Date(today.getTime() + 6 * 24 * 60 * 60 * 1000), 'ป่วย ต้องไปพบแพทย์', 'pending']
      ],
      [
        'INSERT INTO leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES (?, ?, ?, ?, ?, ?)',
        [3, 'personal', new Date(today.getTime() + 15 * 24 * 60 * 60 * 1000), new Date(today.getTime() + 16 * 24 * 60 * 60 * 1000), 'ลากิจส่วนตัว มีธุระสำคัญ', 'pending']
      ],
    ];

    for (const [query, params] of insertQueries) {
      try {
        await connection.execute(query, params);
        console.log(`✅ สร้างข้อมูลสำเร็จ: ${params[1]} leave for employee_id ${params[0]}`);
      } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
          console.log(`⚠️  ข้อมูลซ้ำ (ข้าม): employee_id ${params[0]}`);
        } else {
          console.error(`❌ Error: ${error.message}`);
        }
      }
    }

    // ตรวจสอบผลลัพธ์
    console.log('\n📋 ข้อมูล pending leaves หลังสร้าง:');
    const [pendingLeaves] = await connection.execute(`
      SELECT 
        lv.id,
        lv.user_id as employee_id,
        CONCAT(e.first_name, ' ', e.last_name) as employee_name,
        e.department,
        lv.leave_type,
        lv.start_date,
        lv.end_date,
        lv.status
      FROM leaves lv
      LEFT JOIN employees e ON lv.user_id = e.employee_id
      WHERE lv.status = 'pending'
      ORDER BY lv.created_at DESC
    `);
    console.table(pendingLeaves);

    console.log(`\n✅ สร้างข้อมูลสำเร็จ! มี ${pendingLeaves.length} รายการ pending leaves`);
    console.log('💡 ตอนนี้ admin ควรเห็นข้อมูลในหน้า "การจัดการการลา" แล้ว');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    if (connection) await connection.end();
  }
}

createPendingLeaves();

