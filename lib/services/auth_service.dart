import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../config/api_config.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    // Load user from SharedPreferences on initialization
    _loadUserFromPrefs();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final username = prefs.getString('username');
      final token = prefs.getString('auth_token');

      if (userId != null && username != null && token != null) {
        // Try to fetch fresh profile data from backend
        await fetchUserProfile();
      }
    } catch (e) {
      print('Error loading user from prefs: $e');
    }
  }

  // Fetch user profile from backend API
  Future<void> fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getInt('user_id');
      final username = prefs.getString('username');

      if (token == null || userId == null) {
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.profileUrl),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>?;

        if (userData != null) {
          // Ensure role is included from SharedPreferences if not in profile response
          final savedRole = prefs.getString('role')?.trim().toLowerCase();
          if (savedRole != null && (userData['role'] == null || userData['role'].toString().trim().isEmpty)) {
            userData['role'] = savedRole;
          }
          // Map backend data to UserModel
          _currentUser = UserModel.fromJson(userData);
          notifyListeners();
        }
      } else if (response.statusCode == 404) {
        // Profile not found (e.g., admin user without employee record)
        // Use basic info from login and preserve role from SharedPreferences
        final email = prefs.getString('email') ?? '';
        final role = prefs.getString('role')?.trim().toLowerCase();
        _currentUser = UserModel(
          id: userId.toString(),
          firstName: username ?? 'User',
          lastName: '',
          email: email,
          position: role == 'admin' ? 'Administrator' : 'Employee',
          isManager: role == 'manager',
          role: role,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      // Fallback to basic info from SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');
        final username = prefs.getString('username');
        final email = prefs.getString('email') ?? '';
        final role = prefs.getString('role')?.trim().toLowerCase();

        if (userId != null && username != null) {
          _currentUser = UserModel(
            id: userId.toString(),
            firstName: username,
            lastName: '',
            email: email,
            position: role == 'admin' ? 'Administrator' : 'Employee',
            isManager: role == 'manager',
            role: role,
          );
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  // Set user from login response
  Future<void> setUserFromLogin(Map<String, dynamic> loginData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save basic info to SharedPreferences
      if (loginData['user_id'] != null) {
        await prefs.setInt('user_id', loginData['user_id'] as int);
      }
      if (loginData['username'] != null) {
        await prefs.setString('username', loginData['username'] as String);
      }
      if (loginData['token'] != null) {
        await prefs.setString('auth_token', loginData['token'] as String);
      }

      // Try to get user data from login response
      final userData = loginData['user'] as Map<String, dynamic>?;
      
      if (userData != null) {
        // Use data from login response
        // Ensure role is included from login response
        final role = loginData['role']?.toString().trim().toLowerCase();
        if (role != null) {
          userData['role'] = role;
        }
        _currentUser = UserModel.fromJson(userData);
        notifyListeners();
      }

      // Fetch full profile from backend
      // This might overwrite with profile data, but role should be preserved from SharedPreferences
      await fetchUserProfile();
    } catch (e) {
      print('Error setting user from login: $e');
    }
  }

  void login(String email, String password) {
    // This method is kept for backward compatibility
    // Actual login is handled in login_screen.dart
  }

  Future<void> logout() async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('role');
      await prefs.remove('auth_token');
    } catch (e) {
      print('Error clearing prefs: $e');
    }
    notifyListeners();
  }

  void updateProfile({
    String? firstName,
    String? lastName,
    String? position,
    String? avatarPath,
  }) {
    if (_currentUser == null) return;

    _currentUser = UserModel(
      id: _currentUser!.id,
      firstName: firstName ?? _currentUser!.firstName,
      lastName: lastName ?? _currentUser!.lastName,
      email: _currentUser!.email,
      position: position ?? _currentUser!.position,
      avatarUrl: avatarPath ?? _currentUser!.avatarUrl,
    );
    notifyListeners();
  }
}

