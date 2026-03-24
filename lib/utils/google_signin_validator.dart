import 'package:flutter/foundation.dart';
import 'google_signin_config.dart';

class GoogleSignInValidator {
  /// Kiểm tra cấu hình Google Sign-In có đúng không
  static Map<String, dynamic> validateConfiguration() {
    Map<String, dynamic> result = {
      'isValid': true,
      'errors': <String>[],
      'warnings': <String>[],
      'info': <String>[],
    };

    // Kiểm tra package name
    if (GoogleSignInConfig.packageName.isEmpty) {
      result['isValid'] = false;
      result['errors'].add('Package name không được để trống');
    } else {
      result['info'].add('Package name: ${GoogleSignInConfig.packageName}');
    }

    // Kiểm tra App ID
    if (GoogleSignInConfig.appId.isEmpty) {
      result['isValid'] = false;
      result['errors'].add('App ID không được để trống');
    } else {
      result['info'].add('App ID: ${GoogleSignInConfig.appId}');
    }

    // Kiểm tra SHA-1 fingerprint
    if (GoogleSignInConfig.sha1Fingerprint.isEmpty) {
      result['isValid'] = false;
      result['errors'].add('SHA-1 fingerprint không được để trống');
    } else {
      result['info'].add('SHA-1: ${GoogleSignInConfig.sha1Fingerprint}');
    }

    // Kiểm tra client IDs
    if (GoogleSignInConfig.androidClientId.isEmpty) {
      result['isValid'] = false;
      result['errors'].add('Android Client ID không được để trống');
    }

    if (GoogleSignInConfig.webClientId.isEmpty) {
      result['warnings'].add('Web Client ID không được cấu hình');
    }

    if (GoogleSignInConfig.iosClientId.isEmpty) {
      result['warnings'].add('iOS Client ID không được cấu hình');
    }

    // Kiểm tra cấu hình cho platform hiện tại
    if (GoogleSignInConfig.isConfigured) {
      result['info'].add('Cấu hình cho platform hiện tại: OK');
      result['info'].add('Client ID hiện tại: ${GoogleSignInConfig.currentClientId}');
    } else {
      result['isValid'] = false;
      result['errors'].add('Cấu hình cho platform hiện tại không hợp lệ');
    }

    return result;
  }

  /// In thông tin cấu hình ra console
  static void printConfiguration() {
    print('=== GOOGLE SIGN-IN CONFIGURATION ===');
    print('Package Name: ${GoogleSignInConfig.packageName}');
    print('App ID: ${GoogleSignInConfig.appId}');
    print('SHA-1: ${GoogleSignInConfig.sha1Fingerprint}');
    print('Android Client ID: ${GoogleSignInConfig.androidClientId}');
    print('Web Client ID: ${GoogleSignInConfig.webClientId}');
    print('iOS Client ID: ${GoogleSignInConfig.iosClientId}');
    print('Current Platform: ${kIsWeb ? 'Web' : defaultTargetPlatform.name}');
    print('Current Client ID: ${GoogleSignInConfig.currentClientId}');
    print('Is Configured: ${GoogleSignInConfig.isConfigured}');
    print('=====================================');
  }

  /// Kiểm tra và in kết quả validation
  static void validateAndPrint() {
    final result = validateConfiguration();
    
    print('=== GOOGLE SIGN-IN VALIDATION ===');
    print('Status: ${result['isValid'] ? '✅ VALID' : '❌ INVALID'}');
    
    if (result['errors'].isNotEmpty) {
      print('\n❌ ERRORS:');
      for (String error in result['errors']) {
        print('  - $error');
      }
    }
    
    if (result['warnings'].isNotEmpty) {
      print('\n⚠️  WARNINGS:');
      for (String warning in result['warnings']) {
        print('  - $warning');
      }
    }
    
    if (result['info'].isNotEmpty) {
      print('\nℹ️  INFO:');
      for (String info in result['info']) {
        print('  - $info');
      }
    }
    
    print('==================================');
  }
}

