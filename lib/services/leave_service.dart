import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leave_model.dart';
import '../config/api_config.dart';

class LeaveService extends ChangeNotifier {
  List<LeaveRequest> _leaveRequests = [];
  LeaveBalance _leaveBalance = LeaveBalance.defaultBalance();

  List<LeaveRequest> get leaveRequests => List.unmodifiable(_leaveRequests);
  LeaveBalance get leaveBalance => _leaveBalance;

  LeaveService() {
    _loadLeaveHistory();
    _loadLeaveBalance();
  }

  // โหลดประวัติการลาจาก backend
  Future<void> _loadLeaveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _initializeMockData(); // ใช้ mock data ถ้าไม่มี token
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.leaveHistoryUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final leaves = data['leaves'] as List<dynamic>? ?? [];
        
        _leaveRequests = leaves.map((leave) {
          return LeaveRequest(
            id: leave['id'].toString(),
            type: _parseLeaveType(leave['leave_type']),
            startDate: DateTime.parse(leave['start_date']),
            endDate: DateTime.parse(leave['end_date']),
            totalDays: leave['total_days'] != null
                ? (leave['total_days'] as num).toDouble()
                : _calculateTotalDays(
                    DateTime.parse(leave['start_date']),
                    DateTime.parse(leave['end_date']),
                  ).toDouble(),
            reason: leave['reason'] ?? '',
            documentPaths: [],
            approver: leave['approved_by'] != null ? 'Manager' : '',
            status: _parseLeaveStatus(leave['status']),
            createdAt: DateTime.parse(leave['created_at']),
            updatedAt: leave['updated_at'] != null 
                ? DateTime.parse(leave['updated_at']) 
                : null,
          );
        }).toList();
        
