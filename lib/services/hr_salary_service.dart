import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/salary_history_model.dart';
import '../config/api_config.dart';

class HrSalaryService extends ChangeNotifier {
  SalaryDashboardSummary? _summary;
  PayrollOverview? _payrollOverview;
  List<EmployeeSalarySummary> _employees = [];
  List<SalaryHistoryModel> _recentAdjustments = [];
  bool _isLoading = false;
  String? _errorMessage;

  SalaryDashboardSummary? get summary => _summary;
  PayrollOverview? get payrollOverview => _payrollOverview;
  List<EmployeeSalarySummary> get employees => List.unmodifiable(_employees);
  List<SalaryHistoryModel> get recentAdjustments => List.unmodifiable(_recentAdjustments);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// โหลดข้อมูลสรุปภาพรวม
  Future<void> loadSummary() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _errorMessage = 'ไม่พบ Token กรุณาเข้าสู่ระบบใหม่';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.hrSalarySummaryUrl),
        headers: ApiConfig.headersWithAuth(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // ตรวจสอบว่า response body เป็น JSON หรือ HTML
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          _errorMessage = 'API endpoint ยังไม่พร้อมใช้งาน (Server ส่ง HTML กลับมา)';
          debugPrint('API returned HTML instead of JSON. Response: ${response.body.substring(0, 200)}');
          _summary = null;
          _isLoading = false;
          notifyListeners();
          return;
        }
        
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;
          _summary = SalaryDashboardSummary.fromJson(data);
          _errorMessage = null;
        } catch (e) {
          debugPrint('Error parsing summary JSON: $e');
          _errorMessage = 'ไม่สามารถแปลงข้อมูลได้: ${e.toString()}';
          _summary = null;
        }
      } else {
        // ตรวจสอบว่า response body เป็น JSON หรือ HTML
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          _errorMessage = 'API endpoint ยังไม่พร้อมใช้งาน (HTTP ${response.statusCode})';
          debugPrint('API returned HTML instead of JSON. Status: ${response.statusCode}');
          _summary = null;
        } else {
          try {
            final errorData = json.decode(response.body) as Map<String, dynamic>?;
            _errorMessage = errorData?['message'] ?? 'ไม่สามารถโหลดข้อมูลได้ (HTTP ${response.statusCode})';
            _summary = null;
          } catch (_) {
            _errorMessage = 'ไม่สามารถโหลดข้อมูลได้ (HTTP ${response.statusCode})';
            _summary = null;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading salary summary: $e');
      if (e.toString().contains('TimeoutException')) {
        _errorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองอีกครั้ง';
      } else if (e.toString().contains('FormatException') && e.toString().contains('<!DOCTYPE')) {
        _errorMessage = 'API endpoint ยังไม่พร้อมใช้งาน (Server ส่ง HTML กลับมา)';
      } else {
        _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      }
      _summary = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// โหลดรายชื่อพนักงานพร้อมข้อมูลเงินเดือน
  Future<void> loadEmployees({String? search, String? department}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _errorMessage = 'ไม่พบ Token กรุณาเข้าสู่ระบบใหม่';
        _employees = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (department != null && department.isNotEmpty) {
        queryParams['department'] = department;
      }

      final uri = Uri.parse(ApiConfig.hrSalaryEmployeesUrl).replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.headersWithAuth(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // ตรวจสอบว่า response body เป็น JSON หรือ HTML
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          _errorMessage = 'API endpoint ยังไม่พร้อมใช้งาน (Server ส่ง HTML กลับมา)';
          debugPrint('API returned HTML instead of JSON. Response: ${response.body.substring(0, 200)}');
          _employees = [];
          _isLoading = false;
          notifyListeners();
          return;
        }
        
        try {
          final data = json.decode(response.body);
          final List<dynamic> employeesList = data is List
              ? data
              : (data['employees'] as List<dynamic>? ?? 
                 data['data'] as List<dynamic>? ?? []);

          _employees = employeesList
              .map((json) => EmployeeSalarySummary.fromJson(json as Map<String, dynamic>))
              .toList();
          _errorMessage = null;
          debugPrint('Loaded ${_employees.length} employees from API');
        } catch (e) {
          debugPrint('Error parsing employees JSON: $e');
          _errorMessage = 'ไม่สามารถแปลงข้อมูลได้: ${e.toString()}';
          _employees = [];
        }
      } else {
        // ตรวจสอบว่า response body เป็น JSON หรือ HTML
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          _errorMessage = 'API endpoint ยังไม่พร้อมใช้งาน (HTTP ${response.statusCode})';
          debugPrint('API returned HTML instead of JSON. Status: ${response.statusCode}');
          _employees = [];
        } else {
          try {
            final errorData = json.decode(response.body) as Map<String, dynamic>?;
            _errorMessage = errorData?['message'] ?? 'ไม่สามารถโหลดข้อมูลได้ (HTTP ${response.statusCode})';
            _employees = [];
          } catch (_) {
            _errorMessage = 'ไม่สามารถโหลดข้อมูลได้ (HTTP ${response.statusCode})';
            _employees = [];
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading employees: $e');
      if (e.toString().contains('TimeoutException')) {
        _errorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองอีกครั้ง';
      } else if (e.toString().contains('FormatException') && e.toString().contains('<!DOCTYPE')) {
        _errorMessage = 'API endpoint ยังไม่พร้อมใช้งาน (Server ส่ง HTML กลับมา)';
      } else {
        _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      }
      _employees = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// โหลดการปรับเงินเดือนล่าสุด
  Future<void> loadRecentAdjustments({int limit = 10}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _errorMessage = 'ไม่พบ Token';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse(ApiConfig.hrSalaryRecentAdjustmentsUrl).replace(
        queryParameters: {'limit': limit.toString()},
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        // ตรวจสอบว่า response body เป็น JSON หรือ HTML
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          // ไม่แสดง error สำหรับ recent adjustments เพราะเป็นข้อมูลเสริม
          _recentAdjustments = [];
          return;
        }
        
        final data = json.decode(response.body);
        final List<dynamic> adjustmentsList = data is List
            ? data
            : (data['adjustments'] as List<dynamic>? ?? []);

        _recentAdjustments = adjustmentsList
            .map((json) => SalaryHistoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _errorMessage = null;
      } else {
        // ไม่แสดง error สำหรับ recent adjustments เพราะเป็นข้อมูลเสริม
        _recentAdjustments = [];
      }
    } catch (e) {
      debugPrint('Error loading recent adjustments: $e');
      // ไม่แสดง error สำหรับ recent adjustments เพราะเป็นข้อมูลเสริม
      _recentAdjustments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// สร้างเงินเดือนแรก (START)
  Future<bool> createStartingSalary({
    required int employeeId,
    required double salaryAmount,
    required DateTime effectiveDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final currentUserId = prefs.getInt('user_id');

      if (token == null) {
        _errorMessage = 'ไม่พบ Token';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.hrSalaryCreateUrl),
        headers: ApiConfig.headersWithAuth(token),
        body: json.encode({
          'employee_id': employeeId,
          'salary_amount': salaryAmount,
          'effective_date': effectiveDate.toIso8601String().split('T')[0],
          'salary_type': 'START',
          'created_by': currentUserId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _errorMessage = null;
        // Reload data
        await loadSummary();
        await loadEmployees();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        _errorMessage = errorData?['message'] ?? 'ไม่สามารถบันทึกข้อมูลได้';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error creating starting salary: $e');
      _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// ปรับเงินเดือน (ADJUST)
  Future<bool> adjustSalary({
    required int employeeId,
    required double newSalaryAmount,
    required DateTime effectiveDate,
    required String reason,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final currentUserId = prefs.getInt('user_id');

      if (token == null) {
        _errorMessage = 'ไม่พบ Token';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (reason.trim().isEmpty) {
        _errorMessage = 'กรุณากรอกเหตุผล';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.hrSalaryAdjustUrl),
        headers: ApiConfig.headersWithAuth(token),
        body: json.encode({
          'employee_id': employeeId,
          'salary_amount': newSalaryAmount,
          'effective_date': effectiveDate.toIso8601String().split('T')[0],
          'salary_type': 'ADJUST',
          'reason': reason,
          'created_by': currentUserId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _errorMessage = null;
        // Reload data
        await loadSummary();
        await loadEmployees();
        await loadRecentAdjustments();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        _errorMessage = errorData?['message'] ?? 'ไม่สามารถบันทึกข้อมูลได้';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error adjusting salary: $e');
      _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// โหลดประวัติเงินเดือนของพนักงาน
  Future<List<SalaryHistoryModel>> loadEmployeeSalaryHistory(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return [];
      }

      final uri = Uri.parse(ApiConfig.hrSalaryEmployeeHistoryUrl).replace(
        queryParameters: {'employee_id': employeeId.toString()},
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> historyList = data is List
            ? data
            : (data['history'] as List<dynamic>? ?? []);

        return historyList
            .map((json) => SalaryHistoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading employee salary history: $e');
      return [];
    }
  }

  /// โหลดข้อมูล Payroll Overview (ภาพรวมเงินเดือนประจำเดือน)
  Future<void> loadPayrollOverview({int? month, int? year}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // ใช้ mock data ตามที่ส่งไปก่อน
      await Future.delayed(const Duration(milliseconds: 300));
      
      final now = DateTime.now();
      final selectedMonth = month ?? now.month;
      final selectedYear = year ?? now.year;

      // Mock data สำหรับ Payroll Overview
      _payrollOverview = PayrollOverview(
        totalGrossSalary: 1250000.00, // ยอดเงินเดือนรวม
        totalEmployees: 12, // จำนวนพนักงาน 12 คน
        totalDeductions: 87500.00, // ยอดหักรวม
        netPay: 1162500.00, // ยอดจ่ายสุทธิ
        status: PayrollStatus.calculated, // สถานะ: คำนวณแล้ว
        month: selectedMonth,
        year: selectedYear,
      );

      _errorMessage = null;
      debugPrint('Payroll Overview loaded: ${_payrollOverview?.totalEmployees} employees');
    } catch (e) {
      debugPrint('Error loading payroll overview: $e');
      _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      _payrollOverview = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// คำนวณ Payroll Overview จากข้อมูลพนักงานจริง
  Future<void> _calculatePayrollOverviewFromEmployees(int month, int year) async {
    try {
      // ตรวจสอบว่ามีข้อมูลพนักงานอยู่แล้วหรือไม่
      if (_employees.isEmpty) {
        // ถ้ายังไม่มีข้อมูล ให้โหลดก่อน
        await loadEmployees();
      }

      if (_employees.isEmpty) {
        _errorMessage = 'ไม่พบข้อมูลพนักงาน';
        _payrollOverview = null;
        return;
      }

      // คำนวณจากข้อมูลพนักงานจริง
      final totalEmployees = _employees.length;
      double totalGrossSalary = 0.0;
      double totalDeductions = 0.0;

      for (var employee in _employees) {
        // ยอดเงินเดือนรวม = เงินเดือนปัจจุบันของแต่ละคน
        totalGrossSalary += employee.currentSalary;

        // คำนวณยอดหัก (ประมาณ 7% ของเงินเดือน สำหรับประกันสังคม + ภาษี)
        // ประกันสังคม: 5% ของเงินเดือน (สูงสุด 750 บาท)
        final socialSecurity = (employee.currentSalary * 0.05).clamp(0.0, 750.0);
        
        // ภาษี: ประมาณ 2% ของเงินเดือน (ตัวอย่าง)
        final tax = employee.currentSalary * 0.02;
        
        totalDeductions += socialSecurity + tax;
      }

      final netPay = totalGrossSalary - totalDeductions;

      _payrollOverview = PayrollOverview(
        totalGrossSalary: totalGrossSalary,
        totalEmployees: totalEmployees,
        totalDeductions: totalDeductions,
        netPay: netPay,
        status: PayrollStatus.calculated,
        month: month,
        year: year,
      );

      _errorMessage = null;
      debugPrint('Calculated Payroll Overview: $totalEmployees employees, Total: $totalGrossSalary, Net: $netPay');
    } catch (e) {
      debugPrint('Error calculating payroll overview: $e');
      _errorMessage = 'ไม่สามารถคำนวณข้อมูลได้: ${e.toString()}';
      _payrollOverview = null;
    }
  }

  /// โหลดข้อมูลทั้งหมด (Summary + Employees + Recent Adjustments + Payroll Overview)
  Future<void> loadAllData({String? search, String? department}) async {
    await Future.wait([
      loadSummary(),
      loadEmployees(search: search, department: department),
      loadRecentAdjustments(),
      loadPayrollOverview(),
    ]);
  }

  /// Refresh ข้อมูลทั้งหมด
  Future<void> refresh({String? search, String? department}) async {
    await loadAllData(search: search, department: department);
  }
}

