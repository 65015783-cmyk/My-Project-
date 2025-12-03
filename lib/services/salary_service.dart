import 'package:flutter/foundation.dart';
import '../models/salary.dart';

class SalaryService extends ChangeNotifier {
  List<Salary> _salaryHistory = [];
  Salary? _currentSalary;
  bool _isLoading = false;

  List<Salary> get salaryHistory => _salaryHistory;
  Salary? get currentSalary => _currentSalary;
  bool get isLoading => _isLoading;

  // ดึงข้อมูลเงินเดือนปัจจุบัน
  Future<void> fetchCurrentSalary() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: เรียก API จริง
      // final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/salary/current'));
      
      // Mock data สำหรับทดสอบ
      await Future.delayed(const Duration(seconds: 1));
      
      final now = DateTime.now();
      _currentSalary = Salary(
        month: _getThaiMonth(now.month),
        year: now.year + 543, // แปลงเป็น พ.ศ.
        paymentDate: DateTime(now.year, now.month, 25),
        baseSalary: 25000,
        bonus: 2000,
        overtime: 1500,
        allowance: 3000,
        transportAllowance: 1000,
        otherIncome: 0,
        tax: 1200,
        socialSecurity: 750,
        providentFund: 500,
        loan: 0,
        fine: 0,
        otherDeductions: 0,
        workDays: 22,
        leaveDays: 1,
        overtimeHours: 10,
      );
    } catch (e) {
      debugPrint('Error fetching salary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ดึงประวัติเงินเดือน
  Future<void> fetchSalaryHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: เรียก API จริง
      // final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/salary/history'));
      
      // Mock data สำหรับทดสอบ
      await Future.delayed(const Duration(seconds: 1));
      
      final now = DateTime.now();
      _salaryHistory = List.generate(6, (index) {
        final month = now.month - index;
        final year = month <= 0 ? now.year - 1 : now.year;
        final adjustedMonth = month <= 0 ? month + 12 : month;
        
        return Salary(
          month: _getThaiMonth(adjustedMonth),
          year: year + 543,
          paymentDate: DateTime(year, adjustedMonth, 25),
          baseSalary: 25000,
          bonus: index == 0 ? 2000 : 0,
          overtime: 1000 + (index * 200),
          allowance: 3000,
          transportAllowance: 1000,
          otherIncome: 0,
          tax: 1200,
          socialSecurity: 750,
          providentFund: 500,
          loan: 0,
          fine: 0,
          otherDeductions: 0,
          workDays: 22,
          leaveDays: index % 3 == 0 ? 1 : 0,
          overtimeHours: 8 + (index * 2),
        );
      });
    } catch (e) {
      debugPrint('Error fetching salary history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getThaiMonth(int month) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
      'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
      'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return months[month - 1];
  }
}

