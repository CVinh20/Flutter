// lib/models/voucher.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String id;
  final String code;
  final String name;
  final String description;
  final double discount; // Phần trăm giảm giá (0-100)
  final double? maxDiscount; // Số tiền giảm tối đa
  final double minOrderValue; // Giá trị đơn hàng tối thiểu để áp dụng
  final DateTime validFrom;
  final DateTime validTo;
  final int totalQuantity; // Tổng số lượng voucher
  final int usedQuantity; // Số lượng đã sử dụng
  final bool isActive;
  final String? imageUrl;
  final List<String>? usedBy; // Danh sách userId đã sử dụng

  Voucher({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.discount,
    this.maxDiscount,
    required this.minOrderValue,
    required this.validFrom,
    required this.validTo,
    required this.totalQuantity,
    this.usedQuantity = 0,
    this.isActive = true,
    this.imageUrl,
    this.usedBy,
  });

  // Kiểm tra voucher còn hợp lệ không
  bool get isValid {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(validFrom) && 
           now.isBefore(validTo) &&
           usedQuantity < totalQuantity;
  }

  // Số lượng còn lại
  int get remainingQuantity => totalQuantity - usedQuantity;

  // Tính số tiền giảm giá
  double calculateDiscount(double orderValue) {
    if (!isValid || orderValue < minOrderValue) {
      return 0;
    }
    
    double discountAmount = orderValue * (discount / 100);
    
    if (maxDiscount != null && discountAmount > maxDiscount!) {
      discountAmount = maxDiscount!;
    }
    
    return discountAmount;
  }

  factory Voucher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Voucher(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      discount: (data['discount'] ?? 0).toDouble(),
      maxDiscount: data['maxDiscount']?.toDouble(),
      minOrderValue: (data['minOrderValue'] ?? 0).toDouble(),
      validFrom: (data['validFrom'] as Timestamp).toDate(),
      validTo: (data['validTo'] as Timestamp).toDate(),
      totalQuantity: data['totalQuantity'] ?? 0,
      usedQuantity: data['usedQuantity'] ?? 0,
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl'],
      usedBy: data['usedBy'] != null ? List<String>.from(data['usedBy']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'discount': discount,
      'maxDiscount': maxDiscount,
      'minOrderValue': minOrderValue,
      'validFrom': Timestamp.fromDate(validFrom),
      'validTo': Timestamp.fromDate(validTo),
      'totalQuantity': totalQuantity,
      'usedQuantity': usedQuantity,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'usedBy': usedBy,
    };
  }

  Voucher copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    double? discount,
    double? maxDiscount,
    double? minOrderValue,
    DateTime? validFrom,
    DateTime? validTo,
    int? totalQuantity,
    int? usedQuantity,
    bool? isActive,
    String? imageUrl,
    List<String>? usedBy,
  }) {
    return Voucher(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      discount: discount ?? this.discount,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      usedQuantity: usedQuantity ?? this.usedQuantity,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      usedBy: usedBy ?? this.usedBy,
    );
  }
}
