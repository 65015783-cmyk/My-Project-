import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/salary_history_model.dart';
import '../config/api_config.dart';

class HrSalaryService extends ChangeNotifier {
  SalaryDashboardSummary? _summary;
  List<EmployeeSalarySummary> _employees = [];
  List<SalaryHistoryModel> _recentAdjustments = [];
  bool _isLoading = false;
  String? _errorMessage;

  SalaryDashboardSummary? get summary => _summary;
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
        _errorMessage = 'ไม่พบ Token';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.hrSalarySummaryUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        // ตรวจสอบว่า response body เป็น JSON หรือ HTML
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          _errorMessage = 'API endpoint ยังไม่พร้อมใช้งาน (Server ส่ง HTML กลับมา)';
          debugPrint('API returned HTML instead of JSON. Response: ${response.body.substring(0, 200)}');
          return;
        }
        
        final data = json.decode(response.body) as Map<String, dynamic>;
        _summary = SalaryDashboardSummary.fromJson(data);
        _errorMessage = null;
      } else {
        // ตรวจสอบว่า response body เป็น JSON หรือ HTML
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          _errorMessage = 'API endpoint ยังไม่พร้อมใช้งาน (HTTP ${response.statusCode})';
          debugPrint('API returned HTML instead of JSON. Status: ${response.statusCode}');
          return;
        }
        
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>?;
          _errorMessage = errorData?['message'] ?? 'ไม่สามารถโหลดข้อมูลได้ (HTTP ${response.statusCode})';
        } catch (_) {
          _errorMessage = 'ไม่สามารถโหลดข้อมูลได้ (HTTP ${response.statusCode})';
        }
      }
    } catch (e) {
      debugPrint('Error loading salary summary: $e');
      if (e.toString().contains('FormatException') && e.toString().contains('<!DOCTYPE')) {
        _errorMessage = 'API endpoint ยังไม่พร้อมใช้งาน (Server ส่ง HTML กลับมา)';
      } else {
        _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      }
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
        _errorMessage = 'ไม่พบ Token';
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
      );

      if (response.statusCode == 200) {
        // ตรวจสอบว่า response body เป็น JSON หรือ HTML
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          _errorMessage = 'API endpoint ยังไม่พร้อมใช้งาน (Server ส่ง HTML กลับมา)';
          debugPrint('API returned HTML instead of JSON. Response: ${response.body.substring(0, 200)}');
          return;
        }
        
        final data = json.decode(response.body);
        final List<dynamic> employeesList = data is List
            ? data
            : (data['employees'] as List<dynamic>? ?? []);

        _employees = employeesList
            .map((json) => EmployeeSalarySummary.fromJson(json as Map<String, dynamic>))
            .toList();
        _errorMessage = null;
      } else {
        // ตรวจสอบว่า response body เป็น JSON หรือ HTML
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          _errorMessage = 'API endpoint ยังไม่พร้อมใช้งาน (HTTP ${response.statusCode})';
          debugPrint('API returned HTML instead of JSON. Status: ${response.statusCode}');
          return;
        }
        
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>?;
          _errorMessage = errorData?['message'] ?? 'ไม่สามารถโหลดข้อมูลได้ (HTTP ${response.statusCode})';
        } catch (_) {
          _errorMessage = 'ไม่สามารถโหลดข้อมูลได้ (HTTP ${response.statusCode})';
        }
      }
    } catch (e) {
      debugPrint('Error loading employees: $e');
      if (e.toString().contains('FormatException') && e.toString().contains('<!DOCTYPE')) {
        _errorMessage = 'API endpoint ยังไม่พร้อมใช้งาน (Server ส่ง HTML กลับมา)';
      } else {
        _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      }
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

  /// โหลดข้อมูลทั้งหมด (Summary + Employees + Recent Adjustments)
  Future<void> loadAllData({String? search, String? department}) async {
    await Future.wait([
      loadSummary(),
      loadEmployees(search: search, department: department),
      loadRecentAdjustments(),
    ]);
  }

  /// Refresh ข้อมูลทั้งหมด
  Future<void> refresh({String? search, String? department}) async {
    await loadAllData(search: search, department: department);
  }
}

