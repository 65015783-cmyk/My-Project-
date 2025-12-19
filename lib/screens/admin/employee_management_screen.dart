import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  // ดึง headers พร้อม authentication token
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/employees'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _employees = List<Map<String, dynamic>>.from(data['employees'] ?? []);
        });
      }
    } catch (e) {
      // Mock data ถ้าเชื่อมต่อไม่ได้
      setState(() {
        _employees = [
          {
            'user_id': 1,
            'username': 'admin',
            'email': 'admin@humans.com',
            'role': 'admin',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'user_id': 2,
            'username': 'montita',
            'email': 'montita@example.com',
            'role': 'employee',
            'created_at': DateTime.now().toIso8601String(),
          },
        ];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEmployee(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ที่จะลบพนักงานคนนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final headers = await _getAuthHeaders();
        await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/api/employees/$userId'),
          headers: headers,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบพนักงานสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          _loadEmployees();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เกิดข้อผิดพลาดในการลบ'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEmployeeDialog({Map<String, dynamic>? employee}) {
    final isEdit = employee != null;
    final usernameController = TextEditingController(text: employee?['username'] ?? '');
    final firstNameController = TextEditingController(text: employee?['first_name'] ?? '');
    final lastNameController = TextEditingController(text: employee?['last_name'] ?? '');
    final emailController = TextEditingController(text: employee?['email'] ?? '');
    final passwordController = TextEditingController();
    String selectedRole = employee?['role'] ?? 'employee';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'แก้ไขพนักงาน' : 'เพิ่มพนักงานใหม่'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // First name
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ (First name)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Last name
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'นามสกุล (Last name)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Username (สำหรับใช้ login)
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username (สำหรับเข้าสู่ระบบ)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'รหัสผ่านใหม่ (เว้นว่างถ้าไม่เปลี่ยน)' : 'รหัสผ่าน',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'employee', child: Text('Employee')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (firstNameController.text.isEmpty ||
                    lastNameController.text.isEmpty ||
                    usernameController.text.isEmpty || 
                    emailController.text.isEmpty ||
                    (!isEdit && passwordController.text.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                
                if (isEdit) {
                  await _updateEmployee(
                    employee['user_id'],
                    usernameController.text,
                    emailController.text,
                    passwordController.text.isEmpty ? null : passwordController.text,
                    selectedRole,
                    firstNameController.text,
                    lastNameController.text,
                  );
                } else {
                  await _createEmployee(
                    usernameController.text,
                    emailController.text,
                    passwordController.text,
                    selectedRole,
                    firstNameController.text,
                    lastNameController.text,
                  );
                }
              },
              child: Text(isEdit ? 'บันทึก' : 'เพิ่ม'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createEmployee(
      String username,
      String email,
      String password,
      String role,
      String firstName,
      String lastName) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/employees'),
        headers: headers,
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );

      if (mounted) {
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เพิ่มพนักงานสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          _loadEmployees();
        } else {
          try {
            final errorData = json.decode(response.body) as Map<String, dynamic>?;
            final errorMessage = errorData?['message'] ?? 'เกิดข้อผิดพลาดในการเพิ่มพนักงาน';
            final hint = errorData?['hint'];
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(errorMessage),
                    if (hint != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        hint,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 8),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาด: ${response.statusCode}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถเชื่อมต่อ Backend ได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateEmployee(
      int userId,
      String username,
      String email,
      String? password,
      String role,
      String firstName,
      String lastName) async {
    try {
      final body = {
        'username': username,
        'email': email,
        'role': role,
        'first_name': firstName,
        'last_name': lastName,
      };
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/employees/$userId'),
        headers: headers,
        body: json.encode(body),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('แก้ไขพนักงานสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          _loadEmployees();
        } else {
          try {
            final errorData = json.decode(response.body) as Map<String, dynamic>?;
            final errorMessage = errorData?['message'] ?? 'เกิดข้อผิดพลาดในการแก้ไข';
            final hint = errorData?['hint'];
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(errorMessage),
                    if (hint != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        hint,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 8),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาด: ${response.statusCode}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถเชื่อมต่อ Backend ได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'จัดการพนักงาน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadEmployees,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _employees.length,
                  itemBuilder: (context, index) {
                    final employee = _employees[index];
                    return _buildEmployeeCard(employee);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEmployeeDialog(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มพนักงาน'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีข้อมูลพนักงาน',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'กดปุ่ม + เพื่อเพิ่มพนักงานใหม่',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final role = employee['role'] ?? 'employee';
    final isAdmin = role == 'admin';
    final isManager = role == 'manager';
    
    Color getRoleColor() {
      if (isAdmin) return const Color(0xFFFF9800);
      if (isManager) return const Color(0xFFFF6B00);
      return const Color(0xFF4CAF50);
    }
    
    String getRoleLabel() {
      if (isAdmin) return 'Admin';
      if (isManager) return 'Manager';
      return 'Employee';
    }
    
    IconData getRoleIcon() {
      if (isAdmin) return Icons.admin_panel_settings;
      if (isManager) return Icons.verified_user;
      return Icons.person;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: getRoleColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            getRoleIcon(),
            color: getRoleColor(),
          ),
        ),
        title: Text(
          employee['username'] ?? 'N/A',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              employee['email'] ?? 'N/A',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: getRoleColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                getRoleLabel(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: getRoleColor(),
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
              onPressed: () => _showEmployeeDialog(employee: employee),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteEmployee(employee['user_id']),
            ),
          ],
        ),
      ),
    );
  }
}

