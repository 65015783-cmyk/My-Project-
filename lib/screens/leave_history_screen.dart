import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/leave_service.dart';
import '../models/leave_model.dart';

class LeaveHistoryScreen extends StatelessWidget {
  const LeaveHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leaveService = Provider.of<LeaveService>(context);
    final leaveRequests = leaveService.leaveRequests;

    // คำนวณจำนวนวันที่ "ลาไปแล้ว" ของปีปัจจุบัน แยกตามประเภท สำหรับ user ปัจจุบัน
    final currentYear = DateTime.now().year;
    final double sickUsed = leaveRequests
        .where((leave) =>
            leave.type == LeaveType.sickLeave &&
            leave.startDate.year == currentYear &&
            leave.status == LeaveStatus.approved)
        .fold<double>(0, (sum, leave) => sum + leave.totalDays);

    // ลากิจใช้ไป = รวมวันลาของประเภท: ลากิจส่วนตัว, ลาครึ่งวัน, ลากลับก่อน
    final double personalUsed = leaveRequests
        .where((leave) =>
            (leave.type == LeaveType.personalLeave ||
                leave.type == LeaveType.halfDayLeave ||
                leave.type == LeaveType.earlyLeave) &&
            leave.startDate.year == currentYear &&
            leave.status == LeaveStatus.approved)
        .fold<double>(0, (sum, leave) => sum + leave.totalDays);

    // รวมใช้ไป = ทุกประเภทในปีนี้ที่อนุมัติแล้ว
    final double totalUsed = leaveRequests
        .where((leave) =>
            leave.startDate.year == currentYear &&
            leave.status == LeaveStatus.approved)
        .fold<double>(0, (sum, leave) => sum + leave.totalDays);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('ประวัติการลา'),
      ),
      body: Column(
        children: [
          // Leave Balance Summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'ยอดวันลาที่ใช้ไปในปีนี้',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBalanceCard(
                      'ลาป่วยใช้ไป',
                      sickUsed.toStringAsFixed(1),
                      Colors.white,
                    ),
                    _buildBalanceCard(
                      'ลากิจใช้ไป',
                      personalUsed.toStringAsFixed(1),
                      Colors.white,
                    ),
                    _buildBalanceCard(
                      'รวม',
                      totalUsed.toStringAsFixed(1),
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Leave History List
          Expanded(
            child: leaveRequests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: leaveRequests.length,
                    itemBuilder: (context, index) {
                      return _buildLeaveCard(leaveRequests[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีประวัติการลา',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const Text(
          'วัน',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveCard(LeaveRequest leave) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: leave.type == LeaveType.sickLeave
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            leave.type == LeaveType.sickLeave
                ? Icons.medical_services
                : Icons.person,
            color: leave.type == LeaveType.sickLeave ? Colors.red : Colors.blue,
            size: 24,
          ),
        ),
        title: Text(
          leave.type.thaiLabel,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(leave.dateRangeFormatted),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: leave.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    leave.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: leave.status.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${leave.totalDays} วัน',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.expand_more,
          color: Colors.grey[400],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('เหตุผล', leave.reason),
                const SizedBox(height: 8),
                _buildDetailRow('ผู้อนุมัติ', leave.approver),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'วันที่ส่งคำขอ',
                  DateFormat('d MMMM yyyy HH:mm', 'th').format(leave.createdAt),
                ),
                if (leave.documentPaths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'เอกสารประกอบ:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: leave.documentPaths.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(leave.documentPaths[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (leave.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'เหตุผลที่ไม่อนุมัติ:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                leave.rejectionReason!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

