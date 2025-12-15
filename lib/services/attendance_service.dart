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
          
          // Parse check_in_time
          final checkInTimeValue = attendanceData['check_in_time'];
          if (checkInTimeValue != null && checkInTimeValue.toString().isNotEmpty) {
            try {
              final checkInTimeStr = checkInTimeValue.toString().trim();
              
              // MySQL DATETIME format: "YYYY-MM-DD HH:mm:ss" หรือ "YYYY-MM-DDTHH:mm:ss.000Z"
              // ลบ microseconds ถ้ามี และแปลง timezone
              String normalizedTime = checkInTimeStr;
              if (normalizedTime.contains('T')) {
                // ISO format: "2024-12-14T07:15:00.000Z" -> "2024-12-14 07:15:00"
                normalizedTime = normalizedTime.split('T')[0] + ' ' + 
                                 normalizedTime.split('T')[1].split('.')[0].split('Z')[0];
              }
              
              checkInTime = DateTime.parse(normalizedTime);
            } catch (e) {
              // Ignore parsing errors
            }
          }
          
          // Parse check_out_time
          final checkOutTimeValue = attendanceData['check_out_time'];
          if (checkOutTimeValue != null && checkOutTimeValue.toString().isNotEmpty) {
            try {
              final checkOutTimeStr = checkOutTimeValue.toString().trim();
              
              String normalizedTime = checkOutTimeStr;
              if (normalizedTime.contains('T')) {
                normalizedTime = normalizedTime.split('T')[0] + ' ' + 
                                 normalizedTime.split('T')[1].split('.')[0].split('Z')[0];
              }
              
              checkOutTime = DateTime.parse(normalizedTime);
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
        // อัปเดต attendance ทันทีเพื่อให้ UI แสดงเวลาทันที (optimistic update)
        final now = DateTime.now();
        
        // สร้าง AttendanceModel ใหม่ด้วย checkInTime
        final newAttendance = AttendanceModel(
          id: _todayAttendance?.id ?? 'att_${now.millisecondsSinceEpoch}',
          date: selectedDate,
          checkInTime: effectiveCheckInTime,
          checkOutTime: _todayAttendance?.checkOutTime,
          checkInImagePath: imagePath.isNotEmpty ? imagePath : null,
          workSchedule: _defaultSchedule,
        );
        
        // อัปเดต _todayAttendance
        _todayAttendance = newAttendance;
        
        print('[AttendanceService] ========== CHECK-IN SUCCESS ==========');
        print('[AttendanceService] checkInTime: $effectiveCheckInTime');
        print('[AttendanceService] checkInTimeFormatted: ${_todayAttendance?.checkInTimeFormatted}');
        print('[AttendanceService] _todayAttendance is null: ${_todayAttendance == null}');
        print('[AttendanceService] _todayAttendance.checkInTime is null: ${_todayAttendance?.checkInTime == null}');
        
        // แจ้งให้ UI อัปเดตทันที (optimistic update)
        notifyListeners();
        print('[AttendanceService] notifyListeners() called after check-in');
        
        // ไม่โหลดข้อมูลจาก API เพื่อให้แสดงเวลาที่กด check-in จริงๆ
        // ผู้ใช้ต้องการให้แสดงเวลาที่กด check-in เองเท่านั้น ไม่ใช่เวลาจาก API
        
        return true;
      } else if (response.statusCode == 400 && isAlreadyCheckedIn) {
        // ถ้า API บอกว่าเช็คอินแล้ว ให้ใช้เวลาปัจจุบันที่กดเข้างาน
        print('[AttendanceService] ========== ALREADY CHECKED IN ==========');
        print('[AttendanceService] Using current check-in time: $effectiveCheckInTime');
        
        // อัปเดต attendance ด้วยเวลาปัจจุบันที่กดเข้างาน
        final now = DateTime.now();
        final newAttendance = AttendanceModel(
          id: _todayAttendance?.id ?? 'att_${now.millisecondsSinceEpoch}',
          date: selectedDate,
          checkInTime: effectiveCheckInTime, // ใช้เวลาปัจจุบันที่กดเข้างาน
          checkOutTime: _todayAttendance?.checkOutTime,
          checkInImagePath: imagePath.isNotEmpty ? imagePath : _todayAttendance?.checkInImagePath,
          workSchedule: _defaultSchedule,
        );
        
        _todayAttendance = newAttendance;
        
        print('[AttendanceService] Updated checkInTime: ${_todayAttendance?.checkInTimeFormatted}');
        
        // แจ้งให้ UI อัปเดต
        notifyListeners();
        
        print('[AttendanceService] Using current check-in time instead of API time');
        
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
        // อัปเดต attendance ทันทีเพื่อให้ UI แสดงเวลาทันที
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        _todayAttendance = AttendanceModel(
          id: _todayAttendance?.id ?? 'att_${now.millisecondsSinceEpoch}',
          date: _todayAttendance?.date ?? today,
          checkInTime: _todayAttendance?.checkInTime,
          checkOutTime: now,
          checkInImagePath: _todayAttendance?.checkInImagePath,
          workSchedule: _defaultSchedule,
        );
        
        print('[AttendanceService] ========== CHECK-OUT SUCCESS ==========');
        print('[AttendanceService] checkOutTime: $now');
        print('[AttendanceService] checkOutTimeFormatted: ${_todayAttendance?.checkOutTimeFormatted}');
        
        // แจ้งให้ UI อัปเดตทันที
        notifyListeners();
        
        // ไม่โหลดข้อมูลจาก API เพื่อให้แสดงเวลาที่กด check-out จริงๆ
        // ผู้ใช้ต้องการให้แสดงเวลาที่กด check-out เองเท่านั้น ไม่ใช่เวลาจาก API
        
        return true;
      } else if (response.statusCode == 400 && isAlreadyCheckedOut) {
        // ถ้า API บอกว่าเช็คเอาท์แล้ว ให้ใช้เวลาปัจจุบันที่กดเช็คเอาท์ (หรือเวลาที่มีอยู่แล้ว)
        print('[AttendanceService] ========== ALREADY CHECKED OUT ==========');
        final now = DateTime.now();
        print('[AttendanceService] Using current check-out time: $now');

        final today = DateTime(now.year, now.month, now.day);

        // ถ้ามีเวลา checkOut เดิมอยู่แล้วให้คงไว้ ไม่ทับค่าเดิม
        final effectiveCheckOutTime = _todayAttendance?.checkOutTime ?? now;

        final newAttendance = AttendanceModel(
          id: _todayAttendance?.id ?? 'att_${now.millisecondsSinceEpoch}',
          date: _todayAttendance?.date ?? today,
          checkInTime: _todayAttendance?.checkInTime,
          checkOutTime: effectiveCheckOutTime,
          checkInImagePath: _todayAttendance?.checkInImagePath,
          workSchedule: _defaultSchedule,
        );

        _todayAttendance = newAttendance;

        print('[AttendanceService] Updated checkOutTime: ${_todayAttendance?.checkOutTimeFormatted}');

        // แจ้งให้ UI อัปเดต
        notifyListeners();

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
      final userId = prefs.getInt('user_id')?.toString();

      if (token == null || userId == null) {
        _history.clear();
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.attendanceAllUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // รองรับทั้งรูปแบบ { attendance: [...] } และเป็น list ตรงๆ
        final List<dynamic> list =
            (data is Map<String, dynamic> && data['attendance'] is List)
                ? data['attendance'] as List
                : (data is List ? data : []);

        final List<AttendanceModel> items = [];

        for (final raw in list) {
          if (raw is! Map<String, dynamic>) continue;

          final attendanceData = raw;

          // ถ้ามี user_id ใน response ให้กรองให้ตรงกับ user ปัจจุบัน
          final attendanceUserId = attendanceData['user_id']?.toString() ??
              attendanceData['employee_id']?.toString();
          if (attendanceUserId != null && attendanceUserId != userId) {
            continue;
          }

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

            // check_in_time
            final checkInTimeValue = attendanceData['check_in_time'];
            if (checkInTimeValue != null &&
                checkInTimeValue.toString().isNotEmpty) {
              try {
                String normalizedTime = checkInTimeValue.toString().trim();
                if (normalizedTime.contains('T')) {
                  normalizedTime = normalizedTime.split('T')[0] +
                      ' ' +
                      normalizedTime
                          .split('T')[1]
                          .split('.')[0]
                          .split('Z')[0];
                }
                checkInTime = DateTime.parse(normalizedTime);
              } catch (_) {}
            }

            // check_out_time
            final checkOutTimeValue = attendanceData['check_out_time'];
            if (checkOutTimeValue != null &&
                checkOutTimeValue.toString().isNotEmpty) {
              try {
                String normalizedTime = checkOutTimeValue.toString().trim();
                if (normalizedTime.contains('T')) {
                  normalizedTime = normalizedTime.split('T')[0] +
                      ' ' +
                      normalizedTime
                          .split('T')[1]
                          .split('.')[0]
                          .split('Z')[0];
                }
                checkOutTime = DateTime.parse(normalizedTime);
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

