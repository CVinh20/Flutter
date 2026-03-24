// lib/services/momo_service.dart

class MomoService {
  // Thông tin tài khoản Momo
  static const String _phoneNumber = '0344091018'; 
  static const String _accountName = 'Nguyen Anh Khoi'; 
  

  static String generateDeepLink({
    required double amount,
    required String description,
  }) {
    final int amountInt = amount.toInt();

    return 'momo://transfer?phone=$_phoneNumber&amount=$amountInt&note=${Uri.encodeComponent(description)}';
  }
  
 
  static String generateQRData({
    required double amount,
    required String description,
  }) {
    final int amountInt = amount.toInt();
    // Format: PHONE|AMOUNT|NOTE
    return '$_phoneNumber|$amountInt|$description';
  }
  
  /// Generate payment description
  static String generateDescription(String bookingId, String customerName) {
    final shortId = bookingId.substring(bookingId.length - 8);
    return 'GG $shortId ${customerName.split(' ').last}';
  }
  
  /// Get Momo account info for display
  static Map<String, String> getMomoInfo() {
    return {
      'phoneNumber': _phoneNumber,
      'accountName': _accountName,
    };
  }
  
  /// Format số tiền VNĐ
  static String formatAmount(double amount) {
    return '${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}đ';
  }
}
