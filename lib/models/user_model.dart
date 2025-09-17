class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role;
  final String? semester;
  final String? phoneNumber;
  final bool isVerified;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.semester,
    this.phoneNumber,
    required this.isVerified,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: data['role'] ?? '',
      semester: data['semester'],
      phoneNumber: data['phoneNumber'],
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role,
      'semester': semester,
      'phoneNumber': phoneNumber,
      'isVerified': isVerified,
    };
  }
}