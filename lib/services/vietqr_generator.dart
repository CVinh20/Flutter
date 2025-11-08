import 'package:flutter/foundation.dart';

class VietQRGenerator {
  // Thông tin tài khoản test
  static const String BANK_ID = "MBBANK"; // Theo chuẩn VietQR
  static const String ACCOUNT_NO = "0344091018";
  static const String ACCOUNT_NAME = "Nguyen Anh Khoi";

  /// Generates a VietQR image URL.
  static String generateImageUrl({
    required String amount,
    required String addInfo, // Transfer content, e.g., booking ID
  }) {
    try {
      // Chuẩn hóa amount
      final sanitizedAmount = amount.replaceAll(RegExp(r'[^0-9]'), '');
      if (sanitizedAmount.isEmpty) {
        throw Exception('Số tiền không hợp lệ');
      }

      // URL-encode the additional info (transfer content)
      final encodedAddInfo = Uri.encodeComponent(addInfo);

      // Create the URL
      final qrUrl =
          'https://api.vietqr.io/image/$BANK_ID-$ACCOUNT_NO-compact.png?amount=$sanitizedAmount&addInfo=$encodedAddInfo&accountName=$ACCOUNT_NAME';

      if (kDebugMode) {
        print('VietQR URL Generated: $qrUrl');
      }

      return qrUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating VietQR URL: $e');
      }
      rethrow; // Re-throw the exception to be handled by the UI
    }
  }

  // Thông tin tài khoản test (giữ lại để tương thích với các phần khác nếu cần)
  static const String TEST_ACCOUNT = ACCOUNT_NO;
  static const String TEST_NAME = ACCOUNT_NAME;
}