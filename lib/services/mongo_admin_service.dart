import '../models/category.dart';
import '../models/voucher.dart';
import '../models/stylist.dart';
import '../models/user.dart';
import '../models/service.dart';
import '../models/branch.dart';
import 'api_service.dart';

class MongoAdminService {
  // ========== STATISTICS ==========
  static Future<int> getServicesCount() async {
    try {
      final response = await ApiService.get('/services', queryParams: {'limit': '1'});
      if (response['success'] && response['pagination'] != null) {
        return response['pagination']['total'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting services count: $e');
      return 0;
    }
  }

  static Future<int> getBranchesCount() async {
    try {
      final response = await ApiService.get('/branches');
      if (response['success'] && response['data'] is List) {
        return (response['data'] as List).length;
      }
      return 0;
    } catch (e) {
      print('Error getting branches count: $e');
      return 0;
    }
  }

  static Future<int> getStylistsCount() async {
    try {
      final response = await ApiService.get('/stylists', queryParams: {'limit': '1'});
      if (response['success'] && response['pagination'] != null) {
        return response['pagination']['total'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting stylists count: $e');
      return 0;
    }
  }

  static Future<int> getTodayBookingsCount() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final response = await ApiService.get('/bookings', queryParams: {
        'startDate': startOfDay.toIso8601String(),
      });
      if (response['success'] && response['data'] is List) {
        return (response['data'] as List).length;
      }
      return 0;
    } catch (e) {
      print('Error getting today bookings count: $e');
      return 0;
    }
  }

  static Future<int> getUsersCount() async {
    try {
      final response = await ApiService.get('/users');
      if (response['success'] && response['data'] is List) {
        return (response['data'] as List).length;
      }
      return 0;
    } catch (e) {
      print('Error getting users count: $e');
      return 0;
    }
  }

  // ========== USERS MANAGEMENT ==========
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await ApiService.get('/users');
      if (response['success']) {
        final data = response['data'] as List<dynamic>;
        return data.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  static Future<UserModel> getUserById(String userId) async {
    final response = await ApiService.get('/users/$userId');
    return UserModel.fromJson(Map<String, dynamic>.from(response['data']));
  }

  static Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async {
    final response = await ApiService.put('/users/$userId', data);
    return UserModel.fromJson(Map<String, dynamic>.from(response['data']));
  }

  static Future<void> deleteUser(String userId) async {
    await ApiService.delete('/users/$userId');
  }

  static Future<bool> isAdmin(String userId) async {
    try {
      final user = await getUserById(userId);
      return user.isAdmin;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // ========== STYLISTS MANAGEMENT ==========
  static Future<List<Stylist>> getAllStylists() async {
    try {
      final response = await ApiService.get('/stylists', queryParams: {'limit': '100'});
      if (response['success']) {
        final data = response['data'] as List<dynamic>;
        return data.map((e) => Stylist.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all stylists: $e');
      return [];
    }
  }

  static Future<Stylist> createStylist(Map<String, dynamic> stylistData) async {
    final response = await ApiService.post('/stylists', stylistData);
    return Stylist.fromJson(Map<String, dynamic>.from(response['data']));
  }

  static Future<Stylist> updateStylist(String stylistId, Map<String, dynamic> data) async {
    final response = await ApiService.put('/stylists/$stylistId', data);
    return Stylist.fromJson(Map<String, dynamic>.from(response['data']));
  }

  static Future<void> deleteStylist(String stylistId) async {
    await ApiService.delete('/stylists/$stylistId');
  }

  static Future<List<Map<String, dynamic>>> getAvailableStylists() async {
    try {
      final stylists = await getAllStylists();
      return stylists.map((s) => {'id': s.id, 'name': s.name}).toList();
    } catch (e) {
      print('Error getting available stylists: $e');
      return [];
    }
  }

  // Create stylist account (user)
  static Future<String> createStylistAccount({
    required String email,
    required String password,
    String? stylistId,
    required String stylistName,
  }) async {
    try {
      // Register user với role stylist
      final response = await ApiService.post('/auth/register', {
        'fullName': stylistName,
        'email': email,
        'password': password,
        'role': 'stylist',
        if (stylistId != null) 'stylistId': stylistId,
      });
      
      if (response['success']) {
        final userId = response['data']['_id'] ?? response['data']['id'];
        return userId.toString();
      }
      throw Exception('Failed to create stylist account');
    } catch (e) {
      print('Error creating stylist account: $e');
      rethrow;
    }
  }

  static Future<UserModel?> getStylistUser(String stylistId) async {
    try {
      final users = await getAllUsers();
      try {
        return users.firstWhere(
          (user) => user.stylistId == stylistId,
        );
      } catch (e) {
        // Không tìm thấy user - trả về null thay vì throw
        return null;
      }
    } catch (e) {
      // Lỗi khi gọi getAllUsers
      return null;
    }
  }

  // ========== SERVICES MANAGEMENT ==========
  static Future<List<Service>> getAllServices() async {
    try {
      final response = await ApiService.get('/services', queryParams: {'limit': '100'});
      if (response['success']) {
        final data = response['data'] as List<dynamic>;
        return data.map((e) => Service.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all services: $e');
      return [];
    }
  }

  static Future<Service> createService(Map<String, dynamic> serviceData) async {
    final response = await ApiService.post('/services', serviceData);
    return Service.fromJson(Map<String, dynamic>.from(response['data']));
  }

  static Future<Service> updateService(String serviceId, Map<String, dynamic> data) async {
    final response = await ApiService.put('/services/$serviceId', data);
    return Service.fromJson(Map<String, dynamic>.from(response['data']));
  }

  static Future<void> deleteService(String serviceId) async {
    await ApiService.delete('/services/$serviceId');
  }

  // ========== BRANCHES MANAGEMENT ==========
  static Future<List<Branch>> getAllBranches() async {
    try {
      final response = await ApiService.get('/branches');
      if (response['success']) {
        final data = response['data'] as List<dynamic>;
        return data.map((e) => Branch.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all branches: $e');
      return [];
    }
  }

  static Future<Branch> createBranch(Map<String, dynamic> branchData) async {
    final response = await ApiService.post('/branches', branchData);
    return Branch.fromJson(Map<String, dynamic>.from(response['data']));
  }

  static Future<Branch> updateBranch(String branchId, Map<String, dynamic> data) async {
    final response = await ApiService.put('/branches/$branchId', data);
    return Branch.fromJson(Map<String, dynamic>.from(response['data']));
  }

  static Future<void> deleteBranch(String branchId) async {
    await ApiService.delete('/branches/$branchId');
  }

  // ========== CATEGORIES ==========
  static Future<List<Category>> fetchCategories({bool includeInactive = true}) async {
    final response = await ApiService.get(
      '/categories',
      queryParams: {'includeInactive': includeInactive.toString()},
    );
    if (response['success'] != true) return [];
    final data = response['data'] as List<dynamic>;
    return data.map((e) => Category.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<Category> createCategory({required String name, String? description}) async {
    final response = await ApiService.post('/categories', {
      'name': name,
      'description': description,
    });
    return Category.fromJson(Map<String, dynamic>.from(response['data']));
  }

  static Future<Category> updateCategory(Category category) async {
    final response = await ApiService.put('/categories/${category.id}', {
      'name': category.name,
    });
    return Category.fromJson(Map<String, dynamic>.from(response['data']));
  }

  static Future<void> deleteCategory(String id) async {
    await ApiService.delete('/categories/$id');
  }

  // ========== VOUCHERS ==========
  static Future<List<Voucher>> fetchVouchers({bool includeInactive = true}) async {
    final response = await ApiService.get(
      '/vouchers',
      queryParams: {'includeInactive': includeInactive.toString()},
    );
    if (response['success'] != true) return [];
    final data = response['data'] as List<dynamic>;
    return data.map((e) => Voucher.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<Voucher> createVoucher(Voucher voucher) async {
    final response = await ApiService.post('/vouchers', {
      'code': voucher.code,
      'name': voucher.name,
      'description': voucher.description,
      'discount': voucher.discount,
      'maxDiscount': voucher.maxDiscount,
      'minOrderValue': voucher.minOrderValue,
      'totalQuantity': voucher.totalQuantity,
      'usedQuantity': voucher.usedQuantity,
      'validFrom': voucher.validFrom.toIso8601String(),
      'validTo': voucher.validTo.toIso8601String(),
      'isActive': voucher.isActive,
    });
    return Voucher.fromJson(Map<String, dynamic>.from(response['data']));
  }

  static Future<Voucher> updateVoucher(Voucher voucher) async {
    final response = await ApiService.put('/vouchers/${voucher.id}', {
      'code': voucher.code,
      'name': voucher.name,
      'description': voucher.description,
      'discount': voucher.discount,
      'maxDiscount': voucher.maxDiscount,
      'minOrderValue': voucher.minOrderValue,
      'totalQuantity': voucher.totalQuantity,
      'usedQuantity': voucher.usedQuantity,
      'validFrom': voucher.validFrom.toIso8601String(),
      'validTo': voucher.validTo.toIso8601String(),
      'isActive': voucher.isActive,
    });
    return Voucher.fromJson(Map<String, dynamic>.from(response['data']));
  }

  static Future<Voucher> toggleVoucher(Voucher voucher) async {
    return updateVoucher(voucher.copyWith(isActive: !voucher.isActive));
  }

  static Future<void> deleteVoucher(String id) async {
    await ApiService.delete('/vouchers/$id');
  }
}


