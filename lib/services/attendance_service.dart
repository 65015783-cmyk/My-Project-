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
    _todayAttendance = AttendanceModel(
      id: 'att_${now.millisecondsSinceEpoch}',
      date: today,
      checkInTime: DateTime.now().hour >= 8 ? DateTime.now() : null,
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
  }) async {
    final selectedDate = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();

    _todayAttendance = AttendanceModel(
      id: 'att_${now.millisecondsSinceEpoch}',
      date: selectedDate,
      checkInTime: now,
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

