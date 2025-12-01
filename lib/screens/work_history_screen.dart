import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'leave_history_screen.dart';

class WorkHistoryScreen extends StatelessWidget {
  const WorkHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyItems = _getMockHistory();

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
      body: historyItems.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                return _buildHistoryCard(historyItems[index]);
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
                Text(
                  item.date,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: item.status.color,
                    ),
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

  List<HistoryItem> _getMockHistory() {
    final now = DateTime.now();
    return [
      HistoryItem(
        date: DateFormat('EEEE d MMMM yyyy', 'th').format(now),
        checkIn: '08:30',
        checkOut: '17:30',
        hoursWorked: '8.5',
        status: WorkStatus.complete,
      ),
      HistoryItem(
        date: DateFormat('EEEE d MMMM yyyy', 'th').format(now.subtract(const Duration(days: 1))),
        checkIn: '08:25',
        checkOut: '17:45',
        hoursWorked: '9.3',
        status: WorkStatus.complete,
      ),
      HistoryItem(
        date: DateFormat('EEEE d MMMM yyyy', 'th').format(now.subtract(const Duration(days: 2))),
        checkIn: '08:30',
        checkOut: '--:--',
        status: WorkStatus.pending,
      ),
    ];
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
  complete(Colors.green, 'ครบ'),
  pending(Colors.orange, 'รอดำเนินการ'),
  absent(Colors.red, 'ขาดงาน');

  final Color color;
  final String label;

  const WorkStatus(this.color, this.label);
}

