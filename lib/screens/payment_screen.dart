import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/data_service.dart';
import '../services/vietqr_generator.dart';
import '../main.dart';
import 'package:intl/intl.dart'; // Added for NumberFormat

class PaymentScreen extends StatefulWidget {
  final Booking booking;

  const PaymentScreen({Key? key, required this.booking}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final DataService _dataService = DataService();
  // Không cần _selectedPaymentMethod vì luôn là VietQR

  Widget _buildVietQRSection() {
    try {
      // Format số tiền thành chuỗi số nguyên
      final amount = widget.booking.service.price.toStringAsFixed(0);

      // Tạo URL hình ảnh VietQR
      final qrImageUrl = VietQRGenerator.generateImageUrl(
        amount: amount,
        addInfo: 'DH${widget.booking.id}',
      );

      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // QR Code
            Container(
              width: 250, // Đặt kích thước cố định
              height: 250,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Image.network(
                // Sử dụng Image.network để hiển thị QR từ URL
                qrImageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Lỗi tải mã QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),

            // Thông tin thanh toán
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildPaymentInfo(
                    'Ngân hàng:',
                    'MB Bank', // Giữ nguyên hoặc có thể lấy từ config
                    Icons.account_balance,
                  ),
                  Divider(height: 16),
                  _buildPaymentInfo(
                    'Số tài khoản:',
                    VietQRGenerator.ACCOUNT_NO, // Sử dụng hằng số mới
                    Icons.credit_card,
                  ),
                  Divider(height: 16),
                  _buildPaymentInfo(
                    'Chủ tài khoản:',
                    VietQRGenerator.ACCOUNT_NAME, // Sử dụng hằng số mới
                    Icons.person,
                  ),
                  Divider(height: 16),
                  _buildPaymentInfo(
                    'Số tiền:',
                    '${widget.booking.service.price.toStringAsFixed(0)}đ',
                    Icons.monetization_on,
                  ),
                  Divider(height: 16),
                  _buildPaymentInfo(
                    'Nội dung CK:',
                    'DH${widget.booking.id}',
                    Icons.message,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vui lòng mở ứng dụng ngân hàng và quét mã QR để thanh toán',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Không thể tạo mã QR:\n$e',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPaymentInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Spacer(),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Future<void> _confirmPayment() async {
    // Cập nhật trạng thái booking với phương thức VietQR
    final updatedBooking = widget.booking.copyWith(
      paymentMethod: 'vietqr', // Luôn là VietQR
      status: 'Đã xác nhận', // Hoặc 'Chờ xác nhận' nếu cần admin duyệt
    );

    try {
      // Nếu booking chưa có ID (chưa được tạo trên Firestore), tạo mới
      if (widget.booking.id.isEmpty) {
        await _dataService.createBooking(updatedBooking);
      } else {
        // Nếu đã có ID, cập nhật
        await _dataService.updateBooking(updatedBooking.id, updatedBooking.toJson());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Thanh toán thành công! Lịch hẹn đã được xác nhận.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Đợi một chút để người dùng thấy thông báo
        await Future.delayed(Duration(milliseconds: 500));

        // Quay về màn hình chính và chuyển sang tab My Bookings
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Đợi một chút để animation hoàn tất
        await Future.delayed(Duration(milliseconds: 100));

        if (!mounted) return;
        // Chuyển sang tab My Bookings
        MainScreenState.navigateToBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xác nhận thanh toán: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán Online'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Section số tiền
            Container(
              margin: EdgeInsets.only(bottom: 20),
              padding: EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: Colors.green.shade700,
                    size: 32,
                  ),
                  SizedBox(width: 16),
                  Text(
                    NumberFormat.currency(
                      symbol: 'đ',
                    ).format(widget.booking.service.price),
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
            ),
            _buildVietQRSection(),
            SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _confirmPayment,
          child: Text(
            'Tôi đã thanh toán',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0891B2),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
