// Test script สำหรับทดสอบการอนุมัติการลา
const http = require('http');

// ข้อมูลทดสอบ - ต้องแก้ไขตามข้อมูลจริง
const leaveId = 1; // เปลี่ยนเป็น ID ของการลาที่ต้องการทดสอบ
const token = 'your-jwt-token-here'; // เปลี่ยนเป็น JWT token จาก login

const data = JSON.stringify({
  status: 'approved'
});

const options = {
  hostname: 'localhost',
  port: 3000,
  path: `/api/leave/${leaveId}/status`,
  method: 'PATCH',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
    'Content-Length': data.length
  }
};

console.log(`Testing leave approval API...`);
console.log(`URL: http://${options.hostname}:${options.port}${options.path}`);
console.log(`Method: ${options.method}`);
console.log(`Data: ${data}`);

const req = http.request(options, (res) => {
  console.log(`\nStatus Code: ${res.statusCode}`);
  console.log(`Headers:`, res.headers);

  let responseData = '';

  res.on('data', (chunk) => {
    responseData += chunk;
  });

  res.on('end', () => {
    console.log(`\nResponse Body:`, responseData);
    try {
      const json = JSON.parse(responseData);
      console.log(`\nParsed JSON:`, JSON.stringify(json, null, 2));
    } catch (e) {
      console.log(`\nResponse is not JSON`);
    }
  });
});

req.on('error', (error) => {
  console.error(`\nError:`, error.message);
});

req.write(data);
req.end();
