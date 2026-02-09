import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import '../config/api_config.dart';

class AttendanceService extends ChangeNotifier {
  AttendanceModel? _todayAttendance;
  final WorkSchedule _defaultSchedule = WorkSchedule.defaultSchedule();
  String? _currentUserId; // เก็บ user ID ปัจจุบัน
  final List<AttendanceModel> _history = []; // ประวัติการทำงานทั้งหมด

  AttendanceModel? get todayAttendance => _todayAttendance;
  List<AttendanceModel> get history => List.unmodifiable(_history);

  AttendanceService() {
    // เริ่มต้นด้วยข้อมูลว่าง ไม่โหลดจาก API
    // จะโหลดเฉพาะหลังจาก check-in/check-out แล้ว
    _initializeTodayAttendance();
  }

  // Clear attendance data เมื่อเปลี่ยน user
  void clearAttendance() {
    print('[AttendanceService] Clearing attendance data');
    _todayAttendance = null;
    _currentUserId = null;
    _initializeTodayAttendance();
    notifyListeners();
  }

  Future<void> loadTodayAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getInt('user_id')?.toString();

      if (token == null || userId == null) {
        _initializeTodayAttendance();
        return;
      }

      // ตรวจสอบว่า user เปลี่ยนหรือไม่
      if (_currentUserId != null && _currentUserId != userId) {
        print('[AttendanceService] User changed from $_currentUserId to $userId, clearing attendance');
        clearAttendance();
      }
      _currentUserId = userId;

      final response = await http.get(
        Uri.parse(ApiConfig.attendanceTodayUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final attendanceData = data['attendance'] as Map<String, dynamic>?;

        if (attendanceData != null && attendanceData.isNotEmpty) {
          // ตรวจสอบว่า attendance นี้เป็นของ user ปัจจุบันหรือไม่
          final attendanceUserId = attendanceData['user_id']?.toString() ?? 
                                   attendanceData['employee_id']?.toString();
          
          if (attendanceUserId != null && attendanceUserId != userId) {
            print('[AttendanceService] Attendance belongs to different user ($attendanceUserId vs $userId), ignoring');
            // ไม่ reset attendance ถ้ามีข้อมูลอยู่แล้ว
            if (_todayAttendance == null) {
              _initializeTodayAttendance();
            }
            notifyListeners();
            return;
          }

          // Parse จาก database format
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          // Parse date
          final dateStr = attendanceData['date']?.toString() ?? '';
          final attendanceDate = dateStr.isNotEmpty 
              ? DateTime.parse(dateStr.split(' ')[0].split('T')[0])
              : today;
          
          DateTime? checkInTime;
          DateTime? checkOutTime;
          
          // Parse check_in_time (รองรับทั้ง DATETIME และ ISO8601 + Z)
          final checkInTimeValue = attendanceData['check_in_time'];
          if (checkInTimeValue != null && checkInTimeValue.toString().isNotEmpty) {
            try {
              final checkInTimeStr = checkInTimeValue.toString().trim();

              if (checkInTimeStr.contains('T')) {
                // ISO8601 string (เช่น จาก JSON) - แปลงจาก UTC -> Local
                checkInTime = DateTime.parse(checkInTimeStr).toLocal();
              } else {
                // MySQL DATETIME (local time)
                checkInTime = DateTime.parse(checkInTimeStr);
              }
            } catch (e) {
              // Ignore parsing errors
            }
          }
          
          // Parse check_out_time (รองรับทั้ง DATETIME และ ISO8601 + Z)
          final checkOutTimeValue = attendanceData['check_out_time'];
          if (checkOutTimeValue != null && checkOutTimeValue.toString().isNotEmpty) {
            try {
              final checkOutTimeStr = checkOutTimeValue.toString().trim();

              if (checkOutTimeStr.contains('T')) {
                checkOutTime = DateTime.parse(checkOutTimeStr).toLocal();
              } else {
                checkOutTime = DateTime.parse(checkOutTimeStr);
              }
            } catch (e) {
              // Ignore parsing errors
            }
          }

          // ใช้ attendanceDate ที่ได้จากข้างบนแล้ว
          _todayAttendance = AttendanceModel(
            id: 'att_${attendanceData['id'] ?? now.millisecondsSinceEpoch}',
            date: attendanceDate,
            checkInTime: checkInTime,
            checkOutTime: checkOutTime,
            checkInImagePath: attendanceData['check_in_image_path']?.toString(),
            workSchedule: _defaultSchedule,
          );
        } else {
          // ไม่ reset attendance ถ้ามีข้อมูลอยู่แล้ว (เช่น หลังจาก check-in)
          // ถ้ายังไม่มีข้อมูล attendance เลย ให้ initialize
          if (_todayAttendance == null) {
            _initializeTodayAttendance();
          }
          // ถ้ามีข้อมูลอยู่แล้ว (เช่น มี checkInTime) ไม่ต้อง reset
        }
      } else {
        // ไม่ reset attendance ถ้ามีข้อมูลอยู่แล้ว
        // ถ้ายังไม่มีข้อมูล attendance เลย ให้ initialize
        if (_todayAttendance == null) {
          _initializeTodayAttendance();
        }
        // ถ้ามีข้อมูลอยู่แล้ว (เช่น มี checkInTime) ไม่ต้อง reset
      }
    } catch (e) {
      print('[AttendanceService] Error loading attendance: $e');
      // ไม่ reset attendance ถ้ามีข้อมูลอยู่แล้ว
      // ถ้ายังไม่มีข้อมูล attendance เลย ให้ initialize
      if (_todayAttendance == null) {
        _initializeTodayAttendance();
      }
      // ถ้ามีข้อมูลอยู่แล้ว (เช่น มี checkInTime) ไม่ต้อง reset
    }
    
