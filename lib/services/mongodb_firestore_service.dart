import '../models/booking.dart';
import '../models/service.dart';
import '../models/branch.dart';
import '../models/stylist.dart';
import '../models/voucher.dart';
import '../models/category.dart';
import 'api_service.dart';

class MongoDBFirestoreService {
  // ==================== BOOKINGS ====================

  // Get user bookings
  static Future<List<Booking>> getUserBookings() async {
    try {
      // Check if user is logged in
      final token = await ApiService.getToken();
      if (token == null) {
        print('⚠️ getUserBookings: No token, returning empty list');
        return [];
      }
      
      print('🔍 Fetching user bookings...');
      final response = await ApiService.get('/bookings/user');
      print('📦 Response: ${response.toString()}');
      
      if (response['success']) {
        final List<dynamic> data = response['data'];
        print('✅ Found ${data.length} bookings');
        return data.map((json) => Booking.fromJson(json)).toList();
      }
      print('⚠️ Response success=false');
      return [];
    } catch (e) {
      print('❌ Error fetching bookings: $e');
      return []; // Return empty instead of throwing
    }
  }

  // Create booking
  static Future<Booking> createBooking(Booking booking) async {
    try {
      final bookingPayload = booking.toJson()
        ..['serviceImage'] = booking.service.image;

      final response = await ApiService.post('/bookings', bookingPayload);
      if (response['success']) {
        return Booking.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Failed to create booking');
      }
    } catch (e) {
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  // Update booking
  static Future<Booking> updateBooking(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await ApiService.put('/bookings/$bookingId', updates);
      if (response['success']) {
        return Booking.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Failed to update booking');
      }
    } catch (e) {
      throw Exception('Failed to update booking: ${e.toString()}');
    }
  }

  // Cancel booking
  static Future<void> cancelBooking(String bookingId) async {
    try {
      await ApiService.delete('/bookings/$bookingId');
    } catch (e) {
      throw Exception('Failed to cancel booking: ${e.toString()}');
    }
  }

  // ==================== SERVICES ====================

  // Get all services
  static Future<List<Service>> getServices({
    int page = 1,
    int limit = 20,
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
      throw Exception('Failed to get services: ${e.toString()}');
    }
  }

  // Get featured services
  static Future<List<Service>> getFeaturedServices() async {
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
      throw Exception('Failed to get featured services: ${e.toString()}');
    }
  }

  // Search services
  static Future<List<Service>> searchServices(
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
      throw Exception('Failed to search services: ${e.toString()}');
    }
  }

  // ==================== BRANCHES ====================

  // Get all branches
  static Future<List<Branch>> getBranches() async {
    try {
      final response = await ApiService.get(
        '/branches/active',
        includeAuth: false,
      );
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Branch.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get branches: ${e.toString()}');
    }
  }

  // Get nearby branches
  static Future<List<Branch>> getNearbyBranches(
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
      throw Exception('Failed to get nearby branches: ${e.toString()}');
    }
  }

  // ==================== STYLISTS ====================

  // Get stylists by branch
  static Future<List<Stylist>> getStylistsByBranch(String branchId) async {
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
      throw Exception('Failed to get stylists: ${e.toString()}');
    }
  }

  // Get top rated stylists
  static Future<List<Stylist>> getTopRatedStylists() async {
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
      throw Exception('Failed to get top rated stylists: ${e.toString()}');
    }
  }

  // ==================== VOUCHERS ====================

  // Get active vouchers
  static Future<List<Voucher>> getActiveVouchers() async {
    try {
      final response = await ApiService.get(
        '/vouchers/active',
        includeAuth: false,
      );
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Voucher.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get vouchers: ${e.toString()}');
    }
  }

  // Validate voucher
  static Future<Map<String, dynamic>> validateVoucher(
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
        throw Exception(response['error'] ?? 'Invalid voucher');
      }
    } catch (e) {
      throw Exception('Failed to validate voucher: ${e.toString()}');
    }
  }

  // Get user vouchers
  static Future<List<Map<String, dynamic>>> getUserVouchers(
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
      throw Exception('Failed to get user vouchers: ${e.toString()}');
    }
  }

  // ==================== CATEGORIES ====================

  static Future<List<Category>> getCategories() async {
    try {
      final response = await ApiService.get('/categories', includeAuth: false);
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Category.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get categories: ${e.toString()}');
    }
  }

  // ==================== STYLIST BOOKINGS & OPERATIONS ====================

  static Future<List<Booking>> getStylistBookings(String stylistId) async {
    try {
      final response = await ApiService.get('/bookings/stylist/$stylistId');
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Booking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get stylist bookings: ${e.toString()}');
    }
  }

  static Future<void> checkInBooking(String bookingId) async {
    try {
      await ApiService.patch('/bookings/$bookingId/check-in', {});
    } catch (e) {
      throw Exception('Failed to check in: ${e.toString()}');
    }
  }

  static Future<void> updateServiceStatus(
    String bookingId,
    String serviceStatus,
  ) async {
    try {
      await ApiService.patch('/bookings/$bookingId/service-status', {
        'serviceStatus': serviceStatus,
      });
    } catch (e) {
      throw Exception('Failed to update service status: ${e.toString()}');
    }
  }

  static Future<void> updateStylistNotes(String bookingId, String notes) async {
    try {
      await ApiService.patch('/bookings/$bookingId/notes', {
        'stylistNotes': notes,
      });
    } catch (e) {
      throw Exception('Failed to update stylist notes: ${e.toString()}');
    }
  }

  // ==================== FAVORITES ====================

  static Future<List<Service>> getFavoriteServices() async {
    try {
      final response = await ApiService.get('/users/favorites');
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Service.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // Fail silently for favorites
      print('Failed to get favorite services: ${e.toString()}');
      return [];
    }
  }

  static Future<void> toggleFavoriteService(String serviceId) async {
    try {
      await ApiService.post('/users/favorites/$serviceId', {});
    } catch (e) {
      throw Exception('Failed to toggle favorite: ${e.toString()}');
    }
  }

  // ==================== VOUCHER OPERATIONS ====================

  static Future<bool> applyVoucher(String voucherId, String userId) async {
    try {
      final response = await ApiService.post('/vouchers/apply', {
        'voucherId': voucherId,
        'userId': userId,
      });
      return response['success'] == true;
    } catch (e) {
      print('Failed to apply voucher: ${e.toString()}');
      return false;
    }
  }

  static Future<bool> saveVoucherForUser(String voucherId) async {
    try {
      final response = await ApiService.post('/user-vouchers', {
        'voucherId': voucherId,
      });
      return response['success'] == true;
    } catch (e) {
      print('Failed to save voucher: ${e.toString()}');
      return false;
    }
  }
}
