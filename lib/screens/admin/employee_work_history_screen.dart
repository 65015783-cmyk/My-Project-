import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../models/attendance_model.dart';

/// หน้าจอแสดงประวัติการทำงานของพนักงานแต่ละคน (สำหรับ HR / Admin)
class EmployeeWorkHistoryScreen extends StatefulWidget {
  final String employeeId;
  final String fullName;
  final String? department;
  final String? position;

  const EmployeeWorkHistoryScreen({
    super.key,
    required this.employeeId,
    required this.fullName,
    this.department,
    this.position,
  });

  @override
  State<EmployeeWorkHistoryScreen> createState() => _EmployeeWorkHistoryScreenState();
}

class _EmployeeWorkHistoryScreenState extends State<EmployeeWorkHistoryScreen> {
  bool _isLoading = true;
  List<AttendanceModel> _history = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmployeeHistory();
  }

  Future<void> _loadEmployeeHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'กรุณาเข้าสู่ระบบก่อน';
          _history = [];
        });
        return;
      }

      // ใช้ attendanceAllUrl และให้ Backend กรองเองถ้ารองรับ query parameter
      // หากไม่รองรับ เราจะกรองเองที่ฝั่ง Client อีกชั้นหนึ่ง
      final uri = Uri.parse(ApiConfig.attendanceAllUrl).replace(
        queryParameters: {
          // รองรับได้หลายชื่อ field ใน Backend
          'employeeId': widget.employeeId,
          'userId': widget.employeeId,
        },
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ไม่สามารถโหลดประวัติการทำงานได้ (Status: ${response.statusCode})';
          _history = [];
        });
        return;
      }

      final decoded = json.decode(response.body);

      // รองรับหลายรูปแบบ response
      List<dynamic> rawList;
      if (decoded is Map<String, dynamic>) {
        if (decoded['attendances'] is List) {
          rawList = decoded['attendances'] as List<dynamic>;
        } else if (decoded['attendance'] is List) {
          rawList = decoded['attendance'] as List<dynamic>;
        } else if (decoded['data'] is List) {
          rawList = decoded['data'] as List<dynamic>;
        } else {
          rawList = const [];
        }
      } else if (decoded is List) {
        rawList = decoded;
      } else {
        rawList = const [];
      }

      final List<AttendanceModel> items = [];
      final defaultSchedule = WorkSchedule.defaultSchedule();

      for (final raw in rawList) {
        if (raw is! Map<String, dynamic>) continue;

        final attendanceData = raw;

        // ตรวจสอบให้แน่ใจว่าเป็นของพนักงานคนที่ต้องการ
        final idValue = attendanceData['user_id']?.toString() ??
            attendanceData['employee_id']?.toString() ??
            attendanceData['userId']?.toString() ??
            attendanceData['employeeId']?.toString();

        if (idValue == null || idValue != widget.employeeId) {
          continue;
        }

        try {
          // Parse date
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final dateStr = attendanceData['date']?.toString() ??
              attendanceData['attendance_date']?.toString() ??
              '';
          final attendanceDate = dateStr.isNotEmpty
              ? DateTime.parse(dateStr.split(' ')[0].split('T')[0])
              : today;

          DateTime? checkInTime;
          DateTime? checkOutTime;

          // check_in_time (รองรับทั้ง DATETIME และ ISO8601 + Z)
          final checkInTimeValue = attendanceData['check_in_time'] ??
              attendanceData['checkInTime'] ??
              attendanceData['check_in'] ??
              attendanceData['clock_in'];
          if (checkInTimeValue != null && checkInTimeValue.toString().isNotEmpty) {
            try {
              final timeStr = checkInTimeValue.toString().trim();
              if (timeStr.contains('T')) {
                checkInTime = DateTime.parse(timeStr).toLocal();
              } else {
                checkInTime = DateTime.parse(timeStr);
              }
            } catch (_) {}
          }

          // check_out_time (รองรับทั้ง DATETIME และ ISO8601 + Z)
          final checkOutTimeValue = attendanceData['check_out_time'] ??
              attendanceData['checkOutTime'] ??
              attendanceData['check_out'] ??
              attendanceData['clock_out'];
          if (checkOutTimeValue != null && checkOutTimeValue.toString().isNotEmpty) {
            try {
              final timeStr = checkOutTimeValue.toString().trim();
              if (timeStr.contains('T')) {
                checkOutTime = DateTime.parse(timeStr).toLocal();
              } else {
                checkOutTime = DateTime.parse(timeStr);
              }
            } catch (_) {}
          }

          items.add(
            AttendanceModel(
              id: 'att_${attendanceData['id'] ?? attendanceDate.millisecondsSinceEpoch}',
              date: attendanceDate,
              checkInTime: checkInTime,
              checkOutTime: checkOutTime,
              checkInImagePath: attendanceData['check_in_image_path']?.toString(),
              workSchedule: defaultSchedule,
            ),
          );
        } catch (_) {
          // ข้าม record ที่ parse ไม่ได้
          continue;
        }
      }

      // เรียงจากวันที่ล่าสุดไปเก่าสุด
      items.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _history = items;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
        _history = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyItems = _mapAttendanceToHistoryItems(_history);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('ประวัติการทำงาน'),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : historyItems.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadEmployeeHistory,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: historyItems.length,
                              itemBuilder: (context, index) {
                                return _buildHistoryCard(historyItems[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final initials = widget.fullName.trim().isNotEmpty ? widget.fullName.trim()[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[100],
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.position != null && widget.position!.isNotEmpty)
                  Text(
                    widget.position!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                if (widget.department != null && widget.department!.isNotEmpty)
                  Text(
                    widget.department!,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีประวัติการทำงาน',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'เกิดข้อผิดพลาด',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadEmployeeHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่อีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.date,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: item.status.color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.status == WorkStatus.complete
                            ? Icons.check_circle
                            : item.status == WorkStatus.pending
                                ? Icons.pending
                                : Icons.cancel,
                        size: 14,
                        color: item.status.color,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.status.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: item.status.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTimeItem('เข้างาน', item.checkIn, Colors.green),
                const SizedBox(width: 20),
                _buildTimeItem('ออกงาน', item.checkOut, Colors.orange),
              ],
            ),
            if (item.hoursWorked != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'รวมเวลาทำงาน: ${item.hoursWorked} ชั่วโมง',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeItem(String label, String time, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<HistoryItem> _mapAttendanceToHistoryItems(List<AttendanceModel> records) {
    return records.map((att) {
      final checkIn = att.checkInTimeFormatted;
      final checkOut = att.checkOutTimeFormatted;

      String? hoursWorked;
      if (att.checkInTime != null && att.checkOutTime != null) {
        final diff = att.checkOutTime!.difference(att.checkInTime!).inMinutes;
        final hours = diff / 60;
        hoursWorked = hours.toStringAsFixed(1);
      }

      final status = att.checkInTime != null && att.checkOutTime != null
          ? WorkStatus.complete // เข้างานและออกงานครบ
          : att.checkInTime != null
              ? WorkStatus.pending // เข้างานแล้ว แต่ยังไม่ออกงาน
              : WorkStatus.absent; // ไม่ได้เข้างาน

      // ใช้รูปแบบวันที่ไทยเหมือนในหน้าลูกจ้างทั่วไป
      final dateFormatted = DateFormat('EEEE d MMMM y', 'th_TH').format(att.date.add(const Duration(days: 0)));

      return HistoryItem(
        date: dateFormatted,
        checkIn: checkIn,
        checkOut: checkOut,
        hoursWorked: hoursWorked,
        status: status,
      );
    }).toList();
  }
}

class HistoryItem {
  final String date;
  final String checkIn;
  final String checkOut;
  final String? hoursWorked;
  final WorkStatus status;

  HistoryItem({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    this.hoursWorked,
    required this.status,
  });
}

enum WorkStatus {
  complete(Colors.green, 'เข้างานและออกงานครบ'),
  pending(Colors.orange, 'ยังไม่ออกงาน'),
  absent(Colors.red, 'ขาดงาน');

  final Color color;
  final String label;

  const WorkStatus(this.color, this.label);
}