    notifyListeners();
  }

  void _initializeTodayAttendance() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if attendance already exists
    // เริ่มต้นวันใหม่โดยยังไม่ถือว่าเช็คอิน (เวลาเข้างานเป็น null)
    _todayAttendance = AttendanceModel(
      id: 'att_${now.millisecondsSinceEpoch}',
      date: today,
      checkInTime: null,
      checkInImagePath: null,
      workSchedule: _defaultSchedule,
    );
  }

  void checkIn() {
    if (_todayAttendance == null || _todayAttendance!.isCheckedIn) {
      return;
    }

    final updated = AttendanceModel(
      id: _todayAttendance!.id,
      date: _todayAttendance!.date,
      checkInTime: DateTime.now(),
      checkOutTime: _todayAttendance!.checkOutTime,
      checkInImagePath: _todayAttendance!.checkInImagePath,
      workSchedule: _todayAttendance!.workSchedule,
    );

    _todayAttendance = updated;
    notifyListeners();
  }

  Future<bool> checkInWithImage({
    required DateTime date,
    required String imagePath,
    DateTime? checkInTime,
  }) async {
    final selectedDate = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final effectiveCheckInTime = checkInTime ?? now;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return false;
      }

      final dateStr = selectedDate.toIso8601String().split('T')[0]; // YYYY-MM-DD

      print('[AttendanceService] ========== CHECK-IN REQUEST ==========');
      print('[AttendanceService] URL: ${ApiConfig.checkInUrl}');
      print('[AttendanceService] Date: $dateStr');
      print('[AttendanceService] ImagePath: ${imagePath.isNotEmpty ? "exists" : "empty"}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.checkInUrl),
        headers: ApiConfig.headersWithAuth(token),
        body: json.encode({
          'date': dateStr,
          'imagePath': imagePath,
        }),
      );

      print('[AttendanceService] Response status: ${response.statusCode}');
      print('[AttendanceService] Response body: ${response.body}');

      // ตรวจสอบว่า response body มี message ว่ามีการเช็คอินแล้วหรือไม่
      final responseBody = response.body;
      final isAlreadyCheckedIn = responseBody.contains('เช็คอินวันนี้แล้ว') || 
                                  responseBody.contains('already checked in') ||
                                  responseBody.contains('already checked-in');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[AttendanceService] ========== CHECK-IN SUCCESS ==========');
        print('[AttendanceService] Response: ${response.body}');
        
        // พยายาม parse checkInTime จาก response
        DateTime? serverCheckInTime;
        try {
          final responseData = json.decode(response.body) as Map<String, dynamic>?;
          if (responseData != null && responseData['checkInTime'] != null) {
            final checkInTimeStr = responseData['checkInTime'].toString();

            if (checkInTimeStr.contains('T')) {
              // ISO8601 + Z -> แปลงจาก UTC เป็นเวลาเครื่อง
              serverCheckInTime = DateTime.parse(checkInTimeStr).toLocal();
            } else {
              serverCheckInTime = DateTime.parse(checkInTimeStr);
            }
            print('[AttendanceService] Parsed server checkInTime: $serverCheckInTime');
          }
        } catch (e) {
          print('[AttendanceService] Could not parse checkInTime from response: $e');
        }
        
        // ใช้เวลาจาก server ถ้ามี ไม่เช่นนั้นใช้เวลาที่ส่งไป
        final finalCheckInTime = serverCheckInTime ?? effectiveCheckInTime;
        
        // อัปเดต attendance ด้วยเวลาจาก server
        final now = DateTime.now();
        final newAttendance = AttendanceModel(
          id: _todayAttendance?.id ?? 'att_${now.millisecondsSinceEpoch}',
          date: selectedDate,
          checkInTime: finalCheckInTime,
          checkOutTime: _todayAttendance?.checkOutTime,
          checkInImagePath: imagePath.isNotEmpty ? imagePath : null,
          workSchedule: _defaultSchedule,
        );
        
        _todayAttendance = newAttendance;
        
        print('[AttendanceService] Final checkInTime: $finalCheckInTime');
        print('[AttendanceService] checkInTimeFormatted: ${_todayAttendance?.checkInTimeFormatted}');
        
        // แจ้งให้ UI อัปเดตทันที
        notifyListeners();
        print('[AttendanceService] notifyListeners() called after check-in');
        
        // โหลดข้อมูลจาก API เพื่อให้แน่ใจว่าข้อมูลตรงกับ backend
        await loadTodayAttendance();
        print('[AttendanceService] Reloaded attendance from API');
        
        return true;
      } else if (response.statusCode == 400 && isAlreadyCheckedIn) {
        // ถ้า API บอกว่าเช็คอินแล้ว ให้โหลดข้อมูลจาก API เพื่อใช้เวลาจริงจาก backend
        print('[AttendanceService] ========== ALREADY CHECKED IN ==========');
        print('[AttendanceService] Loading attendance from API to get actual check-in time');
        
        // โหลดข้อมูลจาก API เพื่อใช้เวลาจริงจาก backend
        await loadTodayAttendance();
        print('[AttendanceService] Reloaded attendance from API');
        print('[AttendanceService] checkInTimeFormatted: ${_todayAttendance?.checkInTimeFormatted}');
        
        // return true เพื่อให้ UI แสดงว่าเช็คอินสำเร็จแล้ว
        return true;
      } else {
        print('[AttendanceService] ========== CHECK-IN FAILED ==========');
        print('[AttendanceService] Status code: ${response.statusCode}');
        print('[AttendanceService] Response: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('[AttendanceService] ========== CHECK-IN ERROR ==========');
      print('[AttendanceService] Error: $e');
      print('[AttendanceService] Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> checkOut() async {
    print('[AttendanceService] ========== CHECK-OUT REQUEST ==========');
    
    // ตรวจสอบว่ามี check-out แล้วหรือไม่
    if (_todayAttendance != null && _todayAttendance!.isCheckedOut) {
      print('[AttendanceService] Already checked out');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('[AttendanceService] No auth token');
        return false;
      }

      print('[AttendanceService] URL: ${ApiConfig.checkOutUrl}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.checkOutUrl),
        headers: ApiConfig.headersWithAuth(token),
        body: json.encode({}),
      );

      print('[AttendanceService] Response status: ${response.statusCode}');
      print('[AttendanceService] Response body: ${response.body}');

      // ตรวจสอบว่า response body มี message ว่ามีการเช็คเอาท์แล้วหรือไม่
      final responseBody = response.body;
      final isAlreadyCheckedOut = responseBody.contains('เช็คเอาท์วันนี้แล้ว') ||
          responseBody.contains('เช็คเอาท์แล้ว') ||
          responseBody.contains('already checked out') ||
          responseBody.contains('already checked-out');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[AttendanceService] ========== CHECK-OUT SUCCESS ==========');
        print('[AttendanceService] Response: ${response.body}');
        
        // พยายาม parse checkOutTime จาก response
        DateTime? serverCheckOutTime;
        try {
          final responseData = json.decode(response.body) as Map<String, dynamic>?;
          if (responseData != null && responseData['checkOutTime'] != null) {
            final checkOutTimeStr = responseData['checkOutTime'].toString();

            if (checkOutTimeStr.contains('T')) {
              serverCheckOutTime = DateTime.parse(checkOutTimeStr).toLocal();
            } else {
              serverCheckOutTime = DateTime.parse(checkOutTimeStr);
            }
            print('[AttendanceService] Parsed server checkOutTime: $serverCheckOutTime');
          }
        } catch (e) {
          print('[AttendanceService] Could not parse checkOutTime from response: $e');
        }
        
        // ใช้เวลาจาก server ถ้ามี ไม่เช่นนั้นใช้เวลาปัจจุบัน
        final finalCheckOutTime = serverCheckOutTime ?? DateTime.now();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        _todayAttendance = AttendanceModel(
          id: _todayAttendance?.id ?? 'att_${now.millisecondsSinceEpoch}',
          date: _todayAttendance?.date ?? today,
          checkInTime: _todayAttendance?.checkInTime,
          checkOutTime: finalCheckOutTime,
          checkInImagePath: _todayAttendance?.checkInImagePath,
          workSchedule: _defaultSchedule,
        );
        
        print('[AttendanceService] Final checkOutTime: $finalCheckOutTime');
        print('[AttendanceService] checkOutTimeFormatted: ${_todayAttendance?.checkOutTimeFormatted}');
        
        // แจ้งให้ UI อัปเดตทันที
        notifyListeners();
        
        // โหลดข้อมูลจาก API เพื่อให้แน่ใจว่าข้อมูลตรงกับ backend
        await loadTodayAttendance();
        print('[AttendanceService] Reloaded attendance from API');
        
        return true;
      } else if (response.statusCode == 400 && isAlreadyCheckedOut) {
        // ถ้า API บอกว่าเช็คเอาท์แล้ว ให้โหลดข้อมูลจาก API เพื่อใช้เวลาจริงจาก backend
        print('[AttendanceService] ========== ALREADY CHECKED OUT ==========');
        print('[AttendanceService] Loading attendance from API to get actual check-out time');
        
        // โหลดข้อมูลจาก API เพื่อใช้เวลาจริงจาก backend
        await loadTodayAttendance();
        print('[AttendanceService] Reloaded attendance from API');
        print('[AttendanceService] checkOutTimeFormatted: ${_todayAttendance?.checkOutTimeFormatted}');
        
        // return true เพื่อให้ UI แสดงว่าเช็คเอาท์สำเร็จแล้ว
        return true;
      } else {
        print('[AttendanceService] ========== CHECK-OUT FAILED ==========');
        print('[AttendanceService] Status code: ${response.statusCode}');
        print('[AttendanceService] Response: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('[AttendanceService] ========== CHECK-OUT ERROR ==========');
      print('[AttendanceService] Error: $e');
      print('[AttendanceService] Stack trace: $stackTrace');
      return false;
    }
  }

  Future<void> refreshAttendance() async {
    await loadTodayAttendance();
  }

  /// โหลดประวัติการทำงานทั้งหมดของผู้ใช้ปัจจุบัน
  Future<void> loadAttendanceHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // ถ้าไม่มี token แสดงว่ายังไม่เข้าสู่ระบบ
      if (token == null) {
        _history.clear();
        notifyListeners();
        return;
      }
      // ใช้ endpoint /api/attendance/history สำหรับดึงประวัติของ "ผู้ใช้ปัจจุบัน"
      final response = await http.get(
        Uri.parse(ApiConfig.attendanceHistoryUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      print('[AttendanceService][History] Request URL: ${ApiConfig.attendanceHistoryUrl}');
      print('[AttendanceService][History] Response status: ${response.statusCode}');
      print('[AttendanceService][History] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // รองรับทั้งรูปแบบ
        // - { attendance: [...] }
        // - { attendances: [...] }  // ใช้ในหน้าจอ Admin
        // - { data: [...] }
        // - [ ... ] list ตรงๆ
        List<dynamic> list;
        if (data is Map<String, dynamic>) {
          if (data['attendance'] is List) {
            list = data['attendance'] as List<dynamic>;
          } else if (data['attendances'] is List) {
            list = data['attendances'] as List<dynamic>;
          } else if (data['data'] is List) {
            list = data['data'] as List<dynamic>;
          } else {
            list = const [];
          }
        } else if (data is List) {
          list = data;
        } else {
          list = const [];
        }

        final List<AttendanceModel> items = [];

        for (final raw in list) {
          if (raw is! Map<String, dynamic>) continue;

          final attendanceData = raw;

          try {
            // Parse date
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final dateStr = attendanceData['date']?.toString() ?? '';
            final attendanceDate = dateStr.isNotEmpty
                ? DateTime.parse(dateStr.split(' ')[0].split('T')[0])
                : today;

            DateTime? checkInTime;
            DateTime? checkOutTime;

            // check_in_time (รองรับทั้ง DATETIME และ ISO8601 + Z)
            final checkInTimeValue = attendanceData['check_in_time'];
            if (checkInTimeValue != null &&
                checkInTimeValue.toString().isNotEmpty) {
              try {
                final timeStr = checkInTimeValue.toString().trim();
                if (timeStr.contains('T')) {
                  checkInTime = DateTime.parse(timeStr).toLocal();
                } else {
                  checkInTime = DateTime.parse(timeStr);
                }
              } catch (_) {}
            }

            // check_out_time (รองรับทั้ง DATETIME และ ISO8601 + Z)
            final checkOutTimeValue = attendanceData['check_out_time'];
            if (checkOutTimeValue != null &&
                checkOutTimeValue.toString().isNotEmpty) {
              try {
                final timeStr = checkOutTimeValue.toString().trim();
                if (timeStr.contains('T')) {
                  checkOutTime = DateTime.parse(timeStr).toLocal();
                } else {
                  checkOutTime = DateTime.parse(timeStr);
                }
              } catch (_) {}
            }

            items.add(
              AttendanceModel(
                id: 'att_${attendanceData['id'] ?? attendanceDate.millisecondsSinceEpoch}',
                date: attendanceDate,
                checkInTime: checkInTime,
                checkOutTime: checkOutTime,
                checkInImagePath:
                    attendanceData['check_in_image_path']?.toString(),
                workSchedule: _defaultSchedule,
              ),
            );
          } catch (_) {
            // ข้าม record ที่ parse ไม่ได้
            continue;
          }
        }

        // เรียงจากวันที่ล่าสุดไปเก่าสุด
        items.sort((a, b) => b.date.compareTo(a.date));

        _history
          ..clear()
          ..addAll(items);
      } else {
        _history.clear();
      }
    } catch (_) {
      _history.clear();
    }

    notifyListeners();
  }
}

