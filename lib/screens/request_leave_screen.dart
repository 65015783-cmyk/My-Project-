import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/leave_service.dart';
import '../models/leave_model.dart';

class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  LeaveType? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  double _totalDays = 0.0; // เปลี่ยนเป็น double เพื่อรองรับ 0.5 วัน
  final TextEditingController _reasonController = TextEditingController();
  final List<String> _documentPaths = [];
  bool _isSubmitting = false;

  // ตัวเลือกช่วงเวลาสำหรับ "ลากลับก่อน" / "ลาครึ่งวัน"
  TimeOfDay? _earlyLeaveTime; // เวลาออก เช่น 14:30
  String? _halfDaySession; // 'morning' หรือ 'afternoon' สำหรับลาครึ่งวัน
  
  // เวลาออกงานปกติ (default: 17:30)
  static const TimeOfDay _normalEndTime = TimeOfDay(hour: 17, minute: 30);

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _calculateDays() {
    if (_selectedLeaveType == LeaveType.earlyLeave) {
      // ลากลับก่อน: คำนวณตามเวลาออก
      if (_earlyLeaveTime != null) {
        // คำนวณความแตกต่างระหว่างเวลาออกปกติ (17:30) กับเวลาออกที่เลือก
        final normalMinutes = _normalEndTime.hour * 60 + _normalEndTime.minute;
        final leaveMinutes = _earlyLeaveTime!.hour * 60 + _earlyLeaveTime!.minute;
        final diffMinutes = normalMinutes - leaveMinutes;
        
        // ≤ 2 ชม. (120 นาที) → 0 วัน, > 2 ชม. → 0.5 วัน
        setState(() {
          _totalDays = diffMinutes > 120 ? 0.5 : 0.0;
        });
      } else {
        setState(() {
          _totalDays = 0.0;
        });
      }
    } else if (_selectedLeaveType == LeaveType.halfDayLeave) {
      // ลาครึ่งวัน → 0.5 วันเสมอ
      setState(() {
        _totalDays = 0.5;
      });
    } else {
      // สำหรับลาป่วยและลากิจ = คำนวณตามวันที่ (เต็มวัน)
      if (_startDate != null && _endDate != null) {
        setState(() {
          _totalDays = _calculateBusinessDays(_startDate!, _endDate!).toDouble();
        });
      }
    }
  }

  // สร้างรายการเวลาสำหรับ dropdown (12:00 - 17:30 ทุก 30 นาที)
  List<TimeOfDay> _getTimeOptions() {
    final List<TimeOfDay> times = [];
    for (int hour = 12; hour <= 17; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        if (hour == 17 && minute > 30) break; // หยุดที่ 17:30
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


  int _calculateBusinessDays(DateTime start, DateTime end) {
    int days = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      // Exclude weekends: Saturday (6) and Sunday (7)
      if (current.weekday != DateTime.saturday && 
          current.weekday != DateTime.sunday) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  Widget _buildTimeSelector() {
    final timeOptions = _getTimeOptions();
    final selectedTimeIndex = _earlyLeaveTime != null
        ? timeOptions.indexWhere((time) =>
            time.hour == _earlyLeaveTime!.hour &&
            time.minute == _earlyLeaveTime!.minute)
        : -1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeOfDay>(
          value: _earlyLeaveTime,
          isExpanded: true,
          hint: Row(
            children: [
              const Icon(Icons.access_time, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'เลือกเวลาออก',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
          items: timeOptions.map((TimeOfDay time) {
            return DropdownMenuItem<TimeOfDay>(
              value: time,
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimeForDropdown(time),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (TimeOfDay? newTime) {
            if (newTime != null) {
              setState(() {
                _earlyLeaveTime = newTime;
                _calculateDays(); // คำนวณใหม่เมื่อเปลี่ยนเวลา
              });
            }
          },
        ),
      ),
    );
  }


  Widget _buildHalfDayChip({
    required String label,
    required String value,
  }) {
    final bool selected = _halfDaySession == value;
    return InkWell(
      onTap: () {
        setState(() {
          _halfDaySession = value;
          _calculateDays(); // คำนวณใหม่เมื่อเปลี่ยนครึ่งวัน
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.purple[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.purple : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.purple[800] : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('th', 'TH'),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // สำหรับลากลับก่อนและลาครึ่งวัน ตั้ง endDate = startDate
        if (_selectedLeaveType == LeaveType.earlyLeave || 
            _selectedLeaveType == LeaveType.halfDayLeave) {
          _endDate = picked;
        } else {
          // สำหรับลาป่วยและลากิจ ตรวจสอบว่า endDate ต้องไม่น้อยกว่า startDate
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        }
        _calculateDays();
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกวันที่เริ่มต้นก่อน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('th', 'TH'),
    );
    
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _calculateDays();
      });
    }
  }

  Future<void> _addDocument() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'เพิ่มเอกสาร',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'ถ่ายรูป',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'เลือกรูป',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (image != null) {
        setState(() {
          _documentPaths.add(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _documentPaths.removeAt(index);
    });
  }

  String _formatThaiDate(DateTime date) {
    final thaiDays = [
      'วันอาทิตย์',
      'วันจันทร์',
      'วันอังคาร',
      'วันพุธ',
      'วันพฤหัสบดี',
      'วันศุกร์',
      'วันเสาร์',
    ];
    
    final thaiMonths = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];

    final weekdayIndex = date.weekday == 7 ? 0 : date.weekday;
    final weekday = thaiDays[weekdayIndex];
    final day = date.day;
    final month = thaiMonths[date.month - 1];
    final year = date.year + 543;

    return '$weekday $day $month $year';
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกประเภทการลา'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // สำหรับลากลับก่อนและลาครึ่งวัน ต้องมีแค่วันที่เดียว
    if (_selectedLeaveType == LeaveType.earlyLeave || 
        _selectedLeaveType == LeaveType.halfDayLeave) {
      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเลือกวันที่'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      // ตั้ง endDate = startDate สำหรับลากลับก่อนและลาครึ่งวัน
      _endDate = _startDate;
    } else {
      // สำหรับลาป่วยและลากิจ ต้องมีทั้งวันที่เริ่มต้นและสิ้นสุด
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเลือกวันที่เริ่มต้นและสิ้นสุด'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Check if documents are required
    if (_selectedLeaveType == LeaveType.sickLeave && 
        _totalDays > 3 && 
        _documentPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลาป่วยมากกว่า 3 วัน ต้องแนบใบรับรองแพทย์'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // จำกัดสิทธิ์ "ลากลับก่อน" ไม่เกิน 10 ครั้งต่อปี (นับเฉพาะใบที่ไม่ถูกปฏิเสธ)
    if (_selectedLeaveType == LeaveType.earlyLeave) {
      final leaveService = Provider.of<LeaveService>(context, listen: false);
      final currentYear = DateTime.now().year;
      final usedEarlyLeave = leaveService.leaveRequests.where((leave) =>
          leave.type == LeaveType.earlyLeave &&
          leave.startDate.year == currentYear &&
          leave.status != LeaveStatus.rejected).length;

      if (usedEarlyLeave >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('คุณใช้สิทธิ์ลากลับก่อนครบ 10 ครั้งแล้วในปีนี้'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // ตรวจสอบช่วงเวลาสำหรับลากลับก่อน / ลาครึ่งวัน
    if (_selectedLeaveType == LeaveType.earlyLeave) {
      if (_earlyLeaveTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเลือกเวลาออก'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else if (_selectedLeaveType == LeaveType.halfDayLeave) {
      if (_halfDaySession == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเลือกครึ่งวันเช้า หรือ ครึ่งวันบ่าย'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final leaveService = Provider.of<LeaveService>(context, listen: false);

      // แนบรายละเอียดช่วงเวลาเข้าไปในเหตุผลการลา (ไม่ต้องแก้ backend)
      String finalReason = _reasonController.text;
      if (_selectedLeaveType == LeaveType.earlyLeave) {
        if (_earlyLeaveTime != null) {
          final buffer = StringBuffer(finalReason.trim());
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write('ช่วงเวลา: ออกเวลา ${_earlyLeaveTime!.format(context)}');
          finalReason = buffer.toString();
        }
      } else if (_selectedLeaveType == LeaveType.halfDayLeave) {
        if (_halfDaySession != null) {
          final buffer = StringBuffer(finalReason.trim());
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write('ช่วงเวลา: ');
          if (_halfDaySession == 'morning') {
            buffer.write('ครึ่งวันเช้า');
          } else if (_halfDaySession == 'afternoon') {
            buffer.write('ครึ่งวันบ่าย');
          }
          finalReason = buffer.toString();
        }
      }

      await leaveService.submitLeaveRequest(
        type: _selectedLeaveType!,
        startDate: _startDate!,
        endDate: _endDate!,
        reason: finalReason,
        documentPaths: _documentPaths,
        totalDays: _totalDays, // ส่ง totalDays ที่คำนวณแล้ว
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งคำขอลางานสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveService = Provider.of<LeaveService>(context);
    final leaveBalance = leaveService.leaveBalance;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('ขอลางาน'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leave Balance Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'ยอดวันลาคงเหลือ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // แถวแรก: ลาป่วย และ ลากิจ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBalanceItem(
                          'ลาป่วย',
                          '${leaveBalance.sickLeaveRemaining} วัน',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _buildBalanceItem(
                          'ลากิจ',
                          '${leaveBalance.personalLeaveRemaining} วัน',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Leave Type Selection
              const Text(
                'ประเภทการลา',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildLeaveTypeCard(
                      LeaveType.sickLeave,
                      Colors.red,
                      Icons.medical_services,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLeaveTypeCard(
                      LeaveType.personalLeave,
                      Colors.blue,
                      Icons.person,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildLeaveTypeCard(
                      LeaveType.earlyLeave,
                      Colors.orange,
                      Icons.logout,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLeaveTypeCard(
                      LeaveType.halfDayLeave,
                      Colors.purple,
                      Icons.timelapse,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date Selection
              // สำหรับลากลับก่อนและลาครึ่งวัน แสดงแค่วันที่เดียว
              if (_selectedLeaveType == LeaveType.earlyLeave || 
                  _selectedLeaveType == LeaveType.halfDayLeave)
                _buildDateSelector(
                  label: 'วันที่',
                  date: _startDate,
                  onTap: _selectStartDate,
                  icon: Icons.calendar_today,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildDateSelector(
                        label: 'วันที่เริ่มต้น',
                        date: _startDate,
                        onTap: _selectStartDate,
                        icon: Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateSelector(
                        label: 'วันสิ้นสุด',
                        date: _endDate,
                        onTap: _selectEndDate,
                        icon: Icons.event,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Time / Session for Early Leave & Half Day
              if (_selectedLeaveType == LeaveType.earlyLeave ||
                  _selectedLeaveType == LeaveType.halfDayLeave) ...[
                const Text(
                  'ช่วงเวลา',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (_selectedLeaveType == LeaveType.earlyLeave) ...[
                  _buildTimeSelector(),
                  const SizedBox(height: 16),
                ] else if (_selectedLeaveType == LeaveType.halfDayLeave) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildHalfDayChip(
                          label: 'ครึ่งวันเช้า',
                          value: 'morning',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHalfDayChip(
                          label: 'ครึ่งวันบ่าย',
                          value: 'afternoon',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              
              // Total Days
              if (_totalDays > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        _totalDays == 0.5 
                          ? 'จำนวนวันลา: ครึ่งวัน (0.5 วัน)'
                          : _totalDays == 0
                            ? 'จำนวนวันลา: 0 วัน (ไม่นับวันลา)'
                            : 'จำนวนวันลา: ${_totalDays.toStringAsFixed(_totalDays.truncateToDouble() == _totalDays ? 0 : 1)} วัน',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Reason
              const Text(
                'เหตุผลการลา',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  enableSuggestions: true,
                  autocorrect: true,
                  // ไม่จำกัดการพิมพ์ - รองรับทั้งไทยและอังกฤษ
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกเหตุผลการลา';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'กรุณากรอกเหตุผลการลา...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Documents Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'เอกสารประกอบ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addDocument,
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มเอกสาร'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Document Requirements Info
              if (_selectedLeaveType != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedLeaveType == LeaveType.sickLeave
                              ? 'ลาป่วย: ต้องแนบใบรับรองแพทย์ (ถ้าลามากกว่า 3 วัน)'
                              : _selectedLeaveType == LeaveType.personalLeave
                                  ? 'ลากิจส่วนตัว: สามารถแนบเอกสารประกอบได้ (ถ้ามี)'
                                  : _selectedLeaveType == LeaveType.earlyLeave
                                      ? 'ลากลับก่อน: จำกัดสิทธิ์ไม่เกิน 10 ครั้งต่อปี'
                                      : 'ลาครึ่งวัน: ใช้สำหรับการลาเป็นช่วงเวลาสั้น ๆ ในวันทำงาน',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Document Grid
              if (_documentPaths.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _documentPaths.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_documentPaths[index]),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeDocument(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              
              if (_documentPaths.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined, 
                           size: 48, 
                           color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'ยังไม่มีเอกสาร',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitLeaveRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'ส่งคำขอลางาน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveTypeCard(LeaveType type, Color color, IconData icon) {
    final isSelected = _selectedLeaveType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLeaveType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              type.thaiLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date != null ? _formatThaiDate(date) : 'เลือกวันที่',
              style: TextStyle(
                fontSize: 14,
                fontWeight: date != null ? FontWeight.bold : FontWeight.normal,
                color: date != null ? Colors.black87 : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

