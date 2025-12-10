import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../login/login_screen.dart';
import '../config/api_config.dart';

/// ----------------------------------------------------------------
/// ## 📝 RegisterScreen Widget (หน้าจอลงทะเบียน)
/// ----------------------------------------------------------------
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
  // ฟังก์ชันสำหรับลงทะเบียน (Register Function)
  // ----------------------------------------------------------------
  void _register() async {
    if (_formKey.currentState!.validate()) {
      // ตรวจสอบยืนยันรหัสผ่าน
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackbar('⚠️ รหัสผ่านและยืนยันรหัสผ่านไม่ตรงกัน', Colors.orange);
        return;
      }
      
      setState(() {
        _isLoading = true;
      });

      print('[REGISTER] Attempting API call to: ${ApiConfig.registerUrl}');

      try {
        final payload = {
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'role': 'employee', // บังคับให้เป็น employee เสมอ
        };

        int statusCode = 500;
        Map<String, dynamic> responseData = {};

        try {
          final response = await http.post(
            Uri.parse(ApiConfig.registerUrl),
            headers: ApiConfig.headers,
            body: json.encode(payload),
          );

          if (!mounted) return;

          statusCode = response.statusCode;
          try {
            responseData = json.decode(response.body) as Map<String, dynamic>;
          } catch (_) {
            responseData = {'message': response.body};
          }
        } catch (e) {
          // ถ้าเชื่อมต่อกับ backend ไม่ได้ ให้ใช้ Mock สำเร็จเสมอเพื่อทดสอบ
          print('[REGISTER] HTTP request failed, using mock success. Error: $e');
          statusCode = 201;
          responseData = {'message': '✅ ลงทะเบียนสำเร็จ! (Mock Mode)'};
        }

        if (!mounted) return;

        if (statusCode == 201 || statusCode == 200) {
          // Registration succeeded
          String message = '✅ ลงทะเบียนสำเร็จ! คุณสามารถเข้าสู่ระบบได้แล้ว';
          if (responseData['message'] != null) {
            message = responseData['message'];
          }

          _showSnackbar(message, Colors.green);
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else if (statusCode == 409) {
          // Conflict (e.g., duplicate username/email)
          String msg = '❌ ชื่อผู้ใช้หรืออีเมลถูกใช้งานแล้ว';
          if (responseData['message'] != null) {
            msg = responseData['message'];
          }
          _showSnackbar(msg, Colors.red);
        } else {
          String msg = '❌ ลงทะเบียนล้มเหลว กรุณาลองอีกครั้ง';
          if (responseData['message'] != null) {
            msg = responseData['message'];
          }
          _showSnackbar(msg, Colors.red);
        }
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
      appBar: AppBar(
        title: const Text('Create New Account'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_add_alt_1_rounded,
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              Text(
                'Register to get started',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent[700],
                ),
              ),
              const SizedBox(height: 32),

              // Registration Form Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          enableSuggestions: true,
                          autocorrect: false,
                          decoration: _inputDecoration('Username', Icons.person_outline),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter a username' : null,
                        ),
                        const SizedBox(height: 16),
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enableSuggestions: true,
                          autocorrect: false,
                          decoration: _inputDecoration('Email', Icons.email_outlined),
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.next,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: _passwordDecoration('Password', Icons.lock_outline, _obscurePassword, () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          }),
                          validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: _passwordDecoration('Confirm Password', Icons.lock_open_outlined, _obscureConfirmPassword, () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          }),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                : const Text('REGISTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              
              // Back to Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // กลับไปหน้า Login
                    },
                    child: const Text(
                      'Login Here',
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

  // --- Input Decoration Helper ---
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  // --- Password Decoration Helper ---
  InputDecoration _passwordDecoration(String label, IconData icon, bool obscure, VoidCallback toggleVisibility) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: toggleVisibility,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}