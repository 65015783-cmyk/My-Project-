class Salary {
  final String month;
  final int year;
  final DateTime paymentDate;
  final double baseSalary;
  final double bonus;
  final double overtime;
  final double commission; // ค่าคอมมิชชั่น
  final double allowance;
  final double positionAllowance; // ค่าตำแหน่ง
  final double transportAllowance;
  final double otherIncome;
  final double tax;
  final double socialSecurity;
  final double providentFund;
  final double loan;
  final double fine;
  final double otherDeductions;
  final int workDays;
  final int leaveDays;
  final double overtimeHours;

  Salary({
    required this.month,
    required this.year,
    required this.paymentDate,
    required this.baseSalary,
    this.bonus = 0,
    this.overtime = 0,
    this.commission = 0,
    this.allowance = 0,
    this.positionAllowance = 0,
    this.transportAllowance = 0,
    this.otherIncome = 0,
    this.tax = 0,
    this.socialSecurity = 0,
    this.providentFund = 0,
    this.loan = 0,
    this.fine = 0,
    this.otherDeductions = 0,
    required this.workDays,
    this.leaveDays = 0,
    this.overtimeHours = 0,
  });

  // คำนวณรายได้รวม
  double get totalIncome =>
      baseSalary + 
      bonus + 
      overtime + 
      commission + 
      allowance + 
      positionAllowance + 
      transportAllowance + 
      otherIncome;

  // คำนวณรายการหักรวม
  double get totalDeductions =>
      tax + 
      socialSecurity + 
      providentFund + 
      loan + 
      fine + 
      otherDeductions;

  // คำนวณเงินเดือนสุทธิ
  double get netSalary => totalIncome - totalDeductions;

  factory Salary.fromJson(Map<String, dynamic> json) {
    // Helper แปลงค่าเป็น double/int ให้ทนทานต่อทั้ง num และ String
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', ''));
        return parsed ?? 0.0;
      }
      return 0.0;
    }

    int _parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.replaceAll(',', ''));
        return parsed ?? 0;
      }
      return 0;
    }

    // Parse month - อาจเป็น int (1-12) หรือ string (ชื่อเดือนภาษาไทย)
    String monthStr;
    if (json['month'] is int) {
      monthStr = _getThaiMonth(json['month'] as int);
    } else {
      monthStr = json['month']?.toString() ?? _getThaiMonth(DateTime.now().month);
    }

    // Parse year - อาจเป็น พ.ศ. หรือ ค.ศ.
    int year;
    if (json['year'] is int) {
      year = json['year'] as int;
      // ถ้า year < 2500 แสดงว่าเป็น ค.ศ. ให้แปลงเป็น พ.ศ.
      if (year < 2500) {
        year = year + 543;
      }
    } else {
      year = DateTime.now().year + 543;
    }

    // Parse payment_date
    DateTime paymentDate;
    if (json['payment_date'] != null) {
      try {
        paymentDate = DateTime.parse(json['payment_date'].toString());
      } catch (_) {
        paymentDate = DateTime.now();
      }
    } else {
      paymentDate = DateTime.now();
    }

    return Salary(
      month: monthStr,
      year: year,
      paymentDate: paymentDate,
      baseSalary: _parseDouble(json['base_salary']),
      bonus: _parseDouble(json['bonus']),
      overtime: _parseDouble(json['overtime']),
      commission: _parseDouble(json['commission']),
      allowance: _parseDouble(json['allowance']),
      positionAllowance: _parseDouble(json['position_allowance']),
      transportAllowance: _parseDouble(json['transport_allowance']),
      otherIncome: _parseDouble(json['other_income']),
      tax: _parseDouble(json['tax']),
      socialSecurity: _parseDouble(json['social_security']),
      providentFund: _parseDouble(json['provident_fund']),
      loan: _parseDouble(json['loan']),
      fine: _parseDouble(json['fine']),
      otherDeductions: _parseDouble(json['other_deductions']),
      workDays: _parseInt(json['work_days']),
      leaveDays: _parseInt(json['leave_days']),
      overtimeHours: _parseDouble(json['overtime_hours']),
    );
  }

  static String _getThaiMonth(int month) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
      'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
      'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return months[month - 1];
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'payment_date': paymentDate.toIso8601String(),
      'base_salary': baseSalary,
      'bonus': bonus,
      'overtime': overtime,
      'commission': commission,
      'allowance': allowance,
      'position_allowance': positionAllowance,
      'transport_allowance': transportAllowance,
      'other_income': otherIncome,
      'tax': tax,
      'social_security': socialSecurity,
      'provident_fund': providentFund,
      'loan': loan,
      'fine': fine,
      'other_deductions': otherDeductions,
      'work_days': workDays,
      'leave_days': leaveDays,
      'overtime_hours': overtimeHours,
    };
  }

  // ใช้สำหรับปรับค่าบางฟิลด์ (เช่น OT) โดยไม่ต้องสร้าง object ใหม่ทั้งหมดด้วยมือ
  Salary copyWith({
    String? month,
    int? year,
    DateTime? paymentDate,
    double? baseSalary,
    double? bonus,
    double? overtime,
    double? commission,
    double? allowance,
    double? positionAllowance,
    double? transportAllowance,
    double? otherIncome,
    double? tax,
    double? socialSecurity,
    double? providentFund,
    double? loan,
    double? fine,
    double? otherDeductions,
    int? workDays,
    int? leaveDays,
    double? overtimeHours,
  }) {
    return Salary(
      month: month ?? this.month,
      year: year ?? this.year,
      paymentDate: paymentDate ?? this.paymentDate,
      baseSalary: baseSalary ?? this.baseSalary,
      bonus: bonus ?? this.bonus,
      overtime: overtime ?? this.overtime,
      commission: commission ?? this.commission,
      allowance: allowance ?? this.allowance,
      positionAllowance: positionAllowance ?? this.positionAllowance,
      transportAllowance: transportAllowance ?? this.transportAllowance,
      otherIncome: otherIncome ?? this.otherIncome,
      tax: tax ?? this.tax,
      socialSecurity: socialSecurity ?? this.socialSecurity,
      providentFund: providentFund ?? this.providentFund,
      loan: loan ?? this.loan,
      fine: fine ?? this.fine,
      otherDeductions: otherDeductions ?? this.otherDeductions,
      workDays: workDays ?? this.workDays,
      leaveDays: leaveDays ?? this.leaveDays,
      overtimeHours: overtimeHours ?? this.overtimeHours,
    );
  }
}

