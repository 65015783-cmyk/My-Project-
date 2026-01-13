import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/attendance_service.dart';
import '../models/attendance_model.dart';
import 'leave_history_screen.dart';

class WorkHistoryScreen extends StatefulWidget {
  const WorkHistoryScreen({super.key});

  @override
  State<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends State<WorkHistoryScreen> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    // โหลดประวัติการทำงานเมื่อเปิดหน้าจอ
    _loadFuture = Provider.of<AttendanceService>(
      context,
      listen: false,
    ).loadAttendanceHistory();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceService = Provider.of<AttendanceService>(context);
    final historyItems = _mapAttendanceToHistoryItems(attendanceService.history);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('ประวัติการทำงาน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            tooltip: 'ประวัติการลา',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LeaveHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              historyItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (historyItems.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyItems.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(historyItems[index]);
            },
          );
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
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีประวัติการทำงาน',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.date,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: item.status.color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.status == WorkStatus.complete
                            ? Icons.check_circle
                            : item.status == WorkStatus.pending
                                ? Icons.pending
                                : Icons.cancel,
                        size: 14,
                        color: item.status.color,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.status.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: item.status.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTimeItem('เข้างาน', item.checkIn, Colors.green),
                const SizedBox(width: 20),
                _buildTimeItem('ออกงาน', item.checkOut, Colors.orange),
              ],
            ),
            if (item.hoursWorked != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'รวมเวลาทำงาน: ${item.hoursWorked} ชั่วโมง',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeItem(String label, String time, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<HistoryItem> _mapAttendanceToHistoryItems(
    List<AttendanceModel> records,
  ) {
    return records.map((att) {
      final checkIn = att.checkInTimeFormatted;
      final checkOut = att.checkOutTimeFormatted;

      String? hoursWorked;
      if (att.checkInTime != null && att.checkOutTime != null) {
        final diff = att.checkOutTime!.difference(att.checkInTime!).inMinutes;
        final hours = (diff / 60);
        hoursWorked = hours.toStringAsFixed(1);
      }

      // กำหนดสถานะ: ครบ (เข้างานและออกงานครบ) หรือ รอดำเนินการ (ยังไม่ออกงาน)
      final status = att.checkInTime != null && att.checkOutTime != null
          ? WorkStatus.complete  // เข้างานและออกงานครบ
          : att.checkInTime != null
              ? WorkStatus.pending  // เข้างานแล้ว แต่ยังไม่ออกงาน
              : WorkStatus.absent;  // ยังไม่เข้างาน (ไม่ควรเกิดใน history)

      return HistoryItem(
        date: att.dateFormatted,
        checkIn: checkIn,
        checkOut: checkOut,
        hoursWorked: hoursWorked,
        status: status,
      );
    }).toList();
  }
}

class HistoryItem {
  final String date;
  final String checkIn;
  final String checkOut;
  final String? hoursWorked;
  final WorkStatus status;

  HistoryItem({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    this.hoursWorked,
    required this.status,
  });
}

enum WorkStatus {
  complete(Colors.green, 'เข้างานและออกงานครบ'),
  pending(Colors.orange, 'ยังไม่ออกงาน'),
  absent(Colors.red, 'ขาดงาน');

  final Color color;
  final String label;

  const WorkStatus(this.color, this.label);
}

