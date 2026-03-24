// lib/models/stylist.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Stylist {
  final String id;
  final String name;
  final String image;
  final double rating;
  final String experience;
  final String? userId; // ID của tài khoản user liên kết
  final String? branchId;
  final String? branchName;

  Stylist({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.experience,
    this.userId,
    this.branchId,
    this.branchName,
  });

  factory Stylist.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Stylist(
      id: doc.id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      experience: data['experience'] ?? '',
      userId: data['userId'],
      branchId: data['branchId'],
      branchName: data['branchName'],
    );
  }

  // JSON serialization for API (MongoDB)
  factory Stylist.fromJson(Map<String, dynamic> json) {
    return Stylist(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      experience: json['experience'] ?? '',
      userId: json['userId'],
      branchId: json['branchId'],
      branchName: json['branchName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'name': name,
      'image': image,
      'imageUrl': image,
      'rating': rating,
      'experience': experience,
      'branchId': branchId,
      'branchName': branchName,
    };
  }

  // === PHẦN SỬA LỖI: Ghi đè toán tử so sánh và hashCode ===
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stylist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
