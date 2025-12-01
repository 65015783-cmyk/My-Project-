import 'package:flutter/foundation.dart';
import '../models/leave_model.dart';

class LeaveService extends ChangeNotifier {
  List<LeaveRequest> _leaveRequests = [];
  LeaveBalance _leaveBalance = LeaveBalance.defaultBalance();

  List<LeaveRequest> get leaveRequests => List.unmodifiable(_leaveRequests);
  LeaveBalance get leaveBalance => _leaveBalance;

  LeaveService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Mock leave requests
    _leaveRequests = [
      LeaveRequest(
        id: 'leave_1',
        type: LeaveType.sickLeave,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().subtract(const Duration(days: 3)),
        totalDays: 3,
        reason: 'ไม่สบาย มีไข้',
        documentPaths: [],
        approver: 'หัวหน้าแผนก',
        status: LeaveStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      LeaveRequest(
        id: 'leave_2',
        type: LeaveType.personalLeave,
        startDate: DateTime.now().add(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        totalDays: 3,
        reason: 'ธุระส่วนตัว',
        documentPaths: [],
        approver: 'หัวหน้าแผนก',
        status: LeaveStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
    notifyListeners();
  }

  Future<void> submitLeaveRequest({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required List<String> documentPaths,
  }) async {
    final totalDays = _calculateTotalDays(startDate, endDate);
    
    final newRequest = LeaveRequest(
      id: 'leave_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      startDate: startDate,
      endDate: endDate,
      totalDays: totalDays,
      reason: reason,
      documentPaths: documentPaths,
      approver: 'หัวหน้าแผนก',
      status: LeaveStatus.pending,
      createdAt: DateTime.now(),
    );

    _leaveRequests.insert(0, newRequest);
    
    // Update leave balance (mock)
    if (type == LeaveType.sickLeave) {
      _leaveBalance = LeaveBalance(
        sickLeaveRemaining: _leaveBalance.sickLeaveRemaining - totalDays,
        personalLeaveRemaining: _leaveBalance.personalLeaveRemaining,
      );
    } else {
      _leaveBalance = LeaveBalance(
        sickLeaveRemaining: _leaveBalance.sickLeaveRemaining,
        personalLeaveRemaining: _leaveBalance.personalLeaveRemaining - totalDays,
      );
    }

    notifyListeners();
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

