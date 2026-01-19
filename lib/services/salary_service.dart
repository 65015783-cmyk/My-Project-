import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/salary.dart';
import '../config/api_config.dart';

class SalaryService extends ChangeNotifier {
  List<Salary> _salaryHistory = [];
  Salary? _currentSalary;
  Salary? _selectedSalary; // เงินเดือนที่เลือกตามปี/เดือน
  bool _isLoading = false;
  String? _errorMessage;

  List<Salary> get salaryHistory => _salaryHistory;
  Salary? get currentSalary => _currentSalary;
  Salary? get selectedSalary => _selectedSalary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ดึงข้อมูลเงินเดือนปัจจุบัน
  Future<void> fetchCurrentSalary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final now = DateTime.now();

      if (token == null) {
        _errorMessage = 'ไม่พบ Token กรุณาเข้าสู่ระบบใหม่';
        _currentSalary = null;
        return;
      }

      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.salarySummaryUrl}?year=${now.year}&month=${now.month}'),
          headers: ApiConfig.headersWithAuth(token),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          _currentSalary = Salary.fromJson(data);
          _errorMessage = null;
        } else {
          _errorMessage = 'ไม่สามารถโหลดข้อมูลเงินเดือนได้ (HTTP ${response.statusCode})';
          _currentSalary = null;
        }
      } catch (e) {
        debugPrint('Error calling salary summary API: $e');
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูลเงินเดือน: ${e.toString()}';
        _currentSalary = null;
      }
    } catch (e) {
      debugPrint('Error fetching current salary: $e');
      _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูลเงินเดือน: ${e.toString()}';
      _currentSalary = null;
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
      // TODO: ถ้ามี endpoint ประวัติเงินเดือนจริง ให้เรียกที่นี่
      // ตอนนี้ยังไม่มีจึงเคลียร์ list และรอให้ backend รองรับในอนาคต
      _salaryHistory = [];
    } catch (e) {
      debugPrint('Error fetching salary history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ดึงข้อมูลสรุปเงินเดือนตามปีและเดือน
  Future<void> fetchSalarySummary({required int year, required int month}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _errorMessage = 'ไม่พบ Token กรุณาเข้าสู่ระบบใหม่';
        _selectedSalary = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.salarySummaryUrl}?year=$year&month=$month'),
          headers: ApiConfig.headersWithAuth(token),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          _selectedSalary = Salary.fromJson(data);
          _errorMessage = null;
        } else {
          _errorMessage = 'ไม่สามารถโหลดข้อมูลเงินเดือนได้ (HTTP ${response.statusCode})';
          _selectedSalary = null;
        }
      } catch (e) {
        debugPrint('API Error while loading salary summary: $e');
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูลเงินเดือน: ${e.toString()}';
        _selectedSalary = null;
      }
    } catch (e) {
      debugPrint('Error fetching salary summary: $e');
      _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูลเงินเดือน: ${e.toString()}';
      _selectedSalary = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // สร้าง Mock Salary Data
  Salary _createMockSalary(int year, int month) {
    // แปลง year จาก พ.ศ. เป็น ค.ศ. ถ้าจำเป็น
    int actualYear = year > 2500 ? year - 543 : year;
    
    return Salary(
      month: _getThaiMonth(month),
      year: year,
      paymentDate: DateTime(actualYear, month, 25),
      baseSalary: 35000,
      bonus: month == 12 ? 5000 : 0, // โบนัสเดือนธันวาคม
      overtime: 2500 + (month * 100), // ค่าล่วงเวลาแตกต่างกันตามเดือน
      allowance: 3000,
      transportAllowance: 1500,
      otherIncome: month % 3 == 0 ? 1000 : 0, // รายได้อื่นๆ ทุก 3 เดือน
      tax: 2100,
      socialSecurity: 1050,
      providentFund: 700,
      loan: month <= 6 ? 2000 : 0, // เงินกู้ครึ่งปีแรก
      fine: 0,
      otherDeductions: 0,
      workDays: 22 - (month % 4), // วันทำงานแตกต่างกัน
      leaveDays: month % 3 == 0 ? 1 : 0, // วันลา
      overtimeHours: 15 + (month % 5), // ชั่วโมง OT
    );
  }

  // ดาวน์โหลดสลิปเงินเดือน
  Future<String?> downloadSalarySlip({required int year, required int month}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Mock: สร้างไฟล์ PDF ตัวอย่าง
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.salarySlipDownloadUrl}?year=$year&month=$month'),
          headers: token != null ? ApiConfig.headersWithAuth(token) : ApiConfig.headers,
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final contentType = response.headers['content-type'] ?? '';
          final isPdf = contentType.contains('application/pdf') || 
                        contentType.contains('application/octet-stream');
          
          if (isPdf || response.bodyBytes.isNotEmpty) {
            final directory = await getApplicationDocumentsDirectory();
            final fileName = 'สลิปเงินเดือน_${year}_${month.toString().padLeft(2, '0')}.pdf';
            final filePath = '${directory.path}/$fileName';
            final file = File(filePath);
            
            await file.writeAsBytes(response.bodyBytes);
            return filePath;
          }
        }
      } catch (e) {
        debugPrint('API download failed, creating mock PDF: $e');
      }

      // สร้าง Mock PDF (ไฟล์ข้อความแทน PDF จริง)
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'สลิปเงินเดือน_${year}_${month.toString().padLeft(2, '0')}.txt';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      final salary = _selectedSalary ?? _createMockSalary(year, month);
      final slipContent = _generateMockSlipContent(salary, year, month);
      
      await file.writeAsString(slipContent, encoding: utf8);
      
      return filePath;
    } catch (e) {
      debugPrint('Error downloading salary slip: $e');
      rethrow;
    }
  }

  // สร้างเนื้อหาสลิปเงินเดือน Mock
  String _generateMockSlipContent(Salary salary, int year, int month) {
    final monthName = _getThaiMonth(month);
    final dateFormat = DateFormat('dd MMMM yyyy', 'th');
    
    return '''
╔═══════════════════════════════════════════════════════════╗
║              สลิปเงินเดือน - Salary Slip                    ║
╠═══════════════════════════════════════════════════════════╣
║ งวด: $monthName $year                                      ║
║ วันที่จ่าย: ${dateFormat.format(salary.paymentDate)}                      ║
╠═══════════════════════════════════════════════════════════╣
║ รายได้ (Income)                                            ║
╠═══════════════════════════════════════════════════════════╣
║ เงินเดือนพื้นฐาน        ${salary.baseSalary.toStringAsFixed(2).padLeft(15)} บาท ║
║ โบนัส                    ${salary.bonus.toStringAsFixed(2).padLeft(15)} บาท ║
║ ค่าล่วงเวลา              ${salary.overtime.toStringAsFixed(2).padLeft(15)} บาท ║
║ เบี้ยเลี้ยง              ${salary.allowance.toStringAsFixed(2).padLeft(15)} บาท ║
║ ค่าเดินทาง              ${salary.transportAllowance.toStringAsFixed(2).padLeft(15)} บาท ║
║ รายได้อื่นๆ              ${salary.otherIncome.toStringAsFixed(2).padLeft(15)} บาท ║
║ ───────────────────────────────────────────────────────── ║
║ รวมรายได้                ${salary.totalIncome.toStringAsFixed(2).padLeft(15)} บาท ║
╠═══════════════════════════════════════════════════════════╣
║ รายการหัก (Deductions)                                     ║
╠═══════════════════════════════════════════════════════════╣
║ ภาษีเงินได้หัก ณ ที่จ่าย  ${salary.tax.toStringAsFixed(2).padLeft(15)} บาท ║
║ ประกันสังคม              ${salary.socialSecurity.toStringAsFixed(2).padLeft(15)} บาท ║
║ กองทุนสำรองเลี้ยงชีพ      ${salary.providentFund.toStringAsFixed(2).padLeft(15)} บาท ║
║ เงินกู้/เงินยืม            ${salary.loan.toStringAsFixed(2).padLeft(15)} บาท ║
║ ค่าปรับ                  ${salary.fine.toStringAsFixed(2).padLeft(15)} บาท ║
║ การหักอื่นๆ              ${salary.otherDeductions.toStringAsFixed(2).padLeft(15)} บาท ║
║ ───────────────────────────────────────────────────────── ║
║ รวมรายการหัก              ${salary.totalDeductions.toStringAsFixed(2).padLeft(15)} บาท ║
╠═══════════════════════════════════════════════════════════╣
║ เงินเดือนสุทธิ (Net Salary)                                ║
║                    ${salary.netSalary.toStringAsFixed(2).padLeft(15)} บาท ║
╠═══════════════════════════════════════════════════════════╣
║ สถิติการทำงาน                                              ║
║ วันทำงาน: ${salary.workDays} วัน | วันลา: ${salary.leaveDays} วัน | OT: ${salary.overtimeHours.toInt()} ชม. ║
╚═══════════════════════════════════════════════════════════╝

หมายเหตุ: นี่เป็นสลิปเงินเดือนตัวอย่าง (Mock Data)
สำหรับการทดสอบระบบเท่านั้น
''';
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

