import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// Model สำหรับข้อมูลประวัติเงินเดือน (salary_history table)
class SalaryHistoryModel {
  final int salaryId;
  final int employeeId;
  final double salaryAmount;
  final DateTime effectiveDate;
  final SalaryType salaryType;
  final String? reason;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SalaryHistoryModel({
    required this.salaryId,
    required this.employeeId,
    required this.salaryAmount,
    required this.effectiveDate,
    required this.salaryType,
    this.reason,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  /// แปลงจาก JSON
  factory SalaryHistoryModel.fromJson(Map<String, dynamic> json) {
    return SalaryHistoryModel(
      salaryId: json['salary_id'] as int? ?? 
                int.tryParse(json['salary_id']?.toString() ?? '') ?? 0,
      employeeId: json['employee_id'] as int? ?? 
                  int.tryParse(json['employee_id']?.toString() ?? '') ?? 0,
      salaryAmount: (json['salary_amount'] as num?)?.toDouble() ?? 0.0,
      effectiveDate: json['effective_date'] != null
          ? DateTime.parse(json['effective_date'].toString().split(' ')[0])
          : DateTime.now(),
      salaryType: SalaryType.fromString(json['salary_type']?.toString() ?? 'START'),
      reason: json['reason']?.toString(),
      createdBy: json['created_by'] as int? ?? 
                 (json['created_by'] != null 
                     ? int.tryParse(json['created_by'].toString()) 
                     : null),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
    );
  }

  /// แปลงเป็น JSON
  Map<String, dynamic> toJson() {
    return {
      'salary_id': salaryId,
      'employee_id': employeeId,
      'salary_amount': salaryAmount,
      'effective_date': effectiveDate.toIso8601String().split('T')[0],
      'salary_type': salaryType.value,
      'reason': reason,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// รูปแบบวันที่ที่มีผล (ภาษาไทย)
  String get effectiveDateFormatted {
    final thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    
    final day = effectiveDate.day;
    final month = thaiMonths[effectiveDate.month - 1];
    final year = effectiveDate.year + 543; // แปลงเป็น พ.ศ.
    
    return '$day $month $year';
  }

  /// รูปแบบเงินเดือน (พร้อม comma และ บาท)
  String get salaryAmountFormatted {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(salaryAmount)} บาท';
  }
}

/// Enum สำหรับประเภทเงินเดือน
enum SalaryType {
  start('START', 'เงินเดือนเริ่มต้น'),
  adjust('ADJUST', 'ปรับเงินเดือน');

  final String value;
  final String label;

  const SalaryType(this.value, this.label);

  static SalaryType fromString(String value) {
    return SalaryType.values.firstWhere(
      (type) => type.value == value.toUpperCase(),
      orElse: () => SalaryType.start,
    );
  }
}

/// Model สำหรับข้อมูลสรุปเงินเดือนของพนักงาน
class EmployeeSalarySummary {
  final int employeeId;
  final String fullName;
  final String? position;
  final String? department;
  final double currentSalary;
  final double startingSalary;
  final double baseSalary;
  final int adjustmentCount;
  final DateTime? lastAdjustmentDate;
  final SalaryHistoryModel? lastAdjustment;

  EmployeeSalarySummary({
    required this.employeeId,
    required this.fullName,
    this.position,
    this.department,
    required this.currentSalary,
    required this.startingSalary,
    required this.baseSalary,
    required this.adjustmentCount,
    this.lastAdjustmentDate,
    this.lastAdjustment,
  });

  factory EmployeeSalarySummary.fromJson(Map<String, dynamic> json) {
    // Parse current_salary - อาจเป็น num หรือ String
    double parseSalary(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? 0.0;
      }
      return 0.0;
    }

    // Base salary: use base_salary if provided, otherwise use current_salary
    final baseSalaryValue = parseSalary(json['base_salary'] ?? json['current_salary']);
    
    return EmployeeSalarySummary(
      employeeId: json['employee_id'] as int? ?? 
                  int.tryParse(json['employee_id']?.toString() ?? '') ?? 0,
      fullName: json['full_name']?.toString() ?? 
                '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      position: json['position']?.toString(),
      department: json['department']?.toString(),
      currentSalary: parseSalary(json['current_salary']),
      startingSalary: parseSalary(json['starting_salary']),
      baseSalary: baseSalaryValue,
      adjustmentCount: json['adjustment_count'] as int? ?? 
                      int.tryParse(json['adjustment_count']?.toString() ?? '0') ?? 0,
      lastAdjustmentDate: json['last_adjustment_date'] != null
          ? DateTime.parse(json['last_adjustment_date'].toString().split(' ')[0])
          : null,
      lastAdjustment: json['last_adjustment'] != null
          ? SalaryHistoryModel.fromJson(json['last_adjustment'] as Map<String, dynamic>)
          : null,
    );
  }

  /// เงินเดือนปัจจุบัน (Format)
  String get currentSalaryFormatted {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(currentSalary)} บาท';
  }

  /// เงินเดือนแรก (Format)
  String get startingSalaryFormatted {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(startingSalary)} บาท';
  }

