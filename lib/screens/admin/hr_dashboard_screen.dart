import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../../config/api_config.dart';
import 'leave_list_screen.dart';

class HRDashboardScreen extends StatefulWidget {
  const HRDashboardScreen({super.key});

  @override
  State<HRDashboardScreen> createState() => _HRDashboardScreenState();
}

class _HRDashboardScreenState extends State<HRDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _summaryData;
  List<dynamic>? _employeeSummary;
  Map<String, dynamic>? _totals;
  bool _showEmployeeList = false; // ควบคุมการแสดงรายชื่อพนักงาน
  String? _selectedDepartment; // แผนกที่เลือก
  int? _currentYear; // ปีที่กำลังแสดง

  @override
  void initState() {
    super.initState();
    _loadLeaveSummary();
  }

  Future<void> _loadLeaveSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.leaveSummaryUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      print('[HR Dashboard] Response status: ${response.statusCode}');
      print('[HR Dashboard] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('[HR Dashboard] Parsed data: $data');
        
        setState(() {
          _summaryData = data;
          _employeeSummary = data['summary'] as List<dynamic>?;
          _totals = data['totals'] as Map<String, dynamic>?;
          _currentYear = data['year'] as int? ?? DateTime.now().year;
          _isLoading = false;
        });
        
        print('[HR Dashboard] Employee summary count: ${_employeeSummary?.length ?? 0}');
        print('[HR Dashboard] Totals: $_totals');
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'ไม่สามารถโหลดข้อมูลได้';
        
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$errorMessage (Status: ${response.statusCode})'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading leave summary: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'HR Dashboard - สรุปข้อมูลวันลา',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.blue),
            onPressed: () => _showExportOptions(context),
            tooltip: 'Export ข้อมูล',
          ),
          IconButton(
            icon: const Icon(Icons.assessment, color: Colors.purple),
            onPressed: () => _showExecutiveSummary(context),
            tooltip: 'รายงานผู้บริหาร',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loadLeaveSummary,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showEmployeeList
              ? _buildEmployeeListScreen()
              : _buildSummaryScreen(),
    );
  }

  // Helper function to parse string to int
  int? _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  Widget _buildSummaryScreen() {
    return RefreshIndicator(
      onRefresh: _loadLeaveSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'สรุปข้อมูลวันลา',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (_currentYear != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            'ปี ${_currentYear}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'กดการ์ดเพื่อดูรายละเอียดพนักงานแต่ละคน',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Actions for Executives
            _buildExecutiveQuickActions(),
            const SizedBox(height: 24),
            
            // Summary Cards - แสดงการ์ดเดียวที่กดได้
            if (_totals != null) _buildClickableSummaryCards(_totals!),
            if (_totals == null && !_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ไม่สามารถโหลดข้อมูลสรุปได้',
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeListScreen() {
    // ถ้ายังไม่ได้เลือกแผนก ให้แสดงรายการแผนก
    if (_selectedDepartment == null) {
      return _buildDepartmentListScreen();
    }
    
    // ถ้าเลือกแผนกแล้ว ให้แสดงรายชื่อพนักงานในแผนกนั้น
    return _buildEmployeesByDepartmentScreen();
  }

  Widget _buildDepartmentListScreen() {
    if (_employeeSummary == null || _employeeSummary!.isEmpty) {
      return Column(
        children: [
          _buildListAppBar('รายชื่อพนักงาน', () {
            setState(() {
              _showEmployeeList = false;
              _selectedDepartment = null;
            });
          }),
          Expanded(child: _buildEmptyState()),
        ],
      );
    }

    // จัดกลุ่มพนักงานตามแผนก
    final Map<String, List<dynamic>> departmentGroups = {};
    for (var emp in _employeeSummary!) {
      final dept = emp['department']?.toString() ?? 'ไม่มีแผนก';
      if (!departmentGroups.containsKey(dept)) {
        departmentGroups[dept] = [];
      }
      departmentGroups[dept]!.add(emp);
    }

    // คำนวณสถิติของแต่ละแผนก
    final List<Map<String, dynamic>> departmentStats = [];
    departmentGroups.forEach((dept, employees) {
      int totalEmployees = employees.length;
      int totalLeave = 0;
      int totalPending = 0;
      int totalRemaining = 0;

      for (var emp in employees) {
        totalLeave += _parseInt(emp['total_leave_days']) ?? 0;
        totalPending += _parseInt(emp['pending_leave_days']) ?? 0;
        totalRemaining += _parseInt(emp['remaining_leave_days']) ?? 0;
      }

      departmentStats.add({
        'department': dept,
        'employeeCount': totalEmployees,
        'totalLeave': totalLeave,
        'totalPending': totalPending,
        'totalRemaining': totalRemaining,
        'employees': employees,
      });
    });

    // เรียงตามชื่อแผนก
    departmentStats.sort((a, b) => (a['department'] as String).compareTo(b['department'] as String));

    return Column(
      children: [
        _buildListAppBar('รายชื่อพนักงาน', () {
          setState(() {
            _showEmployeeList = false;
            _selectedDepartment = null;
          });
        }),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadLeaveSummary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...departmentStats.map((deptStat) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDepartmentCard(
                      department: deptStat['department'] as String,
                      employeeCount: deptStat['employeeCount'] as int,
                      totalLeave: deptStat['totalLeave'] as int,
                      totalPending: deptStat['totalPending'] as int,
                      totalRemaining: deptStat['totalRemaining'] as int,
                      onTap: () {
                        setState(() {
                          _selectedDepartment = deptStat['department'] as String;
                        });
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeesByDepartmentScreen() {
    if (_employeeSummary == null || _employeeSummary!.isEmpty) {
      return Column(
        children: [
          _buildListAppBar(_selectedDepartment ?? 'แผนก', () {
            setState(() {
              _selectedDepartment = null;
            });
          }),
          Expanded(child: _buildEmptyState()),
        ],
      );
    }

    // กรองพนักงานตามแผนกที่เลือก
    final employeesInDept = _employeeSummary!.where((emp) {
      final dept = emp['department']?.toString() ?? 'ไม่มีแผนก';
      return dept == _selectedDepartment;
    }).toList();

    return Column(
      children: [
        _buildListAppBar(_selectedDepartment ?? 'แผนก', () {
          setState(() {
            _selectedDepartment = null;
          });
        }),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadLeaveSummary,
            child: employeesInDept.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...employeesInDept.map((emp) {
                        final totalLeave = _parseInt(emp['total_leave_days']) ?? 0;
                        final sickLeave = _parseInt(emp['sick_leave_days']) ?? 0;
                        final personalLeave = _parseInt(emp['personal_leave_days']) ?? 0;
                        final pendingLeave = _parseInt(emp['pending_leave_days']) ?? 0;
                        final remainingLeave = _parseInt(emp['remaining_leave_days']) ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildEmployeeCard(
                            emp: emp,
                            totalLeave: totalLeave,
                            sickLeave: sickLeave,
                            personalLeave: personalLeave,
                            pendingLeave: pendingLeave,
                            remainingLeave: remainingLeave,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildListAppBar(String title, VoidCallback onBack) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard({
    required String department,
    required int employeeCount,
    required int totalLeave,
    required int totalPending,
    required int totalRemaining,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: totalPending > 0
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getColorFromName(department).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business,
                  size: 24,
                  color: _getColorFromName(department),
                ),
              ),
              const SizedBox(width: 12),
              // Department Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      department,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '$employeeCount คน',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'ลาทั้งหมด $totalLeave วัน',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stats - ใช้ Flexible เพื่อป้องกัน overflow
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (totalPending > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pending, size: 12, color: Colors.orange[700]),
                              const SizedBox(width: 4),
                              Text(
                                '$totalPending',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (totalRemaining < 5 ? Colors.red[50] : Colors.green[50]),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (totalRemaining < 5 ? Colors.red[200]! : Colors.green[200]!),
                        ),
                      ),
                      child: Text(
                        'เหลือ $totalRemaining',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: (totalRemaining < 5 ? Colors.red[700] : Colors.green[700]),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClickableSummaryCards(Map<String, dynamic> totals) {
    final totalEmployees = _parseInt(totals['total_employees']) ?? 0;
    final totalApproved = _parseInt(totals['total_approved_days']) ?? 0;
    final totalPending = _parseInt(totals['total_pending_days']) ?? 0;
    final totalRejected = _parseInt(totals['total_rejected_days']) ?? 0;

    return Column(
      children: [
        // การ์ดหลัก - รายชื่อพนักงาน (กดได้)
        _buildClickableCard(
          title: 'รายชื่อพนักงาน',
          value: totalEmployees.toString(),
          icon: Icons.people,
          color: Colors.blue,
          onTap: () {
            setState(() {
              _showEmployeeList = true;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // การ์ดอื่นๆ - ใช้สไตล์เดียวกับการ์ดรายชื่อพนักงาน
        _buildClickableCard(
          title: 'วันลาที่อนุมัติ',
          value: totalApproved.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LeaveListScreen(
                  status: 'approved',
                  title: 'อนุมัติแล้ว',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildClickableCard(
          title: 'รออนุมัติ',
          value: totalPending.toString(),
          icon: Icons.pending,
          color: Colors.orange,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LeaveListScreen(
                  status: 'pending',
                  title: 'รออนุมัติ',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildClickableCard(
          title: 'ไม่อนุมัติ',
          value: totalRejected.toString(),
          icon: Icons.cancel,
          color: Colors.red,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LeaveListScreen(
                  status: 'rejected',
                  title: 'ไม่อนุมัติ',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildClickableCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 32,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> totals) {
    final totalEmployees = _parseInt(totals['total_employees']) ?? 0;
    final totalApproved = _parseInt(totals['total_approved_days']) ?? 0;
    final totalPending = _parseInt(totals['total_pending_days']) ?? 0;
    final totalRejected = _parseInt(totals['total_rejected_days']) ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'จำนวนพนักงาน',
                totalEmployees.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'วันลาที่อนุมัติ',
                totalApproved.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'รออนุมัติ',
                totalPending.toString(),
                Icons.pending,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'ไม่อนุมัติ',
                totalRejected.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCards(List<dynamic> employees) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: employees.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final emp = employees[index];
        final totalLeave = _parseInt(emp['total_leave_days']) ?? 0;
        final sickLeave = _parseInt(emp['sick_leave_days']) ?? 0;
        final personalLeave = _parseInt(emp['personal_leave_days']) ?? 0;
        final pendingLeave = _parseInt(emp['pending_leave_days']) ?? 0;
        final remainingLeave = _parseInt(emp['remaining_leave_days']) ?? 0;

        return _buildEmployeeCard(
          emp: emp,
          totalLeave: totalLeave,
          sickLeave: sickLeave,
          personalLeave: personalLeave,
          pendingLeave: pendingLeave,
          remainingLeave: remainingLeave,
        );
      },
    );
  }

  Widget _buildEmployeeCard({
    required Map<String, dynamic> emp,
    required int totalLeave,
    required int sickLeave,
    required int personalLeave,
    required int pendingLeave,
    required int remainingLeave,
  }) {
    final fullName = emp['full_name']?.toString() ?? '-';
    final position = emp['position']?.toString() ?? '-';
    final department = emp['department']?.toString() ?? '-';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showEmployeeDetails(context, emp, totalLeave, sickLeave, personalLeave, pendingLeave, remainingLeave);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: pendingLeave > 0 
                  ? Colors.orange.withValues(alpha: 0.3)
                  : remainingLeave < 5 
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name and Position
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getColorFromName(fullName).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        fullName.isNotEmpty && fullName != '-'
                            ? fullName.substring(0, 1).toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getColorFromName(fullName),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and Position
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.work_outline, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                position,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (department.isNotEmpty && department != '-')
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(Icons.business_outlined, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  department,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Arrow icon
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Leave Summary
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'ลาทั้งหมด',
                      totalLeave.toString(),
                      Colors.blue,
                      Icons.event,
                      subtitle: 'ลาไปแล้วทั้งหมด',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      'ลาป่วย',
                      sickLeave.toString(),
                      Colors.blue[300]!,
                      Icons.medical_services,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      'ลากิจ',
                      personalLeave.toString(),
                      Colors.purple[300]!,
                      Icons.person_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'รออนุมัติ',
                      pendingLeave.toString(),
                      pendingLeave > 0 ? Colors.orange : Colors.grey,
                      Icons.pending,
                      highlight: pendingLeave > 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      'เหลือ',
                      remainingLeave.toString(),
                      remainingLeave < 5 ? Colors.red : Colors.green,
                      Icons.event_available,
                      highlight: true,
                      subtitle: 'ปี ${_currentYear ?? DateTime.now().year}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon, {bool highlight = false, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: highlight
            ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorFromName(String name) {
    if (name.isEmpty || name == '-') return Colors.grey;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[name.hashCode % colors.length];
  }

  void _showEmployeeDetails(
    BuildContext context,
    Map<String, dynamic> emp,
    int totalLeave,
    int sickLeave,
    int personalLeave,
    int pendingLeave,
    int remainingLeave,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getColorFromName(emp['full_name']?.toString() ?? '').withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (emp['full_name']?.toString() ?? '-').isNotEmpty && emp['full_name']?.toString() != '-'
                            ? (emp['full_name']?.toString() ?? '-').substring(0, 1).toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getColorFromName(emp['full_name']?.toString() ?? ''),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp['full_name']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emp['position']?.toString() ?? '-',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (emp['department']?.toString() != null && emp['department']?.toString() != '-')
                          Text(
                            emp['department']?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'สรุปข้อมูลวันลา',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_currentYear != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              'ปี $_currentYear',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // แสดงวันลาทั้งหมดที่ลาไปแล้ว (ไม่จำกัดปี)
                    _buildDetailRow('ลาทั้งหมดที่ลาไปแล้ว', '${totalLeave} วัน', Colors.blue),
                    const SizedBox(height: 4),
                    _buildDetailRow('  - ลาป่วย', '${sickLeave} วัน', Colors.blue[300]!),
                    _buildDetailRow('  - ลากิจส่วนตัว', '${personalLeave} วัน', Colors.purple[300]!),
                    const SizedBox(height: 8),
                    _buildDetailRow('รออนุมัติ', '${pendingLeave} วัน', Colors.orange),
                    // แสดงวันลาที่เหลือตามปีปัจจุบัน
                    _buildDetailRow('วันลาที่เหลือ (ปี $_currentYear)', '${remainingLeave} วัน', 
                        remainingLeave < 5 ? Colors.red : Colors.green, isHighlight: true),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentYear != null
                                  ? 'ข้อมูลนี้แสดงเฉพาะปี $_currentYear\nวันลาที่เหลือคำนวณจาก 30 วันต่อปี'
                                  : 'วันลาที่เหลือคำนวณจาก 30 วันต่อปี',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isHighlight ? color.withValues(alpha: 0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: isHighlight
                  ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
                  : null,
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ไม่มีข้อมูลพนักงาน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ยังไม่มีพนักงานในระบบ หรือยังไม่มีข้อมูลวันลา',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadLeaveSummary,
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

  Widget _buildExecutiveQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple[50]!,
            Colors.blue[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: Colors.purple[700], size: 24),
              const SizedBox(width: 8),
              const Text(
                'สำหรับผู้บริหาร',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.assessment,
                  label: 'รายงานสรุป',
                  color: Colors.purple,
                  onTap: () => _showExecutiveSummary(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.download,
                  label: 'Export ข้อมูล',
                  color: Colors.blue,
                  onTap: () => _showExportOptions(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export ข้อมูล',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildExportOption(
              context,
              icon: Icons.picture_as_pdf,
              title: 'Export เป็น PDF',
              subtitle: 'รายงานสรุปข้อมูลวันลาในรูปแบบ PDF',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              context,
              icon: Icons.table_chart,
              title: 'Export เป็น Excel',
              subtitle: 'ข้อมูลรายละเอียดในรูปแบบ Excel (.xlsx)',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              context,
              icon: Icons.description,
              title: 'Export เป็น CSV',
              subtitle: 'ข้อมูลดิบในรูปแบบ CSV สำหรับวิเคราะห์',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _exportToCSV();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }

  void _showExecutiveSummary(BuildContext context) {
    if (_totals == null || _employeeSummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณารอให้ข้อมูลโหลดเสร็จก่อน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExecutiveSummaryScreen(
          totals: _totals!,
          employeeSummary: _employeeSummary!,
        ),
      ),
    );
  }

  Future<void> _exportToPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กำลังเตรียม Export เป็น PDF...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implement PDF export
    await Future.delayed(const Duration(seconds: 1));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ฟีเจอร์ Export PDF กำลังพัฒนา'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _exportToExcel() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กำลังเตรียม Export เป็น Excel...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implement Excel export
    await Future.delayed(const Duration(seconds: 1));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ฟีเจอร์ Export Excel กำลังพัฒนา'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _exportToCSV() async {
    if (_employeeSummary == null || _employeeSummary!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีข้อมูลให้ Export'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // สร้าง CSV content
      final csvBuffer = StringBuffer();
      
      // Header
      csvBuffer.writeln('ชื่อ-นามสกุล,ตำแหน่ง,แผนก,ลาทั้งหมด,ลาป่วย,ลากิจ,รออนุมัติ,เหลือ');
      
      // Data
      for (var emp in _employeeSummary!) {
        csvBuffer.writeln(
          '${emp['full_name'] ?? '-'},'
          '${emp['position'] ?? '-'},'
          '${emp['department'] ?? '-'},'
          '${_parseInt(emp['total_leave_days']) ?? 0},'
          '${_parseInt(emp['sick_leave_days']) ?? 0},'
          '${_parseInt(emp['personal_leave_days']) ?? 0},'
          '${_parseInt(emp['pending_leave_days']) ?? 0},'
          '${_parseInt(emp['remaining_leave_days']) ?? 0}'
        );
      }

      // ใช้ share_plus เพื่อแชร์ CSV
      await Share.share(
        csvBuffer.toString(),
        subject: 'รายงานข้อมูลวันลา - ${DateTime.now().toString().split(' ')[0]}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export CSV สำเร็จ!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Executive Summary Screen
class ExecutiveSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> totals;
  final List<dynamic> employeeSummary;

  const ExecutiveSummaryScreen({
    super.key,
    required this.totals,
    required this.employeeSummary,
  });

  // Helper function to parse string to int
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final totalEmployees = _parseInt(totals['total_employees']);
    final totalApproved = _parseInt(totals['total_approved_days']);
    final totalPending = _parseInt(totals['total_pending_days']);
    final totalRejected = _parseInt(totals['total_rejected_days']);

    // คำนวณสถิติตามแผนก
    final Map<String, Map<String, int>> deptStats = {};
    for (var emp in employeeSummary) {
      final dept = emp['department']?.toString() ?? 'ไม่มีแผนก';
      if (!deptStats.containsKey(dept)) {
        deptStats[dept] = {
          'count': 0,
          'totalLeave': 0,
          'pending': 0,
        };
      }
      deptStats[dept]!['count'] = (deptStats[dept]!['count'] ?? 0) + 1;
      deptStats[dept]!['totalLeave'] = (deptStats[dept]!['totalLeave'] ?? 0) + 
        _parseInt(emp['total_leave_days']);
      deptStats[dept]!['pending'] = (deptStats[dept]!['pending'] ?? 0) + 
        _parseInt(emp['pending_leave_days']);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'รายงานสรุปสำหรับผู้บริหาร',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.blue[400]!],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'รายงานสรุปข้อมูลวันลา',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'วันที่: ${DateTime.now().toString().split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Key Metrics
            const Text(
              'ตัวชี้วัดหลัก',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'จำนวนพนักงาน',
                    totalEmployees.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'วันลาที่อนุมัติ',
                    totalApproved.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'รออนุมัติ',
                    totalPending.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'ไม่อนุมัติ',
                    totalRejected.toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Department Summary
            const Text(
              'สรุปตามแผนก',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...deptStats.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.people, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${entry.value['count']} คน',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.event, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'ลา ${entry.value['totalLeave']} วัน',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if ((entry.value['pending'] as int? ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Text(
                            'รอ ${entry.value['pending']} วัน',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),
            // Recommendations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'ข้อเสนอแนะ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (totalPending > 0)
                    _buildRecommendation(
                      'มีวันลารออนุมัติ $totalPending วัน ควรพิจารณาให้เร็วที่สุด',
                      Colors.orange,
                    ),
                  if (totalPending == 0 && totalApproved > 0)
                    _buildRecommendation(
                      'ไม่มีวันลารออนุมัติ ระบบทำงานได้ดี',
                      Colors.green,
                    ),
                  _buildRecommendation(
                    'ควรตรวจสอบวันลาที่เหลือของพนักงานเป็นประจำ',
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

