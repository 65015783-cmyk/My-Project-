import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

enum OvertimeStatus {
  pending('รออนุมัติ', Colors.orange),
  approved('อนุมัติแล้ว', Colors.green),
  rejected('ไม่อนุมัติ', Colors.red);

  final String label;
  final Color color;

  const OvertimeStatus(this.label, this.color);
}

class OvertimeRequest {
  final int id;
  final int userId;
  final DateTime date;
  final String startTime; // Format: "HH:mm"
  final String endTime; // Format: "HH:mm"
  final double totalHours;
  final String? reason;
  final OvertimeStatus status;
  final int? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Additional fields from join
  final String? employeeName;
  final String? department;
  final String? position;
  final String? approverName;
  
  // Evidence image path
  final String? evidenceImagePath;

  OvertimeRequest({
    required this.id,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalHours,
    this.reason,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    this.employeeName,
    this.department,
    this.position,
    this.approverName,
    this.evidenceImagePath,
  });

  String get dateFormatted {
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

  String get timeRangeFormatted {
    return '$startTime - $endTime';
  }

  String get totalHoursFormatted {
    return '${totalHours.toStringAsFixed(2)} ชั่วโมง';
  }

  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
    // Helper function to parse hours (รองรับทั้ง String และ num)
    double parseHours(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    // Helper function to parse int (รองรับทั้ง String และ num)
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    return OvertimeRequest(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      totalHours: parseHours(json['total_hours']),
      reason: json['reason'] as String?,
      status: OvertimeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OvertimeStatus.pending,
      ),
      approvedBy: json['approved_by'] != null ? parseInt(json['approved_by']) : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      employeeName: json['employee_name'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      approverName: json['approver_name'] as String?,
      evidenceImagePath: json['evidence_image_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'total_hours': totalHours,
      'reason': reason,
      'status': status.name,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class OvertimeSummary {
  final int totalRequests;
  final double approvedHours;
  final double pendingHours;
  final double rejectedHours;

  OvertimeSummary({
    required this.totalRequests,
    required this.approvedHours,
    required this.pendingHours,
    required this.rejectedHours,
  });

  factory OvertimeSummary.fromJson(Map<String, dynamic> json) {
    // รองรับทั้ง String และ num
    int parseTotalRequests(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    double parseHours(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return OvertimeSummary(
      totalRequests: parseTotalRequests(json['total_requests']),
      approvedHours: parseHours(json['approved_hours']),
      pendingHours: parseHours(json['pending_hours']),
      rejectedHours: parseHours(json['rejected_hours']),
    );
  }
}

class OvertimeRate {
  final int id;
  final String rateType; // 'weekday', 'weekend', 'holiday'
  final double multiplier;
  final String? description;

  OvertimeRate({
    required this.id,
    required this.rateType,
    required this.multiplier,
    this.description,
  });

  String get rateTypeLabel {
    switch (rateType) {
      case 'weekday':
        return 'วันธรรมดา';
      case 'weekend':
        return 'วันหยุดสุดสัปดาห์';
      case 'holiday':
        return 'วันหยุดนักขัตฤกษ์';
      default:
        return rateType;
    }
  }

  factory OvertimeRate.fromJson(Map<String, dynamic> json) {
    return OvertimeRate(
      id: json['id'] as int,
      rateType: json['rate_type'] as String,
      multiplier: (json['multiplier'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }
}
