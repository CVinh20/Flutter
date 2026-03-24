import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? phoneNumber;

  /// Vai trò: 'admin' | 'stylist' | 'customer' | 'manager' | 'receptionist'
  final String role;

  /// ID của stylist nếu user là stylist
  final String? stylistId;
  
  /// Trạng thái hoạt động
  final bool isActive;
  
  /// Danh sách dịch vụ yêu thích (IDs)
  final List<String> favoriteServices;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.stylistId,
    this.isActive = true,
    this.favoriteServices = const [],
    required this.createdAt,
    DateTime? updatedAt,
    this.lastLoginAt,

    /// Cho phép truyền thẳng role hoặc dùng isAdmin để backward compatibility
    String? role,
    bool isAdmin = false,
  }) : 
    role = role ?? (isAdmin ? 'admin' : (stylistId != null ? 'stylist' : 'customer')),
    updatedAt = updatedAt ?? createdAt;

  /// Getter tương thích với code cũ: user.isAdmin
  bool get isAdmin => role == 'admin';

  /// User có phải stylist không
  bool get isStylist =>
      role == 'stylist' || (stylistId != null && stylistId!.isNotEmpty);

  // ====== Dùng cho Firestore (code cũ) ======
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final bool isAdminFlag = data['isAdmin'] ?? false;
    final String? stylistId = data['stylistId'];

    final String role =
        data['role'] ??
        (isAdminFlag
            ? 'admin'
            : (stylistId != null && stylistId.isNotEmpty
                  ? 'stylist'
                  : 'customer'));

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      phoneNumber: data['phoneNumber'],
      isAdmin: isAdminFlag,
      stylistId: stylistId,
      isActive: data['isActive'] ?? true,
      favoriteServices: (data['favoriteServices'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      role: role,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      // Lưu cả role và isAdmin để tương thích
      'role': role,
      'isAdmin': isAdmin,
      'stylistId': stylistId,
      'isActive': isActive,
      'favoriteServices': favoriteServices,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    bool? isAdmin,
    String? role,
    String? stylistId,
    bool? isActive,
    List<String>? favoriteServices,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    final newRole =
        role ??
        (isAdmin != null ? (isAdmin ? 'admin' : 'customer') : this.role);

    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      stylistId: stylistId ?? this.stylistId,
      isActive: isActive ?? this.isActive,
      favoriteServices: favoriteServices ?? this.favoriteServices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      role: newRole,
    );
  }

  // ====== JSON từ API MongoDB ======
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final String? apiRole = json['role'];
    final bool isAdminFlag = apiRole != null
        ? apiRole == 'admin'
        : (json['isAdmin'] ?? false);

    final String role =
        apiRole ??
        (isAdminFlag
            ? 'admin'
            : (json['stylistId'] != null ? 'stylist' : 'customer'));

    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? json['fullName'] ?? '',
      photoURL: json['photoURL'] ?? json['avatar'],
      phoneNumber: json['phoneNumber'],
      isAdmin: isAdminFlag,
      stylistId: json['stylistId'],
      isActive: json['isActive'] ?? true,
      favoriteServices: (json['favoriteServices'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'].toString())
          : null,
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'email': email,
      'displayName': displayName,
      'fullName': displayName,
      'photoURL': photoURL,
      'avatar': photoURL,
      'phoneNumber': phoneNumber,
      'role': role,
      'isAdmin': isAdmin,
      'stylistId': stylistId,
      'isActive': isActive,
      'favoriteServices': favoriteServices,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }
}
