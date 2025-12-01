class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String position;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.position,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';
  String get shortName => firstName;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      position: json['position'] as String,
      avatarUrl: json['avatarUrl'] as String?,
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
    };
  }
}

