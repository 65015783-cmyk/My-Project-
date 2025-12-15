import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  Map<String, dynamic>? _summaryData;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final currentYear = DateTime.now().year;
      final response = await http.get(
        Uri.parse('${ApiConfig.leaveMySummaryUrl}?year=$currentYear'),
        headers: ApiConfig.headersWithAuth(token),
      );

      print('[Calendar Screen] Response status: ${response.statusCode}');
      print('[Calendar Screen] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('[Calendar Screen] Parsed data: $data');
        setState(() {
          _summaryData = data;
          _isLoading = false;
        });
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        print('[Calendar Screen] Error response: $errorData');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[Calendar Screen] Error loading summary: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayOfMonth = DateTime(year, month, 1);
    final startingWeekday = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final totalCells = daysInMonth + startingWeekday;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          DateFormat('MMMM yyyy', 'th').format(DateTime(year, month)),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.today, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Navigation
          Container(
              color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: Colors.grey[700]),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(year, month - 1, 1);
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM', 'th').format(DateTime(year, month)),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: Colors.grey[700]),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(year, month + 1, 1);
                    });
                  },
                ),
              ],
            ),
          ),
          // Weekday Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส']
                  .map((day) => SizedBox(
                        width: 40,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Calendar Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
              ),
                itemCount: totalCells,
              itemBuilder: (context, index) {
                  if (index < startingWeekday) {
                  return const SizedBox.shrink();
                }

                  final day = index - startingWeekday + 1;
                  final cellDate = DateTime(year, month, day);
                  final isToday = _isSameDay(cellDate, DateTime.now());
                  final isSelected = _selectedDay != null && 
                      _isSameDay(cellDate, _selectedDay!);
                final isWeekend = (index % 7) == 0 || (index % 7) == 6;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = cellDate;
                      });
                    },
                    child: Container(
                  decoration: BoxDecoration(
                        color: isSelected
                        ? const Color(0xFF2196F3)
                            : isToday
                                ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: const Color(0xFF2196F3),
                                width: 2,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                          ),
                              ],
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                            ? Colors.white
                            : isWeekend
                                ? Colors.grey[400]
                                : Colors.black87,
                            fontSize: 15,
                          ),
                      ),
                    ),
                  ),
                );
              },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Summary Section
          RefreshIndicator(
            onRefresh: _loadSummary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSummaryContent(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  Widget _buildSummaryContent() {
    if (_summaryData == null) {
      return Column(
        children: [
          const Text(
            'ไม่สามารถโหลดข้อมูลได้',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _loadSummary,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('ลองอีกครั้ง'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      );
    }

    final leaveSummary = _summaryData!['leave_summary'] as Map<String, dynamic>? ?? {};
    final attendanceSummary = _summaryData!['attendance_summary'] as Map<String, dynamic>? ?? {};
    final currentYear = _parseInt(_summaryData!['year']) != 0 
        ? _parseInt(_summaryData!['year']) 
        : DateTime.now().year;

    final totalWorkDays = _parseInt(attendanceSummary['total_work_days']);
    final daysWorked = _parseInt(attendanceSummary['days_worked']);
    final leaveDays = _parseInt(attendanceSummary['leave_days']);
    
    // remaining_leave_days อาจเป็น 0 ได้ ถ้าเป็น null หรือไม่มีข้อมูลให้ใช้ default 30
    final remainingLeaveValue = leaveSummary['remaining_leave_days'];
    final remainingLeaveDays = remainingLeaveValue != null 
        ? _parseInt(remainingLeaveValue) 
        : 30;

    return Column(
      children: [
        _buildSummaryRow('วันทำงานทั้งหมด', '$totalWorkDays วัน', const Color(0xFF2196F3)),
        const SizedBox(height: 12),
        _buildSummaryRow('ลางาน', '$leaveDays วัน', const Color(0xFFFF9800)),
        const SizedBox(height: 12),
        _buildSummaryRow('มาทำงาน', '$daysWorked วัน', const Color(0xFF4CAF50)),
        const SizedBox(height: 12),
        _buildSummaryRow(
          'วันลาคงเหลือ (ปี $currentYear)', 
          '$remainingLeaveDays วัน', 
          remainingLeaveDays < 5 ? Colors.red : Colors.green,
          isHighlight: true,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
                fontSize: 15,
            color: Color(0xFF424242),
                fontWeight: FontWeight.w500,
              ),
          ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: isHighlight
                ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
                : null,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
