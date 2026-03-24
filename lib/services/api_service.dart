import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  static const String authTokenKey = 'auth_token';

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(authTokenKey);
  }

  // Store token
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(authTokenKey, token);
    print('💾 Token saved to SharedPreferences: ${token.substring(0, 20)}...');
  }

  // Remove token
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(authTokenKey);
  }

  // Get headers with auth token
  static Future<Map<String, String>> getHeaders({
    bool includeAuth = true,
  }) async {
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('🔑 Using token: ${token.substring(0, 20)}...');
      } else {
        print('! No token found in storage');
      }
    }

    return headers;
  }

  // Handle API response
  static Map<String, dynamic> handleResponse(http.Response response) {
    final body = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      if (response.statusCode == 401) {
        // Token không hợp lệ - chỉ xóa local, không gọi API logout để tránh loop
        print('! 401 Unauthorized - clearing local token');
        removeToken();
      }
      
      throw ApiException(
        message: body['message'] ?? body['error'] ?? 'Unknown error occurred',
        statusCode: response.statusCode,
        details: body['details'],
      );
    }
  }

  // GET request
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await getHeaders(includeAuth: includeAuth);
      print('🌐 GET $uri');
      print('📋 Headers: ${headers.keys.join(", ")}');
      
      final response = await http.get(uri, headers: headers);
      print('📥 Response: ${response.statusCode}');

      return handleResponse(response);
    } catch (e) {
      print('❌ GET Error: $e');
      rethrow;
    }
  }

  // POST request
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await getHeaders(includeAuth: includeAuth);
      print('🌐 POST $uri');
      print('📋 Headers: ${headers.keys.join(", ")}');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(data),
      );
      print('📥 Response: ${response.statusCode}');

      return handleResponse(response);
    } catch (e) {
      print('❌ POST Error: $e');
      rethrow;
    }
  }

  // PUT request
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await getHeaders(includeAuth: includeAuth);
      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(data),
      );

      return handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // PATCH request
  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await getHeaders(includeAuth: includeAuth);
      final response = await http.patch(
        uri,
        headers: headers,
        body: json.encode(data),
      );

      return handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // DELETE request
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await getHeaders(includeAuth: includeAuth);
      final response = await http.delete(uri, headers: headers);

      return handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic details;

  ApiException({required this.message, required this.statusCode, this.details});

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }
}
