import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:intl/intl.dart';
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
  
  // ข้อมูลสรุปรายวัน
  bool _isLoadingDaily = false;
  Map<String, dynamic>? _dailySummary;
  DateTime _selectedDate = DateTime.now(); // วันที่ที่เลือก

  @override
  void initState() {
    super.initState();
    _loadLeaveSummary();
    _loadDailySummary();
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

  Future<void> _loadDailySummary() async {
    setState(() {
      _isLoadingDaily = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoadingDaily = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('กรุณาเข้าสู่ระบบก่อน'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // ส่งวันที่ที่เลือกไปยัง API
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      
      // ลองดึงข้อมูลจาก daily summary API ก่อน
      final summaryUrl = '${ApiConfig.dailyAttendanceSummaryUrl}?date=$dateStr';
      final summaryResponse = await http.get(
        Uri.parse(summaryUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      print('[HR Dashboard] Daily summary response status: ${summaryResponse.statusCode}');
      print('[HR Dashboard] Daily summary response body: ${summaryResponse.body}');

      if (summaryResponse.statusCode == 200) {
        final data = json.decode(summaryResponse.body) as Map<String, dynamic>;
        setState(() {
          _dailySummary = {
            'date': dateStr,
            'total_employees': _parseInt(data['total_employees']) ?? _parseInt(data['totalEmployees']) ?? _totals?['total_employees'] ?? 0,
            'attended': _parseInt(data['attended']) ?? _parseInt(data['present']) ?? 0,
            'late': _parseInt(data['late']) ?? _parseInt(data['lateArrivals']) ?? 0,
            'on_leave': _parseInt(data['on_leave']) ?? _parseInt(data['onLeave']) ?? _parseInt(data['leave']) ?? 0,
            'absent': _parseInt(data['absent']) ?? _parseInt(data['absentees']) ?? 0,
          };
          _isLoadingDaily = false;
        });
        return;
      }

      // ถ้า daily summary API ไม่พร้อม ให้คำนวณจากข้อมูลจริง
      print('[HR Dashboard] Daily summary API not available, calculating from raw data...');
      await _calculateDailySummaryFromRawData(dateStr, token);
      
    } catch (e) {
      print('Error loading daily summary: $e');
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      setState(() {
        _dailySummary = null;
        _isLoadingDaily = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถโหลดข้อมูลได้: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _calculateDailySummaryFromRawData(String dateStr, String token) async {
    try {
      // ดึงข้อมูล attendance ทั้งหมดสำหรับวันที่เลือก
      final attendanceUrl = '${ApiConfig.attendanceAllUrl}?date=$dateStr';
      final attendanceResponse = await http.get(
        Uri.parse(attendanceUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      // ดึงข้อมูลพนักงานทั้งหมด
      final totalEmployees = _parseInt(_totals?['total_employees']) ?? 0;
      
      // ดึงข้อมูลลา - ใช้ leave details API
      final leaveDetailsUrl = '${ApiConfig.leaveDetailsUrl}?date=$dateStr';
      final leaveResponse = await http.get(
        Uri.parse(leaveDetailsUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      int attended = 0;
      int late = 0;
      int onLeave = 0;
      Set<String> attendedUserIds = {};
      Set<String> leaveUserIds = {};

      // ประมวลผลข้อมูลลา
      if (leaveResponse.statusCode == 200) {
        final leaveData = json.decode(leaveResponse.body);
        final List<dynamic> leaveList = leaveData is List 
            ? leaveData 
            : (leaveData['leaves'] as List<dynamic>? ?? 
               leaveData['leave_list'] as List<dynamic>? ?? 
               leaveData['data'] as List<dynamic>? ?? []);
        
        for (var leave in leaveList) {
          final startDate = leave['start_date']?.toString() ?? 
                           leave['startDate']?.toString() ??
                           leave['start_date_time']?.toString();
          final endDate = leave['end_date']?.toString() ?? 
                         leave['endDate']?.toString() ??
                         leave['end_date_time']?.toString();
          final status = leave['status']?.toString() ?? '';
          
          // ตรวจสอบเฉพาะ leave ที่อนุมัติแล้ว
          if (startDate != null && endDate != null && 
              (status.toLowerCase() == 'approved' || status.toLowerCase() == 'อนุมัติ')) {
            try {
              final start = DateTime.parse(startDate.split(' ')[0].split('T')[0]);
              final end = DateTime.parse(endDate.split(' ')[0].split('T')[0]);
              final selected = DateTime.parse(dateStr);
              
              // ตรวจสอบว่า selected date อยู่ในช่วงวันลาหรือไม่
              if ((selected.isAfter(start.subtract(const Duration(days: 1))) && 
                   selected.isBefore(end.add(const Duration(days: 1)))) ||
                  (selected.year == start.year && selected.month == start.month && selected.day == start.day) ||
                  (selected.year == end.year && selected.month == end.month && selected.day == end.day)) {
                final userId = leave['user_id']?.toString() ?? 
                              leave['employee_id']?.toString() ?? 
                              leave['userId']?.toString() ??
                              leave['user']?.toString();
                if (userId != null) {
                  leaveUserIds.add(userId);
                }
              }
            } catch (e) {
              print('Error parsing leave date: $e');
            }
          }
        }
      } else {
        // ถ้า leave details API ไม่พร้อม ลองใช้ leave summary
        print('[HR Dashboard] Leave details API not available, trying leave summary...');
        try {
          final leaveSummaryUrl = ApiConfig.leaveSummaryUrl;
          final leaveSummaryResponse = await http.get(
            Uri.parse(leaveSummaryUrl),
            headers: ApiConfig.headersWithAuth(token),
          );
          
          if (leaveSummaryResponse.statusCode == 200) {
            final leaveData = json.decode(leaveSummaryResponse.body) as Map<String, dynamic>;
            final employeeSummary = leaveData['summary'] as List<dynamic>? ?? [];
            
            // ใช้ข้อมูลจาก employee summary เพื่อหาว่าใครลาวันนี้
            // ต้องตรวจสอบจาก leave history ของแต่ละคน
            for (var emp in employeeSummary) {
              // ตรวจสอบว่ามีการลาวันนี้หรือไม่ (ต้องดึงจาก leave history)
              // สำหรับตอนนี้จะข้ามไปก่อน
            }
          }
        } catch (e) {
          print('Error loading leave summary: $e');
        }
      }

      // ประมวลผลข้อมูล attendance
      if (attendanceResponse.statusCode == 200) {
        final attendanceData = json.decode(attendanceResponse.body);
        final List<dynamic> attendances = attendanceData is List 
            ? attendanceData 
            : (attendanceData['attendances'] as List<dynamic>? ?? 
               attendanceData['data'] as List<dynamic>? ?? []);

        final selectedDate = DateTime.parse(dateStr);
        const lateThreshold = '08:30'; // เวลามาสาย (8:30 น.)

        for (var att in attendances) {
          final attDateStr = att['date']?.toString() ?? '';
          if (attDateStr.isEmpty) continue;
          
          try {
            final attDate = DateTime.parse(attDateStr.split(' ')[0].split('T')[0]);
            if (attDate.year == selectedDate.year && 
                attDate.month == selectedDate.month && 
                attDate.day == selectedDate.day) {
              
              final userId = att['user_id']?.toString() ?? 
                            att['employee_id']?.toString() ?? 
                            att['userId']?.toString();
              
              if (userId != null && !leaveUserIds.contains(userId)) {
                final checkInTime = att['check_in_time']?.toString() ?? 
                                  att['checkInTime']?.toString();
                
                if (checkInTime != null && checkInTime.isNotEmpty) {
                  attendedUserIds.add(userId);
                  
                  // ตรวจสอบว่ามาสายหรือไม่
                  try {
                    final timeStr = checkInTime.split(' ')[1].split('.')[0]; // HH:mm:ss
                    final timeParts = timeStr.split(':');
                    final hour = int.parse(timeParts[0]);
                    final minute = int.parse(timeParts[1]);
                    
                    if (hour > 8 || (hour == 8 && minute > 30)) {
                      late++;
                    }
                  } catch (e) {
                    print('Error parsing check-in time: $e');
                  }
                }
              }
            }
          } catch (e) {
            print('Error parsing attendance date: $e');
          }
        }
      }

      attended = attendedUserIds.length;
      onLeave = leaveUserIds.length;
      final absent = totalEmployees - attended - onLeave;

      setState(() {
        _dailySummary = {
          'date': dateStr,
          'total_employees': totalEmployees,
          'attended': attended,
          'late': late,
          'on_leave': onLeave,
          'absent': absent > 0 ? absent : 0,
        };
        _isLoadingDaily = false;
      });

      print('[HR Dashboard] Calculated summary: attended=$attended, late=$late, onLeave=$onLeave, absent=$absent');
      
    } catch (e) {
      print('Error calculating daily summary: $e');
      setState(() {
        _dailySummary = null;
        _isLoadingDaily = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถคำนวณข้อมูลได้: ${e.toString()}'),
            backgroundColor: Colors.orange,
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
            
            // Daily Summary Section - สรุปรายวัน
            _buildDailySummarySection(),
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

  Widget _buildDailySummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'สรุปรายวัน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.download, color: Colors.blue),
                tooltip: 'Export ข้อมูลสรุปรายวัน',
                enabled: _dailySummary != null,
                onSelected: (value) {
                  switch (value) {
                    case 'csv':
                      _exportDailySummaryToCSV();
                      break;
                    case 'excel':
                      _exportDailySummaryToExcel();
                      break;
                    case 'pdf':
                      _exportDailySummaryToPDF();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'csv',
                    child: Row(
                      children: [
                        Icon(Icons.description, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Export เป็น CSV'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'excel',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Export เป็น Excel'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Export เป็น PDF'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date Picker
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  locale: const Locale('th', 'TH'),
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                  });
                  _loadDailySummary();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingDaily)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_dailySummary != null)
            _buildDailySummaryCards()
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'ไม่มีข้อมูลสำหรับวันที่เลือก',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCards() {
    final totalEmployees = _parseInt(_dailySummary!['total_employees']) ?? 0;
    final attended = _parseInt(_dailySummary!['attended']) ?? 0;
    final late = _parseInt(_dailySummary!['late']) ?? 0;
    final onLeave = _parseInt(_dailySummary!['on_leave']) ?? 0;
    final absent = _parseInt(_dailySummary!['absent']) ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDailyStatCard(
                'มา',
                attended.toString(),
                Icons.check_circle,
                Colors.green,
                subtitle: 'คน',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDailyStatCard(
                'มาสาย',
                late.toString(),
                Icons.schedule,
                Colors.orange,
                subtitle: 'คน',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDailyStatCard(
                'ลา',
                onLeave.toString(),
                Icons.event_busy,
                Colors.blue,
                subtitle: 'คน',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDailyStatCard(
                'ขาด',
                absent.toString(),
                Icons.cancel,
                Colors.red,
                subtitle: 'คน',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รวมทั้งหมด',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '$totalEmployees คน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
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
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _exportDailySummaryToCSV() async {
    if (_dailySummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีข้อมูลให้ Export'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กำลังสร้างไฟล์ CSV...'),
          backgroundColor: Colors.blue,
        ),
      );

      final csvBuffer = StringBuffer();
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      
      // Header
      csvBuffer.writeln('รายงานสรุปการเข้างานรายวัน');
      csvBuffer.writeln('วันที่,$dateStr');
      csvBuffer.writeln('');
      csvBuffer.writeln('ประเภท,จำนวน (คน)');
      
      // Data
      csvBuffer.writeln('มา,${_parseInt(_dailySummary!['attended']) ?? 0}');
      csvBuffer.writeln('มาสาย,${_parseInt(_dailySummary!['late']) ?? 0}');
      csvBuffer.writeln('ลา,${_parseInt(_dailySummary!['on_leave']) ?? 0}');
      csvBuffer.writeln('ขาด,${_parseInt(_dailySummary!['absent']) ?? 0}');
      csvBuffer.writeln('รวมทั้งหมด,${_parseInt(_dailySummary!['total_employees']) ?? 0}');

      // Save CSV file
      final output = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName = 'รายงานสรุปการเข้างานรายวัน_${dateStr.replaceAll('-', '')}_${now.millisecondsSinceEpoch}.csv';
      final filePath = '${output.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(csvBuffer.toString().codeUnits);

      // Share or open file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'รายงานสรุปการเข้างานรายวัน - $dateStr',
        subject: 'รายงานสรุปการเข้างานรายวัน',
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

  Future<void> _exportDailySummaryToExcel() async {
    if (_dailySummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีข้อมูลให้ Export'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กำลังสร้างไฟล์ Excel...'),
          backgroundColor: Colors.blue,
        ),
      );

      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      
      // สร้าง Excel workbook
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['สรุปการเข้างานรายวัน'];

      // Header
      sheet.appendRow([TextCellValue('รายงานสรุปการเข้างานรายวัน')]);
      sheet.appendRow([TextCellValue('วันที่'), TextCellValue(dateStr)]);
      sheet.appendRow([]);
      sheet.appendRow([TextCellValue('ประเภท'), TextCellValue('จำนวน (คน)')]);

      // Data
      sheet.appendRow([
        TextCellValue('มา'),
        IntCellValue(_parseInt(_dailySummary!['attended']) ?? 0),
      ]);
      sheet.appendRow([
        TextCellValue('มาสาย'),
        IntCellValue(_parseInt(_dailySummary!['late']) ?? 0),
      ]);
      sheet.appendRow([
        TextCellValue('ลา'),
        IntCellValue(_parseInt(_dailySummary!['on_leave']) ?? 0),
      ]);
      sheet.appendRow([
        TextCellValue('ขาด'),
        IntCellValue(_parseInt(_dailySummary!['absent']) ?? 0),
      ]);
      sheet.appendRow([
        TextCellValue('รวมทั้งหมด'),
        IntCellValue(_parseInt(_dailySummary!['total_employees']) ?? 0),
      ]);

      // Style header
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#E0E0E0'),
        horizontalAlign: HorizontalAlign.Center,
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).cellStyle = headerStyle;

      // Save Excel file
      final output = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName = 'รายงานสรุปการเข้างานรายวัน_${dateStr.replaceAll('-', '')}_${now.millisecondsSinceEpoch}.xlsx';
      final filePath = '${output.path}/$fileName';
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          text: 'รายงานสรุปการเข้างานรายวัน - $dateStr',
          subject: 'รายงานสรุปการเข้างานรายวัน',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export Excel สำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportDailySummaryToPDF() async {
    if (_dailySummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีข้อมูลให้ Export'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กำลังสร้างไฟล์ PDF...'),
          backgroundColor: Colors.blue,
        ),
      );

      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final dateFormat = DateFormat('dd/MM/yyyy', 'th');
      final formattedDate = dateFormat.format(_selectedDate);
      
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'รายงานสรุปการเข้างานรายวัน',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'วันที่: $formattedDate',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Summary Cards
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPDFStatCard(
                    'มา',
                    '${_parseInt(_dailySummary!['attended']) ?? 0}',
                    PdfColors.green,
                  ),
                  _buildPDFStatCard(
                    'มาสาย',
                    '${_parseInt(_dailySummary!['late']) ?? 0}',
                    PdfColors.orange,
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPDFStatCard(
                    'ลา',
                    '${_parseInt(_dailySummary!['on_leave']) ?? 0}',
                    PdfColors.blue,
                  ),
                  _buildPDFStatCard(
                    'ขาด',
                    '${_parseInt(_dailySummary!['absent']) ?? 0}',
                    PdfColors.red,
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Total
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'รวมทั้งหมด',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${_parseInt(_dailySummary!['total_employees']) ?? 0} คน',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      // Save PDF
      final output = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName = 'รายงานสรุปการเข้างานรายวัน_${dateStr.replaceAll('-', '')}_${now.millisecondsSinceEpoch}.pdf';
      final filePath = '${output.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'รายงานสรุปการเข้างานรายวัน - $formattedDate',
        subject: 'รายงานสรุปการเข้างานรายวัน',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export PDF สำเร็จ!'),
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

  pw.Widget _buildPDFStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 200,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              color: color,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กำลังสร้างไฟล์ PDF...'),
          backgroundColor: Colors.blue,
        ),
      );

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy', 'th');
      final now = DateTime.now();

      // สร้าง PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'รายงานสรุปข้อมูลวันลา',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'วันที่: ${dateFormat.format(now)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    if (_currentYear != null)
                      pw.Text(
                        'ปี: $_currentYear',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Summary
              if (_totals != null)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('จำนวนพนักงาน', '${_parseInt(_totals!['total_employees']) ?? 0}'),
                      _buildSummaryItem('วันลาที่อนุมัติ', '${_parseInt(_totals!['total_approved_days']) ?? 0}'),
                      _buildSummaryItem('รออนุมัติ', '${_parseInt(_totals!['total_pending_days']) ?? 0}'),
                      _buildSummaryItem('ไม่อนุมัติ', '${_parseInt(_totals!['total_rejected_days']) ?? 0}'),
                    ],
                  ),
                ),
              pw.SizedBox(height: 20),

              // Table Header
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('ชื่อ-นามสกุล', isHeader: true),
                      _buildTableCell('ตำแหน่ง', isHeader: true),
                      _buildTableCell('แผนก', isHeader: true),
                      _buildTableCell('ลาทั้งหมด', isHeader: true),
                      _buildTableCell('ลาป่วย', isHeader: true),
                      _buildTableCell('ลากิจ', isHeader: true),
                      _buildTableCell('รออนุมัติ', isHeader: true),
                      _buildTableCell('เหลือ', isHeader: true),
                    ],
                  ),
                  // Data rows
                  ..._employeeSummary!.map((emp) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(emp['full_name']?.toString() ?? '-'),
                        _buildTableCell(emp['position']?.toString() ?? '-'),
                        _buildTableCell(emp['department']?.toString() ?? '-'),
                        _buildTableCell('${_parseInt(emp['total_leave_days']) ?? 0}'),
                        _buildTableCell('${_parseInt(emp['sick_leave_days']) ?? 0}'),
                        _buildTableCell('${_parseInt(emp['personal_leave_days']) ?? 0}'),
                        _buildTableCell('${_parseInt(emp['pending_leave_days']) ?? 0}'),
                        _buildTableCell('${_parseInt(emp['remaining_leave_days']) ?? 0}'),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      // Save PDF
      final output = await getTemporaryDirectory();
      final fileName = 'รายงานข้อมูลวันลา_${now.millisecondsSinceEpoch}.pdf';
      final filePath = '${output.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Share or open file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'รายงานข้อมูลวันลา - ${dateFormat.format(now)}',
        subject: 'รายงานข้อมูลวันลา',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export PDF สำเร็จ!'),
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

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _exportToExcel() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กำลังสร้างไฟล์ Excel...'),
          backgroundColor: Colors.blue,
        ),
      );

      // สร้าง Excel workbook
      final excel = Excel.createExcel();
      excel.delete('Sheet1'); // ลบ sheet เริ่มต้น
      final sheet = excel['รายงานข้อมูลวันลา'];

      // Header row
      sheet.appendRow([
        TextCellValue('ชื่อ-นามสกุล'),
        TextCellValue('ตำแหน่ง'),
        TextCellValue('แผนก'),
        TextCellValue('ลาทั้งหมด'),
        TextCellValue('ลาป่วย'),
        TextCellValue('ลากิจ'),
        TextCellValue('รออนุมัติ'),
        TextCellValue('เหลือ'),
      ]);

      // Style header
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#E0E0E0'),
        horizontalAlign: HorizontalAlign.Center,
      );
      for (var i = 0; i < 8; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
      }

      // Data rows
      for (var emp in _employeeSummary!) {
        sheet.appendRow([
          TextCellValue(emp['full_name']?.toString() ?? '-'),
          TextCellValue(emp['position']?.toString() ?? '-'),
          TextCellValue(emp['department']?.toString() ?? '-'),
          IntCellValue(_parseInt(emp['total_leave_days']) ?? 0),
          IntCellValue(_parseInt(emp['sick_leave_days']) ?? 0),
          IntCellValue(_parseInt(emp['personal_leave_days']) ?? 0),
          IntCellValue(_parseInt(emp['pending_leave_days']) ?? 0),
          IntCellValue(_parseInt(emp['remaining_leave_days']) ?? 0),
        ]);
      }

      // Summary row
      if (_totals != null) {
        sheet.appendRow([]);
        sheet.appendRow([
          TextCellValue('สรุป'),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
        ]);
        sheet.appendRow([
          TextCellValue('จำนวนพนักงาน'),
          IntCellValue(_parseInt(_totals!['total_employees']) ?? 0),
          TextCellValue(''),
          TextCellValue('วันลาที่อนุมัติ'),
          IntCellValue(_parseInt(_totals!['total_approved_days']) ?? 0),
          TextCellValue(''),
          TextCellValue('รออนุมัติ'),
          IntCellValue(_parseInt(_totals!['total_pending_days']) ?? 0),
        ]);
      }

      // Save Excel file
      final output = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName = 'รายงานข้อมูลวันลา_${now.millisecondsSinceEpoch}.xlsx';
      final filePath = '${output.path}/$fileName';
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        // Share or open file
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          text: 'รายงานข้อมูลวันลา - ${DateFormat('dd/MM/yyyy', 'th').format(now)}',
          subject: 'รายงานข้อมูลวันลา',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export Excel สำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('ไม่สามารถสร้างไฟล์ Excel ได้');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กำลังสร้างไฟล์ CSV...'),
          backgroundColor: Colors.blue,
        ),
      );

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

      // Save CSV file
      final output = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName = 'รายงานข้อมูลวันลา_${now.millisecondsSinceEpoch}.csv';
      final filePath = '${output.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(csvBuffer.toString().codeUnits);

      // Share or open file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'รายงานข้อมูลวันลา - ${DateFormat('dd/MM/yyyy', 'th').format(now)}',
        subject: 'รายงานข้อมูลวันลา',
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
class ExecutiveSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> totals;
  final List<dynamic> employeeSummary;

  const ExecutiveSummaryScreen({
    super.key,
    required this.totals,
    required this.employeeSummary,
  });

  @override
  State<ExecutiveSummaryScreen> createState() => _ExecutiveSummaryScreenState();
}

class _ExecutiveSummaryScreenState extends State<ExecutiveSummaryScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _currentTotals;
  List<dynamic>? _currentEmployeeSummary;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _currentTotals = widget.totals;
    _currentEmployeeSummary = widget.employeeSummary;
    // โหลดข้อมูลใหม่เมื่อเปิดหน้าครั้งแรกเพื่อให้ได้ข้อมูลล่าสุด
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForDate(_selectedDate);
    });
  }

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

  Future<void> _loadDataForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // ดึงข้อมูล leave summary ล่าสุด (ไม่ส่งวันที่เพราะ API นี้เป็นข้อมูลสรุปรวม)
      // สำหรับข้อมูลรายวัน ควรใช้ daily attendance summary API
      final response = await http.get(
        Uri.parse(ApiConfig.leaveSummaryUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      print('[Executive Summary] Loading data, response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('[Executive Summary] Data loaded: ${data.keys}');
        setState(() {
          _currentTotals = data['totals'] as Map<String, dynamic>?;
          _currentEmployeeSummary = data['summary'] as List<dynamic>?;
          _isLoading = false;
          _lastUpdateTime = DateTime.now();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อัปเดตข้อมูลเรียบร้อย'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ไม่สามารถโหลดข้อมูลได้ (Status: ${response.statusCode})'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('[Executive Summary] Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = _currentTotals ?? widget.totals;
    final employeeSummary = _currentEmployeeSummary ?? widget.employeeSummary;
    
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () => _loadDataForDate(_selectedDate),
            tooltip: 'รีเฟรชข้อมูล',
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.download, color: Colors.blue),
              onPressed: () => _exportExecutiveSummary(context),
              tooltip: 'Export ข้อมูล',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadDataForDate(_selectedDate),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - มี padding ด้านซ้ายและขวาเล็กน้อย
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.blue[400]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'รายงานสรุปข้อมูลวันลา',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date Picker
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            locale: const Locale('th', 'TH'),
                          );
                          if (picked != null && picked != _selectedDate) {
                            setState(() {
                              _selectedDate = picked;
                            });
                            await _loadDataForDate(picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ] else if (_lastUpdateTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'อัปเดตล่าสุด: ${DateFormat('HH:mm', 'th').format(_lastUpdateTime!)} น.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Key Metrics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'ตัวชี้วัดหลัก',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'จำนวนพนักงาน',
                      totalEmployees.toString(),
                      Icons.people,
                      Colors.blue,
                      onTap: () {
                        // แสดงรายชื่อพนักงานทั้งหมด
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            height: MediaQuery.of(context).size.height * 0.8,
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
                                      const Expanded(
                                        child: Text(
                                          'รายชื่อพนักงานทั้งหมด',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                                // Employee List
                                Expanded(
                                  child: employeeSummary.isEmpty
                                      ? const Center(
                                          child: Text('ไม่มีข้อมูลพนักงาน'),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.all(16),
                                          itemCount: employeeSummary.length,
                                          itemBuilder: (context, index) {
                                            final emp = employeeSummary[index];
                                            return Card(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  backgroundColor: Colors.blue[100],
                                                  child: Text(
                                                    (emp['full_name']?.toString() ?? '?')[0].toUpperCase(),
                                                    style: TextStyle(
                                                      color: Colors.blue[700],
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                title: Text(
                                                  emp['full_name']?.toString() ?? '-',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (emp['position'] != null)
                                                      Text(emp['position'].toString()),
                                                    if (emp['department'] != null)
                                                      Text(
                                                        emp['department'].toString(),
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                trailing: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      'ลา: ${_parseInt(emp['total_leave_days'])} วัน',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    if (_parseInt(emp['pending_leave_days']) > 0)
                                                      Container(
                                                        margin: const EdgeInsets.only(top: 4),
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orange[50],
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(
                                                            color: Colors.orange[200]!,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'รอ ${_parseInt(emp['pending_leave_days'])} วัน',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.orange[700],
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'วันลาที่อนุมัติ',
                      totalApproved.toString(),
                      Icons.check_circle,
                      Colors.green,
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'รออนุมัติ',
                      totalPending.toString(),
                      Icons.pending,
                      Colors.orange,
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'ไม่อนุมัติ',
                      totalRejected.toString(),
                      Icons.cancel,
                      Colors.red,
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Department Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'สรุปตามแผนก',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...deptStats.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
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
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    Widget cardContent = Column(
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
    );

    final container = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: cardContent,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: container,
        ),
      );
    }

    return container;
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

  Future<void> _exportExecutiveSummary(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กำลังสร้างไฟล์ CSV...'),
          backgroundColor: Colors.blue,
        ),
      );

      final csvBuffer = StringBuffer();
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy', 'th').format(now);
      
      // Helper function (reuse existing _parseInt from class)
      int parseValue(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) {
          return int.tryParse(value) ?? 0;
        }
        if (value is double) return value.toInt();
        return 0;
      }
      
      final totals = _currentTotals ?? widget.totals;
      final employeeSummary = _currentEmployeeSummary ?? widget.employeeSummary;
      
      // Header
      csvBuffer.writeln('รายงานสรุปสำหรับผู้บริหาร');
      csvBuffer.writeln('วันที่,$dateStr');
      csvBuffer.writeln('');
      csvBuffer.writeln('ตัวชี้วัดหลัก');
      csvBuffer.writeln('จำนวนพนักงาน,${parseValue(totals['total_employees'])}');
      csvBuffer.writeln('วันลาที่อนุมัติ,${parseValue(totals['total_approved_days'])}');
      csvBuffer.writeln('รออนุมัติ,${parseValue(totals['total_pending_days'])}');
      csvBuffer.writeln('ไม่อนุมัติ,${parseValue(totals['total_rejected_days'])}');
      csvBuffer.writeln('');
      csvBuffer.writeln('สรุปตามแผนก');
      csvBuffer.writeln('แผนก,จำนวนคน,ลาทั้งหมด,รออนุมัติ');
      
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
          parseValue(emp['total_leave_days']);
        deptStats[dept]!['pending'] = (deptStats[dept]!['pending'] ?? 0) + 
          parseValue(emp['pending_leave_days']);
      }
      
      // Data
      for (var entry in deptStats.entries) {
        csvBuffer.writeln(
          '${entry.key},'
          '${entry.value['count']},'
          '${entry.value['totalLeave']},'
          '${entry.value['pending']}'
        );
      }

      // Save CSV file
      final output = await getTemporaryDirectory();
      final fileName = 'รายงานสรุปสำหรับผู้บริหาร_${now.millisecondsSinceEpoch}.csv';
      final filePath = '${output.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(csvBuffer.toString().codeUnits);

      // Share or open file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'รายงานสรุปสำหรับผู้บริหาร - $dateStr',
        subject: 'รายงานสรุปสำหรับผู้บริหาร',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export CSV สำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

