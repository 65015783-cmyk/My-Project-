import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'leave_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
        return;
      }

      print('[Notifications] Loading notifications...');
      
      final response = await http.get(
        Uri.parse(ApiConfig.notificationsUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      print('[Notifications] Response status: ${response.statusCode}');
      print('[Notifications] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final notificationsData = data['notifications'] as List<dynamic>? ?? [];
        
        print('[Notifications] Found ${notificationsData.length} notifications');
        
        setState(() {
          _notifications = notificationsData.map((notif) {
            print('[Notifications] Parsing notification: $notif');
            
            // Parse created_at safely - แปลงเป็น local time
            String timeStr = '';
            try {
              // Parse UTC time จาก database
              final createdAtUtc = DateTime.parse(notif['created_at']);
              // แปลงเป็น local time
              final createdAtLocal = createdAtUtc.toLocal();
              // Format เป็นภาษาไทย
              timeStr = DateFormat('d MMM yyyy HH:mm', 'th').format(createdAtLocal);
            } catch (e) {
              print('[Notifications] Error parsing date: $e');
              timeStr = 'ไม่ระบุเวลา';
            }
            
            // Parse leave_id
            int? leaveId;
            if (notif['leave_id'] != null) {
              if (notif['leave_id'] is int) {
                leaveId = notif['leave_id'] as int;
              } else if (notif['leave_id'] is String) {
                leaveId = int.tryParse(notif['leave_id'] as String);
              } else {
                leaveId = int.tryParse(notif['leave_id'].toString());
              }
            }
            
            print('[Notifications] Parsed leaveId: $leaveId from ${notif['leave_id']} (type: ${notif['leave_id']?.runtimeType})');
            
            final notification = NotificationItem(
              id: notif['id'].toString(),
              title: notif['title'] ?? '',
              message: notif['message'] ?? '',
              time: timeStr,
              type: _parseNotificationType(notif['type']),
              isUnread: notif['is_read'] == false || notif['is_read'] == 0,
              leaveId: leaveId,
            );
            
            print('[Notifications] Created notification: id=${notification.id}, title=${notification.title}, leaveId=${notification.leaveId}');
            return notification;
          }).toList();
          
          print('[Notifications] Total notifications in state: ${_notifications.length}');
          _isLoading = false;
        });
      } else {
        print('[Notifications] Error: ${response.statusCode} - ${response.body}');
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    }
  }

  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'success':
      case 'approved':
        return NotificationType.approval;
      case 'warning':
      case 'rejected':
        return NotificationType.warning;
      case 'salary':
        return NotificationType.salary;
      case 'meeting':
        return NotificationType.meeting;
      default:
        return NotificationType.approval;
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      await http.patch(
        Uri.parse('${ApiConfig.notificationsUrl}/$notificationId/read'),
        headers: ApiConfig.headersWithAuth(token),
      );

      // อัปเดตสถานะใน local
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = NotificationItem(
            id: _notifications[index].id,
            title: _notifications[index].title,
            message: _notifications[index].message,
            time: _notifications[index].time,
            type: _notifications[index].type,
            isUnread: false,
            leaveId: _notifications[index].leaveId,
          );
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[Notifications] Building widget - isLoading: $_isLoading, count: ${_notifications.length}');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('[Notifications] Manual refresh triggered');
              _loadNotifications();
            },
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () {
                    print('[Notifications] Pull to refresh triggered');
                    return _loadNotifications();
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      print('[Notifications] Building card for index $index: ${_notifications[index].title}');
                      final card = _buildNotificationCard(_notifications[index]);
                      print('[Notifications] Card widget created for index $index');
                      return card;
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีการแจ้งเตือน',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    print('[Notifications] Building card widget for: ${notification.title}');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: notification.isUnread ? Colors.blue[50] : Colors.white,
      child: InkWell(
        onTap: () {
          print('[Notifications] Card tapped: ${notification.title}');
          print('[Notifications] leaveId: ${notification.leaveId}');
          print('[Notifications] isLeaveRelated: ${notification.title.contains('การลา') || notification.title.contains('อนุมัติ') || notification.title.contains('ปฏิเสธ')}');
          
          if (notification.isUnread) {
            _markAsRead(notification.id);
          }
          
          // Navigate to leave detail if it's a leave-related notification and has leaveId
          // สำหรับแจ้งเตือนอื่นๆ ไม่ทำอะไร (แค่ mark as read)
          final isLeaveRelated = notification.title.contains('การลา') || 
                                 notification.title.contains('อนุมัติ') || 
                                 notification.title.contains('ปฏิเสธ');
          
          if (isLeaveRelated) {
            if (notification.leaveId != null) {
              print('[Notifications] Navigating to LeaveDetailScreen with leaveId: ${notification.leaveId}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaveDetailScreen(leaveId: notification.leaveId!),
                ),
              );
            } else {
              print('[Notifications] Leave notification but no leaveId - cannot navigate');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ไม่พบข้อมูลการลา'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            print('[Notifications] Not a leave-related notification - no action');
          }
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: notification.type.color.withValues(alpha: 0.1),
            child: Icon(
              notification.type.icon,
              color: notification.type.color,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                notification.time,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          trailing: notification.isUnread
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool isUnread;
  final int? leaveId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isUnread = false,
    this.leaveId,
  });
}

enum NotificationType {
  approval(Icons.check_circle, Colors.green),
  salary(Icons.attach_money, Colors.purple),
  meeting(Icons.event, Colors.blue),
  warning(Icons.warning, Colors.orange);

  final IconData icon;
  final Color color;

  const NotificationType(this.icon, this.color);
}