        notifyListeners();
      } else {
        _initializeMockData(); // ใช้ mock data ถ้าโหลดไม่สำเร็จ
      }
    } catch (e) {
      print('Error loading leave history: $e');
      _initializeMockData(); // ใช้ mock data ถ้าเกิด error
    }
  }

  void _initializeMockData() {
    // Mock leave requests (fallback)
    _leaveRequests = [];
    notifyListeners();
  }

  /// โหลดยอดวันลาคงเหลือจาก backend (ข้อมูลปัจจุบัน)
  Future<void> _loadLeaveBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _leaveBalance = LeaveBalance.defaultBalance();
        notifyListeners();
        return;
      }

      final currentYear = DateTime.now().year;
      final response = await http.get(
        Uri.parse('${ApiConfig.leaveMySummaryUrl}?year=$currentYear'),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // สมมติ backend ส่ง key: totalLeave, sickUsed, personalUsed, remaining
        final int total = (data['totalLeave'] as num?)?.toInt() ?? 0;
        final int sickUsed = (data['sickUsed'] as num?)?.toInt() ?? 0;
        final int personalUsed = (data['personalUsed'] as num?)?.toInt() ?? 0;
        final int remaining = (data['remaining'] as num?)?.toInt() ?? 0;

        // แปลงเป็น LeaveBalance: เหลือป่วย/ลากิจ และรวม
        final sickRemaining = (data['sickRemaining'] as num?)?.toInt() ??
            (total - sickUsed);
        final personalRemaining =
            (data['personalRemaining'] as num?)?.toInt() ??
                (remaining - sickRemaining);

        // คำนวณ earlyLeave และ halfDayLeave ที่เหลือ
        final currentYear = DateTime.now().year;
        final earlyLeaveUsed = _leaveRequests.where((leave) =>
            leave.type == LeaveType.earlyLeave &&
            leave.startDate.year == currentYear &&
            leave.status != LeaveStatus.rejected).length;
        final halfDayLeaveUsed = _leaveRequests.where((leave) =>
            leave.type == LeaveType.halfDayLeave &&
            leave.startDate.year == currentYear &&
            leave.status != LeaveStatus.rejected).length;
        
        final int earlyLeaveRemaining;
        if (data['earlyLeaveRemaining'] != null) {
          earlyLeaveRemaining = (data['earlyLeaveRemaining'] as num).toInt();
        } else {
          earlyLeaveRemaining = (10 - earlyLeaveUsed).clamp(0, 10);
        }
        
        final int halfDayLeaveRemaining;
        if (data['halfDayLeaveRemaining'] != null) {
          halfDayLeaveRemaining = (data['halfDayLeaveRemaining'] as num).toInt();
        } else {
          halfDayLeaveRemaining = (999 - halfDayLeaveUsed).clamp(0, 999);
        }

        _leaveBalance = LeaveBalance(
          sickLeaveRemaining: sickRemaining,
          personalLeaveRemaining: personalRemaining,
          earlyLeaveRemaining: earlyLeaveRemaining,
          halfDayLeaveRemaining: halfDayLeaveRemaining,
        );
        notifyListeners();
      } else {
        // ถ้า API พัง ใช้ค่าที่มีอยู่ (หรือ default)
        _leaveBalance = _leaveBalance;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading leave balance: $e');
      // ไม่ reset ค่าเดิม เผื่อ UI ยังใช้ได้
      notifyListeners();
    }
  }

  // ส่งคำขอลาไปยัง backend API
  Future<void> submitLeaveRequest({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required List<String> documentPaths,
    required double totalDays, // รับ totalDays จาก UI
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('ไม่พบ Token การยืนยันตัวตน');
      }

      // แปลง LeaveType เป็น string สำหรับ API
      String leaveType;
      switch (type) {
        case LeaveType.sickLeave:
          leaveType = 'sick';
          break;
        case LeaveType.personalLeave:
          leaveType = 'personal';
          break;
        case LeaveType.earlyLeave:
          leaveType = 'early';
          break;
        case LeaveType.halfDayLeave:
          leaveType = 'half_day';
          break;
      }

      // ส่งคำขอลาไปยัง backend
      final response = await http.post(
        Uri.parse(ApiConfig.leaveRequestUrl),
        headers: ApiConfig.headersWithAuth(token),
        body: json.encode({
          'leaveType': leaveType,
          'startDate': startDate.toIso8601String().split('T')[0], // YYYY-MM-DD
          'endDate': endDate.toIso8601String().split('T')[0], // YYYY-MM-DD
          'reason': reason,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // สร้าง leave request object (ใช้ totalDays ที่ส่งมา)
        final newRequest = LeaveRequest(
          id: data['leaveId'].toString(),
          type: type,
          startDate: startDate,
          endDate: endDate,
          totalDays: totalDays,
          reason: reason,
          documentPaths: documentPaths,
          approver: '', // ยังไม่มีคนอนุมัติ
          status: LeaveStatus.pending,
          createdAt: DateTime.now(),
        );

        _leaveRequests.insert(0, newRequest);
        
        // Update leave balance (หักเฉพาะวันลาป่วยและลากิจเต็มวัน)
        // สำหรับลาครึ่งวัน (0.5 วัน) ให้หักจาก personal leave
        switch (type) {
          case LeaveType.sickLeave:
            _leaveBalance = LeaveBalance(
              sickLeaveRemaining: (_leaveBalance.sickLeaveRemaining - totalDays).round(),
              personalLeaveRemaining: _leaveBalance.personalLeaveRemaining,
              earlyLeaveRemaining: _leaveBalance.earlyLeaveRemaining,
              halfDayLeaveRemaining: _leaveBalance.halfDayLeaveRemaining,
            );
            break;
          case LeaveType.personalLeave:
            _leaveBalance = LeaveBalance(
              sickLeaveRemaining: _leaveBalance.sickLeaveRemaining,
              personalLeaveRemaining:
                  (_leaveBalance.personalLeaveRemaining - totalDays).round(),
              earlyLeaveRemaining: _leaveBalance.earlyLeaveRemaining,
              halfDayLeaveRemaining: _leaveBalance.halfDayLeaveRemaining,
            );
            break;
          case LeaveType.halfDayLeave:
            // ลาครึ่งวัน → หัก 0.5 วันจาก personal leave และหักจำนวนครั้ง
            _leaveBalance = LeaveBalance(
              sickLeaveRemaining: _leaveBalance.sickLeaveRemaining,
              personalLeaveRemaining:
                  (_leaveBalance.personalLeaveRemaining - totalDays).round(),
              earlyLeaveRemaining: _leaveBalance.earlyLeaveRemaining,
              halfDayLeaveRemaining: (_leaveBalance.halfDayLeaveRemaining - 1).clamp(0, 999),
            );
            break;
          case LeaveType.earlyLeave:
            // ลากลับก่อน: ถ้า > 2 ชม. (0.5 วัน) → หักจาก personal leave
            // ถ้า ≤ 2 ชม. (0 วัน) → ไม่หัก
            // แต่หักจำนวนครั้งเสมอ
            _leaveBalance = LeaveBalance(
              sickLeaveRemaining: _leaveBalance.sickLeaveRemaining,
              personalLeaveRemaining: totalDays > 0
                  ? (_leaveBalance.personalLeaveRemaining - totalDays).round()
                  : _leaveBalance.personalLeaveRemaining,
              earlyLeaveRemaining: (_leaveBalance.earlyLeaveRemaining - 1).clamp(0, 10),
              halfDayLeaveRemaining: _leaveBalance.halfDayLeaveRemaining,
            );
            break;
        }

        notifyListeners();
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        throw Exception(errorData?['message'] ?? 'เกิดข้อผิดพลาดในการส่งคำขอลางาน');
      }
    } catch (e) {
      print('Error submitting leave request: $e');
      rethrow; // Throw error เพื่อให้ UI แสดง error message
    }
  }

  // Helper functions
  LeaveType _parseLeaveType(String? type) {
    switch (type) {
      case 'sick':
        return LeaveType.sickLeave;
      case 'personal':
        return LeaveType.personalLeave;
      case 'early':
        return LeaveType.earlyLeave;
      case 'half_day':
        return LeaveType.halfDayLeave;
      case 'vacation':
        return LeaveType.personalLeave; // map vacation to personalLeave
      default:
        return LeaveType.personalLeave;
    }
  }

  LeaveStatus _parseLeaveStatus(String? status) {
    switch (status) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'pending':
      default:
        return LeaveStatus.pending;
    }
  }

  int _calculateTotalDays(DateTime start, DateTime end) {
    // Calculate business days (excluding weekends)
    int days = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      // Exclude weekends: Saturday (6) and Sunday (7)
      if (current.weekday != DateTime.saturday && 
          current.weekday != DateTime.sunday) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  void updateLeaveStatus(String leaveId, LeaveStatus status, {String? rejectionReason}) {
    final index = _leaveRequests.indexWhere((leave) => leave.id == leaveId);
    if (index != -1) {
      final leave = _leaveRequests[index];
      _leaveRequests[index] = LeaveRequest(
        id: leave.id,
        type: leave.type,
        startDate: leave.startDate,
        endDate: leave.endDate,
        totalDays: leave.totalDays,
        reason: leave.reason,
        documentPaths: leave.documentPaths,
        approver: leave.approver,
        status: status,
        createdAt: leave.createdAt,
        updatedAt: DateTime.now(),
        rejectionReason: rejectionReason,
      );
      notifyListeners();
    }
  }
}

