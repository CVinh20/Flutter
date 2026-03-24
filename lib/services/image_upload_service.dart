import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'api_service.dart';

class ImageUploadService {
  static const String baseUrl = ApiService.baseUrl;

  /// Upload single image file to server
  static Future<String> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/upload/image');
      final request = http.MultipartRequest('POST', uri);

      // Get file extension
      final ext = imageFile.path.split('.').last.toLowerCase();
      final contentType = _getContentType(ext);

      // Add image file
      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: imageFile.path.split('/').last,
        contentType: contentType,
      );
      request.files.add(multipartFile);

      // Send request
      print('📤 Uploading image: ${imageFile.path}');
      print('📝 Content-Type: $contentType');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        final imageUrl = jsonResponse['url'];
        print('✅ Image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Upload failed: ${jsonResponse['message']}');
        throw Exception(jsonResponse['message'] ?? 'Upload failed');
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  static MediaType _getContentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  /// Upload multiple images
  static Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    try {
      final uri = Uri.parse('$baseUrl/upload/images');
      final request = http.MultipartRequest('POST', uri);

      // Add all image files
      for (var imageFile in imageFiles) {
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();
        final multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      // Send request
      print('📤 Uploading ${imageFiles.length} images');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        final images = jsonResponse['images'] as List;
        final imageUrls = images.map((img) => img['url'] as String).toList();
        print('✅ Images uploaded successfully: ${imageUrls.length} files');
        return imageUrls;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Upload failed');
      }
    } catch (e) {
      print('❌ Error uploading images: $e');
      throw Exception('Failed to upload images: $e');
    }
  }

  /// Delete image from server
  static Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract filename from URL
      final filename = imageUrl.split('/').last;
      final uri = Uri.parse('$baseUrl/upload/image/$filename');

      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        print('✅ Image deleted successfully');
      } else {
        final jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['message'] ?? 'Delete failed');
      }
    } catch (e) {
      print('❌ Error deleting image: $e');
      throw Exception('Failed to delete image: $e');
    }
  }
}
