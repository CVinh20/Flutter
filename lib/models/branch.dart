// lib/models/branch.dart
class Branch {
  final String id;
  final String name;
  final String address;
  final String hours;
  final double rating;
  final String image;
  final double latitude;
  final double longitude;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.hours,
    required this.rating,
    required this.image,
    required this.latitude,
    required this.longitude,
  });

  // JSON serialization for API (MongoDB)
  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      hours: json['hours'] ?? '8:00 - 22:00',
      rating: (json['rating'] ?? 0.0).toDouble(),
      image: json['image'] ?? json['imageUrl'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'name': name,
      'address': address,
      'hours': hours,
      'rating': rating,
      'image': image,
      'imageUrl': image,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
