class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String position;
  final String? avatarUrl;
  final bool isManager;
  final String? role;
  final String? department;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.position,
    this.avatarUrl,
    this.isManager = false,
    this.role,
    this.department,
  });

  String get fullName => '$firstName $lastName';
  String get shortName => firstName;
  
  bool get isAdmin => (role ?? '') == 'admin';
  bool get isManagerRole => (role ?? '') == 'manager';
  bool get canApproveLeave => isAdmin || isManagerRole;

  // Helper function to safely parse bool from dynamic value
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? 
          json['user_id']?.toString() ?? 
          json['employee_id']?.toString() ?? '1',
      firstName: json['firstName']?.toString() ?? 
                 json['first_name']?.toString() ?? 
                 json['username']?.toString() ?? 'User',
      lastName: json['lastName']?.toString() ?? 
                json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      position: json['position']?.toString() ?? 
                json['department']?.toString() ?? 
                'Employee',
      avatarUrl: json['avatarUrl']?.toString() ?? 
                 json['avatar_url']?.toString(),
      isManager: _parseBool(json['isManager']) || 
                 _parseBool(json['is_manager']) ||
                 false,
      role: json['role']?.toString(),
      department: json['department']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'position': position,
      'avatarUrl': avatarUrl,
      'isManager': isManager,
      'role': role,
      'department': department,
    };
  }
}

