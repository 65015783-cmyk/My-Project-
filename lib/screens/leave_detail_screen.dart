import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../models/leave_model.dart';

class LeaveDetailScreen extends StatefulWidget {
  final int leaveId;

  const LeaveDetailScreen({
    super.key,
    required this.leaveId,
  });

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  Map<String, dynamic>? _leaveData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaveDetail();
  }

  Future<void> _loadLeaveDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _error = 'ไม่พบ Token การยืนยันตัวตน';
          _isLoading = false;
        });
        return;
      }

      // ดึงข้อมูลการลาจาก history และหา leave ที่ตรงกับ leaveId
      final response = await http.get(
        Uri.parse(ApiConfig.leaveHistoryUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final leaves = data['leaves'] as List<dynamic>? ?? [];
        
        // หา leave ที่ตรงกับ leaveId (รองรับทั้ง int และ string)
        Map<String, dynamic>? leave;
        try {
          leave = leaves.firstWhere(
            (l) {
              final id = l['id'];
              // รองรับทั้ง int และ string
              if (id is int) {
                return id == widget.leaveId;
              } else if (id is String) {
                return int.tryParse(id) == widget.leaveId;
              }
              return false;
            },
            orElse: () => null,
          ) as Map<String, dynamic>?;
        } catch (e) {
          print('[LeaveDetail] Error finding leave: $e');
          leave = null;
        }

        if (leave != null) {
          setState(() {
            _leaveData = leave;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'ไม่พบข้อมูลการลา (ID: ${widget.leaveId})';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'เกิดข้อผิดพลาดในการโหลดข้อมูล (Status: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'เกิดข้อผิดพลาด: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  LeaveType _parseLeaveType(String? type) {
    switch (type) {
      case 'sick':
        return LeaveType.sickLeave;
      case 'personal':
        return LeaveType.personalLeave;
      default:
        return LeaveType.personalLeave;
    }
  }

  LeaveStatus _parseLeaveStatus(String? status) {
    switch (status) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'pending':
      default:
        return LeaveStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('รายละเอียดการลา'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLeaveDetail,
                        child: const Text('ลองอีกครั้ง'),
                      ),
                    ],
                  ),
                )
              : _leaveData == null
                  ? const Center(
                      child: Text('ไม่พบข้อมูลการลา'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildLeaveDetailCard(),
                    ),
    );
  }

  Widget _buildLeaveDetailCard() {
    final leaveType = _parseLeaveType(_leaveData!['leave_type']);
    final status = _parseLeaveStatus(_leaveData!['status']);
    final startDate = DateTime.parse(_leaveData!['start_date']);
    final endDate = DateTime.parse(_leaveData!['end_date']);
    final totalDays = _leaveData!['total_days'] ?? 
        endDate.difference(startDate).inDays + 1;
    final reason = _leaveData!['reason'] ?? '';
    final createdAt = _leaveData!['created_at'] != null
        ? DateTime.parse(_leaveData!['created_at'])
        : null;
    final approvedAt = _leaveData!['approved_at'] != null
        ? DateTime.parse(_leaveData!['approved_at'])
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Type and Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: leaveType == LeaveType.sickLeave
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    leaveType.thaiLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: leaveType == LeaveType.sickLeave
                          ? Colors.red
                          : Colors.blue,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: status.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date Range
            _buildDetailRow(
              Icons.calendar_today,
              'วันที่ลา',
              '${DateFormat('d MMMM yyyy', 'th').format(startDate)} - ${DateFormat('d MMMM yyyy', 'th').format(endDate)}',
            ),
            const SizedBox(height: 16),

            // Total Days
            _buildDetailRow(
              Icons.event,
              'จำนวนวัน',
              '$totalDays วัน',
            ),
            const SizedBox(height: 16),

            // Reason
            _buildDetailRow(
              Icons.description,
              'เหตุผล',
              reason,
            ),
            const SizedBox(height: 16),

            // Created At
            if (createdAt != null)
              _buildDetailRow(
                Icons.access_time,
                'วันที่ส่งคำขอ',
                DateFormat('d MMMM yyyy HH:mm', 'th').format(createdAt.toLocal()),
              ),
            if (createdAt != null) const SizedBox(height: 16),

            // Approved At
            if (approvedAt != null)
              _buildDetailRow(
                Icons.check_circle,
                'วันที่อนุมัติ/ปฏิเสธ',
                DateFormat('d MMMM yyyy HH:mm', 'th').format(approvedAt.toLocal()),
              ),
            if (approvedAt != null) const SizedBox(height: 16),

            // Rejection Reason (if rejected)
            if (status == LeaveStatus.rejected && _leaveData!['rejection_reason'] != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'เหตุผลที่ไม่อนุมัติ:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _leaveData!['rejection_reason'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

