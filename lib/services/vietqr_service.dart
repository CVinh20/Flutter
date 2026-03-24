// lib/services/vietqr_service.dart
import 'dart:convert';

class VietQRService {
  // VietQR API generates QR code for bank transfer
  // Format: https://img.vietqr.io/image/[BANK]-[ACCOUNT_NUMBER]-[TEMPLATE].png?amount=[AMOUNT]&addInfo=[DESCRIPTION]
  
  static const String _bankId = 'MB'; // Vietcombank - Thay bằng ngân hàng thực tế
  static const String _accountNumber = '0344091018'; // Thay bằng số tài khoản thực tế
  static const String _accountName = 'Nguyen Anh Khoi'; // Tên tài khoản
  static const String _template = 'compact2'; // compact, compact2, print, qr_only
  
  /// Generate VietQR URL
  /// 
  /// [amount] - Số tiền thanh toán
  /// [description] - Nội dung chuyển khoản
  /// [orderId] - Mã đơn hàng để tracking
  static String generateQRUrl({
    required double amount,
    required String description,
    String? orderId,
  }) {
    final int amountInt = amount.toInt();
    final String encodedDescription = Uri.encodeComponent(description);
    
    final String url = 'https://img.vietqr.io/image/'
        '$_bankId-$_accountNumber-$_template.png'
        '?amount=$amountInt'
        '&addInfo=$encodedDescription'
        '${orderId != null ? '&accountName=$_accountName' : ''}';
    
    return url;
  }
  
  /// Generate payment description
  static String generateDescription(String bookingId, String customerName) {
    // Giới hạn 25 ký tự cho nội dung chuyển khoản
    final shortId = bookingId.substring(bookingId.length - 8);
    return 'GG $shortId ${customerName.split(' ').last}';
  }
  
  /// Get bank info for display
  static Map<String, String> getBankInfo() {
    return {
      'bankName': 'MBBank',
      'accountNumber': _accountNumber,
      'accountName': _accountName,
    };
  }
}
