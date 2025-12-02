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
  static String get leaveRequestUrl => '$baseUrl/api/leave/request';
  static String get profileUrl => '$baseUrl/api/profile';
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> headersWithAuth(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}

