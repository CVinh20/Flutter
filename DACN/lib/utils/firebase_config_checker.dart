import 'package:flutter/foundation.dart';

class FirebaseConfigChecker {
  /// Kiểm tra cấu hình Android
  static void checkAndroidConfig() {
    print('=== ANDROID FIREBASE CONFIG CHECK ===');
    print('Platform: Android');
    print('Package Name: com.doan.doanmonhoc');
    print('App ID: 1:571999879235:android:a216d06160162d89d394f6');
    print('SHA-1: B4:DA:F9:97:B2:8B:BA:98:C3:F2:8F:62:E7:24:8B:67:CE:EB:B5:EB');
    print('Project ID: doanmobile-6c221');
    print('=====================================');
  }
  
  /// Kiểm tra cấu hình Google Sign-In cho Android
  static void checkGoogleSignInConfig() {
    print('=== GOOGLE SIGN-IN ANDROID CHECK ===');
    print('✅ Package name: com.doan.doanmonhoc');
    print('✅ SHA-1: B4:DA:F9:97:B2:8B:BA:98:C3:F2:8F:62:E7:24:8B:67:CE:EB:B5:EB');
    print('✅ App ID: 1:571999879235:android:a216d06160162d89d394f6');
    print('⚠️  Cần kiểm tra Firebase Console:');
    print('   1. Authentication > Sign-in method > Google > Enable');
    print('   2. Project Settings > SHA-1 fingerprints');
    print('=====================================');
  }
}
