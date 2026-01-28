import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../services/overtime_service.dart';
import '../models/overtime_model.dart';
import '../config/api_config.dart';
import 'request_overtime_screen.dart';

class OvertimeHistoryScreen extends StatefulWidget {
  const OvertimeHistoryScreen({super.key});

  @override
  State<OvertimeHistoryScreen> createState() => _OvertimeHistoryScreenState();
}

class _OvertimeHistoryScreenState extends State<OvertimeHistoryScreen> {
  String? _selectedStatus;
  int? _selectedMonth;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final overtimeService = Provider.of<OvertimeService>(context, listen: false);
    await overtimeService.loadMyRequests(
      status: _selectedStatus,
      month: _selectedMonth,
      year: _selectedYear,
    );
    await overtimeService.loadSummary(
      month: _selectedMonth,
      year: _selectedYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการขอ OT'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<OvertimeService>(
        builder: (context, overtimeService, _) {
          if (overtimeService.isLoading && overtimeService.myRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: Column(
              children: [
                // สรุป
                if (overtimeService.summary != null)
                  _buildSummaryCard(overtimeService.summary!),
                
                // รายการ
                Expanded(
                  child: overtimeService.myRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ยังไม่มีประวัติการขอ OT',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: overtimeService.myRequests.length,
                          itemBuilder: (context, index) {
                            final request = overtimeService.myRequests[index];
                            return _buildRequestCard(request);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RequestOvertimeScreen(),
            ),
          );
          // รีโหลดข้อมูลเสมอเมื่อกลับมาจากหน้าขอ OT
          // รีเซ็ต filter เพื่อให้เห็นคำขอใหม่
          if (mounted) {
            setState(() {
              _selectedStatus = null; // รีเซ็ต filter
            });
            await _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('ขอ OT'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSummaryCard(OvertimeSummary summary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สรุป OT เดือนนี้',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'อนุมัติแล้ว',
                  '${summary.approvedHours.toStringAsFixed(2)} ชม.',
                  Colors.green[100]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryItem(
                  'รออนุมัติ',
                  '${summary.pendingHours.toStringAsFixed(2)} ชม.',
                  Colors.orange[100]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(OvertimeRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: request.status.color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.access_time,
            color: request.status.color,
          ),
        ),
        title: Text(
          request.dateFormatted,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('เวลา: ${request.timeRangeFormatted}'),
            Text('ชั่วโมง: ${request.totalHoursFormatted}'),
            if (request.reason != null && request.reason!.isNotEmpty)
              Text(
                'เหตุผล: ${request.reason}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: request.status.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: request.status.color),
          ),
          child: Text(
            request.status.label,
            style: TextStyle(
              color: request.status.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {
          _showRequestDetails(request);
        },
      ),
    );
  }

  void _showRequestDetails(OvertimeRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Text(
                      'รายละเอียดคำขอ OT',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: request.status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: request.status.color),
                      ),
                      child: Text(
                        request.status.label,
                        style: TextStyle(
                          color: request.status.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow('วันที่', request.dateFormatted),
                _buildDetailRow('เวลา', request.timeRangeFormatted),
                _buildDetailRow('ชั่วโมง OT', request.totalHoursFormatted),
                if (request.reason != null && request.reason!.isNotEmpty)
                  _buildDetailRow('เหตุผล', request.reason!),
                if (request.approverName != null)
                  _buildDetailRow('ผู้อนุมัติ', request.approverName!),
                if (request.approvedAt != null)
                  _buildDetailRow(
                    'วันที่อนุมัติ',
                    DateFormat('dd/MM/yyyy HH:mm', 'th').format(request.approvedAt!),
                  ),
                if (request.rejectionReason != null)
                  _buildDetailRow('เหตุผลที่ปฏิเสธ', request.rejectionReason!),
                // แสดงรูปภาพหลักฐาน (ถ้ามี)
                if (request.evidenceImagePath != null && request.evidenceImagePath!.isNotEmpty)
                  _buildEvidenceImage(request.evidenceImagePath!),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEvidenceImage(String imagePath) {
    final imageUrl = ApiConfig.getEvidenceImageUrl(imagePath);
    
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'หลักฐาน',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: () {
                // เปิดรูปภาพแบบเต็มหน้าจอ
                _showFullImage(imageUrl);
              },
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(height: 8),
                          Text('ไม่สามารถโหลดรูปภาพได้'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text('ไม่สามารถโหลดรูปภาพได้'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
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
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final statuses = ['ทั้งหมด', 'รออนุมัติ', 'อนุมัติแล้ว', 'ไม่อนุมัติ'];
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('กรองข้อมูล'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'สถานะ',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('ทั้งหมด')),
                  const DropdownMenuItem(value: 'pending', child: Text('รออนุมัติ')),
                  const DropdownMenuItem(value: 'approved', child: Text('อนุมัติแล้ว')),
                  const DropdownMenuItem(value: 'rejected', child: Text('ไม่อนุมัติ')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = null;
                });
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('รีเซ็ต'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }
}
