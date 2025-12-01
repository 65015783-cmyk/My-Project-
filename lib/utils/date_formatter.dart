import 'package:intl/intl.dart';

class DateFormatter {
  static String formatThaiDate(DateTime date) {
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

    final thaiDays = [
      'อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์',
    ];

    final weekday = thaiDays[date.weekday % 7];
    final day = date.day;
    final month = thaiMonths[date.month - 1];
    final year = date.year + 543; // Convert to Buddhist Era

    return '$weekday $day $month $year';
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('d MMM yyyy HH:mm', 'th').format(dateTime);
  }
}

