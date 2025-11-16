// lib/models/stylist.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Stylist {
  final String id;
  final String name;
  final String image;
  final double rating;
  final String experience;

  Stylist({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.experience,
  });

  factory Stylist.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Stylist(
      id: doc.id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      experience: data['experience'] ?? '',
    );
  }

  // === PHẦN SỬA LỖI: Ghi đè toán tử so sánh và hashCode ===
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stylist &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
  
}