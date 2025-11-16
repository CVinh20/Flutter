// lib/models/branch.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Branch {
  final String id;
  final String name;
  final String address;
  final String hours;
  final double rating;
  final String image;
  // --- THÊM 2 TRƯỜNG MỚI ---
  final double latitude;
  final double longitude;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.hours,
    required this.rating,
    required this.image,
    // --- CẬP NHẬT CONSTRUCTOR ---
    required this.latitude,
    required this.longitude,
  });

  factory Branch.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Branch(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      hours: data['hours'] ?? '8:00 - 22:00',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      image: data['image'] ?? '',
      // --- LẤY DỮ LIỆU TỌA ĐỘ TỪ FIRESTORE ---
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}