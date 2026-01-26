import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/overtime_service.dart';
import '../models/overtime_model.dart';

class RequestOvertimeScreen extends StatefulWidget {
  const RequestOvertimeScreen({super.key});

  @override
  State<RequestOvertimeScreen> createState() => _RequestOvertimeScreenState();
}

class _RequestOvertimeScreenState extends State<RequestOvertimeScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 30);
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  double _calculatedHours = 0.0;

  // สร้างรายการเวลาสำหรับ dropdown (ทุก 15 นาที)
  List<TimeOfDay> _getTimeOptions() {
    final List<TimeOfDay> times = [];
    // เริ่มจาก 17:30 (เวลาออกงานปกติ) ถึง 23:00
    for (int hour = 17; hour <= 23; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        if (hour == 17 && minute < 30) continue; // ข้ามเวลาก่อน 17:30
        if (hour == 23 && minute > 0) break; // หยุดที่ 23:00
        times.add(TimeOfDay(hour: hour, minute: minute));
      }
    }
    return times;
  }

  // แปลง TimeOfDay เป็น String สำหรับแสดงใน dropdown
  String _formatTimeForDropdown(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$period $displayHour:$minute';
  }

  @override
  void initState() {
    super.initState();
    _calculateHours();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _calculateHours() {
    final startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';
    setState(() {
      _calculatedHours = OvertimeService.calculateHours(startTimeStr, endTimeStr);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('th', 'TH'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onStartTimeChanged(TimeOfDay? newTime) {
    if (newTime == null) return;
    setState(() {
      _startTime = newTime;
      // ปรับเวลาสิ้นสุดให้มากกว่าเวลาเริ่มต้น
      if (_endTime.hour < _startTime.hour || 
          (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
        // หาเวลาถัดไปที่มากกว่าเวลาเริ่มต้น
        final timeOptions = _getTimeOptions();
        final currentIndex = timeOptions.indexWhere((t) => 
          t.hour == _startTime.hour && t.minute == _startTime.minute
        );
        if (currentIndex >= 0 && currentIndex < timeOptions.length - 1) {
          _endTime = timeOptions[currentIndex + 1];
        } else {
          // ถ้าไม่เจอ ให้เพิ่ม 1 ชั่วโมง
          _endTime = TimeOfDay(
            hour: _startTime.hour + 1,
            minute: _startTime.minute,
          );
        }
      }
      _calculateHours();
    });
  }

  void _onEndTimeChanged(TimeOfDay? newTime) {
    if (newTime == null) return;
    if (newTime.hour < _startTime.hour || 
        (newTime.hour == _startTime.hour && newTime.minute <= _startTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มต้น'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _endTime = newTime;
      _calculateHours();
    });
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_calculatedHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกช่วงเวลาที่ถูกต้อง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final overtimeService = Provider.of<OvertimeService>(context, listen: false);
    
    final startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

    final result = await overtimeService.createRequest(
      date: _selectedDate,
      startTime: startTimeStr,
      endTime: endTimeStr,
      reason: _reasonController.text.trim(),
    );

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'ส่งคำขอ OT สำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'เกิดข้อผิดพลาด'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ขอทำงานล่วงเวลา (OT)'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // วันที่
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text('วันที่'),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy', 'th').format(_selectedDate),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 16),

            // เวลาเริ่มต้น
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'เวลาเริ่มต้น',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TimeOfDay>(
                          value: _startTime,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                          items: _getTimeOptions().map((TimeOfDay time) {
                            return DropdownMenuItem<TimeOfDay>(
                              value: time,
                              child: Text(
                                _formatTimeForDropdown(time),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _onStartTimeChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // เวลาสิ้นสุด
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.orange, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'เวลาสิ้นสุด',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TimeOfDay>(
                          value: _endTime,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                          items: _getTimeOptions()
                              .where((time) => 
                                time.hour > _startTime.hour || 
                                (time.hour == _startTime.hour && time.minute > _startTime.minute)
                              )
                              .map((TimeOfDay time) {
                            return DropdownMenuItem<TimeOfDay>(
                              value: time,
                              child: Text(
                                _formatTimeForDropdown(time),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _onEndTimeChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // สรุปชั่วโมง OT
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ชั่วโมง OT ทั้งหมด:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${_calculatedHours.toStringAsFixed(2)} ชั่วโมง',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // เหตุผล
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'เหตุผล (ไม่บังคับ)',
                hintText: 'ระบุเหตุผลในการทำงานล่วงเวลา',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 4,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),

            // ปุ่มส่งคำขอ
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'ส่งคำขอ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
