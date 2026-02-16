import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/salary_service.dart';
import '../services/overtime_service.dart';
import '../models/salary.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> with SingleTickerProviderStateMixin {
  TabController get _tabController => _tabControllerInstance;
  late final TabController _tabControllerInstance;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _tabControllerInstance = TabController(length: 2, vsync: this);
    // รอให้ widget build เสร็จก่อนแล้วค่อยโหลดข้อมูล
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final salaryService = Provider.of<SalaryService>(context, listen: false);
        // โหลดข้อมูลเงินเดือนปัจจุบันก่อน
        salaryService.fetchCurrentSalary();
        // แล้วโหลดข้อมูลตามปี/เดือนที่เลือก
        _loadSalaryData();
      }
    });
  }

  @override
  void dispose() {
    _tabControllerInstance.dispose();
    super.dispose();
  }

  void _loadSalaryData() {
    if (!mounted) return;
    final salaryService = Provider.of<SalaryService>(context, listen: false);
    salaryService.fetchSalarySummary(year: _selectedYear, month: _selectedMonth);

    // โหลดสรุป OT ของเดือน/ปีเดียวกัน เพื่อใช้คำนวณค่าล่วงเวลา
    final overtimeService = Provider.of<OvertimeService>(context, listen: false);
    overtimeService.loadSummary(month: _selectedMonth, year: _selectedYear);
  }

  List<int> _getYearList() {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index + 1); // 5 ปีย้อนหลัง
  }

  List<String> _getMonthList() {
    return [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
      'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
      'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
  }

  Future<void> _downloadSalarySlip() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final salaryService = Provider.of<SalaryService>(context, listen: false);
      final filePath = await salaryService.downloadSalarySlip(
        year: _selectedYear,
        month: _selectedMonth,
      );

      if (mounted && filePath != null) {
        // แชร์ไฟล์
        final file = XFile(filePath);
        await Share.shareXFiles(
          [file],
          text: 'สลิปเงินเดือน ${_getMonthList()[_selectedMonth - 1]} $_selectedYear',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ดาวน์โหลดสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'สรุปเงินเดือน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'สรุปเงินเดือน'),
            Tab(text: 'สลิปเงินเดือน'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date Selection Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'เลือกปี',
                    value: _selectedYear.toString(),
                    items: _getYearList().map((year) => year.toString()).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = int.parse(value!);
                        _loadSalaryData();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'เลือกเดือน',
                    value: _getMonthList()[_selectedMonth - 1],
                    items: _getMonthList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = _getMonthList().indexOf(value!) + 1;
                        _loadSalaryData();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildSlipTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTab() {
    return Consumer<SalaryService>(
      builder: (context, salaryService, child) {
        if (salaryService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // ใช้ selectedSalary ถ้ามี หรือใช้ currentSalary
        final salary = salaryService.selectedSalary ?? salaryService.currentSalary;

        if (salaryService.errorMessage != null || salary == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  salaryService.errorMessage ?? 'ยังไม่เปิดเผยข้อมูล',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'กรุณารอเจ้าหน้าที่ฝ่ายบุคคล\nเปิดให้ตรวจสอบอีกครั้ง',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Net Salary Card (UI เดิม)
              _buildNetSalaryCard(salary),
              const SizedBox(height: 16),
              
              // Payment Date Card
              _buildPaymentDateCard(salary),
              const SizedBox(height: 16),
              
              // Income Section
              _buildSectionTitle('รายได้'),
              const SizedBox(height: 8),
              _buildIncomeCard(context, salary),
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
              _buildDownloadButton(salary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlipTab() {
    return Consumer<SalaryService>(
      builder: (context, salaryService, child) {
        // ใช้ selectedSalary หรือ currentSalary
        final salary = salaryService.selectedSalary ?? salaryService.currentSalary;

        if (salaryService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (salary == null && salaryService.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  salaryService.errorMessage!,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'กรุณารอเจ้าหน้าที่ฝ่ายบุคคล\nเปิดให้ตรวจสอบอีกครั้ง',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // แสดงข้อมูลสลิปเงินเดือน
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // สรุปข้อมูลสลิป
              if (salary != null) ...[
                Container(
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
                      Icon(
                        Icons.picture_as_pdf,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'สลิปเงินเดือน',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${salary.month} ${salary.year}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSlipInfoItem('เงินเดือนสุทธิ', salary.netSalary, Colors.green),
                          _buildSlipInfoItem('รวมรายได้', salary.totalIncome, Colors.blue),
                          _buildSlipInfoItem('รวมหัก', salary.totalDeductions, Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // ปุ่มดาวน์โหลด
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadSalarySlip,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _isDownloading ? 'กำลังดาวน์โหลด...' : 'ดาวน์โหลดสลิปเงินเดือน',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ไฟล์จะถูกบันทึกในเครื่องและสามารถแชร์ได้',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlipInfoItem(String label, double amount, Color color) {
    final numberFormat = NumberFormat('#,##0', 'th_TH');
    return Column(
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
          '฿${numberFormat.format(amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodCard(Salary salary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'งวดปกติ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เดือน ${salary.month} ${salary.year}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
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

  // ปรับค่าล่วงเวลาในมุมมองจากข้อมูลสรุป OT ที่อนุมัติแล้ว (ฝั่ง client)
  Salary _applyOvertimeFromSummary(BuildContext context, Salary salary) {
    final overtimeService = Provider.of<OvertimeService>(context);
    final summary = overtimeService.summary;

    // ถ้า backend ส่งค่าล่วงเวลามาแล้ว ให้ใช้ค่าจาก backend ตรงๆ
    if (salary.overtime > 0 || summary == null || summary.approvedHours <= 0) {
      return salary;
    }

    // คำนวณค่า OT แบบประมาณการ:
    // ชั่วโมงทำงานต่อเดือน = วันทำงาน * 8 ชม.
    // อัตราค่าจ้างต่อชั่วโมง = เงินเดือนพื้นฐาน / ชั่วโมงทำงานต่อเดือน
    // เงิน OT = approvedHours * hourlyRate * 1.5 (สมมติเป็นวันธรรมดา)
    final workDays = salary.workDays > 0 ? salary.workDays : 22;
    final baseHours = workDays * 8;
    if (baseHours <= 0) return salary;

    final hourlyRate = salary.baseSalary / baseHours;
    const weekdayMultiplier = 1.5; // ใช้เรทวันธรรมดาเป็นค่าเริ่มต้น
    final overtimeAmount = summary.approvedHours * hourlyRate * weekdayMultiplier;

    return salary.copyWith(
      overtime: overtimeAmount,
      overtimeHours: summary.approvedHours,
    );
  }

  Widget _buildIncomeCard(BuildContext context, Salary salary) {
    final adjustedSalary = _applyOvertimeFromSummary(context, salary);

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
          _buildDetailRow('เงินเดือนพื้นฐาน', adjustedSalary.baseSalary, Colors.green),
          const Divider(height: 24),
          _buildDetailRow('โบนัส', adjustedSalary.bonus, Colors.green),
          const Divider(height: 24),
          _buildDetailRow(
            'ค่าล่วงเวลา (${adjustedSalary.overtimeHours.toInt()} ชม.)',
            adjustedSalary.overtime,
            Colors.green,
          ),
          const Divider(height: 24),
          _buildDetailRow('เบี้ยเลี้ยง', adjustedSalary.allowance, Colors.green),
          const Divider(height: 24),
          _buildDetailRow('ค่าเดินทาง', adjustedSalary.transportAllowance, Colors.green),
          const Divider(height: 24),
          _buildDetailRow('รายได้อื่นๆ', adjustedSalary.otherIncome, Colors.green),
          const Divider(height: 24, thickness: 2),
          _buildDetailRow('รวมรายได้', adjustedSalary.totalIncome, Colors.green, isBold: true),
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
          _buildDetailRow('ภาษีเงินได้หัก ณ ที่จ่าย', salary.tax, Colors.red),
          const Divider(height: 24),
          _buildDetailRow('ประกันสังคม', salary.socialSecurity, Colors.red),
          const Divider(height: 24),
          _buildDetailRow('กองทุนสำรองเลี้ยงชีพ', salary.providentFund, Colors.red),
          const Divider(height: 24),
          _buildDetailRow('เงินกู้/เงินยืม', salary.loan, Colors.red),
          const Divider(height: 24),
          _buildDetailRow('ค่าปรับ', salary.fine, Colors.red),
          const Divider(height: 24),
          _buildDetailRow('การหักอื่นๆ', salary.otherDeductions, Colors.red),
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
            '${salary.overtimeHours.toInt()}',
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
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFF2196F3),
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

  Widget _buildDownloadButton(Salary salary) {
    return ElevatedButton.icon(
      onPressed: _isDownloading ? null : _downloadSalarySlip,
      icon: _isDownloading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.download),
      label: Text(
        _isDownloading ? 'กำลังดาวน์โหลด...' : 'ดาวน์โหลดสลิปเงินเดือน',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
}

