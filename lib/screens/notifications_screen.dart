import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = _getMockNotifications();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(notifications[index]);
              },
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.type.color.withValues(alpha: 0.1),
          child: Icon(
            notification.type.icon,
            color: notification.type.color,
          ),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
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
    );
  }

  List<NotificationItem> _getMockNotifications() {
    final now = DateTime.now();
    return [
      NotificationItem(
        title: 'อนุมัติการลางาน',
        message: 'การขอลางานของคุณได้รับการอนุมัติแล้ว',
        time: DateFormat('d MMM yyyy HH:mm', 'th').format(now.subtract(const Duration(hours: 2))),
        type: NotificationType.approval,
        isUnread: true,
      ),
      NotificationItem(
        title: 'เงินเดือน',
        message: 'เงินเดือนสำหรับเดือนนี้พร้อมให้ตรวจสอบแล้ว',
        time: DateFormat('d MMM yyyy', 'th').format(now.subtract(const Duration(days: 1))),
        type: NotificationType.salary,
        isUnread: true,
      ),
      NotificationItem(
        title: 'การประชุม',
        message: 'มีการประชุมทีมพรุ่งนี้ เวลา 10:00 น.',
        time: DateFormat('d MMM yyyy', 'th').format(now.subtract(const Duration(days: 2))),
        type: NotificationType.meeting,
        isUnread: false,
      ),
    ];
  }
}

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool isUnread;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isUnread = false,
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

