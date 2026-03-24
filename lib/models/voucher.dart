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
  final List<String>?
  productIds; // Danh sách productId áp dụng (null = áp dụng cho tất cả)
  final String? voucherType; // 'service', 'product', 'all' (null = all)

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
    this.productIds,
    this.voucherType,
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

  // Kiểm tra voucher có áp dụng cho sản phẩm không
  bool canApplyToProduct(String productId) {
    if (productIds == null || productIds!.isEmpty) {
      return true; // Áp dụng cho tất cả sản phẩm
    }
    return productIds!.contains(productId);
  }

  // Kiểm tra voucher có áp dụng cho đơn hàng không (dựa trên danh sách productIds)
  bool canApplyToOrder(List<String> orderProductIds) {
    if (productIds == null || productIds!.isEmpty) {
      return true; // Áp dụng cho tất cả
    }
    // Kiểm tra xem có ít nhất 1 sản phẩm trong đơn hàng nằm trong danh sách productIds
    return orderProductIds.any((id) => productIds!.contains(id));
  }

  factory Voucher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse dates with null safety
    DateTime parseDate(dynamic value, DateTime defaultDate) {
      if (value == null) return defaultDate;
      if (value is Timestamp) return value.toDate();
      return defaultDate;
    }

    final now = DateTime.now();

    return Voucher(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      discount: (data['discount'] ?? 0).toDouble(),
      maxDiscount: data['maxDiscount']?.toDouble(),
      minOrderValue: (data['minOrderValue'] ?? 0).toDouble(),
      validFrom: parseDate(data['validFrom'], now),
      validTo: parseDate(data['validTo'], now.add(const Duration(days: 30))),
      totalQuantity: data['totalQuantity'] ?? 0,
      usedQuantity: data['usedQuantity'] ?? 0,
      isActive: data['isActive'] ?? false,
      imageUrl: data['imageUrl'],
      usedBy: data['usedBy'] != null ? List<String>.from(data['usedBy']) : null,
      productIds: data['productIds'] != null
          ? List<String>.from(data['productIds'])
          : null,
      voucherType: data['voucherType'],
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
      'productIds': productIds,
      'voucherType': voucherType,
    };
  }

  // JSON serialization for API (MongoDB)
  factory Voucher.fromJson(Map<String, dynamic> json) {
    // Parse _id - có thể là string hoặc object với $oid
    String parseId(dynamic id) {
      if (id == null) return '';
      if (id is String) return id;
      if (id is Map && id.containsKey('\$oid')) return id['\$oid'];
      return id.toString();
    }

    return Voucher(
      id: parseId(json['_id'] ?? json['id']),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      discount: (json['discount'] ?? 0).toDouble(),
      maxDiscount: json['maxDiscount'] != null 
          ? (json['maxDiscount'] as num).toDouble() 
          : null,
      minOrderValue: (json['minOrderValue'] ?? 0).toDouble(),
      validFrom: json['validFrom'] != null
          ? DateTime.parse(json['validFrom'])
          : DateTime.now(),
      validTo: json['validTo'] != null
          ? DateTime.parse(json['validTo'])
          : DateTime.now().add(const Duration(days: 30)),
      totalQuantity: json['totalQuantity'] ?? 0,
      usedQuantity: json['usedQuantity'] ?? 0,
      isActive: json['isActive'] ?? false,
      imageUrl: json['imageUrl'],
      usedBy: json['usedBy'] != null ? List<String>.from(json['usedBy']) : null,
      productIds: json['productIds'] != null
          ? List<String>.from(json['productIds'])
          : null,
      voucherType: json['voucherType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'code': code,
      'name': name,
      'description': description,
      'discount': discount,
      'maxDiscount': maxDiscount,
      'minOrderValue': minOrderValue,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'totalQuantity': totalQuantity,
      'usedQuantity': usedQuantity,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'usedBy': usedBy,
      'productIds': productIds,
      'voucherType': voucherType,
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
    List<String>? productIds,
    String? voucherType,
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
      productIds: productIds ?? this.productIds,
      voucherType: voucherType ?? this.voucherType,
    );
  }
}
