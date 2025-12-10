module.exports = {
  port: process.env.PORT || 3000,
  jwtSecret: process.env.JWT_SECRET || 'your-secret-key-change-this-in-production',
  db: {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'humans_app', // เปลี่ยนจาก root เป็น humans_app
    password: process.env.DB_PASSWORD || '12345678',
    database: process.env.DB_NAME || 'humans',
    port: process.env.DB_PORT || 3306,
  }
};

