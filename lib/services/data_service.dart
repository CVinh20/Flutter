// lib/services/data_service.dart
// Service thống nhất để quản lý tất cả dữ liệu từ MongoDB
import '../models/booking.dart';
import '../models/service.dart';
import '../models/branch.dart';
import '../models/stylist.dart';
import '../models/voucher.dart';
import '../models/category.dart';
import 'api_service.dart';
import 'mongodb_auth_service.dart';

class DataService {
  // ==================== BOOKINGS ====================

  // Lấy danh sách booking của user
  Future<List<Booking>> getUserBookings() async {
    try {
      // Check if user is logged in
      final token = await ApiService.getToken();
      if (token == null) {
        print('⚠️ getUserBookings: No token, returning empty list');
        return [];
      }
      
      // Get all bookings (limit=100 instead of default 10)
      final response = await ApiService.get(
        '/bookings/user',
        queryParams: {'limit': '100'},
      );
      if (response['success']) {
        final List<dynamic> data = response['data'];
        print('✅ Loaded ${data.length} bookings from MongoDB');
        return data.map((json) => Booking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getUserBookings: $e');
      return []; // Return empty instead of throwing
    }
  }

  // Tạo booking mới
  Future<Booking> createBooking(Booking booking) async {
    try {
      final currentUser = MongoDBAuthService.currentUser;
      if (currentUser == null) {
        throw Exception('Vui lòng đăng nhập để đặt lịch');
      }

      final bookingPayload = {
        'userId': currentUser.id, // Thêm userId
        'serviceId': booking.service.id,
        'serviceName': booking.service.name,
        'servicePrice': booking.service.price,
        'serviceDuration': booking.service.duration,
        'serviceImage': booking.service.image,
        'stylistId': booking.stylist.id,
        'stylistName': booking.stylist.name,
        'dateTime': booking.dateTime.toIso8601String(),
        'status': booking.status,
        'note': booking.note,
        'customerName': booking.customerName,
        'customerPhone': booking.customerPhone,
        'branchName': booking.branchName,
        'paymentMethod': booking.paymentMethod ?? 'cash',
        'amount': booking.amount,
        'discount': booking.discount ?? 0,
        'voucherCode': booking.voucherCode,
        'originalAmount': booking.originalAmount,
        'isPaid': booking.isPaid,
      };

      print('📤 Creating booking for user ${currentUser.id}: ${booking.service.name} at ${booking.dateTime}');
      final response = await ApiService.post('/bookings', bookingPayload);
      if (response['success']) {
        print('✅ Booking created successfully with ID: ${response['data']['_id']}');
        return Booking.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Không thể tạo booking');
      }
    } catch (e) {
      print('❌ Error creating booking: $e');
      throw Exception('Không thể tạo đặt lịch: ${e.toString()}');
    }
  }

  // Cập nhật booking
  Future<Booking> updateBooking(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await ApiService.put('/bookings/$bookingId', updates);
      if (response['success']) {
        return Booking.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Không thể cập nhật booking');
      }
    } catch (e) {
      throw Exception('Không thể cập nhật đặt lịch: ${e.toString()}');
    }
  }

  // Hủy booking (update status thành cancelled)
  Future<void> cancelBooking(String bookingId) async {
    try {
      await ApiService.put('/bookings/$bookingId', {'status': 'cancelled'});
      print('✅ Booking cancelled: $bookingId');
    } catch (e) {
      print('❌ Error cancelling booking: $e');
      throw Exception('Không thể hủy đặt lịch: ${e.toString()}');
    }
  }

  // Xóa booking (xóa vĩnh viễn khỏi database)
  Future<void> deleteBooking(String bookingId) async {
    try {
      await ApiService.delete('/bookings/$bookingId');
      print('✅ Booking deleted: $bookingId');
    } catch (e) {
      throw Exception('Không thể xóa đặt lịch: ${e.toString()}');
    }
  }

  // Xác nhận đơn đặt lịch (cho stylist)
  Future<Booking> confirmBooking(String bookingId, String stylistId) async {
    try {
      final response = await ApiService.post(
        '/bookings/$bookingId/confirm',
        {'stylistId': stylistId},
      );
      if (response['success']) {
        print('✅ Booking confirmed: $bookingId');
        return Booking.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Không thể xác nhận đơn');
      }
    } catch (e) {
      print('❌ Error confirming booking: $e');
      throw Exception('Không thể xác nhận đơn: ${e.toString()}');
    }
  }

  // ==================== SERVICES ====================

  // Lấy tất cả dịch vụ
  Future<List<Service>> getServices({
    int page = 1,
    int limit = 100,
    String? search,
    String? categoryId,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      String endpoint = '/services';
      if (categoryId != null) {
        endpoint = '/services/category/$categoryId';
      }

      final response = await ApiService.get(
        endpoint,
        queryParams: queryParams,
        includeAuth: false,
      );

      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Service.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể lấy danh sách dịch vụ: ${e.toString()}');
    }
  }

  // Lấy dịch vụ theo category
  Future<List<Service>> getServicesByCategory(String categoryId) async {
    return getServices(categoryId: categoryId);
  }

  // Lấy dịch vụ nổi bật
  Future<List<Service>> getFeaturedServices() async {
    try {
      final response = await ApiService.get(
        '/services/featured',
        includeAuth: false,
      );
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Service.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể lấy dịch vụ nổi bật: ${e.toString()}');
    }
  }

  // Tìm kiếm dịch vụ
  Future<List<Service>> searchServices(
    String query, {
    double? minPrice,
    double? maxPrice,
    String? categoryId,
  }) async {
    try {
      final queryParams = <String, String>{'q': query};

      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (categoryId != null) queryParams['category'] = categoryId;

      final response = await ApiService.get(
        '/services/search',
        queryParams: queryParams,
        includeAuth: false,
      );

      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Service.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tìm kiếm dịch vụ: ${e.toString()}');
    }
  }

  // ==================== BRANCHES ====================

  // Lấy tất cả chi nhánh
  Future<List<Branch>> getBranches() async {
    try {
      final response = await ApiService.get(
        '/branches',
        includeAuth: false,
      );
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Branch.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể lấy danh sách chi nhánh: ${e.toString()}');
    }
  }

  // Lấy chi nhánh gần
  Future<List<Branch>> getNearbyBranches(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await ApiService.get(
        '/branches/nearby',
        queryParams: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
        includeAuth: false,
      );

      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Branch.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể lấy chi nhánh gần: ${e.toString()}');
    }
  }

