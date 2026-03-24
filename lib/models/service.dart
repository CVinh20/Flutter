import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final String description;
  final double price;
  final String duration;
  final double rating;
  final String image;
  final String categoryId;

  Service({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    required this.duration,
    required this.rating,
    required this.image,
    this.categoryId = '',
  });

  factory Service.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Service(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      duration: data['duration'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      image: data['image'] ?? '',
      categoryId: data['categoryId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'rating': rating,
      'image': image,
      'categoryId': categoryId,
    };
  }

  Service copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? duration,
    double? rating,
    String? image,
    String? categoryId,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      image: image ?? this.image,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  // JSON serialization for API (MongoDB)
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      image: json['image'] ?? json['imageUrl'] ?? '',
      categoryId: json['categoryId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'rating': rating,
      'image': image,
      'imageUrl': image,
      'categoryId': categoryId,
    };
  }
}
