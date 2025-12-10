import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../register/register.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';


/// ----------------------------------------------------------------
/// ## 🔐 LoginScreen Widget
/// ----------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller สำหรับรับ Username/Email และ Password
  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // ไม่ต้องตรวจสอบ token ใน login screen
    // ให้ SplashScreen เป็นผู้จัดการ authentication และ redirect
    // หน้า login นี้ควรแสดงให้ user login เท่านั้น
  }

  // Helper function สำหรับแสดงข้อความแจ้งเตือน (SnackBar)
  void _showSnackbar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ----------------------------------------------------------------
  // ฟังก์ชันสำหรับเข้าสู่ระบบ (Login Function)
  // ----------------------------------------------------------------
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // ⚠️ **สำคัญ:** ใช้ IP 10.0.2.2 สำหรับ Android Emulator เพื่อเชื่อมต่อกับ localhost
      // final String apiUrl = 'http://10.0.2.2:3000/api/login'; // ใช้เมื่อเชื่อมต่อจริง

      try {
        // พยายามเรียก API จริงก่อน (สำหรับ Android emulator ใช้ 10.0.2.2)
        await Future.delayed(const Duration(seconds: 1)); // เล็กน้อยเพื่อ UI feedback

        final String loginId = _loginIdController.text.trim().toLowerCase();
        final String password = _passwordController.text;

        Map<String, dynamic> data = {};
        int statusCode = 401;

        print('[LOGIN] Attempting API call to: ${ApiConfig.loginUrl}');

        try {
          final response = await http.post(
            Uri.parse(ApiConfig.loginUrl),
            headers: ApiConfig.headers,
            body: json.encode({
              'login_id': loginId,
              'password': password,
            }),
          );

          if (!mounted) return;

          statusCode = response.statusCode;
          print('[LOGIN] Response status: $statusCode, body: ${response.body}');
          try {
            data = json.decode(response.body) as Map<String, dynamic>;
          } catch (_) {
            data = {'message': response.body};
          }
        } catch (e) {
          // ไม่สามารถเชื่อมต่อ Backend ได้
          print('[LOGIN] HTTP request failed. Error: $e');
          
          if (!mounted) return;
          
          _showSnackbar('🌐 ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ โปรดตรวจสอบการเชื่อมต่อ', Colors.red);
          
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (!mounted) return;

        if (statusCode == 200) {
          // ✅ เข้าสู่ระบบสำเร็จ
          String username = data['username'] ?? 'User';
          // Normalize role (trim + lowercase) ทันที
          String role = (data['role'] ?? 'employee').toString().trim().toLowerCase();
          print('[LOGIN] Role received: "$role" (type: ${role.runtimeType})');
          // พยายามอ่าน user_id หาก backend ส่งมา
          int? userId;
          if (data['user_id'] != null) {
            try {
              userId = (data['user_id'] is int) ? data['user_id'] as int : int.parse(data['user_id'].toString());
            } catch (_) {
              userId = null;
            }
          } else if (data['user'] != null) {
            try {
              final u = data['user'];
              if (u is Map && (u['user_id'] != null || u['id'] != null)) {
                final val = u['user_id'] ?? u['id'];
                userId = (val is int) ? val : int.tryParse(val.toString());
              }
            } catch (_) {}
          }

          // เก็บข้อมูลผู้ใช้และ token ลง shared preferences
          try {
            final prefs = await SharedPreferences.getInstance();
            if (userId != null) prefs.setInt('user_id', userId);
            await prefs.setString('username', username);
            // เก็บ role ที่ normalize แล้ว
            await prefs.setString('role', role);
            print('[LOGIN] Saved role to SharedPreferences: "$role"');
            
            // เก็บ email ถ้ามี
            if (data['user'] != null && data['user'] is Map) {
              final userData = data['user'] as Map<String, dynamic>;
              if (userData['email'] != null) {
                await prefs.setString('email', userData['email'].toString());
              }
            } else if (data['email'] != null) {
              await prefs.setString('email', data['email'].toString());
            }
            
            // เก็บ JWT token สำหรับใช้กับ API ที่ต้อง authentication
            if (data['token'] != null) {
              await prefs.setString('auth_token', data['token']);
              print('[LOGIN] Token saved: ${data['token']}');
            }
          } catch (e) {
            print('Failed to save prefs: $e');
          }

          // อัปเดต AuthService ด้วยข้อมูลผู้ใช้
          try {
            final authService = Provider.of<AuthService>(context, listen: false);
            await authService.setUserFromLogin(data);
          } catch (e) {
            print('Error updating AuthService: $e');
          }

          _showSnackbar('✅ เข้าสู่ระบบสำเร็จ! ยินดีต้อนรับคุณ $username ($role)', Colors.green);
          
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (!mounted) return;

          // ----------------------------------------------------------------
          // **✅ การนำทางตาม Role**
          // ----------------------------------------------------------------
          print('[LOGIN] Navigating based on role: "$role"');
          if (role == 'admin') {
            // Admin ไปหน้า Admin Dashboard
            print('[LOGIN] Redirecting to Admin Dashboard');
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            // Employee ไปหน้า Home
            print('[LOGIN] Redirecting to Home');
            Navigator.pushReplacementNamed(context, '/home');
          }
          // ----------------------------------------------------------------
          
        } else if (statusCode == 401 || statusCode == 400) {
          _showSnackbar('⚠️ ล้มเหลว: ${data['message']}', Colors.orange);
        } else {
          _showSnackbar('❌ เกิดข้อผิดพลาด: ${data['message'] ?? 'โปรดลองอีกครั้ง'}', Colors.red);
        }

      } catch (e) {
        print('Error connecting to server: $e');
        _showSnackbar('🌐 ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ โปรดตรวจสอบการเชื่อมต่อ', Colors.red);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 80,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue to HR App',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Login Form Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _loginIdController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          enableSuggestions: true,
                          autocorrect: false,
                          // ไม่จำกัดการพิมพ์ - รองรับทั้งไทยและอังกฤษ
                          decoration: InputDecoration(
                            labelText: 'Username / Email',
                            hintText: 'Enter username (e.g., admin or employee)', // คำแนะนำ
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter username or email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter password (use 1234)', // คำแนะนำ
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Register Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      // ✅ แก้ไข: นำทางไปยัง RegisterScreen โดยใช้ MaterialPageRoute
                      Navigator.push( 
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Register Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}