  // ==================== STYLISTS ====================

  // Lấy tất cả stylists
  Future<List<Stylist>> getStylists() async {
    try {
      final response = await ApiService.get(
        '/stylists',
        includeAuth: false,
      );
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Stylist.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể lấy danh sách stylist: ${e.toString()}');
    }
  }

  // Lấy stylists theo chi nhánh
  Future<List<Stylist>> getStylistsByBranch(String branchId) async {
    try {
      final response = await ApiService.get(
        '/stylists/branch/$branchId',
        includeAuth: false,
      );
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Stylist.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể lấy danh sách stylist: ${e.toString()}');
    }
  }

  // Lấy top stylists
  Future<List<Stylist>> getTopRatedStylists() async {
    try {
      final response = await ApiService.get(
        '/stylists/top-rated',
        includeAuth: false,
      );
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Stylist.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể lấy top stylists: ${e.toString()}');
    }
  }

  // ==================== VOUCHERS ====================

  // Lấy vouchers đang hoạt động (chưa dùng bởi user)
  Future<List<Voucher>> getActiveVouchers({String? userId}) async {
    try {
      final queryParams = userId != null ? {'userId': userId} : <String, String>{};
      final response = await ApiService.get(
        '/vouchers/active',
        queryParams: queryParams,
        includeAuth: false,
      );
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Voucher.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể lấy danh sách voucher: ${e.toString()}');
    }
  }

  // Lấy voucher khả dụng cho user (chưa sử dụng)
  Future<List<Voucher>> getAvailableVouchersForUser(String userId) async {
    try {
      final response = await ApiService.get(
        '/vouchers/available/$userId',
        includeAuth: false,
      );
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Voucher.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể lấy vouchers khả dụng: ${e.toString()}');
    }
  }

  // Lấy tất cả vouchers
  Future<List<Voucher>> getVouchers() async {
    return getActiveVouchers();
  }

  // Lấy voucher theo mã
  Future<Voucher?> getVoucherByCode(String code) async {
    try {
      final response = await ApiService.get(
        '/vouchers/code/$code',
        includeAuth: false,
      );
      if (response['success'] && response['data'] != null) {
        return Voucher.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Không tìm thấy voucher: ${e.toString()}');
      return null;
    }
  }

  // Validate voucher
  Future<Map<String, dynamic>> validateVoucher(
    String code,
    String userId,
    double orderAmount,
  ) async {
    try {
      final response = await ApiService.post('/vouchers/validate', {
        'code': code,
        'userId': userId,
        'orderAmount': orderAmount,
      }, includeAuth: false);

      if (response['success']) {
        return response['data'];
      } else {
        throw Exception(response['error'] ?? 'Voucher không hợp lệ');
      }
    } catch (e) {
      throw Exception('Không thể validate voucher: ${e.toString()}');
    }
  }

  // Áp dụng voucher
  Future<bool> applyVoucher(String voucherId, String userId) async {
    try {
      final response = await ApiService.post('/vouchers/apply', {
        'voucherId': voucherId,
        'userId': userId,
      });
      return response['success'] == true;
    } catch (e) {
      print('Không thể áp dụng voucher: ${e.toString()}');
      return false;
    }
  }

  // Lưu voucher cho user
  Future<bool> saveVoucherForUser(String voucherId) async {
    try {
      final response = await ApiService.post('/user-vouchers', {
        'voucherId': voucherId,
      });
      return response['success'] == true;
    } catch (e) {
      print('Không thể lưu voucher: ${e.toString()}');
      return false;
    }
  }

  // Lấy vouchers của user
  Future<List<Map<String, dynamic>>> getUserVouchers(
    String userId, {
    String status = 'all',
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != 'all') {
        queryParams['status'] = status;
      }

      final response = await ApiService.get(
        '/user-vouchers/user/$userId',
        queryParams: queryParams,
      );

      if (response['success']) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      throw Exception('Không thể lấy vouchers của user: ${e.toString()}');
    }
  }

