// lib/services/category_service.dart
import '../models/category.dart';
import 'api_service.dart';

class CategoryService {
  // Get all categories
  Future<List<Category>> getAllCategories() async {
    try {
      // Get all categories (limit=100 to get all usually)
      final response = await ApiService.get('/categories?limit=100');
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load categories');
      }
    } catch (e) {
      print('Error getting categories: $e');
      rethrow;
    }
  }

  // Get single category
  Future<Category> getCategoryById(String id) async {
    try {
      final response = await ApiService.get('/categories/$id');
      
      if (response['success'] == true) {
        return Category.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to load category');
      }
    } catch (e) {
      print('Error getting category: $e');
      rethrow;
    }
  }

  // Create category
  Future<Category> createCategory(Category category) async {
    try {
      final response = await ApiService.post('/categories', {
        'name': category.name,
        // Add other fields if usage expands
      });
      
      if (response['success'] == true) {
        return Category.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to create category');
      }
    } catch (e) {
      print('Error creating category: $e');
      rethrow;
    }
  }

  // Update category
  Future<Category> updateCategory(String id, Category category) async {
    try {
      final response = await ApiService.put('/categories/$id', {
        'name': category.name,
      });
      
      if (response['success'] == true) {
        return Category.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to update category');
      }
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  // Delete category
  Future<void> deleteCategory(String id) async {
    try {
      final response = await ApiService.delete('/categories/$id');
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete category');
      }
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }
}
