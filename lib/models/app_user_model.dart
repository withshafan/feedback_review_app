import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  final String email;
  final String role; // "user" or "admin"
  final DateTime createdAt;

  AppUserModel({
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory AppUserModel.fromMap(Map<String, dynamic> data) {
    return AppUserModel(
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
