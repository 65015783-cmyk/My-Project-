import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';

class AttendanceService extends ChangeNotifier {
  AttendanceModel? _todayAttendance;
  final WorkSchedule _defaultSchedule = WorkSchedule.defaultSchedule();

  AttendanceModel? get todayAttendance => _todayAttendance;

  AttendanceService() {
    _initializeTodayAttendance();
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

    notifyListeners();
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

  Future<void> checkInWithImage({
    required DateTime date,
    required String imagePath,
    DateTime? checkInTime,
  }) async {
    final selectedDate = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final effectiveCheckInTime = checkInTime ?? now;

    _todayAttendance = AttendanceModel(
      id: 'att_${now.millisecondsSinceEpoch}',
      date: selectedDate,
      checkInTime: effectiveCheckInTime,
      checkInImagePath: imagePath,
      workSchedule: _defaultSchedule,
    );

    notifyListeners();
  }

  void checkOut() {
    if (_todayAttendance == null || !_todayAttendance!.isCheckedIn || _todayAttendance!.isCheckedOut) {
      return;
    }

    final updated = AttendanceModel(
      id: _todayAttendance!.id,
      date: _todayAttendance!.date,
      checkInTime: _todayAttendance!.checkInTime,
      checkOutTime: DateTime.now(),
      checkInImagePath: _todayAttendance!.checkInImagePath,
      workSchedule: _todayAttendance!.workSchedule,
    );

    _todayAttendance = updated;
    notifyListeners();
  }

  Future<void> refreshAttendance() async {
    _initializeTodayAttendance();
  }
}

