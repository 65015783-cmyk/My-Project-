import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'package:intl/intl.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  List<dynamic> _pendingLeaves = [];
  String? _filterDepartment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPendingLeaves();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // รีเฟรชข้อมูลเมื่อแอปกลับมา foreground
    if (state == AppLifecycleState.resumed) {
      _loadPendingLeaves();
    }
  }

  Future<void> _loadPendingLeaves() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('[Leave Management] Loading leaves for admin...');
      final response = await http.get(
        Uri.parse(ApiConfig.leavePendingUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      print('[Leave Management] Response status: ${response.statusCode}');
      print('[Leave Management] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final leaves = data['leaves'] as List<dynamic>? ?? [];
        print('[Leave Management] Found ${leaves.length} leaves');
        if (leaves.isNotEmpty) {
          print('[Leave Management] Sample leave: ${leaves[0]}');
        }
        setState(() {
          _pendingLeaves = leaves;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถโหลดข้อมูลได้'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateLeaveStatus(int leaveId, String status, {String? rejectionReason}) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่พบ Token การยืนยันตัวตน'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('[Leave Approval] Sending request: leaveId=$leaveId, status=$status');

      final response = await http.patch(
        Uri.parse('${ApiConfig.leaveStatusUrl}/$leaveId/status'),
        headers: ApiConfig.headersWithAuth(token),
        body: json.encode({
          'status': status,
          if (rejectionReason != null && rejectionReason.isNotEmpty) 'rejectionReason': rejectionReason,
        }),
      );

      print('[Leave Approval] Response status: ${response.statusCode}');
      print('[Leave Approval] Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status == 'approved' ? 'อนุมัติสำเร็จ' : 'ปฏิเสธสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadPendingLeaves(); // Reload data
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'เกิดข้อผิดพลาด';
        print('[Leave Approval] Error: $errorMessage');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('[Leave Approval] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showApprovalDialog(int leaveId, String employeeName) {
    if (_isLoading) return; // ป้องกันการกดซ้ำ
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('อนุมัติการลา'),
        content: Text('คุณต้องการอนุมัติการลาของ $employeeName ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              print('[Leave Approval] User clicked approve for leaveId: $leaveId');
              _updateLeaveStatus(leaveId, 'approved');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('อนุมัติ'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(int leaveId, String employeeName) {
    if (_isLoading) return; // ป้องกันการกดซ้ำ
    
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปฏิเสธการลา'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('คุณต้องการปฏิเสธการลาของ $employeeName ใช่หรือไม่?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              enableSuggestions: true,
              autocorrect: true,
              maxLines: 3,
              // ไม่จำกัดการพิมพ์ - รองรับทั้งไทยและอังกฤษ
              decoration: const InputDecoration(
                labelText: 'เหตุผล (ไม่บังคับ)',
                hintText: 'กรอกเหตุผลในการปฏิเสธ...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              print('[Leave Approval] User clicked reject for leaveId: $leaveId');
              _updateLeaveStatus(
                leaveId,
                'rejected',
                rejectionReason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ปฏิเสธ'),
          ),
        ],
      ),
    );
  }

  String _formatThaiDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final thaiMonths = [
        'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
    } catch (e) {
      return dateString;
    }
  }

  String _getLeaveTypeLabel(String? type) {
    switch (type) {
      case 'sick':
        return 'ลาป่วย';
      case 'personal':
        return 'ลากิจส่วนตัว';
      case 'vacation':
        return 'ลาพักผ่อน';
      case 'early':
        return 'ลากลับก่อน';
      case 'half_day':
        return 'ลาครึ่งวัน';
      default:
        return 'ลาประเภทอื่น';
    }
  }

  Color _getLeaveTypeColor(String? type) {
    switch (type) {
      case 'sick':
        return Colors.red;
      case 'personal':
        return Colors.blue;
      case 'vacation':
        return Colors.green;
      case 'early':
        return Colors.orange;
      case 'half_day':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getDaysLabel(String? leaveType, String reason, dynamic totalDays) {
    // สำหรับลากลับก่อน
    if (leaveType == 'early') {
      return 'Leave Early';
    }
    
    // สำหรับลาครึ่งวัน
    if (leaveType == 'half_day') {
      // ตรวจสอบจาก reason ว่ามีคำว่า "เช้า" หรือ "บ่าย"
      final reasonLower = reason.toLowerCase();
      if (reasonLower.contains('เช้า') || reasonLower.contains('morning')) {
        return 'Half-day leave (Morning)';
      } else if (reasonLower.contains('บ่าย') || reasonLower.contains('afternoon')) {
        return 'Half-day leave (Afternoon)';
      }
      // ถ้าไม่พบ ให้ default เป็น Morning
      return 'Half-day leave (Morning)';
    }
    
    // สำหรับประเภทอื่นๆ แสดงจำนวนวันปกติ
    return '$totalDays วัน';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // ตรวจสอบสิทธิ์: ต้องเป็น admin หรือ manager เท่านั้น
    if (user == null || (!user.isAdmin && !user.isManagerRole)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('คุณไม่มีสิทธิ์เข้าถึงหน้านี้'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isAdminView = user.isAdmin; // Admin เห็นเฉพาะ approved/rejected, Manager เห็น pending

    // กรองตามแผนก (ถ้ามี)
    final filteredLeaves = _filterDepartment == null
        ? _pendingLeaves
        : _pendingLeaves.where((leave) => 
            leave['department']?.toString() == _filterDepartment).toList();

    // จัดกลุ่มตามแผนก
    final Map<String, List<dynamic>> leavesByDept = {};
    for (var leave in filteredLeaves) {
      final dept = leave['department']?.toString() ?? 'ไม่มีแผนก';
      if (!leavesByDept.containsKey(dept)) {
        leavesByDept[dept] = [];
      }
      leavesByDept[dept]!.add(leave);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isAdminView ? 'ประวัติการลา' : 'อนุมัติการลา',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () {
              _loadPendingLeaves();
              // อัปเดตจำนวนการแจ้งเตือนด้วย
              if (mounted) {
                final notificationService = Provider.of<NotificationService>(context, listen: false);
                notificationService.loadNotificationCount();
              }
            },
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPendingLeaves,
              child: filteredLeaves.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Summary Card
                        if (filteredLeaves.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isAdminView 
                                  ? [Colors.blue[100]!, Colors.blue[50]!]
                                  : [Colors.orange[100]!, Colors.orange[50]!],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isAdminView 
                                  ? Colors.blue[200]!
                                  : Colors.orange[200]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isAdminView ? Icons.history : Icons.pending_actions, 
                                  size: 32, 
                                  color: isAdminView ? Colors.blue[700] : Colors.orange[700],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isAdminView
                                          ? 'มี ${filteredLeaves.length} รายการที่อนุมัติ/ปฏิเสธแล้ว'
                                          : 'มี ${filteredLeaves.length} รายการรออนุมัติ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isAdminView 
                                            ? Colors.blue[900]
                                            : Colors.orange[900],
                                        ),
                                      ),
                                      Text(
                                        isAdminView
                                          ? 'ดูประวัติการอนุมัติ/ปฏิเสธการลา'
                                          : 'กรุณาพิจารณาและอนุมัติ/ปฏิเสธ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isAdminView 
                                            ? Colors.blue[700]
                                            : Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Leave Requests by Department
                        ...leavesByDept.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (leavesByDept.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'แผนก: ${entry.key}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ...entry.value.map((leave) {
                                return _buildLeaveRequestCard(leave, isAdminView);
                              }).toList(),
                              if (entry != leavesByDept.entries.last)
                                const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
            ),
    );
  }

  Widget _buildLeaveRequestCard(Map<String, dynamic> leave, bool isAdminView) {
    final leaveId = leave['id'] as int;
    final employeeId = leave['employee_id'];
    final employeeName = leave['employee_name']?.toString() ?? 'ไม่ระบุชื่อ';
    final position = leave['position']?.toString() ?? '-';
    final department = leave['department']?.toString() ?? '-';
    final employeeEmail = leave['employee_email']?.toString() ?? '';
    final leaveType = leave['leave_type']?.toString();
    final startDate = leave['start_date']?.toString() ?? '';
    final endDate = leave['end_date']?.toString() ?? '';
    final totalDays = leave['total_days'] ?? 0;
    final reason = leave['reason']?.toString() ?? '';
    final createdAt = leave['created_at']?.toString() ?? '';
    final status = leave['status']?.toString() ?? 'pending';

    // สร้าง avatar initial จากชื่อ
    String getInitials(String name) {
      final parts = name.trim().split(' ');
      if (parts.isEmpty) return '?';
      if (parts.length == 1) return parts[0][0].toUpperCase();
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Info Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getLeaveTypeColor(leaveType).withValues(alpha: 0.15),
                  _getLeaveTypeColor(leaveType).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getLeaveTypeColor(leaveType),
                        _getLeaveTypeColor(leaveType).withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getLeaveTypeColor(leaveType).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      getInitials(employeeName),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Employee Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              position,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              department,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (employeeEmail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                employeeEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Leave Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getLeaveTypeColor(leaveType),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getLeaveTypeColor(leaveType).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        leaveType == 'sick' 
                            ? Icons.medical_services 
                            : leaveType == 'personal'
                                ? Icons.person_outline
                                : leaveType == 'early'
                                    ? Icons.logout
                                    : leaveType == 'half_day'
                                        ? Icons.timelapse
                                        : Icons.beach_access,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLeaveTypeLabel(leaveType),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatThaiDate(startDate)} - ${_formatThaiDate(endDate)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        _getDaysLabel(leaveType, reason, totalDays),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Reason
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'เหตุผล',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Created At
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'ส่งเมื่อ: ${createdAt.isNotEmpty ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(createdAt).toLocal()) : '-'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Status and Approver Info (for admin view)
                if (isAdminView) ...[
                  Row(
                    children: [
                      Icon(
                        status == 'approved' ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: status == 'approved' ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'สถานะ: ${status == 'approved' ? 'อนุมัติแล้ว' : 'ปฏิเสธแล้ว'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: status == 'approved' ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (leave['approver_name'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'อนุมัติโดย: ${leave['approver_name']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (leave['approved_at'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'เมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(leave['approved_at']).toLocal())}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  // Action Buttons (only for manager)
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectionDialog(leaveId, employeeName),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('ปฏิเสธ'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _showApprovalDialog(leaveId, employeeName),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('อนุมัติ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final bool isAdminView = user?.isAdmin ?? false;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAdminView ? Icons.history : Icons.check_circle_outline, 
            size: 80, 
            color: isAdminView ? Colors.blue[300] : Colors.green[300],
          ),
          const SizedBox(height: 16),
          Text(
            isAdminView 
              ? 'ไม่มีประวัติการลา' 
              : 'ไม่มีคำขอลารออนุมัติ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAdminView
              ? 'ยังไม่มีคำขอลาที่ได้รับการอนุมัติหรือปฏิเสธ'
              : 'ทุกคำขอลาได้รับการอนุมัติแล้ว',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPendingLeaves,
            icon: const Icon(Icons.refresh),
            label: const Text('รีเฟรชข้อมูล'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

