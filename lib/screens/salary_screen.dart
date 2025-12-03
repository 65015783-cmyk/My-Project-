import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/salary_service.dart';
import '../models/salary.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final salaryService = Provider.of<SalaryService>(context, listen: false);
      salaryService.fetchCurrentSalary();
      salaryService.fetchSalaryHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'เงินเดือน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showSalaryHistory(context);
            },
          ),
        ],
      ),
      body: Consumer<SalaryService>(
        builder: (context, salaryService, child) {
          if (salaryService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final salary = salaryService.currentSalary;
          if (salary == null) {
            return const Center(
              child: Text('ไม่มีข้อมูลเงินเดือน'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Net Salary Card
                _buildNetSalaryCard(salary),
                const SizedBox(height: 16),
                
                // Payment Date Card
                _buildPaymentDateCard(salary),
                const SizedBox(height: 16),
                
                // Income Section
                _buildSectionTitle('รายได้'),
                const SizedBox(height: 8),
                _buildIncomeCard(salary),
                const SizedBox(height: 16),
                
                // Deductions Section
                _buildSectionTitle('รายการหัก'),
                const SizedBox(height: 8),
                _buildDeductionsCard(salary),
                const SizedBox(height: 16),
                
                // Work Statistics
                _buildSectionTitle('สถิติการทำงาน'),
                const SizedBox(height: 8),
                _buildWorkStatsCard(salary),
                const SizedBox(height: 16),
                
                // Download Button
                _buildDownloadButton(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetSalaryCard(Salary salary) {
    final numberFormat = NumberFormat('#,##0.00', 'th_TH');
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${salary.month} ${salary.year}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'จ่ายแล้ว',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'เงินเดือนสุทธิ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '฿ ${numberFormat.format(salary.netSalary)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'รายได้',
                numberFormat.format(salary.totalIncome),
                Colors.green[300]!,
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white24,
              ),
              _buildSummaryItem(
                'หัก',
                numberFormat.format(salary.totalDeductions),
                Colors.red[300]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '฿ $value',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDateCard(Salary salary) {
    final dateFormat = DateFormat('d MMMM yyyy', 'th');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFF9C27B0),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'วันจ่ายเงินเดือน',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(salary.paymentDate),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildIncomeCard(Salary salary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow('เงินเดือนพื้นฐาน', salary.baseSalary, Colors.green),
          if (salary.bonus > 0) ...[
            const Divider(height: 24),
            _buildDetailRow('โบนัส', salary.bonus, Colors.green),
          ],
          if (salary.overtime > 0) ...[
            const Divider(height: 24),
            _buildDetailRow('ค่าล่วงเวลา (${salary.overtimeHours} ชม.)', salary.overtime, Colors.green),
          ],
          if (salary.allowance > 0) ...[
            const Divider(height: 24),
            _buildDetailRow('เบี้ยเลี้ยง', salary.allowance, Colors.green),
          ],
          if (salary.transportAllowance > 0) ...[
            const Divider(height: 24),
            _buildDetailRow('ค่าเดินทาง', salary.transportAllowance, Colors.green),
          ],
          if (salary.otherIncome > 0) ...[
            const Divider(height: 24),
            _buildDetailRow('รายได้อื่นๆ', salary.otherIncome, Colors.green),
          ],
          const Divider(height: 24, thickness: 2),
          _buildDetailRow('รวมรายได้', salary.totalIncome, Colors.green, isBold: true),
        ],
      ),
    );
  }

  Widget _buildDeductionsCard(Salary salary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (salary.tax > 0) 
            _buildDetailRow('ภาษีเงินได้หัก ณ ที่จ่าย', salary.tax, Colors.red),
          if (salary.socialSecurity > 0) ...[
            const Divider(height: 24),
            _buildDetailRow('ประกันสังคม', salary.socialSecurity, Colors.red),
          ],
          if (salary.providentFund > 0) ...[
            const Divider(height: 24),
            _buildDetailRow('กองทุนสำรองเลี้ยงชีพ', salary.providentFund, Colors.red),
          ],
          if (salary.loan > 0) ...[
            const Divider(height: 24),
            _buildDetailRow('เงินกู้/เงินยืม', salary.loan, Colors.red),
          ],
          if (salary.fine > 0) ...[
            const Divider(height: 24),
            _buildDetailRow('ค่าปรับ', salary.fine, Colors.red),
          ],
          if (salary.otherDeductions > 0) ...[
            const Divider(height: 24),
            _buildDetailRow('การหักอื่นๆ', salary.otherDeductions, Colors.red),
          ],
          const Divider(height: 24, thickness: 2),
          _buildDetailRow('รวมรายการหัก', salary.totalDeductions, Colors.red, isBold: true),
        ],
      ),
    );
  }

  Widget _buildWorkStatsCard(Salary salary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.work_outline,
            '${salary.workDays}',
            'วันทำงาน',
            Colors.blue,
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey[300],
          ),
          _buildStatItem(
            Icons.event_busy,
            '${salary.leaveDays}',
            'วันลา',
            Colors.orange,
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey[300],
          ),
          _buildStatItem(
            Icons.access_time,
            '${salary.overtimeHours}',
            'ชั่วโมง OT',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
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
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, double amount, Color color, {bool isBold = false}) {
    final numberFormat = NumberFormat('#,##0.00', 'th_TH');
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          '฿ ${numberFormat.format(amount)}',
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กำลังดาวน์โหลดสลิปเงินเดือน...')),
        );
      },
      icon: const Icon(Icons.download),
      label: const Text(
        'ดาวน์โหลดสลิปเงินเดือน',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  void _showSalaryHistory(BuildContext context) {
    final salaryService = Provider.of<SalaryService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'ประวัติเงินเดือน',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: salaryService.salaryHistory.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final salary = salaryService.salaryHistory[index];
                    return _buildHistoryCard(salary);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Salary salary) {
    final numberFormat = NumberFormat('#,##0.00', 'th_TH');
    final dateFormat = DateFormat('d MMM yyyy', 'th');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${salary.month} ${salary.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                dateFormat.format(salary.paymentDate),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'เงินเดือนสุทธิ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              Text(
                '฿ ${numberFormat.format(salary.netSalary)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

