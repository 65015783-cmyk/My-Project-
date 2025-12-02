import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDay;

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
          Container(
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
            child: Column(
              children: [
                _buildSummaryRow('วันทำงานทั้งหมด', '22 วัน', const Color(0xFF2196F3)),
                const SizedBox(height: 12),
                _buildSummaryRow('ลางาน', '3 วัน', const Color(0xFFFF9800)),
                const SizedBox(height: 12),
                _buildSummaryRow('มาทำงาน', '19 วัน', const Color(0xFF4CAF50)),
              ],
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

  Widget _buildSummaryRow(String label, String value, Color color) {
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
