// lib/models/employee.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String id;
  final String userId; // ID của user account
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? photoURL;
  final String role; // 'stylist', 'receptionist', 'manager', etc.
  final String? stylistId; // ID của stylist (nếu là stylist)
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? additionalInfo; // Thông tin bổ sung

  Employee({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.photoURL,
    required this.role,
    this.stylistId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.additionalInfo,
  });

  factory Employee.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Employee(
      id: doc.id,
      userId: data['userId'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      photoURL: data['photoURL'],
      role: data['role'] ?? 'stylist',
      stylistId: data['stylistId'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      additionalInfo: data['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'role': role,
      'stylistId': stylistId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'additionalInfo': additionalInfo,
    };
  }

  Employee copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? photoURL,
    String? role,
    String? stylistId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Employee(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      stylistId: stylistId ?? this.stylistId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Các phương thức tiện ích
  bool get isStylist => role == 'stylist';
  bool get isManager => role == 'manager';
  bool get isReceptionist => role == 'receptionist';
  
  String get roleDisplayName {
    switch (role) {
      case 'stylist':
        return 'Stylist';
      case 'manager':
        return 'Quản lý';
      case 'receptionist':
        return 'Lễ tân';
      default:
        return 'Nhân viên';
    }
  }
}
