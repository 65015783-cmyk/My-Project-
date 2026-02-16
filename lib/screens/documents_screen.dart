import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../services/salary_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  // เก็บ state การดาวน์โหลดแยกตามแต่ละเอกสาร
  final Set<DocumentType> _downloadingTypes = {};
  pw.Font? _thaiFont;
  pw.Font? _thaiBoldFont;

  List<DocumentItem> get _documents => _getMockDocuments();

  @override
  Widget build(BuildContext context) {
    final documents = _documents;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('เอกสาร'),
      ),
      body: documents.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                return _buildDocumentCard(documents[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีเอกสาร',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentItem doc) {
    final isDownloading = _downloadingTypes.contains(doc.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: doc.type.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            doc.type.icon,
            color: doc.type.color,
            size: 28,
          ),
        ),
        title: Text(
          doc.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              doc.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              doc.date,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: isDownloading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download, color: Colors.blue),
          onPressed: isDownloading
              ? null
              : () {
                  _handleDownload(doc);
                },
        ),
      ),
    );
  }

  List<DocumentItem> _getMockDocuments() {
    return [
      DocumentItem(
        title: 'สลิปเงินเดือนล่าสุด',
        description: 'ดาวน์โหลดสลิปเงินเดือนของเดือนปัจจุบัน',
        date: DateFormat('d MMM yyyy', 'th').format(DateTime.now()),
        type: DocumentType.payslip,
      ),
      DocumentItem(
        title: 'ใบรับรองการทำงาน',
        description: 'ดาวน์โหลดใบรับรองการทำงาน (ตัวอย่าง)',
        date: DateFormat('d MMM yyyy', 'th').format(DateTime.now()),
        type: DocumentType.certificate,
      ),
      DocumentItem(
        title: 'รายงานการทำงาน',
        description: 'รายงานการทำงานประจำเดือน (ตัวอย่าง)',
        date: DateFormat('d MMM yyyy', 'th').format(DateTime.now()),
        type: DocumentType.report,
      ),
    ];
  }

  Future<void> _handleDownload(DocumentItem doc) async {
    // เพิ่ม type นี้เข้าไปใน set ของเอกสารที่กำลังดาวน์โหลด
    setState(() {
      _downloadingTypes.add(doc.type);
    });

    try {
      String? filePath;

      if (doc.type == DocumentType.payslip) {
        // ดาวน์โหลดสลิปเงินเดือนของเดือนปัจจุบัน (ให้ SalaryService จัดการ)
        final now = DateTime.now();
        final salaryService =
            Provider.of<SalaryService>(context, listen: false);
        filePath = await salaryService.downloadSalarySlip(
          year: now.year,
          month: now.month,
        );
      } else if (doc.type == DocumentType.certificate) {
        // สร้างใบรับรองการทำงานเป็น PDF สวยๆ
        filePath = await _generateCertificatePdf(doc);
      } else if (doc.type == DocumentType.report) {
        // สร้างรายงานการทำงานเป็น PDF ตัวอย่าง
        filePath = await _generateWorkReportPdf(doc);
      }

      if (!mounted) return;

      if (filePath != null) {
        await OpenFilex.open(filePath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('กำลังเปิดไฟล์: ${doc.title}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ไม่สามารถดาวน์โหลดเอกสารได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการดาวน์โหลดเอกสาร: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          // ลบ type นี้ออกจาก set เมื่อดาวน์โหลดเสร็จ
          _downloadingTypes.remove(doc.type);
        });
      }
    }
  }

  Future<String> _generateCertificatePdf(DocumentItem doc) async {
    // โหลดฟอนต์ภาษาไทยก่อนสร้าง PDF
    await _thaiTheme();
    
    // ตรวจสอบว่าฟอนต์โหลดสำเร็จหรือไม่
    if (_thaiFont == null) {
      // แสดง warning แต่ยังสร้าง PDF ได้ (จะใช้ฟอนต์ default)
      debugPrint('Warning: Thai font not loaded. PDF will be created with default font.');
    }
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final fullName = (user?.fullName ??
            '${user?.firstName ?? ''} ${user?.lastName ?? ''}')
        .trim();
    final position = user?.position ?? 'พนักงานบริษัท';
    final department = user?.department ?? '';

    final now = DateTime.now();
    final dateStr = DateFormat('d MMMM yyyy', 'th').format(now);

    final theme = pw.ThemeData.withFont(
      base: _thaiFont!,
      bold: _thaiBoldFont ?? _thaiFont!,
    );
    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey700, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 16),
                pw.Text(
                  'ใบรับรองการทำงาน',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    font: _thaiBoldFont ?? _thaiFont!,
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'บริษัท ฮัมแมนส์ จำกัด',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    font: _thaiBoldFont ?? _thaiFont!,
                  ),
                ),
                pw.SizedBox(height: 32),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'หนังสือฉบับนี้ให้ไว้เพื่อรับรองว่า',
                    style: pw.TextStyle(fontSize: 14, font: _thaiFont!),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  fullName.isNotEmpty ? fullName : 'ชื่อ-นามสกุลพนักงาน',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    font: _thaiBoldFont ?? _thaiFont!,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'ตำแหน่ง: $position' +
                      (department.isNotEmpty ? ' | แผนก: $department' : ''),
                  style: pw.TextStyle(fontSize: 14, font: _thaiFont!),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'ปัจจุบันปฏิบัติงานอยู่กับบริษัท ฮัมแมนส์ จำกัด โดยมีความรับผิดชอบตามตำแหน่งดังกล่าว',
                  style: pw.TextStyle(fontSize: 14, font: _thaiFont!),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'หนังสือรับรองฉบับนี้ออกให้เพื่อใช้เป็นหลักฐานประกอบการดำเนินการที่เกี่ยวข้องตามความประสงค์ของพนักงาน',
                  style: pw.TextStyle(fontSize: 14, font: _thaiFont!),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'ออกให้ ณ วันที่ $dateStr',
                        style: pw.TextStyle(fontSize: 12, font: _thaiFont!),
                      ),
                      pw.SizedBox(height: 32),
                      pw.Text(
                        '................................................',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'ผู้มีอำนาจลงนาม',
                        style: pw.TextStyle(fontSize: 12, font: _thaiFont!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'ใบรับรองการทำงาน_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String> _generateWorkReportPdf(DocumentItem doc) async {
    // โหลดฟอนต์ภาษาไทยก่อนสร้าง PDF
    await _thaiTheme();
    
    // ตรวจสอบว่าฟอนต์โหลดสำเร็จหรือไม่
    if (_thaiFont == null) {
      // แสดง warning แต่ยังสร้าง PDF ได้ (จะใช้ฟอนต์ default)
      debugPrint('Warning: Thai font not loaded. PDF will be created with default font.');
    }
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final fullName = (user?.fullName ??
            '${user?.firstName ?? ''} ${user?.lastName ?? ''}')
        .trim();
    final position = user?.position ?? 'พนักงานบริษัท';
    final department = user?.department ?? '';

    final now = DateTime.now();
    final monthStr = DateFormat('MMMM yyyy', 'th').format(now);

    final theme = pw.ThemeData.withFont(
      base: _thaiFont!,
      bold: _thaiBoldFont ?? _thaiFont!,
    );
    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'รายงานการทำงานประจำเดือน',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  font: _thaiBoldFont ?? _thaiFont!,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                monthStr,
                style: pw.TextStyle(fontSize: 14, font: _thaiFont!),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'ชื่อพนักงาน: ${fullName.isNotEmpty ? fullName : 'ชื่อ-นามสกุลพนักงาน'}',
                style: pw.TextStyle(fontSize: 14, font: _thaiFont!),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'ตำแหน่ง: $position',
                style: pw.TextStyle(fontSize: 14, font: _thaiFont!),
              ),
              if (department.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  'แผนก: $department',
                  style: pw.TextStyle(fontSize: 14, font: _thaiFont!),
                ),
              ],
              pw.SizedBox(height: 24),
              pw.Text(
                'สรุปการทำงาน (ตัวอย่าง):',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: _thaiBoldFont ?? _thaiFont!,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Bullet(
                text: 'ปฏิบัติงานตามหน้าที่และความรับผิดชอบครบถ้วนตลอดเดือน',
                style: pw.TextStyle(font: _thaiFont!),
              ),
              pw.Bullet(
                text: 'เข้าร่วมประชุมและกิจกรรมภายในองค์กรอย่างสม่ำเสมอ',
                style: pw.TextStyle(font: _thaiFont!),
              ),
              pw.Bullet(
                text: 'ให้ความร่วมมือกับเพื่อนร่วมงานและผู้บังคับบัญชาเป็นอย่างดี',
                style: pw.TextStyle(font: _thaiFont!),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'หมายเหตุ: รายงานฉบับนี้เป็นตัวอย่างที่สร้างจากระบบเพื่อใช้ทดสอบการดาวน์โหลดเอกสารเท่านั้น',
                style: pw.TextStyle(fontSize: 12, font: _thaiFont!),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'รายงานการทำงาน_${now.year}${now.month.toString().padLeft(2, '0')}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _thaiTheme() async {
    if (_thaiFont != null) return; // ถ้าโหลดแล้วไม่ต้องโหลดซ้ำ
    
    try {
      ByteData? fontData;
      
      // วิธีที่ 1: ลองโหลดจาก local storage (ถ้ามี)
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fontFile = File('${directory.path}/NotoSansThai-Regular.ttf');
        if (await fontFile.exists()) {
          final bytes = await fontFile.readAsBytes();
          fontData = ByteData.view(bytes.buffer);
          debugPrint('Loaded font from local storage (${bytes.length} bytes)');
        }
      } catch (e) {
        debugPrint('Failed to load font from local storage: $e');
      }
      
      // วิธีที่ 2: ถ้ายังไม่มี ลองโหลดจาก assets
      if (fontData == null) {
        try {
          fontData = await rootBundle.load('assets/fonts/NotoSansThai-Regular.ttf');
          debugPrint('Loaded font from assets');
        } catch (e) {
          debugPrint('Failed to load font from assets: $e');
        }
      }
      
      // วิธีที่ 3: ถ้ายังไม่มี ให้แสดง warning
      if (fontData == null) {
        debugPrint('Font not found. Please ensure NotoSansThai-Regular.ttf is in assets/fonts/');
        debugPrint('See FONT_INSTALLATION.md for instructions.');
      }
      
      // ใช้ฟอนต์ที่โหลดได้
      if (fontData != null) {
        try {
          _thaiFont = pw.Font.ttf(fontData);
          _thaiBoldFont = _thaiFont;
          debugPrint('Thai font initialized successfully');
        } catch (e) {
          debugPrint('Error initializing font: $e');
          _thaiFont = null;
          _thaiBoldFont = null;
        }
      } else {
        debugPrint('Error: Could not load Thai font from any source');
        debugPrint('Please download NotoSansThai-Regular.ttf from Google Fonts and place it in assets/fonts/');
        _thaiFont = null;
        _thaiBoldFont = null;
        // ไม่ throw exception เพื่อให้ PDF ยังสร้างได้ (แต่จะไม่มีฟอนต์ไทย)
      }
    } catch (e) {
      debugPrint('Error loading Thai fonts for documents PDF: $e');
      _thaiFont = null;
      _thaiBoldFont = null;
    }
  }
}

class DocumentItem {
  final String title;
  final String description;
  final String date;
  final DocumentType type;

  DocumentItem({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
  });
}

enum DocumentType {
  payslip(Icons.attach_money, Colors.purple),
  certificate(Icons.verified, Colors.green),
  report(Icons.description, Colors.blue);

  final IconData icon;
  final Color color;

  const DocumentType(this.icon, this.color);
}

