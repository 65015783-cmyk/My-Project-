import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/overtime_service.dart';
import '../../models/overtime_model.dart';

class OvertimeApprovalScreen extends StatefulWidget {
  const OvertimeApprovalScreen({super.key});

  @override
  State<OvertimeApprovalScreen> createState() => _OvertimeApprovalScreenState();
}

class _OvertimeApprovalScreenState extends State<OvertimeApprovalScreen> {
  String? _selectedStatus;
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final overtimeService = Provider.of<OvertimeService>(context, listen: false);
    await overtimeService.loadPendingRequests();
    await overtimeService.loadAllRequests(
      status: _selectedStatus,
      department: _selectedDepartment,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('อนุมัติการขอ OT'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'รออนุมัติ', icon: Icon(Icons.pending)),
                Tab(text: 'ทั้งหมด', icon: Icon(Icons.list)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPendingTab(),
                  _buildAllTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    return Consumer<OvertimeService>(
      builder: (context, overtimeService, _) {
        if (overtimeService.isLoading && overtimeService.pendingRequests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: overtimeService.pendingRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ไม่มีคำขอที่รออนุมัติ',
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
                  itemCount: overtimeService.pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = overtimeService.pendingRequests[index];
                    return _buildApprovalCard(request, isPending: true);
                  },
                ),
        );
      },
    );
  }

  Widget _buildAllTab() {
    return Consumer<OvertimeService>(
      builder: (context, overtimeService, _) {
        if (overtimeService.isLoading && overtimeService.allRequests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: overtimeService.allRequests.isEmpty
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
                        'ยังไม่มีข้อมูล',
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
                  itemCount: overtimeService.allRequests.length,
                  itemBuilder: (context, index) {
                    final request = overtimeService.allRequests[index];
                    return _buildApprovalCard(request, isPending: false);
                  },
                ),
        );
      },
    );
  }

  Widget _buildApprovalCard(OvertimeRequest request, {required bool isPending}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
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
          request.employeeName ?? 'ไม่ทราบชื่อ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${request.dateFormatted} • ${request.timeRangeFormatted}'),
            Text(
              '${request.department ?? '-'} • ${request.totalHoursFormatted}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                if (isPending && request.status == OvertimeStatus.pending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectRequest(request),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('ปฏิเสธ', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveRequest(request),
                          icon: const Icon(Icons.check),
                          label: const Text('อนุมัติ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  Future<void> _approveRequest(OvertimeRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการอนุมัติ'),
        content: Text('คุณต้องการอนุมัติคำขอ OT ของ ${request.employeeName ?? 'พนักงาน'} ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('อนุมัติ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final overtimeService = Provider.of<OvertimeService>(context, listen: false);
    final result = await overtimeService.approveRequest(
      requestId: request.id,
      action: 'approve',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'ดำเนินการสำเร็จ'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );

    if (result['success'] == true) {
      _loadData();
    }
  }

  Future<void> _rejectRequest(OvertimeRequest request) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปฏิเสธคำขอ OT'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('คุณต้องการปฏิเสธคำขอ OT ของ ${request.employeeName ?? 'พนักงาน'} ใช่หรือไม่?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'เหตุผล (ไม่บังคับ)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ปฏิเสธ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final overtimeService = Provider.of<OvertimeService>(context, listen: false);
    final result = await overtimeService.approveRequest(
      requestId: request.id,
      action: 'reject',
      rejectionReason: reasonController.text.trim().isEmpty 
          ? null 
          : reasonController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'ดำเนินการสำเร็จ'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );

    if (result['success'] == true) {
      _loadData();
    }
  }

  Future<void> _showFilterDialog() async {
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
                  _selectedDepartment = null;
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
