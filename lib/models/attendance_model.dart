import 'package:intl/intl.dart';

class AttendanceModel {
  final String id;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInImagePath;
  final WorkSchedule workSchedule;

  AttendanceModel({
    required this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInImagePath,
    required this.workSchedule,
  });

  bool get isCheckedIn => checkInTime != null;
  bool get isCheckedOut => checkOutTime != null;

  String get checkInTimeFormatted {
    if (checkInTime == null) return '--:--';
    return DateFormat('HH:mm').format(checkInTime!);
  }

  String get checkOutTimeFormatted {
    if (checkOutTime == null) return '--:--';
    return DateFormat('HH:mm').format(checkOutTime!);
  }

  String get dateFormatted {
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

    // DateTime.weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
    // thaiDays array: 0=Sunday, 1=Monday, 2=Tuesday, ..., 6=Saturday
    final weekdayIndex = date.weekday == 7 ? 0 : date.weekday;
    final weekday = thaiDays[weekdayIndex];
    final day = date.day;
    final month = thaiMonths[date.month - 1];
    final year = date.year + 543; // Convert to Buddhist Era

    return '$weekday $day $month $year';
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'] as String)
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'] as String)
          : null,
      checkInImagePath: json['checkInImagePath'] as String?,
      workSchedule: WorkSchedule.fromJson(json['workSchedule'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkInImagePath': checkInImagePath,
      'workSchedule': workSchedule.toJson(),
    };
  }
}

class WorkSchedule {
  final String morningStart;
  final String morningEnd;
  final String afternoonStart;
  final String afternoonEnd;

  WorkSchedule({
    required this.morningStart,
    required this.morningEnd,
    required this.afternoonStart,
    required this.afternoonEnd,
  });

  String get formatted {
    return '$morningStart - $morningEnd - $afternoonStart - $afternoonEnd';
  }

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    return WorkSchedule(
      morningStart: json['morningStart'] as String,
      morningEnd: json['morningEnd'] as String,
      afternoonStart: json['afternoonStart'] as String,
      afternoonEnd: json['afternoonEnd'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morningStart': morningStart,
      'morningEnd': morningEnd,
      'afternoonStart': afternoonStart,
      'afternoonEnd': afternoonEnd,
    };
  }

  factory WorkSchedule.defaultSchedule() {
    return WorkSchedule(
      morningStart: '08:30',
      morningEnd: '12:30',
      afternoonStart: '13:30',
      afternoonEnd: '17:30',
    );
  }
}

