import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'qr_check_in_form_screen.dart';
import '../services/auth_service.dart';

class QRScannerScreen extends StatefulWidget {
  final String? qrDataToShow; // QR Code data to display for user to scan
  
  const QRScannerScreen({
    super.key,
    this.qrDataToShow,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _qrCodeKey = GlobalKey();
  bool _isProcessing = false;
  bool _torchEnabled = false;
  CameraFacing _cameraFacing = CameraFacing.back;
  bool _showQRCode = false; // Toggle between scanner and QR display

  void _handleQRCode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _processQRCode(barcode.rawValue!);
        break;
      }
    }
  }

  void _processQRCode(String rawValue) {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Try to parse as JSON
      final Map<String, dynamic> qrData = jsonDecode(rawValue);

      // รองรับทั้งรูปแบบเดิม และรูปแบบคีย์แบบย่อ (t/u/n/d)
      final String? typeLong = qrData['type'] as String?;
      final String? typeShort = qrData['t'] as String?; // ci = check-in
      final String? screen = qrData['screen'] as String?;

      final bool isCheckInQr = (typeLong == 'check_in_form') ||
          (screen == 'qr_check_in_form') ||
          (typeShort == 'ci');

      // Check if it's a check-in form QR code
      if (isCheckInQr) {
        // Verify QR Code date matches today
        final qrDateString =
            (qrData['date'] ?? qrData['d']) as String?; // รองรับทั้ง date/d
        if (qrDateString != null) {
          final today = DateTime.now();
          final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          
          if (!qrDateString.startsWith(todayString)) {
            _showError('QR Code หมดอายุแล้ว กรุณาใช้ QR Code ของวันนี้');
            setState(() {
              _isProcessing = false;
            });
            return;
          }
        }
        
        // เติม check-in timestamp ตอนสแกน (ใช้ key เดิมเพื่อความเข้ากันได้)
        qrData['checkInTimestamp'] ??= DateTime.now().toIso8601String();
        
        // Navigate to check-in form with timestamp
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => QRCheckInFormScreen(qrData: qrData),
          ),
        );
      } else {
        // Handle other QR code types
        _showError('QR Code ไม่ถูกต้อง');
      }
    } catch (e) {
      // If not JSON, try to handle as URL or plain text
      if (rawValue.startsWith('http')) {
        // Could open URL if needed
        _showError('QR Code นี้เป็นลิงก์ ไม่ใช่สำหรับเช็คอิน');
      } else {
        _showError('QR Code ไม่ถูกต้อง');
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        // ใช้ไฟล์ต้นฉบับเต็ม ๆ ไม่บีบอัด เพื่อให้ ML Kit อ่าน QR ได้แม่นขึ้น
        // imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _isProcessing = true;
        });

        final file = File(image.path);
        if (await file.exists()) {
          try {
            final inputImage = mlkit.InputImage.fromFilePath(file.path);

            // ลองสแกนรอบที่ 1: แบบทั่วไป (ทุกประเภท barcode)
            final defaultScanner = mlkit.BarcodeScanner();
            List<mlkit.Barcode> barcodes =
                await defaultScanner.processImage(inputImage);
            debugPrint(
                'MLKit (default) from gallery found ${barcodes.length} barcodes');

            // ถ้าไม่เจอเลย ลองโหมดเน้น QR โดยเฉพาะอีกรอบ
            if (barcodes.isEmpty) {
              await defaultScanner.close();
              final qrOnlyScanner = mlkit.BarcodeScanner(
                formats: [mlkit.BarcodeFormat.qrCode],
              );
              barcodes = await qrOnlyScanner.processImage(inputImage);
              debugPrint(
                  'MLKit (QR only) from gallery found ${barcodes.length} barcodes');
              await qrOnlyScanner.close();
            } else {
              await defaultScanner.close();
            }

            if (barcodes.isNotEmpty) {
              final barcode = barcodes.first;
              final value = (barcode.displayValue?.isNotEmpty ?? false)
                  ? barcode.displayValue!
                  : (barcode.rawValue ?? '');

              if (value.isNotEmpty) {
                _processQRCode(value);
                return;
              }
            }
          } catch (e) {
            debugPrint('Error scanning QR code from image with ML Kit: $e');
          }
        }

        setState(() {
          _isProcessing = false;
        });
        if (mounted) {
          // ปรับข้อความให้แนะนำวิธีแก้ให้ผู้ใช้ด้วย
          _showError(
              'ไม่พบ QR Code ในรูปภาพ\nกรุณาใช้รูปที่เห็น QR ชัด ๆ หรือครอปให้เหลือเฉพาะ QR Code');
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        _showError('เกิดข้อผิดพลาดในการเลือกรูป: $e');
      }
    }
  }

  Widget _buildQRCodeDisplay(String qrData) {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'QR Code ของคุณ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'สแกน QR Code นี้เพื่อเช็คอิน',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              RepaintBoundary(
                key: _qrCodeKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 280.0,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveQRCode,
                  icon: const Icon(Icons.download),
                  label: const Text('บันทึก QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'คุณสามารถบันทึก QR Code นี้เพื่อใช้ในภายหลัง\nหรือให้ผู้อื่นสแกนเพื่อเช็คอินให้คุณ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveQRCode() async {
    final qrData = _getQRDataToDisplay();
    if (qrData.isEmpty) return;
    
    try {
      setState(() {
        _isProcessing = true;
      });

      // Create QR code painter (ไม่มีพื้นหลังในตัว)
      final painter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
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
      final qrSize = imageSize;
      final qrOffset = const Offset(0, 0);
      painter.paint(canvas, Size(qrSize, qrSize));

      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(
        imageSize.toInt(),
        imageSize.toInt(),
      );

      // แปลงเป็น PNG bytes
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      uiImage.dispose();
      
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        
        try {
          final today = DateTime.now();
          final dateStr = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
          final timeStr = '${today.hour.toString().padLeft(2, '0')}${today.minute.toString().padLeft(2, '0')}';
          final fileName = 'QR_Code_CheckIn_${dateStr}_$timeStr.png';
          
          // Save to Gallery (most reliable way on Android)
          bool savedToGallery = false;
          String? galleryPath;
          String? savedFilePath;
          
          try {
            // 1) บันทึกลงแกลเลอรี (ให้ไปโผล่ใน Gallery app)
            if (Platform.isAndroid || Platform.isIOS) {
              final result = await ImageGallerySaver.saveImage(
                bytes,
                name: fileName.replaceAll('.png', ''),
                quality: 100,
                isReturnImagePathOfIOS: true,
              );
              
              if (result['isSuccess'] == true) {
                savedToGallery = true;
                galleryPath = result['filePath']?.toString();
                savedFilePath = result['filePath']?.toString();
                debugPrint('Saved to gallery: $galleryPath');
              } else {
                debugPrint('Failed to save to gallery: ${result['errorMessage']}');
              }
            }
          } catch (galleryError) {
            debugPrint('Error saving to gallery: $galleryError');
          }

          // 2) บันทึกไฟล์สำเนาแบบ path ชัดเจน
          try {
            Directory? saveDirectory;

            if (Platform.isAndroid) {
              // เขียนลงโฟลเดอร์ Download ของเครื่อง Android: /storage/emulated/0/Download
              const downloadsPath = '/storage/emulated/0/Download';
              final downloadsDir = Directory(downloadsPath);
              if (!await downloadsDir.exists()) {
                await downloadsDir.create(recursive: true);
              }
              saveDirectory = downloadsDir;
            } else if (Platform.isWindows) {
              // รันบน Windows: เขียนลงโฟลเดอร์ Downloads ของผู้ใช้
              try {
                final downloadsDir = await getDownloadsDirectory();
                saveDirectory = downloadsDir;
              } catch (e) {
                debugPrint('getDownloadsDirectory error: $e');
              }

              // Fallback: ใช้ USERPROFILE/Downloads โดยตรง ถ้า plugin ใช้งานไม่ได้
              if (saveDirectory == null) {
                final userProfile = Platform.environment['USERPROFILE'];
                if (userProfile != null && userProfile.isNotEmpty) {
                  final manualDownloads =
                      Directory('$userProfile\\Downloads');
                  if (!await manualDownloads.exists()) {
                    await manualDownloads.create(recursive: true);
                  }
                  saveDirectory = manualDownloads;
                }
              }

              // ถ้ายังไม่ได้จริง ๆ ใช้โฟลเดอร์ของแอป
              saveDirectory ??= await getApplicationDocumentsDirectory();
            } else {
              // iOS / macOS / Linux ใช้โฟลเดอร์ของแอป
              saveDirectory = await getApplicationDocumentsDirectory();
            }

            final path = '${saveDirectory.path}/$fileName';
            final file = File(path);
            await file.writeAsBytes(bytes, flush: true);
            if (await file.exists()) {
              savedFilePath = path;
              debugPrint('Saved QR copy to: $savedFilePath');
            }
          } catch (fallbackError) {
            debugPrint('Error saving explicit copy: $fallbackError');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('บันทึกไฟล์ลงเครื่องไม่สำเร็จ: $fallbackError'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
          
          // Show success / error messageแบบสั้น
          if (mounted) {
            if (savedToGallery || savedFilePath != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('บันทึก QR Code เรียบร้อยแล้ว'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ไม่สามารถบันทึก QR Code ได้'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('Save error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
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
          _isProcessing = false;
        });
      }
    }
  }

  String _getQRDataToDisplay() {
    if (widget.qrDataToShow != null && widget.qrDataToShow!.isNotEmpty) {
      return widget.qrDataToShow!;
    }
    
    // Generate QR Code from current user if not provided
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null) {
      // Use today's date only (YYYY-MM-DD) so QR Code changes daily
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final checkInData = {
        'userId': user.id,
        'userEmail': user.email,
        'userName': user.fullName,
        'date': dateString, // Only date, ensures QR changes daily
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'check_in_form',
        'screen': 'qr_check_in_form',
      };
      return jsonEncode(checkInData);
    }
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final qrDataToDisplay = _getQRDataToDisplay();
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_showQRCode ? 'QR Code ของคุณ' : 'สแกน QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (!_showQRCode) ...[
            IconButton(
              icon: const Icon(Icons.photo_library, color: Colors.white),
              tooltip: 'เลือกรูป QR Code จากแกลเลอรี',
              onPressed: _pickImageFromGallery,
            ),
            IconButton(
              icon: Icon(
                _torchEnabled ? Icons.flash_on : Icons.flash_off,
                color: _torchEnabled ? Colors.yellow : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _torchEnabled = !_torchEnabled;
                });
                _controller.toggleTorch();
              },
            ),
            IconButton(
              icon: Icon(
                _cameraFacing == CameraFacing.front 
                    ? Icons.camera_rear 
                    : Icons.camera_front,
              ),
              onPressed: () {
                setState(() {
                  _cameraFacing = _cameraFacing == CameraFacing.front 
                      ? CameraFacing.back 
                      : CameraFacing.front;
                });
                _controller.switchCamera();
              },
            ),
          ] else if (qrDataToDisplay.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              tooltip: 'บันทึก QR Code',
              onPressed: _saveQRCode,
            ),
        ],
      ),
      body: _showQRCode && qrDataToDisplay.isNotEmpty
          ? _buildQRCodeDisplay(qrDataToDisplay)
          : Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _handleQRCode,
                ),
                
                // Overlay
                CustomPaint(
                  painter: ScannerOverlayPainter(),
                  child: Container(),
                ),
                
                // Instructions
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Text(
                            'วาง QR Code ภายในกรอบ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isProcessing)
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final overlayRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(overlayRect, paint);

    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final scanArea = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Clear the scan area
    final clearPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;
    canvas.drawRect(scanArea, clearPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(scanArea, borderPaint);

    // Draw corner indicators
    const cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize - cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left, top + scanAreaSize - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


