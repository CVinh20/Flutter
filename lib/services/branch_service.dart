// lib/services/branch_service.dart
import '../models/branch.dart';
import 'api_service.dart';

class BranchService {
  // Get all branches
  Future<List<Branch>> getAllBranches() async {
    try {
      final response = await ApiService.get('/branches');
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Branch.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load branches');
      }
    } catch (e) {
      print('Error getting branches: $e');
      rethrow;
    }
  }

  // Get single branch
  Future<Branch> getBranchById(String id) async {
    try {
      final response = await ApiService.get('/branches/$id');
      
      if (response['success'] == true) {
        return Branch.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to load branch');
      }
    } catch (e) {
      print('Error getting branch: $e');
      rethrow;
    }
  }

  // Create branch
  Future<Branch> createBranch(Branch branch) async {
    try {
      final response = await ApiService.post('/branches', {
        'name': branch.name,
        'address': branch.address,
        'hours': branch.hours,
        'image': branch.image,
        'latitude': branch.latitude,
        'longitude': branch.longitude,
        'rating': branch.rating,
      });
      
      if (response['success'] == true) {
        return Branch.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to create branch');
      }
    } catch (e) {
      print('Error creating branch: $e');
      rethrow;
    }
  }

  // Update branch
  Future<Branch> updateBranch(String id, Branch branch) async {
    try {
      final response = await ApiService.put('/branches/$id', {
        'name': branch.name,
        'address': branch.address,
        'hours': branch.hours,
        'image': branch.image,
        'latitude': branch.latitude,
        'longitude': branch.longitude,
        'rating': branch.rating,
      });
      
      if (response['success'] == true) {
        return Branch.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to update branch');
      }
    } catch (e) {
      print('Error updating branch: $e');
      rethrow;
    }
  }

  // Delete branch
  Future<void> deleteBranch(String id) async {
    try {
      final response = await ApiService.delete('/branches/$id');
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete branch');
      }
    } catch (e) {
      print('Error deleting branch: $e');
      rethrow;
    }
  }

  // Get nearby branches
  Future<List<Branch>> getNearbyBranches({
    required double latitude,
    required double longitude,
    double maxDistance = 10000,
  }) async {
    try {
      final response = await ApiService.get(
        '/branches/nearby?latitude=$latitude&longitude=$longitude&maxDistance=$maxDistance',
      );
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Branch.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load nearby branches');
      }
    } catch (e) {
      print('Error getting nearby branches: $e');
      rethrow;
    }
  }
}
