import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../models/attendance_model.dart';
import '../widgets/daily_work_card.dart';
import '../widgets/action_button.dart';
import 'check_in_screen.dart';
import 'request_leave_screen.dart';
import 'qr_scanner_screen.dart';
import 'salary_screen.dart';
import 'admin/leave_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ไม่โหลด attendance เมื่อเปิดหน้า
    // จะแสดงเวลาเฉพาะเมื่อมีการ check-in/check-out แล้ว
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ไม่ต้อง refresh attendance เมื่อกลับมาหน้าจอ
    // จะแสดงข้อมูลเฉพาะหลังจาก check-in/check-out แล้ว
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final attendanceService = Provider.of<AttendanceService>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu, color: Colors.black87),
              ),
              onPressed: () {
                // Handle menu tap
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              // ขยับข้อความขึ้นไปด้านบนและให้ดูเล็กลง
              titlePadding: const EdgeInsets.only(left: 80, bottom: 8),
              title: Text(
                'Welcome, ${user.shortName}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // User Profile Section
                _buildUserProfileSection(user),
                const SizedBox(height: 24),
                // Daily Work Card
                Consumer<AttendanceService>(
                  builder: (context, service, child) {
                    final attendance = service.todayAttendance;
                    final checkInTime = attendance?.checkInTime;
                    final checkOutTime = attendance?.checkOutTime;
                    print('[HomeScreen] Consumer rebuilt - checkInTime: ${attendance?.checkInTimeFormatted ?? "null"}, checkOutTime: ${attendance?.checkOutTimeFormatted ?? "null"}');
                    
                    // ใช้ key เพื่อ force rebuild เมื่อ checkInTime หรือ checkOutTime เปลี่ยน
                    return DailyWorkCard(
                      key: ValueKey('attendance_${checkInTime?.millisecondsSinceEpoch ?? "null"}_${checkOutTime?.millisecondsSinceEpoch ?? "null"}'),
                      attendance: attendance,
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Action Buttons
                _buildActionButtons(context, attendanceService),
                const SizedBox(height: 24),
                // Manager Section (for non-admin users)
                _buildManagerSection(context, user),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white,
              backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? FileImage(File(user.avatarUrl!))
                  : null,
              child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF2196F3),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.position,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AttendanceService attendanceService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ActionButton(
                icon: Icons.login,
                label: 'เข้างาน',
                color: Colors.green,
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CheckInScreen(),
                    ),
                  );
                  if (result == true) {
                    if (mounted) {
                      // โหลดข้อมูล attendance จาก API เพื่อให้แน่ใจว่าข้อมูลตรงกับ backend
                      final service = Provider.of<AttendanceService>(context, listen: false);
                      await service.loadTodayAttendance();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('เช็คอินสำเร็จ'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionButton(
                icon: Icons.logout,
                label: 'ออกงาน',
                color: Colors.orange,
                onTap: () async {
                  final success = await attendanceService.checkOut();
                  if (success) {
                    // Refresh attendance after check-out (already done in checkOut method)
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('เช็คเอาท์สำเร็จ'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('เช็คเอาท์ล้มเหลว กรุณาลองอีกครั้ง'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                icon: Icons.calendar_month,
                label: 'ลางาน',
                color: Colors.blue,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RequestLeaveScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionButton(
                icon: Icons.attach_money,
                label: 'เงินเดือน',
                color: Colors.purple,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SalaryScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagerSection(BuildContext context, user) {
    // แสดงเฉพาะเมื่อ user เป็น manager (role = 'manager')
    // Admin จะใช้ Admin Dashboard แทน
    final isAdmin = user.isAdmin;
    final isManager = user.isManagerRole;
    
    if (isAdmin || !isManager) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'หัวหน้าแผนก',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'อนุมัติการลาของทีม',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LeaveManagementScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.event_busy),
              label: const Text('อนุมัติการลา'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

