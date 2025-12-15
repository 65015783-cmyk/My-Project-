import 'package:flutter/material.dart';
import 'dart:io';
import '../models/attendance_model.dart';

class DailyWorkCard extends StatefulWidget {
  final AttendanceModel? attendance;

  const DailyWorkCard({
    super.key,
    required this.attendance,
  });

  @override
  State<DailyWorkCard> createState() => _DailyWorkCardState();
}

class _DailyWorkCardState extends State<DailyWorkCard> {
  bool _imageExists = false;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _checkImageExists();
  }

  @override
  void didUpdateWidget(DailyWorkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attendance?.checkInImagePath != widget.attendance?.checkInImagePath) {
      _checkImageExists();
    }
  }

  Future<void> _checkImageExists() async {
    final attendance = widget.attendance ?? _getDefaultAttendance();
    final imagePath = attendance.checkInImagePath;
    
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        final exists = await file.exists();
        if (mounted) {
          setState(() {
            _imageExists = exists;
            _imagePath = exists ? imagePath : null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _imageExists = false;
            _imagePath = null;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _imageExists = false;
          _imagePath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendance = widget.attendance ?? _getDefaultAttendance();
    
    print('[DailyWorkCard] Building - checkInTime: ${attendance.checkInTime}, formatted: ${attendance.checkInTimeFormatted}');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  attendance.dateFormatted,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 16),
          // Work Schedule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 4,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: Color(0xFF1976D2),
                  ),
                  const Text(
                    'วันทำงาน : ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  Text(
                    attendance.workSchedule.formatted,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Check-in and Check-out times
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTimeColumn(
                    'เวลาเข้างาน',
                    attendance.checkInTimeFormatted,
                    Icons.login,
                  ),
                ),
                Container(
                  width: 2,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFBBDEFB),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimeColumn(
                    'เวลาออกงาน',
                    attendance.checkOutTimeFormatted,
                    Icons.logout,
                  ),
                ),
              ],
            ),
          ),
          // Check-in Image
          if (_imageExists && _imagePath != null) ...[
            const SizedBox(height: 16),
            const Divider(
              color: Color(0xFFBBDEFB),
              thickness: 1,
            ),
            const SizedBox(height: 12),
            const Text(
              'หลักฐานการเข้างาน',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_imagePath!),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // ถ้าโหลดรูปไม่สำเร็จ ให้แสดง placeholder
                  return Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF1976D2),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  AttendanceModel _getDefaultAttendance() {
    return AttendanceModel(
      id: 'default',
      date: DateTime.now(),
      workSchedule: WorkSchedule.defaultSchedule(),
    );
  }
}

