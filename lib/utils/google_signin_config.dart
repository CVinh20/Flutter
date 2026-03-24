import 'package:flutter/foundation.dart';

class GoogleSignInConfig {
  static const String webClientId = '571999879235-mo6utir6lpt2ktf7tfpghfcneebi4f3o.apps.googleusercontent.com';
  static const String androidClientId = '571999879235-g83qcl9amq64o0s4itra1733srf66khe.apps.googleusercontent.com';
  static const String iosClientId = '571999879235-rs14boa1fqbcu78aosaevbva9m3qn9ke.apps.googleusercontent.com';
  
  // Thông tin cấu hình mới
  static const String packageName = 'com.doan.doanmonhoc';
  static const String appId = '1:571999879235:android:a216d06160162d89d394f6';
  static const String sha1Fingerprint = 'B4:DA:F9:97:B2:8B:BA:98:C3:F2:8F:62:E7:24:8B:67:CE:EB:B5:EB';
  
  /// Kiểm tra cấu hình Google Sign-In
  static bool get isConfigured {
    if (kIsWeb) {
      return webClientId.isNotEmpty;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return androidClientId.isNotEmpty;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosClientId.isNotEmpty;
    }
    return false;
  }
  
  /// Lấy client ID phù hợp với platform hiện tại
  static String get currentClientId {
    if (kIsWeb) {
      return webClientId;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return androidClientId;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosClientId;
    }
    return webClientId; // fallback
  }
}
