import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../main.dart';
import '../config/api_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Helper function เพื่อลบข้อมูล authentication
  Future<void> _clearAuthData(SharedPreferences prefs) async {
    await prefs.remove('auth_token');
    await prefs.remove('role');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('email');
  }

  @override
  void initState() {
    super.initState();
    // แสดงโลโก้สั้น ๆ ก่อนเข้าแอปหลัก
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      print('[SPLASH] Checking auth - token: ${token != null ? "exists" : "null"}');

      // ถ้าไม่มี token ให้ไปหน้า login
      if (token == null || token.isEmpty) {
        print('[SPLASH] No token, redirecting to login');
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // ตรวจสอบว่า token ยัง valid หรือไม่โดยเรียก profile API
      // ใช้ timeout เพื่อป้องกันการค้างนานเกินไป
      try {
        final response = await http.get(
          Uri.parse(ApiConfig.profileUrl),
          headers: ApiConfig.headersWithAuth(token),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Token validation timeout');
          },
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          // Token ยัง valid - redirect ตาม role
          final role = prefs.getString('role')?.trim().toLowerCase() ?? 'employee';
          print('[SPLASH] Token valid, redirecting based on role: "$role"');
          
          if (role == 'admin') {
            print('[SPLASH] Redirecting to Admin Dashboard');
            Navigator.of(context).pushReplacementNamed('/admin');
          } else {
            print('[SPLASH] Redirecting to Home');
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          // Token ไม่ valid หรือ expired - ลบ token และไปหน้า login
          print('[SPLASH] Token invalid or expired (status: ${response.statusCode}), redirecting to login');
          await _clearAuthData(prefs);
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        }
      } on TimeoutException {
        // Timeout - ลบ token และไปหน้า login (เพื่อความปลอดภัย)
        print('[SPLASH] Token validation timeout, redirecting to login');
        final prefs = await SharedPreferences.getInstance();
        await _clearAuthData(prefs);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        // Network error หรือ error อื่นๆ - ลบ token และไปหน้า login
        print('[SPLASH] Error validating token: $e, redirecting to login');
        await _clearAuthData(prefs);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      print('[SPLASH] Error: $e');
      // ถ้าเกิด error ให้ไปหน้า login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _HRLogo(),
      ),
    );
  }
}

class _HRLogo extends StatelessWidget {
  const _HRLogo();

  @override
  Widget build(BuildContext context) {
    const logoColor = Color(0xFF424242);

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // วงกลมรอบนอก
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: logoColor,
                width: 10,
              ),
            ),
          ),
          // ตัวอักษร HR
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                'H',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: logoColor,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(width: 4),
              Text(
                'R',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: logoColor,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          // ขีดเฉียงของตัว R ออกมานอกวงกลม
          Positioned(
            right: 38,
            bottom: 26,
            child: Transform.rotate(
              angle: 0.9, // ประมาณ 50 องศา
              alignment: Alignment.topLeft,
              child: Container(
                width: 12,
                height: 80,
                decoration: BoxDecoration(
                  color: logoColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


