import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/hr_salary_service.dart';
import '../../models/salary_history_model.dart';
import 'package:intl/intl.dart';
import 'employee_salary_list_screen.dart';

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
          return RefreshIndicator(
            onRefresh: () => service.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payroll Overview Cards
                  service.payrollOverview != null
                      ? _buildPayrollOverviewCards(service.payrollOverview!)
                      : Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              if (service.isLoading)
                                const CircularProgressIndicator()
                              else
                                Column(
                                  children: [
                                    Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'กำลังโหลดข้อมูล...',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildQuickActions(context, service),
                  ),
                  const SizedBox(height: 24),
                  
                  // Recent Adjustments
                  if (service.recentAdjustments.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSectionTitle('การปรับเงินเดือนล่าสุด'),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildRecentAdjustments(service.recentAdjustments),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPayrollOverviewCards(PayrollOverview overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with padding
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  'ภาพรวมเงินเดือน (Payroll Overview)',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: overview.status.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: overview.status.color, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      overview.status == PayrollStatus.paid 
                          ? Icons.check_circle
                          : overview.status == PayrollStatus.calculated
                              ? Icons.calculate
                              : Icons.schedule,
                      size: 14,
                      color: overview.status.color,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        overview.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: overview.status.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${overview.monthName} ${overview.year + 543}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Cards in horizontal rows, full width
        Column(
          children: [
            // Row 1: Total Gross Salary & Total Employees
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 6),
                    child: _buildPayrollCard(
                      title: 'ยอดเงินเดือนรวมประจำเดือน',
                      value: overview.totalGrossSalaryFormatted,
                      icon: Icons.attach_money,
                      color: const Color(0xFF4CAF50),
                      emoji: '💰',
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6, right: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmployeeSalaryListScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: _buildPayrollCard(
                        title: 'จำนวนพนักงานที่รับเงินเดือน',
                        value: '${overview.totalEmployees} คน',
                        icon: Icons.people,
                        color: const Color(0xFF2196F3),
                        emoji: '👥',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Row 2: Total Deductions & Net Pay
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 6),
                    child: _buildPayrollCard(
                      title: 'ยอดหักรวม',
                      subtitle: '(ประกันสังคม, ภาษี, สาย/ขาดงาน)',
                      value: overview.totalDeductionsFormatted,
                      icon: Icons.trending_down,
                      color: const Color(0xFFF44336),
                      emoji: '📉',
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6, right: 16),
                    child: _buildPayrollCard(
                      title: 'ยอดจ่ายสุทธิ',
                      subtitle: '(Net Pay)',
                      value: overview.netPayFormatted,
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFF9C27B0),
                      emoji: '📈',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPayrollCard({
    required String title,
    String? subtitle,
    required String value,
    required IconData icon,
    required Color color,
    required String emoji,
  }) {
    return Container(
      height: 200, // เพิ่มความสูงให้ใหญ่ขึ้น
      padding: const EdgeInsets.all(20), // เพิ่ม padding
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), // เพิ่ม padding ของ icon
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 24), // เพิ่มขนาด emoji
                    ),
                    const SizedBox(width: 6),
                    Icon(icon, color: color, size: 24), // เพิ่มขนาด icon
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 26, // เพิ่มขนาดตัวเลข
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14, // เพิ่มขนาดข้อความ
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12, // เพิ่มขนาด subtitle
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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


}

