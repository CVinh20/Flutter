// lib/screens/admin/manage_bookings_screen.dart
import 'package:flutter/material.dart';
import 'admin_ui.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import '../../services/vietqr_service.dart';
import '../../services/momo_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  String _selectedStatus = 'Tất cả';
  Future<List<Booking>>? _bookingsFuture;

  final List<String> _statusOptions = [
    'Tất cả',
    'Chờ xử lý',
    'Hoàn thành',
    'Đã hủy',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _bookingsFuture = _fetchBookings();
    });
    await _bookingsFuture;
  }

  Future<List<Booking>> _fetchBookings() async {
    final resp = await ApiService.get(
      '/bookings',
      queryParams: {'limit': '200'},
    );
    if (resp['success'] == true) {
      final List<dynamic> data = resp['data'] ?? [];
      return data
          .map((e) => Booking.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await ApiService.put('/bookings/$bookingId', {'status': newStatus});
      await _loadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật trạng thái thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _updatePaymentStatus(String bookingId, bool isPaid) async {
    try {
      // Khi thanh toán xong, tự động chuyển status sang Hoàn tất
      final updateData = isPaid 
        ? {'isPaid': true, 'status': 'Hoàn tất'}
        : {'isPaid': false};
      
      await ApiService.put('/bookings/$bookingId', updateData);
      await _loadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPaid ? 'Đã thanh toán và hoàn thành đơn!' : 'Đánh dấu chưa thanh toán!'),
          backgroundColor: isPaid ? const Color(0xFF43A047) : const Color(0xFFFB8C00),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _showPaymentDialog(String bookingId, double amount, String customerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: const Text(
          'Chọn phương thức thanh toán',
          style: TextStyle(
            color: AdminColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaymentOption(
              icon: Icons.money,
              title: 'Tiền mặt',
              subtitle: 'Thanh toán bằng tiền mặt',
              color: Colors.green,
              onTap: () async {
                Navigator.pop(context);
                await _updatePaymentStatus(bookingId, true);
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              icon: Icons.qr_code,
              title: 'Chuyển khoản ngân hàng',
              subtitle: 'Quét mã VietQR',
              color: const Color(0xFF0891B2),
              onTap: () {
                Navigator.pop(context);
                _showVietQRDialog(bookingId, amount, customerName);
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              icon: Icons.wallet,
              title: 'Ví điện tử Momo',
              subtitle: 'Quét mã Momo',
              color: const Color(0xFFD82D8B),
              onTap: () {
                Navigator.pop(context);
                _showMomoDialog(bookingId, amount, customerName);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đóng',
              style: TextStyle(color: AdminColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AdminColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _showVietQRDialog(String bookingId, double amount, String customerName) {
    final description = VietQRService.generateDescription(bookingId, customerName);
    final qrUrl = VietQRService.generateQRUrl(
      amount: amount,
      description: description,
      orderId: bookingId,
    );
    final bankInfo = VietQRService.getBankInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.surface,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0891B2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      color: Color(0xFF0891B2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Quét mã VietQR',
                    style: TextStyle(color: AdminColors.textPrimary),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Real QR Code using VietQR API
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              qrUrl,
                              width: 250,
                              height: 250,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 250,
                                  height: 250,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Không thể tải QR code', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Số tiền: ${amount.toStringAsFixed(0)}đ',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Ngân hàng:', style: TextStyle(color: Colors.black54)),
                                    Text(
                                      bankInfo['bankName']!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Số TK:', style: TextStyle(color: Colors.black54)),
                                    Text(
                                      bankInfo['accountNumber']!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Chủ TK:', style: TextStyle(color: Colors.black54)),
                                    Text(
                                      bankInfo['accountName']!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Nội dung:', style: TextStyle(color: Colors.black54)),
                                    Text(
                                      description,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Quét mã QR bằng ứng dụng ngân hàng để thanh toán',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updatePaymentStatus(bookingId, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xác nhận đã thanh toán'),
                ),
              ],
            ),
          );
  }

  void _showMomoDialog(String bookingId, double amount, String customerName) {
    final description = MomoService.generateDescription(bookingId, customerName);
    final qrData = MomoService.generateQRData(
      amount: amount,
      description: description,
    );
    final momoInfo = MomoService.getMomoInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.surface,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD82D8B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.wallet,
                      color: Color(0xFFD82D8B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Thanh toán Momo',
                    style: TextStyle(color: AdminColors.textPrimary),
                  ),
                ],
              ),
              content: SizedBox(
                width: 350,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Real QR Code for Momo
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD82D8B), width: 2),
                              ),
                              child: SizedBox(
                                width: 220,
                                height: 220,
                                child: QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: 220,
                                  backgroundColor: Colors.white,
                                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              MomoService.formatAmount(amount),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD82D8B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('SĐT Momo:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                      Text(
                                        momoInfo['phoneNumber']!,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Chủ tài khoản:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                      Flexible(
                                        child: Text(
                                          momoInfo['accountName']!,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Nội dung:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                      Flexible(
                                        child: Text(
                                          description,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD82D8B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Cách thanh toán:',
                              style: TextStyle(
                                color: Color(0xFFD82D8B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Quét mã QR bằng app Momo hoặc nhấn nút "Mở Momo" để chuyển tiền nhanh hơn',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFD82D8B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD82D8B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Cách thanh toán:',
                              style: TextStyle(
                                color: Color(0xFFD82D8B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Quét mã QR bằng app Momo hoặc nhấn nút "Mở Momo" để chuyển tiền nhanh hơn',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFD82D8B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final deepLink = MomoService.generateDeepLink(
                      amount: amount,
                      description: description,
                    );
                    final uri = Uri.parse(deepLink);
                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không thể mở app Momo. Vui lòng quét mã QR.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Mở Momo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD82D8B),
                    side: const BorderSide(color: Color(0xFFD82D8B)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updatePaymentStatus(bookingId, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD82D8B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xác nhận đã thanh toán'),
                ),
              ],
            ),
          );
  }

  Future<void> _deleteBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa đơn đặt lịch này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.delete('/bookings/$bookingId');
        await _loadBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa đơn đặt lịch thành công!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    IconData icon;
    
    switch (status) {
      case 'Chờ xử lý':
      case 'pending':
      case 'Chờ xác nhận':
      case 'Đã xác nhận':
      case 'Đang thực hiện':
        backgroundColor = const Color(0xFFFFA726); // Orange 400
        icon = Icons.schedule;
        status = 'Chờ xử lý'; // Chuẩn hóa hiển thị
        break;
      case 'Hoàn thành':
      case 'completed':
        backgroundColor = const Color(0xFF66BB6A); // Green 400
        icon = Icons.check_circle;
        status = 'Hoàn thành';
        break;
      case 'Đã hủy':
      case 'cancelled':
        backgroundColor = const Color(0xFFEF5350); // Red 400
        icon = Icons.cancel;
        status = 'Đã hủy';
        break;
      default:
        backgroundColor = const Color(0xFF9E9E9E); // Grey 500
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: backgroundColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: backgroundColor),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: backgroundColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    final dateTime = booking.dateTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: Text(
          'Chi tiết đơn #${booking.id.substring(0, 8)}',
          style: const TextStyle(color: AdminColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Khách hàng', booking.customerName),
              _detailRow('SĐT', booking.customerPhone),
              _detailRow('Chi nhánh', booking.branchName),
              _detailRow('Dịch vụ', booking.service.name),
              _detailRow('Stylist', booking.stylist.name),
              _detailRow('Thời gian', dateTime.toString().substring(0, 16)),
              _detailRow('Trạng thái', booking.status),
              _detailRow('Ghi chú', booking.note.isEmpty ? '—' : booking.note),
              const SizedBox(height: 8),
              _detailRow(
                'Số tiền',
                NumberFormat.currency(
                  locale: 'vi_VN',
                  symbol: 'đ',
                ).format(booking.amount),
              ),
              _detailRow('PT thanh toán', booking.paymentMethod ?? 'Chưa chọn'),
              _detailRow(
                'TT thanh toán',
                booking.isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đóng',
              style: TextStyle(color: AdminColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AdminColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AdminColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // Payment flow omitted in Mongo admin view; only status updates are supported.

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Quản lý đơn đặt lịch',
      // FAB tạm ẩn vì API yêu cầu nhiều trường bắt buộc khi tạo mới
      floatingActionButton: null,
      body: Column(
        children: [
          // Filter
          AdminSection(
            title: 'Bộ lọc',
            child: Row(
              children: [
                const Text(
                  'Lọc theo trạng thái:',
                  style: TextStyle(
                    color: AdminColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      dropdownColor: AdminColors.surface,
                      style: const TextStyle(color: AdminColors.textPrimary),
                      underline: const SizedBox(),
                      items: _statusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStatus = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadBookings,
              child: FutureBuilder<List<Booking>>(
                future: _bookingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }

                  final bookings = snapshot.data ?? [];
                  final filtered = _selectedStatus == 'Tất cả'
                      ? bookings
                      : bookings.where((b) {
                          // Map backend status to display status
                          String displayStatus;
                          switch (b.status.toLowerCase()) {
                            case 'pending':
                            case 'confirmed':
                            case 'in_progress':
                            case 'chờ xác nhận':
                            case 'đã xác nhận':
                            case 'đang thực hiện':
                              displayStatus = 'Chờ xử lý';
                              break;
                            case 'completed':
                            case 'hoàn thành':
                              displayStatus = 'Hoàn thành';
                              break;
                            case 'cancelled':
                            case 'đã hủy':
                              displayStatus = 'Đã hủy';
                              break;
                            default:
                              displayStatus = b.status;
                          }
                          return displayStatus == _selectedStatus;
                        }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có đơn đặt lịch nào',
                        style: TextStyle(color: AdminColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final booking = filtered[index];

                      return AdminCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Đơn #${booking.id.substring(0, 8)}',
                                      style: const TextStyle(
                                        color: AdminColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  _buildStatusChip(booking.status),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: AdminColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      booking.customerName,
                                      style: const TextStyle(
                                        color: AdminColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: AdminColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      booking.customerPhone,
                                      style: const TextStyle(
                                        color: AdminColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.store,
                                    size: 16,
                                    color: AdminColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      booking.branchName,
                                      style: const TextStyle(
                                        color: AdminColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: AdminColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      booking.dateTime.toString().substring(
                                        0,
                                        16,
                                      ),
                                      style: const TextStyle(
                                        color: AdminColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (booking.note.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.note,
                                      size: 16,
                                      color: AdminColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        booking.note,
                                        style: const TextStyle(
                                          color: AdminColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: AdminPrimaryButton(
                                      label: 'Chi tiết',
                                      icon: Icons.visibility,
                                      onPressed: () =>
                                          _showBookingDetails(booking),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AdminPrimaryButton(
                                      label: 'Trạng thái',
                                      icon: Icons.sync,
                                      onPressed: () => _showStatusDialog(
                                        booking.id,
                                        booking.status,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: booking.isPaid
                                          ? null
                                          : () => _showPaymentDialog(
                                                booking.id,
                                                booking.amount,
                                                booking.customerName,
                                              ),
                                      icon: const Icon(
                                        Icons.payment,
                                        size: 18,
                                      ),
                                      label: const Text('Thanh toán'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: Colors.grey,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AdminDangerButton(
                                      label: 'Xóa',
                                      icon: Icons.delete,
                                      onPressed: () =>
                                          _deleteBooking(booking.id),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(String bookingId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: const Text(
          'Cập nhật trạng thái',
          style: TextStyle(color: AdminColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn trạng thái mới:'),
            const SizedBox(height: 16),
            ..._statusOptions.where((status) => status != 'Tất cả').map((
              status,
            ) {
              return RadioListTile<String>(
                title: Text(status),
                value: status,
                groupValue: currentStatus,
                onChanged: (value) {
                  if (value != null) {
                    _updateBookingStatus(bookingId, value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AdminColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
