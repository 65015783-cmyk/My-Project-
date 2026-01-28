import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Base URL สำหรับ Backend "humans"
  static String get baseUrl {
    if (kIsWeb) {
      // สำหรับ Web ใช้ localhost
      return 'http://localhost:3000';
    } else {
      // สำหรับ Android Emulator ใช้ 10.0.2.2 เพื่อเชื่อมต่อกับ localhost ของเครื่อง
      return 'http://10.0.2.2:3000';
    }
  }

  // API Endpoints
  static String get loginUrl => '$baseUrl/api/login';
  static String get registerUrl => '$baseUrl/api/register';
  static String get checkInUrl => '$baseUrl/api/attendance/checkin';
  static String get checkOutUrl => '$baseUrl/api/attendance/checkout';
  static String get attendanceTodayUrl => '$baseUrl/api/attendance/today';
  static String get attendanceAllUrl => '$baseUrl/api/attendance/all';
  static String get leaveRequestUrl => '$baseUrl/api/leave/request';
  static String get leaveHistoryUrl => '$baseUrl/api/leave/history';
  static String get leavePendingUrl => '$baseUrl/api/leave/pending';
  static String get leaveStatusUrl => '$baseUrl/api/leave';
  static String get leaveMySummaryUrl => '$baseUrl/api/leave/my-summary';
  static String get profileUrl => '$baseUrl/api/profile';
  static String get leaveSummaryUrl => '$baseUrl/api/admin/leave-summary';
  static String get leaveDetailsUrl => '$baseUrl/api/admin/leave-details';
  static String get notificationsUrl => '$baseUrl/api/notifications';
  static String get dailyAttendanceSummaryUrl => '$baseUrl/api/admin/daily-attendance-summary';
  
  // Overtime Endpoints
  static String get overtimeMyRequestsUrl => '$baseUrl/api/overtime/my-requests';
  static String get overtimeAllUrl => '$baseUrl/api/overtime/all';
  static String get overtimePendingUrl => '$baseUrl/api/overtime/pending';
  static String get overtimeRequestUrl => '$baseUrl/api/overtime/request';
  static String get overtimeApproveUrl => '$baseUrl/api/overtime/approve';
  static String get overtimeSummaryUrl => '$baseUrl/api/overtime/summary';
  static String get overtimeRatesUrl => '$baseUrl/api/overtime/rates';
  
  // HR Salary Management Endpoints
  static String get hrSalarySummaryUrl => '$baseUrl/api/hr/salary/summary';
  static String get hrSalaryEmployeesUrl => '$baseUrl/api/hr/salary/employees';
  static String get hrSalaryRecentAdjustmentsUrl => '$baseUrl/api/hr/salary/recent-adjustments';
  static String get hrSalaryStatisticsUrl => '$baseUrl/api/hr/salary/statistics';
  static String get hrSalaryCreateUrl => '$baseUrl/api/hr/salary/create';
  static String get hrSalaryAdjustUrl => '$baseUrl/api/hr/salary/adjust';
  static String get hrSalaryEmployeeHistoryUrl => '$baseUrl/api/hr/salary/employee-history';
  static String get hrPayrollOverviewUrl => '$baseUrl/api/hr/payroll/overview';
  
  // Employee Salary Endpoints
  static String get salarySummaryUrl => '$baseUrl/api/salary/summary';
  static String get salarySlipUrl => '$baseUrl/api/salary/slip';
  static String get salarySlipDownloadUrl => '$baseUrl/api/salary/slip/download';
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> headersWithAuth(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Helper function สำหรับสร้าง URL ของรูปภาพหลักฐาน OT
  static String getEvidenceImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    // ถ้า imagePath เป็น full URL อยู่แล้ว ให้คืนค่าเดิม
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // ถ้า imagePath เป็น relative path ให้ต่อกับ baseUrl
    return '$baseUrl/$imagePath';
  }
}

