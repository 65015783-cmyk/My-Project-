import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/overtime_model.dart';
import '../config/api_config.dart';

class OvertimeService extends ChangeNotifier {
  List<OvertimeRequest> _myRequests = [];
  List<OvertimeRequest> _allRequests = [];
  List<OvertimeRequest> _pendingRequests = [];
  OvertimeSummary? _summary;
  bool _isLoading = false;

  List<OvertimeRequest> get myRequests => List.unmodifiable(_myRequests);
  List<OvertimeRequest> get allRequests => List.unmodifiable(_allRequests);
  List<OvertimeRequest> get pendingRequests => List.unmodifiable(_pendingRequests);
  OvertimeSummary? get summary => _summary;
  bool get isLoading => _isLoading;

  // โหลดคำขอ OT ของตัวเอง
  Future<void> loadMyRequests({String? status, int? month, int? year}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      String url = ApiConfig.overtimeMyRequestsUrl;
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _myRequests = data.map((json) => OvertimeRequest.fromJson(json)).toList();
      } else {
        _myRequests = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading my OT requests: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // โหลดคำขอ OT ทั้งหมด (สำหรับ Admin/Manager)
  Future<void> loadAllRequests({String? status, String? department, int? month, int? year}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      String url = ApiConfig.overtimeAllUrl;
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (department != null) queryParams['department'] = department;
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _allRequests = data.map((json) => OvertimeRequest.fromJson(json)).toList();
      } else {
        _allRequests = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading all OT requests: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // โหลดคำขอ OT ที่รออนุมัติ (สำหรับ Manager)
  Future<void> loadPendingRequests() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.overtimePendingUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _pendingRequests = data.map((json) => OvertimeRequest.fromJson(json)).toList();
      } else {
        _pendingRequests = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading pending OT requests: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // สร้างคำขอ OT ใหม่
  Future<Map<String, dynamic>> createRequest({
    required DateTime date,
    required String startTime,
    required String endTime,
    String? reason,
    String? evidenceImagePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return {'success': false, 'message': 'กรุณาเข้าสู่ระบบก่อน'};
      }

      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // ถ้ามีรูปภาพ ให้ใช้ multipart/form-data
      if (evidenceImagePath != null && evidenceImagePath.isNotEmpty) {
        try {
          final file = File(evidenceImagePath);
          if (!await file.exists()) {
            return {'success': false, 'message': 'ไม่พบไฟล์รูปภาพ'};
          }

          final request = http.MultipartRequest(
            'POST',
            Uri.parse(ApiConfig.overtimeRequestUrl),
          );

          // เพิ่ม headers
          request.headers.addAll(ApiConfig.headersWithAuth(token));
          request.headers.remove('Content-Type'); // ให้ multipart ตั้งค่าเอง

          // เพิ่ม fields
          request.fields['date'] = dateStr;
          request.fields['start_time'] = startTime;
          request.fields['end_time'] = endTime;
          request.fields['reason'] = reason ?? '';

          // ตรวจสอบชนิดไฟล์จากนามสกุล และกำหนด content-type ให้ถูกต้อง
          final fileName = evidenceImagePath.split('/').last;
          final ext = fileName.split('.').last.toLowerCase();
          MediaType? contentType;
          switch (ext) {
            case 'jpg':
            case 'jpeg':
              contentType = MediaType('image', 'jpeg');
              break;
            case 'png':
              contentType = MediaType('image', 'png');
              break;
            case 'gif':
              contentType = MediaType('image', 'gif');
              break;
            case 'webp':
              contentType = MediaType('image', 'webp');
              break;
            default:
              return {
                'success': false,
                'message':
                    'กรุณาอัปโหลดไฟล์รูปภาพเท่านั้น (jpg, png, gif, webp)',
              };
          }

          // เพิ่มไฟล์รูปภาพ
          final fileStream = http.ByteStream(file.openRead());
          final fileLength = await file.length();
          final multipartFile = http.MultipartFile(
            'evidence_image',
            fileStream,
            fileLength,
            filename: fileName,
            contentType: contentType,
          );
          request.files.add(multipartFile);

          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);
          // log เพื่อตรวจสอบปัญหา
          debugPrint('[OT] createRequest (multipart) status=${response.statusCode} body=${response.body}');
          final data = json.decode(response.body);

          if (response.statusCode == 200 || response.statusCode == 201) {
            // รีโหลดข้อมูลทันที
            await loadMyRequests();
            await loadSummary();
            return {'success': true, 'message': data['message'] ?? 'ส่งคำขอ OT สำเร็จ'};
          } else {
            return {'success': false, 'message': data['message'] ?? 'เกิดข้อผิดพลาด'};
          }
        } catch (e) {
          print('Error uploading OT request with image: $e');
          return {'success': false, 'message': 'เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ: ${e.toString()}'};
        }
      } else {
        // ไม่มีรูปภาพ ใช้ JSON แบบเดิม
        final response = await http.post(
          Uri.parse(ApiConfig.overtimeRequestUrl),
          headers: ApiConfig.headersWithAuth(token),
          body: json.encode({
            'date': dateStr,
            'start_time': startTime,
            'end_time': endTime,
            'reason': reason ?? '',
          }),
        );
        // log เพื่อตรวจสอบปัญหา
        debugPrint('[OT] createRequest (json) status=${response.statusCode} body=${response.body}');

        final data = json.decode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          // รีโหลดข้อมูลทันที
          await loadMyRequests();
          await loadSummary();
          return {'success': true, 'message': data['message'] ?? 'ส่งคำขอ OT สำเร็จ'};
        } else {
          return {'success': false, 'message': data['message'] ?? 'เกิดข้อผิดพลาด'};
        }
      }
    } catch (e) {
      print('Error creating OT request: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: ${e.toString()}'};
    }
  }

  // อนุมัติ/ปฏิเสธคำขอ OT
  Future<Map<String, dynamic>> approveRequest({
    required int requestId,
    required String action, // 'approve' or 'reject'
    String? rejectionReason,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return {'success': false, 'message': 'กรุณาเข้าสู่ระบบก่อน'};
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.overtimeApproveUrl}/$requestId'),
        headers: ApiConfig.headersWithAuth(token),
        body: json.encode({
          'action': action,
          'rejection_reason': rejectionReason,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // รีโหลดข้อมูล
        await loadPendingRequests();
        await loadAllRequests();
        return {'success': true, 'message': data['message'] ?? 'ดำเนินการสำเร็จ'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'เกิดข้อผิดพลาด'};
      }
    } catch (e) {
      print('Error approving OT request: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: ${e.toString()}'};
    }
  }

  // โหลดสรุป OT รายเดือน
  Future<void> loadSummary({int? month, int? year}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return;
      }

      String url = ApiConfig.overtimeSummaryUrl;
      final queryParams = <String, String>{};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _summary = OvertimeSummary.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading OT summary: $e');
    }
  }

  // คำนวณชั่วโมง OT จากเวลาเริ่ม-สิ้นสุด
  static double calculateHours(String startTime, String endTime) {
    try {
      final start = startTime.split(':');
      final end = endTime.split(':');
      
      final startHour = int.parse(start[0]);
      final startMinute = int.parse(start[1]);
      final endHour = int.parse(end[0]);
      final endMinute = int.parse(end[1]);

      final startTotalMinutes = startHour * 60 + startMinute;
      final endTotalMinutes = endHour * 60 + endMinute;

      if (endTotalMinutes <= startTotalMinutes) {
        return 0.0;
      }

      final diffMinutes = endTotalMinutes - startTotalMinutes;
      return double.parse((diffMinutes / 60).toStringAsFixed(2));
    } catch (e) {
      return 0.0;
    }
  }
}
