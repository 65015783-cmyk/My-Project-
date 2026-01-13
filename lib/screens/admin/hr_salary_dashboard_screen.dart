import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/hr_salary_service.dart';
import '../../models/salary_history_model.dart';
import 'package:intl/intl.dart';

class HrSalaryDashboardScreen extends StatefulWidget {
  const HrSalaryDashboardScreen({super.key});

  @override
  State<HrSalaryDashboardScreen> createState() => _HrSalaryDashboardScreenState();
}

class _HrSalaryDashboardScreenState extends State<HrSalaryDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final service = Provider.of<HrSalaryService>(context, listen: false);
      service.loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'HR Dashboard - จัดการเงินเดือน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () {
              final service = Provider.of<HrSalaryService>(context, listen: false);
              service.refresh();
            },
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: Consumer<HrSalaryService>(
        builder: (context, service, child) {
          if (service.isLoading && service.summary == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.errorMessage != null && service.summary == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    service.errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => service.loadAllData(),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => service.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  if (service.summary != null) _buildSummaryCards(service.summary!),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  _buildQuickActions(context, service),
                  const SizedBox(height: 24),
                  
                  // Recent Adjustments
                  if (service.recentAdjustments.isNotEmpty) ...[
                    _buildSectionTitle('การปรับเงินเดือนล่าสุด'),
                    const SizedBox(height: 12),
                    _buildRecentAdjustments(service.recentAdjustments),
                    const SizedBox(height: 24),
                  ],
                  
                  // Employee List
                  _buildSectionTitle('รายชื่อพนักงาน'),
                  const SizedBox(height: 12),
                  if (service.employees.isEmpty)
                    _buildEmptyState()
                  else
                    _buildEmployeeList(service.employees),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(SalaryDashboardSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'สรุปภาพรวม',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // Row 1: Total Employees & Average
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'จำนวนพนักงาน',
                value: summary.totalEmployees.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'เงินเดือนเฉลี่ย',
                value: summary.averageSalaryFormatted,
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Max & Min
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'เงินเดือนสูงสุด',
                value: summary.maxSalaryFormatted,
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'เงินเดือนต่ำสุด',
                value: summary.minSalaryFormatted,
                icon: Icons.trending_down,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Adjustment Count
        _buildSummaryCard(
          title: 'การปรับเงินเดือน (เดือนนี้)',
          value: summary.adjustmentsThisMonth.toString(),
          icon: Icons.swap_horiz,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, HrSalaryService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'การดำเนินการด่วน',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.add,
                label: 'เพิ่มเงินเดือนแรก',
                color: Colors.green,
                onTap: () {
                  // TODO: Navigate to create starting salary screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ฟีเจอร์กำลังพัฒนา')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.swap_horiz,
                label: 'ปรับเงินเดือน',
                color: Colors.blue,
                onTap: () {
                  // TODO: Navigate to adjust salary screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ฟีเจอร์กำลังพัฒนา')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRecentAdjustments(List<SalaryHistoryModel> adjustments) {
    return Column(
      children: adjustments.take(5).map((adjustment) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withValues(alpha: 0.1),
              child: const Icon(Icons.swap_horiz, color: Colors.purple),
            ),
            title: Text('เงินเดือน: ${adjustment.salaryAmountFormatted}'),
            subtitle: Text(
              adjustment.reason ?? 'ไม่ระบุเหตุผล',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              adjustment.effectiveDateFormatted,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmployeeList(List<EmployeeSalarySummary> employees) {
    return Column(
      children: employees.map((employee) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorFromName(employee.fullName).withValues(alpha: 0.2),
              child: Text(
                employee.fullName.isNotEmpty
                    ? employee.fullName.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  color: _getColorFromName(employee.fullName),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              employee.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (employee.position != null)
                  Text('ตำแหน่ง: ${employee.position}'),
                if (employee.department != null)
                  Text('แผนก: ${employee.department}'),
                const SizedBox(height: 4),
                Text(
                  'เงินเดือนปัจจุบัน: ${employee.currentSalaryFormatted}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
            onTap: () {
              // TODO: Navigate to employee salary detail
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ดูรายละเอียด: ${employee.fullName}')),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีข้อมูลพนักงาน',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String name) {
    if (name.isEmpty) return Colors.grey;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[name.hashCode % colors.length];
  }
}