  // ==================== CATEGORIES ====================

  // Lấy tất cả categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await ApiService.get('/categories', includeAuth: false);
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Category.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể lấy danh sách danh mục: ${e.toString()}');
    }
  }

  // Thêm category
  Future<Category> addCategory(Category category) async {
    try {
      final response = await ApiService.post('/categories', category.toJson());
      if (response['success']) {
        return Category.fromJson(response['data']);
      }
      throw Exception('Không thể thêm danh mục');
    } catch (e) {
      throw Exception('Không thể thêm danh mục: ${e.toString()}');
    }
  }

  // Cập nhật category
  Future<Category> updateCategory(Category category) async {
    try {
      final response = await ApiService.put(
        '/categories/${category.id}',
        category.toJson(),
      );
      if (response['success']) {
        return Category.fromJson(response['data']);
      }
      throw Exception('Không thể cập nhật danh mục');
    } catch (e) {
      throw Exception('Không thể cập nhật danh mục: ${e.toString()}');
    }
  }

  // Xóa category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await ApiService.delete('/categories/$categoryId');
    } catch (e) {
      throw Exception('Không thể xóa danh mục: ${e.toString()}');
    }
  }

  // Thêm service
  Future<Service> addService(Service service) async {
    try {
      final response = await ApiService.post('/services', service.toJson());
      if (response['success']) {
        return Service.fromJson(response['data']);
      }
      throw Exception('Không thể thêm dịch vụ');
    } catch (e) {
      throw Exception('Không thể thêm dịch vụ: ${e.toString()}');
    }
  }

  // Cập nhật service
  Future<Service> updateService(Service service) async {
    try {
      final response = await ApiService.put(
        '/services/${service.id}',
        service.toJson(),
      );
      if (response['success']) {
        return Service.fromJson(response['data']);
      }
      throw Exception('Không thể cập nhật dịch vụ');
    } catch (e) {
      throw Exception('Không thể cập nhật dịch vụ: ${e.toString()}');
    }
  }

  // Xóa service
  Future<void> deleteService(String serviceId) async {
    try {
      await ApiService.delete('/services/$serviceId');
    } catch (e) {
      throw Exception('Không thể xóa dịch vụ: ${e.toString()}');
    }
  }

  // ==================== STYLIST OPERATIONS ====================

  // Lấy bookings của stylist
  Future<List<Booking>> getStylistBookings(String stylistId) async {
    try {
      final response = await ApiService.get('/bookings/stylist/$stylistId');
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Booking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể lấy danh sách booking: ${e.toString()}');
    }
  }

  // Check-in booking
  Future<void> checkInBooking(String bookingId) async {
    try {
      await ApiService.patch('/bookings/$bookingId/check-in', {});
    } catch (e) {
      throw Exception('Không thể check-in: ${e.toString()}');
    }
  }

  // Cập nhật trạng thái dịch vụ
  Future<void> updateServiceStatus(
    String bookingId,
    String serviceStatus,
  ) async {
    try {
      await ApiService.patch('/bookings/$bookingId/service-status', {
        'serviceStatus': serviceStatus,
      });
    } catch (e) {
      throw Exception('Không thể cập nhật trạng thái: ${e.toString()}');
    }
  }

  // Cập nhật ghi chú stylist
  Future<void> updateStylistNotes(String bookingId, String notes) async {
    try {
      await ApiService.patch('/bookings/$bookingId/notes', {
        'stylistNotes': notes,
      });
    } catch (e) {
      throw Exception('Không thể cập nhật ghi chú: ${e.toString()}');
    }
  }

  // ==================== FAVORITES ====================

  /// Lấy danh sách dịch vụ yêu thích của user
  Future<List<Service>> getFavoriteServices() async {
    try {
      final response = await ApiService.get('/users/favorites');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => Service.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error loading favorites: $e');
      return []; // Return empty list if user not logged in
    }
  }

  /// Thêm hoặc xóa dịch vụ khỏi danh sách yêu thích
  Future<bool> toggleFavoriteService(String serviceId) async {
    try {
      final response = await ApiService.post('/users/favorites/$serviceId', {});
      if (response['success'] == true) {
        return response['isFavorite'] ?? false;
      }
      return false;
    } catch (e) {
      print('⚠️ Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Kiểm tra dịch vụ có trong danh sách yêu thích không
  Future<bool> isFavoriteService(String serviceId) async {
    try {
      final response = await ApiService.get('/users/favorites/$serviceId/check');
      return response['isFavorite'] ?? false;
    } catch (e) {
      print('⚠️ Error checking favorite: $e');
      return false;
    }
  }
}
