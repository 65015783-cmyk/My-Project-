import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

enum LeaveType {
  sickLeave('ลาป่วย', 'Sick Leave'),
  personalLeave('ลากิจส่วนตัว', 'Personal Leave');

  final String thaiLabel;
  final String englishLabel;
  
  const LeaveType(this.thaiLabel, this.englishLabel);
}

enum LeaveStatus {
  pending('รออนุมัติ', Colors.orange),
  approved('อนุมัติแล้ว', Colors.green),
  rejected('ไม่อนุมัติ', Colors.red);

  final String label;
  final Color color;

  const LeaveStatus(this.label, this.color);
}

class LeaveRequest {
  final String id;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final List<String> documentPaths;
  final String approver;
  final LeaveStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? rejectionReason;

  LeaveRequest({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.documentPaths,
    required this.approver,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.rejectionReason,
  });

  String get dateRangeFormatted {
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return _formatThaiDate(startDate);
    }
    return '${_formatThaiDate(startDate)} - ${_formatThaiDate(endDate)}';
  }

  String _formatThaiDate(DateTime date) {
    final thaiDays = [
      'วันอาทิตย์',
      'วันจันทร์',
      'วันอังคาร',
      'วันพุธ',
      'วันพฤหัสบดี',
      'วันศุกร์',
      'วันเสาร์',
    ];
    
    final thaiMonths = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];

    final weekdayIndex = date.weekday == 7 ? 0 : date.weekday;
    final weekday = thaiDays[weekdayIndex];
    final day = date.day;
    final month = thaiMonths[date.month - 1];
    final year = date.year + 543;

    return '$weekday $day $month $year';
  }

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as String,
      type: LeaveType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LeaveType.personalLeave,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalDays: json['totalDays'] as int,
      reason: json['reason'] as String,
      documentPaths: List<String>.from(json['documentPaths'] as List),
      approver: json['approver'] as String,
      status: LeaveStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LeaveStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'totalDays': totalDays,
      'reason': reason,
      'documentPaths': documentPaths,
      'approver': approver,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }
}

class LeaveBalance {
  final int sickLeaveRemaining;
  final int personalLeaveRemaining;
  final int totalRemaining;

  LeaveBalance({
    required this.sickLeaveRemaining,
    required this.personalLeaveRemaining,
  }) : totalRemaining = sickLeaveRemaining + personalLeaveRemaining;

  factory LeaveBalance.defaultBalance() {
    return LeaveBalance(
      sickLeaveRemaining: 30,
      personalLeaveRemaining: 10,
    );
  }
}

