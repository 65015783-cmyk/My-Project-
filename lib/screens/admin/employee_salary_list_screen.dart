import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/hr_salary_service.dart';
import '../../models/salary_history_model.dart';
import 'package:intl/intl.dart';

class EmployeeSalaryListScreen extends StatefulWidget {
  const EmployeeSalaryListScreen({super.key});

  @override
  State<EmployeeSalaryListScreen> createState() => _EmployeeSalaryListScreenState();
}

class _EmployeeSalaryListScreenState extends State<EmployeeSalaryListScreen> {
  String _searchQuery = '';
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final service = Provider.of<HrSalaryService>(context, listen: false);
      service.loadEmployees();
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
          'รายชื่อพนักงาน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () {
              final service = Provider.of<HrSalaryService>(context, listen: false);
              service.loadEmployees();
            },
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: Consumer<HrSalaryService>(
        builder: (context, service, child) {
          if (service.isLoading && service.employees.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.errorMessage != null && service.employees.isEmpty) {
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
                    onPressed: () => service.loadEmployees(),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            );
          }

          // Filter employees
          final filteredEmployees = service.employees.where((employee) {
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final nameMatch = employee.fullName.toLowerCase().contains(query);
              final positionMatch = employee.position?.toLowerCase().contains(query) ?? false;
              final departmentMatch = employee.department?.toLowerCase().contains(query) ?? false;
              
              if (!(nameMatch || positionMatch || departmentMatch)) {
                return false;
              }
            }
            
            final matchesDepartment = _selectedDepartment == null ||
                employee.department == _selectedDepartment;

            return matchesDepartment;
          }).toList();

          // Get unique departments
          final departments = service.employees
              .map((e) => e.department)
              .where((d) => d != null && d.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          return Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ค้นหาพนักงาน...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    if (departments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      // Department Filter
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'กรองตามแผนก',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        value: _selectedDepartment,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('ทั้งหมด'),
                          ),
                          ...departments.map((dept) => DropdownMenuItem<String>(
                                value: dept,
                                child: Text(dept ?? ''),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              // Employee Count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'พบ ${filteredEmployees.length} คน',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (_searchQuery.isNotEmpty || _selectedDepartment != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _selectedDepartment = null;
                          });
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('ล้างตัวกรอง'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Employee List
              Expanded(
                child: filteredEmployees.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => service.loadEmployees(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = filteredEmployees[index];
                            return _buildEmployeeCard(employee, service);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeSalarySummary employee, HrSalaryService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to employee detail
          _showEmployeeDetail(context, employee, service);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: _getColorFromName(employee.fullName).withValues(alpha: 0.2),
                child: Text(
                  employee.fullName.isNotEmpty
                      ? employee.fullName.substring(0, 1).toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: _getColorFromName(employee.fullName),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Employee Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (employee.position != null)
                      Text(
                        employee.position!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (employee.department != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'แผนก: ${employee.department}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'เงินเดือน: ${employee.currentSalaryFormatted}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedDepartment != null
                ? 'ไม่พบพนักงานที่ค้นหา'
                : 'ยังไม่มีข้อมูลพนักงาน',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetail(
    BuildContext context,
    EmployeeSalarySummary employee,
    HrSalaryService service,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Employee Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: _getColorFromName(employee.fullName).withValues(alpha: 0.2),
                      child: Text(
                        employee.fullName.isNotEmpty
                            ? employee.fullName.substring(0, 1).toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: _getColorFromName(employee.fullName),
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (employee.position != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              employee.position!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          if (employee.department != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'แผนก: ${employee.department}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Salary Information
                _buildDetailSection(
                  'ข้อมูลเงินเดือน',
                  [
                    _buildDetailRow('เงินเดือนปัจจุบัน', employee.currentSalaryFormatted, Colors.green),
                    _buildDetailRow('เงินฐานเงินเดือน', employee.baseSalaryFormatted, Colors.blue),
                    _buildDetailRow('จำนวนครั้งที่ปรับ', '${employee.adjustmentCount} ครั้ง', Colors.orange),
                    if (employee.lastAdjustmentDate != null)
                      _buildDetailRow(
                        'ปรับล่าสุด',
                        employee.lastAdjustmentDateFormatted,
                        Colors.purple,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                // Actions
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    // TODO: Navigate to salary history
                    final history = await service.loadEmployeeSalaryHistory(employee.employeeId);
                    if (context.mounted) {
                      _showSalaryHistory(context, employee, history);
                    }
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('ดูประวัติเงินเดือน'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showSalaryHistory(
    BuildContext context,
    EmployeeSalarySummary employee,
    List<SalaryHistoryModel> history,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Text(
                    'ประวัติเงินเดือน',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // History List
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'ยังไม่มีประวัติเงินเดือน',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.salaryType == SalaryType.adjust
                                  ? Colors.purple.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              child: Icon(
                                item.salaryType == SalaryType.adjust
                                    ? Icons.swap_horiz
                                    : Icons.start,
                                color: item.salaryType == SalaryType.adjust
                                    ? Colors.purple
                                    : Colors.green,
                              ),
                            ),
                            title: Text(
                              item.salaryAmountFormatted,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.salaryType.label),
                                if (item.reason != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.reason!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Text(
                              item.effectiveDateFormatted,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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