  /// เงินฐานเงินเดือน (Format)
  String get baseSalaryFormatted {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(baseSalary)} บาท';
  }

  /// วันที่ปรับล่าสุด (Format)
  String get lastAdjustmentDateFormatted {
    if (lastAdjustmentDate == null) return '-';
    final thaiMonths = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
    ];
    
    return '${lastAdjustmentDate!.day} ${thaiMonths[lastAdjustmentDate!.month - 1]} ${lastAdjustmentDate!.year + 543}';
  }
}

/// Model สำหรับข้อมูลสรุปภาพรวม (Dashboard Summary)
class SalaryDashboardSummary {
  final int totalEmployees;
  final double averageSalary;
  final double maxSalary;
  final double minSalary;
  final int adjustmentsThisMonth;

  SalaryDashboardSummary({
    required this.totalEmployees,
    required this.averageSalary,
    required this.maxSalary,
    required this.minSalary,
    required this.adjustmentsThisMonth,
  });

  factory SalaryDashboardSummary.fromJson(Map<String, dynamic> json) {
    return SalaryDashboardSummary(
      totalEmployees: json['total_employees'] as int? ?? 
                     int.tryParse(json['total_employees']?.toString() ?? '0') ?? 0,
      averageSalary: (json['average_salary'] as num?)?.toDouble() ?? 0.0,
      maxSalary: (json['max_salary'] as num?)?.toDouble() ?? 0.0,
      minSalary: (json['min_salary'] as num?)?.toDouble() ?? 0.0,
      adjustmentsThisMonth: json['adjustments_this_month'] as int? ?? 
                           int.tryParse(json['adjustments_this_month']?.toString() ?? '0') ?? 0,
    );
  }

  /// เงินเดือนเฉลี่ย (Format)
  String get averageSalaryFormatted {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(averageSalary)} บาท';
  }

  /// เงินเดือนสูงสุด (Format)
  String get maxSalaryFormatted {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(maxSalary)} บาท';
  }

  /// เงินเดือนต่ำสุด (Format)
  String get minSalaryFormatted {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(minSalary)} บาท';
  }
}

/// Model สำหรับข้อมูล Payroll Overview (ภาพรวมเงินเดือนประจำเดือน)
class PayrollOverview {
  final double totalGrossSalary; // ยอดเงินเดือนรวมประจำเดือน
  final int totalEmployees; // จำนวนพนักงานที่รับเงินเดือน
  final double totalDeductions; // ยอดหักรวม (ประกันสังคม, ภาษี, สาย/ขาดงาน)
  final double netPay; // ยอดจ่ายสุทธิ (Net Pay)
  final PayrollStatus status; // สถานะการจ่ายเงิน
  final int month; // เดือน
  final int year; // ปี

  PayrollOverview({
    required this.totalGrossSalary,
    required this.totalEmployees,
    required this.totalDeductions,
    required this.netPay,
    required this.status,
    required this.month,
    required this.year,
  });

  factory PayrollOverview.fromJson(Map<String, dynamic> json) {
    return PayrollOverview(
      totalGrossSalary: (json['total_gross_salary'] as num?)?.toDouble() ?? 0.0,
      totalEmployees: json['total_employees'] as int? ?? 0,
      totalDeductions: (json['total_deductions'] as num?)?.toDouble() ?? 0.0,
      netPay: (json['net_pay'] as num?)?.toDouble() ?? 0.0,
      status: PayrollStatus.fromString(json['status']?.toString() ?? 'PENDING'),
      month: json['month'] as int? ?? DateTime.now().month,
      year: json['year'] as int? ?? DateTime.now().year,
    );
  }

  /// ยอดเงินเดือนรวม (Format)
  String get totalGrossSalaryFormatted {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(totalGrossSalary.round())} บาท';
  }

  /// ยอดหักรวม (Format)
  String get totalDeductionsFormatted {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(totalDeductions.round())} บาท';
  }

  /// ยอดจ่ายสุทธิ (Format)
  String get netPayFormatted {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(netPay.round())} บาท';
  }

  /// ชื่อเดือนภาษาไทย
  String get monthName {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
      'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
      'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return months[month - 1];
  }
}

/// Enum สำหรับสถานะการจ่ายเงิน
enum PayrollStatus {
  pending('PENDING', 'รอคำนวณ', Colors.orange),
  calculated('CALCULATED', 'คำนวณแล้ว', Colors.blue),
  paid('PAID', 'จ่ายแล้ว', Colors.green);

  final String value;
  final String label;
  final Color color;

  const PayrollStatus(this.value, this.label, this.color);

  static PayrollStatus fromString(String value) {
    return PayrollStatus.values.firstWhere(
      (status) => status.value == value.toUpperCase(),
      orElse: () => PayrollStatus.pending,
    );
  }
}

