import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../login/login_screen.dart';
import 'employee_management_screen.dart';
import 'attendance_management_screen.dart';
import 'leave_management_screen.dart';
import 'hr_dashboard_screen.dart';
import 'hr_salary_dashboard_screen.dart';
import 'overtime_approval_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // ตรวจสอบว่า user เป็น admin หรือไม่
    if (user == null || !user.isAdmin) {
      // ถ้าไม่ใช่ admin ให้ redirect ไปหน้า home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/home');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              try {
                print('[AdminDashboard] Logout button pressed');
                final attendanceService = Provider.of<AttendanceService>(context, listen: false);
                // Clear attendance data เมื่อ logout
                attendanceService.clearAttendance();
                print('[AdminDashboard] Attendance cleared');
                
                await authService.logout();
                print('[AdminDashboard] Auth service logged out');
                
                // รอสักครู่เพื่อให้แน่ใจว่า logout เสร็จ
                await Future.delayed(const Duration(milliseconds: 100));
                
                if (context.mounted) {
                  print('[AdminDashboard] Navigating to login screen');
                  // ลบ navigation stack ทั้งหมดและไปหน้า login โดยใช้ MaterialPageRoute
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                      settings: const RouteSettings(name: '/login'),
                    ),
                    (route) => false,
                  );
                  print('[AdminDashboard] Navigation completed');
                } else {
                  print('[AdminDashboard] Context not mounted, cannot navigate');
                }
              } catch (e) {
                print('[AdminDashboard] Error during logout: $e');
                // ถ้าเกิด error ให้ลอง navigate อีกครั้ง
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user?.fullName ?? 'Admin'}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Administrator',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // HR Dashboard Section
            const Text(
              'HR Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildManagementCard(
              context,
              title: 'สรุปข้อมูลวันลา',
              subtitle: 'ดูสรุปวันลาของพนักงานทั้งหมด และข้อมูลสำหรับผู้บริหาร',
              icon: Icons.dashboard,
              color: const Color(0xFF9C27B0),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HRDashboardScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildManagementCard(
              context,
              title: 'จัดการเงินเดือน',
              subtitle: 'ดูและจัดการข้อมูลเงินเดือนของพนักงานทั้งหมด',
              icon: Icons.attach_money,
              color: const Color(0xFF4CAF50),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HrSalaryDashboardScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Management Cards
            const Text(
              'Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildManagementCard(
              context,
              title: 'จัดการพนักงาน',
              subtitle: 'เพิ่ม แก้ไข ลบข้อมูลพนักงาน',
              icon: Icons.people,
              color: const Color(0xFF4CAF50),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EmployeeManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildManagementCard(
              context,
              title: 'จัดการการเข้างาน',
              subtitle: 'ดูและจัดการข้อมูลการเข้า-ออกงาน',
              icon: Icons.access_time,
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AttendanceManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildManagementCard(
              context,
              title: 'จัดการการลางาน',
              subtitle: 'อนุมัติ/ปฏิเสธคำขอลางาน',
              icon: Icons.event_busy,
              color: const Color(0xFFFF9800),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LeaveManagementScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

