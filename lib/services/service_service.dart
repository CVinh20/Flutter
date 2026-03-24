// lib/services/service_service.dart
import '../models/service.dart';
import 'api_service.dart';

class ServiceService {
  // Get all services
  Future<List<Service>> getAllServices({
    String? categoryId,
    bool? isFeatured,
    String? search,
    String? sortBy,
  }) async {
    try {
      String url = '/services?';
      if (categoryId != null) url += 'categoryId=$categoryId&';
      if (isFeatured != null) url += 'isFeatured=$isFeatured&';
      if (search != null) url += 'search=$search&';
      if (sortBy != null) url += 'sortBy=$sortBy&';
      
      final response = await ApiService.get(url);
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Service.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load services');
      }
    } catch (e) {
      print('Error getting services: $e');
      rethrow;
    }
  }

  // Get single service
  Future<Service> getServiceById(String id) async {
    try {
      final response = await ApiService.get('/services/$id');
      
      if (response['success'] == true) {
        return Service.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to load service');
      }
    } catch (e) {
      print('Error getting service: $e');
      rethrow;
    }
  }

  // Create service
  Future<Service> createService(Service service) async {
    try {
      final response = await ApiService.post('/services', {
        'name': service.name,
        'categoryId': service.categoryId,
        'duration': service.duration,
        'price': service.price,
        'image': service.image,
        'description': '', // Add if needed
        'rating': service.rating,
      });
      
      if (response['success'] == true) {
        return Service.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to create service');
      }
    } catch (e) {
      print('Error creating service: $e');
      rethrow;
    }
  }

  // Update service
  Future<Service> updateService(String id, Service service) async {
    try {
      final response = await ApiService.put('/services/$id', {
        'name': service.name,
        'categoryId': service.categoryId,
        'duration': service.duration,
        'price': service.price,
        'image': service.image,
        'rating': service.rating,
      });
      
      if (response['success'] == true) {
        return Service.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to update service');
      }
    } catch (e) {
      print('Error updating service: $e');
      rethrow;
    }
  }

  // Delete service
  Future<void> deleteService(String id) async {
    try {
      final response = await ApiService.delete('/services/$id');
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete service');
      }
    } catch (e) {
      print('Error deleting service: $e');
      rethrow;
    }
  }

  // Get featured services
  Future<List<Service>> getFeaturedServices() async {
    try {
      final response = await ApiService.get('/services?isFeatured=true');
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Service.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load featured services');
      }
    } catch (e) {
      print('Error getting featured services: $e');
      rethrow;
    }
  }
}
