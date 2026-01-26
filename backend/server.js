const express = require('express');
const cors = require('cors');
const config = require('./config');
const { testConnection } = require('./db');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Test MySQL Connection
testConnection();

// Import Routes
const authRoutes = require('./routes/auth');
const employeesRoutes = require('./routes/employees');
const attendanceRoutes = require('./routes/attendance');
const leaveRoutes = require('./routes/leave');
const profileRoutes = require('./routes/profile');
const adminRoutes = require('./routes/admin');
const notificationsRoutes = require('./routes/notifications');
const hrRoutes = require('./routes/hr');
const salaryRoutes = require('./routes/salary');
const overtimeRoutes = require('./routes/overtime');

// Use Routes
app.use('/api', authRoutes);
app.use('/api/employees', employeesRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/leave', leaveRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/hr', hrRoutes);
app.use('/api/salary', salaryRoutes);
app.use('/api/overtime', overtimeRoutes);

// Health Check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Humans HR Backend is running',
    timestamp: new Date().toISOString()
  });
});

// Error Handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    message: 'Something went wrong!',
    error: err.message 
  });
});

// Start Server
const PORT = config.port;
app.listen(PORT, () => {
  console.log(`🚀 Humans HR Backend running on http://localhost:${PORT}`);
  console.log(`📊 Database: ${config.db.database}@${config.db.host}:${config.db.port}`);
});

