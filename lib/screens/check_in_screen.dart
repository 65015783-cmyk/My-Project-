import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../utils/date_formatter.dart';
import 'qr_scanner_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  String _qrData = '';

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  void _generateQRCode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        // Generate QR Code that changes daily based on selected date
        final dateString = _selectedDate.toIso8601String().split('T')[0]; // YYYY-MM-DD

        // ใช้โครงสร้างข้อมูลแบบย่อให้ QR ไม่แน่นเกินไป
        // รองรับฝั่งสแกนทั้งคีย์แบบย่อ (u, n, d, t) และแบบเดิม (userId, userName, date, type)
        final checkInData = {
          'ver': 1, // version สำหรับเผื่อเปลี่ยนรูปแบบในอนาคต
          't': 'ci', // ci = check-in
          'u': user.id, // userId แบบย่อ
          'n': user.fullName, // name แบบย่อ
          'd': dateString, // date แบบย่อ

          // คีย์แบบเดิม เผื่อความเข้ากันได้ย้อนหลัง (กล้องสแกนยังอ่านได้เหมือนเดิม)
          'userId': user.id,
          'userName': user.fullName,
          'date': dateString,
          'type': 'check_in_form',
          'screen': 'qr_check_in_form',
        };
        if (mounted) {
          setState(() {
            _qrData = jsonEncode(checkInData);
          });
        }
      }
    });
  }

  Future<void> _saveQRCodeImage() async {
    if (_qrData.isEmpty) return;

    try {
      // สร้าง painter สำหรับ QR (ไม่มีพื้นหลังในตัว)
      final painter = QrPainter(
        data: _qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      // วาดลง Canvas เอง โดยเติมพื้นหลังสีขาวก่อน กันภาพกลายเป็นสีดำทึบ
      const imageSize = 512.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // พื้นหลังขาวเต็มภาพ
      final backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, imageSize, imageSize),
        backgroundPaint,
      );

      // วาด QR ลงบน Canvas
      painter.paint(canvas, const Size(imageSize, imageSize));

      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(
        imageSize.toInt(),
        imageSize.toInt(),
      );

      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      uiImage.dispose();

      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'QR_Code_CheckIn_${dateStr}_$timeStr.png';

      bool savedToGallery = false;
      String? savedFilePath;

      // 1) บันทึกลงแกลเลอรี (Android / iOS)
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          final result = await ImageGallerySaver.saveImage(
            bytes,
            name: fileName.replaceAll('.png', ''),
            quality: 100,
            isReturnImagePathOfIOS: true,
          );

          if (result['isSuccess'] == true) {
            savedToGallery = true;
            savedFilePath = result['filePath']?.toString();
          }
        }
      } catch (_) {}

      // 2) บันทึกสำเนาลงโฟลเดอร์ Download (Android) หรือ Downloads (Windows)
      try {
        Directory? saveDirectory;

        if (Platform.isAndroid) {
          const downloadsPath = '/storage/emulated/0/Download';
          final downloadsDir = Directory(downloadsPath);
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          saveDirectory = downloadsDir;
        } else if (Platform.isWindows) {
          try {
            final downloadsDir = await getDownloadsDirectory();
            saveDirectory = downloadsDir;
          } catch (_) {}

          if (saveDirectory == null) {
            final userProfile = Platform.environment['USERPROFILE'];
            if (userProfile != null && userProfile.isNotEmpty) {
              final manualDownloads = Directory('$userProfile\\Downloads');
              if (!await manualDownloads.exists()) {
                await manualDownloads.create(recursive: true);
              }
              saveDirectory = manualDownloads;
            }
          }

          saveDirectory ??= await getApplicationDocumentsDirectory();
        } else {
          saveDirectory = await getApplicationDocumentsDirectory();
        }

        final path = '${saveDirectory.path}/$fileName';
        final file = File(path);
        await file.writeAsBytes(bytes, flush: true);
        if (await file.exists()) {
          savedFilePath = path;
        }
      } catch (_) {}

      if (!mounted) return;

      // แสดงผลสำเร็จแบบสั้น
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึก QR Code เรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการบันทึก QR Code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime() {
    final now = DateTime.now();
    final thaiMonths = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
    ];
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final day = now.day;
    final month = thaiMonths[now.month - 1];
    final year = now.year;
    return '$hour:$minute น. - $day $month $year';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
      helpText: 'เลือกวันที่',
      cancelText: 'ยกเลิก',
      confirmText: 'ยืนยัน',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _generateQRCode();
    }
  }

  Future<void> _submitCheckIn() async {
    print('[CheckInScreen] ========== SUBMIT CHECK-IN ==========');
    print('[CheckInScreen] Selected date: $_selectedDate');
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      final attendanceService = Provider.of<AttendanceService>(context, listen: false);
      final checkInTime = DateTime.now();
      print('[CheckInScreen] Calling checkInWithImage with time: $checkInTime');
      
      // เช็คอินโดยไม่บังคับให้มีรูปภาพแล้ว ใช้เวลา ณ ตอนกดยืนยัน
      final success = await attendanceService.checkInWithImage(
        date: _selectedDate,
        imagePath: '',
        checkInTime: checkInTime,
      );
      
      print('[CheckInScreen] checkInWithImage returned: $success');

      if (mounted) {
        if (success) {
          // เรียก notifyListeners() อีกครั้งเพื่อให้แน่ใจว่า UI อัปเดต
          final attendanceService = Provider.of<AttendanceService>(context, listen: false);
          attendanceService.notifyListeners();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เช็คอินสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          
          // รอสักครู่เพื่อให้ UI อัปเดตก่อน pop
          await Future.delayed(const Duration(milliseconds: 100));
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เช็คอินล้มเหลว กรุณาลองอีกครั้ง'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final thaiDays = [
      'วันอาทิตย์',
      'วันจันทร์',
      'วันอังคาร',
      'วันพุธ',
      'วันพฤหัสบดี',
      'วันศุกร์',
      'วันเสาร์',
    ];
    
    final thaiMonths = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];

    final weekdayIndex = date.weekday == 7 ? 0 : date.weekday;
    final weekday = thaiDays[weekdayIndex];
    final day = date.day;
    final month = thaiMonths[date.month - 1];
    final year = date.year + 543;

    return '$weekday $day $month $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('เข้างาน'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Selection Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: Color(0xFF2196F3),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'เลือกวันที่',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatDate(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    DateFormat('HH:mm น.').format(DateTime.now()),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 24,
                              ),
                              tooltip: 'เลือกวันที่',
                              onPressed: () => _selectDate(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // QR Code Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.qr_code,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'QR Code สำหรับเช็คอิน',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _qrData.isNotEmpty
                            ? QrImageView(
                                data: _qrData,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.M,
                              )
                            : const SizedBox(
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'QR Code ของคุณสำหรับวันนี้',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'สแกน QR Code นี้เพื่อยืนยันการเข้างาน\nQR Code จะเปลี่ยนทุกวัน',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _formatDateTime(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Button to save QR Code image
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _qrData.isEmpty ? null : _saveQRCodeImage,
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text(
                          'บันทึก QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Button to scan own QR Code
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Navigate to scanner to scan own QR Code, pass QR data to display
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => QRScannerScreen(
                                qrDataToShow: _qrData,
                              ),
                            ),
                          );
                          
                          // If scan successful and form completed, go back
                          if (result == true) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                        label: const Text(
                          'สแกน QR Code เพื่อยืนยันการเข้างาน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Submit Button
            Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'ยืนยันการเข้างาน',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

