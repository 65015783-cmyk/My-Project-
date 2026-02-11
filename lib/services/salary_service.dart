import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/salary.dart';
import '../config/api_config.dart';

class SalaryService extends ChangeNotifier {
  List<Salary> _salaryHistory = [];
  Salary? _currentSalary;
  Salary? _selectedSalary; // เงินเดือนที่เลือกตามปี/เดือน
  bool _isLoading = false;
  String? _errorMessage;

  // ฟอนต์ภาษาไทยสำหรับ PDF
  pw.Font? _thaiFont;
  pw.Font? _thaiBoldFont;

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

      // พยายามดาวน์โหลดจาก backend (ถ้ามี)
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

      // สร้าง Mock PDF ถ้า backend ยังไม่รองรับ
      final salary = _selectedSalary ?? _createMockSalary(year, month);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'สลิปเงินเดือน_${year}_${month.toString().padLeft(2, '0')}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      final pdf = await _generateMockSlipPdf(salary, year, month);
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      debugPrint('Error downloading salary slip: $e');
      rethrow;
    }
  }

  Future<void> _ensureThaiFontsLoaded() async {
    if (_thaiFont != null) return;
    try {
      final regularData =
          await rootBundle.load('assets/fonts/NotoSansThai-Regular.ttf');
      _thaiFont = pw.Font.ttf(regularData);
      _thaiBoldFont = _thaiFont;
    } catch (e) {
      debugPrint('Error loading Thai fonts for salary PDF: $e');
    }
  }

  // สร้าง PDF สลิปเงินเดือน Mock (รองรับภาษาไทย)
  Future<pw.Document> _generateMockSlipPdf(
      Salary salary, int year, int month) async {
    await _ensureThaiFontsLoaded();

    final monthName = DateFormat('LLLL', 'th').format(DateTime(year, month));
    final dateFormat = DateFormat('d MMMM yyyy', 'th');

    final theme = (_thaiFont != null)
        ? pw.ThemeData.withFont(
            base: _thaiFont!,
            bold: _thaiBoldFont ?? _thaiFont!,
          )
        : pw.ThemeData.base();

    final doc = pw.Document(theme: theme);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'สลิปเงินเดือน (Salary Slip)',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  font: _thaiBoldFont ?? _thaiFont,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'งวด: $monthName ${year + 543}',
                style: pw.TextStyle(fontSize: 12, font: _thaiFont),
              ),
              pw.Text(
                'วันที่จ่าย: ${dateFormat.format(salary.paymentDate)}',
                style: pw.TextStyle(fontSize: 12, font: _thaiFont),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'รายได้ (Income)',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: _thaiBoldFont ?? _thaiFont,
                ),
              ),
              pw.Divider(),
              _buildLine('เงินเดือนพื้นฐาน', salary.baseSalary),
              _buildLine('โบนัส', salary.bonus),
              _buildLine('ค่าล่วงเวลา', salary.overtime),
              _buildLine('เบี้ยเลี้ยง', salary.allowance),
              _buildLine('ค่าเดินทาง', salary.transportAllowance),
              _buildLine('รายได้อื่นๆ', salary.otherIncome),
              pw.Divider(),
              _buildLine('รวมรายได้', salary.totalIncome, isBold: true),
              pw.SizedBox(height: 16),
              pw.Text(
                'รายการหัก (Deductions)',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: _thaiBoldFont ?? _thaiFont,
                ),
              ),
              pw.Divider(),
              _buildLine('ภาษีหัก ณ ที่จ่าย', salary.tax),
              _buildLine('ประกันสังคม', salary.socialSecurity),
              _buildLine('กองทุนสำรองเลี้ยงชีพ', salary.providentFund),
              _buildLine('เงินกู้/เงินยืม', salary.loan),
              _buildLine('ค่าปรับ', salary.fine),
              _buildLine('การหักอื่นๆ', salary.otherDeductions),
              pw.Divider(),
              _buildLine('รวมรายการหัก', salary.totalDeductions,
                  isBold: true),
              pw.SizedBox(height: 16),
              pw.Text(
                'เงินเดือนสุทธิ (Net Salary)',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: _thaiBoldFont ?? _thaiFont,
                ),
              ),
              pw.Divider(),
              _buildLine('เงินเดือนสุทธิ', salary.netSalary, isBold: true),
              pw.SizedBox(height: 24),
              pw.Text(
                'สถิติการทำงาน: วันทำงาน ${salary.workDays} วัน, วันลา ${salary.leaveDays} วัน, OT ${salary.overtimeHours.toInt()} ชม.',
                style: pw.TextStyle(fontSize: 12, font: _thaiFont),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'หมายเหตุ: นี่เป็นสลิปเงินเดือนตัวอย่างที่สร้างจากระบบเพื่อใช้ทดสอบเท่านั้น',
                style: pw.TextStyle(fontSize: 10, font: _thaiFont),
              ),
            ],
          );
        },
      ),
    );

    return doc;
  }

  pw.Widget _buildLine(String label, num value, {bool isBold = false}) {
    final textStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      font: isBold ? (_thaiBoldFont ?? _thaiFont) : _thaiFont,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: textStyle),
          pw.Text(
            value.toStringAsFixed(2),
            style: textStyle,
          ),
        ],
      ),
    );
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

