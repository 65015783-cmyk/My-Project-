import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NotificationService extends ChangeNotifier {
  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;

  NotificationService() {
    // ไม่โหลดทันทีใน constructor เพื่อหลีกเลี่ยงการเรียกซ้ำ
  }

  Future<void> loadNotificationCount() async {
    // ป้องกันการเรียกซ้ำถ้ากำลังโหลดอยู่
    if (_isLoading) return;
    
    try {
      _isLoading = true;
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _unreadCount = 0;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.notificationsUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final notificationsData = data['notifications'] as List<dynamic>? ?? [];
        
        // นับจำนวนการแจ้งเตือนที่ยังไม่อ่าน
        _unreadCount = notificationsData.where((notif) {
          return notif['is_read'] == false || notif['is_read'] == 0;
        }).length;
        
        _isLoading = false;
        notifyListeners();
      } else {
        _unreadCount = 0;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _unreadCount = 0;
      _isLoading = false;
      notifyListeners();
    }
  }

  // อัปเดต count จากข้อมูลที่มีอยู่แล้ว (ไม่ต้องเรียก API)
  void updateCountFromList(List<dynamic> notifications) {
    _unreadCount = notifications.where((notif) {
      return notif['is_read'] == false || notif['is_read'] == 0;
    }).length;
    notifyListeners();
  }

  void refresh() {
    loadNotificationCount();
  }
}

