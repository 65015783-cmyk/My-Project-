class Salary {
  final String month;
  final int year;
  final DateTime paymentDate;
  final double baseSalary;
  final double bonus;
  final double overtime;
  final double allowance;
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
    this.allowance = 0,
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
      baseSalary + bonus + overtime + allowance + transportAllowance + otherIncome;

  // คำนวณรายการหักรวม
  double get totalDeductions =>
      tax + socialSecurity + providentFund + loan + fine + otherDeductions;

  // คำนวณเงินเดือนสุทธิ
  double get netSalary => totalIncome - totalDeductions;

  factory Salary.fromJson(Map<String, dynamic> json) {
    return Salary(
      month: json['month'],
      year: json['year'],
      paymentDate: DateTime.parse(json['payment_date']),
      baseSalary: (json['base_salary'] as num).toDouble(),
      bonus: (json['bonus'] as num?)?.toDouble() ?? 0,
      overtime: (json['overtime'] as num?)?.toDouble() ?? 0,
      allowance: (json['allowance'] as num?)?.toDouble() ?? 0,
      transportAllowance: (json['transport_allowance'] as num?)?.toDouble() ?? 0,
      otherIncome: (json['other_income'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      socialSecurity: (json['social_security'] as num?)?.toDouble() ?? 0,
      providentFund: (json['provident_fund'] as num?)?.toDouble() ?? 0,
      loan: (json['loan'] as num?)?.toDouble() ?? 0,
      fine: (json['fine'] as num?)?.toDouble() ?? 0,
      otherDeductions: (json['other_deductions'] as num?)?.toDouble() ?? 0,
      workDays: json['work_days'],
      leaveDays: json['leave_days'] ?? 0,
      overtimeHours: (json['overtime_hours'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'payment_date': paymentDate.toIso8601String(),
      'base_salary': baseSalary,
      'bonus': bonus,
      'overtime': overtime,
      'allowance': allowance,
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
}

