import 'package:intl/intl.dart';

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
    required this.adjustmentCount,
    this.lastAdjustmentDate,
    this.lastAdjustment,
  });

  factory EmployeeSalarySummary.fromJson(Map<String, dynamic> json) {
    return EmployeeSalarySummary(
      employeeId: json['employee_id'] as int? ?? 
                  int.tryParse(json['employee_id']?.toString() ?? '') ?? 0,
      fullName: json['full_name']?.toString() ?? 
                '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      position: json['position']?.toString(),
      department: json['department']?.toString(),
      currentSalary: (json['current_salary'] as num?)?.toDouble() ?? 0.0,
      startingSalary: (json['starting_salary'] as num?)?.toDouble() ?? 0.0,
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

