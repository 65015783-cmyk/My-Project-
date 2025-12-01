import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    // Initialize with mock user for demo
    _currentUser = UserModel(
      id: '1',
      firstName: 'Montita',
      lastName: 'Hongloywong',
      email: 'montita@example.com',
      position: 'Senior Product Engineering',
    );
    notifyListeners();
  }

  void login(String email, String password) {
    // Mock login - in real app, this would call an API
    _currentUser = UserModel(
      id: '1',
      firstName: 'Montita',
      lastName: 'Hongloywong',
      email: email,
      position: 'Senior Product Engineering',
    );
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
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

