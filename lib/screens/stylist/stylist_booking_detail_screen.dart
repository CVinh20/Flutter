// lib/screens/stylist/stylist_booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../models/booking.dart';
import '../../services/firestore_service.dart';

class StylistBookingDetailScreen extends StatefulWidget {
  final Booking booking;

  const StylistBookingDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  State<StylistBookingDetailScreen> createState() => _StylistBookingDetailScreenState();
}

class _StylistBookingDetailScreenState extends State<StylistBookingDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _notesController = TextEditingController();
  
  Booking? _currentBooking;
  bool _isCheckedIn = false;
  String _serviceStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _isCheckedIn = widget.booking.checkInTime != null;
    _serviceStatus = widget.booking.serviceStatus ?? 'pending';
    _notesController.text = widget.booking.stylistNotes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Format số tiền theo định dạng Việt Nam
  String _formatCurrency(double amount) {
    // Format số với dấu chấm phân cách hàng nghìn, không có số thập phân
    // Ví dụ: 50000 -> 50.000đ, 500000 -> 500.000đ
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckedIn) {
      EasyLoading.showInfo('Khách hàng đã được check-in');
      return;
    }

    try {
      await EasyLoading.show(status: 'Đang check-in...');
      await _firestoreService.checkInBooking(_currentBooking!.id);
      
      setState(() {
        _isCheckedIn = true;
        _currentBooking = _currentBooking!.copyWith(
          checkInTime: DateTime.now(),
        );
      });
      
      EasyLoading.dismiss();
      EasyLoading.showSuccess('Check-in thành công!');
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Lỗi: $e');
    }
  }

  Future<void> _updateServiceStatus(String status) async {
    // Kiểm tra xem có thể chuyển sang trạng thái mới không
    // Logic: pending → in_progress → completed (không thể quay lại)
    final currentStatus = _serviceStatus;
    
    // Nếu đã hoàn thành, không thể thay đổi
    if (currentStatus == 'completed') {
      EasyLoading.showInfo('Không thể thay đổi trạng thái sau khi đã hoàn thành');
      return;
    }
    
    // Nếu đang thực hiện, chỉ có thể chuyển sang completed (không thể quay lại pending)
    if (currentStatus == 'in_progress' && status == 'pending') {
      EasyLoading.showInfo('Không thể quay lại trạng thái "Chờ xử lý" sau khi đã bắt đầu thực hiện');
      return;
    }
    
    try {
      await EasyLoading.show(status: 'Đang cập nhật...');
      
      // Sử dụng updateBookingByStylist để đảm bảo consistency
      await _firestoreService.updateBookingByStylist(
        bookingId: _currentBooking!.id,
        serviceStatus: status,
      );
      
      setState(() {
        _serviceStatus = status;
        String newStatus = status == 'completed' 
            ? 'Đã hoàn tất' 
            : status == 'in_progress' 
                ? 'Đang thực hiện' 
                : _currentBooking!.status;
        _currentBooking = _currentBooking!.copyWith(
          serviceStatus: status,
          status: newStatus,
        );
      });
      
      EasyLoading.dismiss();
      EasyLoading.showSuccess('Cập nhật trạng thái thành công!');
    } catch (e) {
      EasyLoading.dismiss();
      
      // Xử lý lỗi cụ thể
      String errorMessage = 'Lỗi: $e';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Lỗi: Không có quyền cập nhật. Vui lòng kiểm tra lại quyền truy cập.';
      } else if (e.toString().contains('not-found')) {
        errorMessage = 'Lỗi: Không tìm thấy booking.';
      }
      
      EasyLoading.showError(errorMessage);
      
      // Log để debug
      print('Error updating service status: $e');
      print('Booking ID: ${_currentBooking!.id}');
      print('Service Status: $status');
    }
  }

  Future<void> _saveNotes() async {
    try {
      await EasyLoading.show(status: 'Đang lưu...');
      
      // Sử dụng updateBookingByStylist để đảm bảo consistency
      await _firestoreService.updateBookingByStylist(
        bookingId: _currentBooking!.id,
        stylistNotes: _notesController.text.trim(),
      );
      
      setState(() {
        _currentBooking = _currentBooking!.copyWith(
          stylistNotes: _notesController.text.trim(),
        );
      });
      
      EasyLoading.dismiss();
      EasyLoading.showSuccess('Lưu ghi chú thành công!');
      FocusScope.of(context).unfocus();
    } catch (e) {
      EasyLoading.dismiss();
      
      // Xử lý lỗi cụ thể
      String errorMessage = 'Lỗi: $e';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Lỗi: Không có quyền cập nhật. Vui lòng kiểm tra lại quyền truy cập.';
      } else if (e.toString().contains('not-found')) {
        errorMessage = 'Lỗi: Không tìm thấy booking.';
      }
      
      EasyLoading.showError(errorMessage);
      
      // Log để debug
      print('Error saving notes: $e');
      print('Booking ID: ${_currentBooking!.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm, dd/MM/yyyy', 'vi');
    final dateFormatTime = DateFormat('HH:mm', 'vi');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0891B2),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Chi tiết lịch hẹn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0891B2),
                      Color(0xFF06B6D4),
                      Color(0xFF22D3EE),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.content_cut_rounded,
                    size: 60,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerInfo(),
                  const SizedBox(height: 20),
                  _buildServiceInfo(),
                  const SizedBox(height: 20),
                  _buildDateTimeInfo(),
                  const SizedBox(height: 20),
                  _buildStatusSection(),
                  const SizedBox(height: 20),
                  _buildCheckInSection(),
                  const SizedBox(height: 20),
                  _buildServiceStatusSection(),
                  const SizedBox(height: 20),
                  _buildNotesSection(),
                  const SizedBox(height: 20),
                  _buildPaymentInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0891B2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF0891B2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin khách hàng',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentBooking!.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _currentBooking!.customerPhone,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.content_cut,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dịch vụ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentBooking!.service.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giá: ${_formatCurrency(_currentBooking!.amount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0891B2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeInfo() {
    final dateFormat = DateFormat('HH:mm, dd/MM/yyyy', 'vi');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.access_time,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thời gian',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(_currentBooking!.dateTime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.store,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chi nhánh',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentBooking!.branchName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    Color statusColor;
    IconData statusIcon;
    String statusText = _currentBooking!.status;

    if (_currentBooking!.serviceStatus == 'completed') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Đã hoàn tất';
    } else if (_currentBooking!.serviceStatus == 'in_progress') {
      statusColor = Colors.orange;
      statusIcon = Icons.access_time;
      statusText = 'Đang thực hiện';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.pending;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trạng thái',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.login,
                  color: _isCheckedIn ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Check-in',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isCheckedIn ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isCheckedIn && _currentBooking!.checkInTime != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Đã check-in lúc ${DateFormat('HH:mm, dd/MM/yyyy', 'vi').format(_currentBooking!.checkInTime!)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleCheckIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Check-in khách hàng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891B2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trạng thái dịch vụ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatusButton(
                    'Chờ xử lý',
                    'pending',
                    Icons.pending,
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusButton(
                    'Đang thực hiện',
                    'in_progress',
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusButton(
                    'Hoàn tất',
                    'completed',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, String status, IconData icon, Color color) {
    final isSelected = _serviceStatus == status;
    final currentStatus = _serviceStatus;
    
    // Xác định xem nút có bị disable không
    bool isDisabled = false;
    String? disabledReason;
    
    // Nếu đã hoàn thành, tất cả các nút khác đều bị disable
    if (currentStatus == 'completed') {
      isDisabled = status != 'completed';
      if (isDisabled) {
        disabledReason = 'Đã hoàn thành';
      }
    }
    // Nếu đang thực hiện, không thể quay lại pending
    else if (currentStatus == 'in_progress' && status == 'pending') {
      isDisabled = true;
      disabledReason = 'Không thể quay lại';
    }
    
    return InkWell(
      onTap: isDisabled ? null : () => _updateServiceStatus(status),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon, 
                color: isSelected ? color : (isDisabled ? Colors.grey[400] : Colors.grey), 
                size: 24
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : (isDisabled ? Colors.grey[400] : Colors.grey),
                ),
                textAlign: TextAlign.center,
              ),
              if (isDisabled && disabledReason != null) ...[
                const SizedBox(height: 2),
                Text(
                  disabledReason!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Color(0xFF0891B2)),
                const SizedBox(width: 8),
                const Text(
                  'Ghi chú của stylist',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ghi chú về kiểu tóc, sản phẩm sử dụng, yêu cầu đặc biệt...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveNotes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0891B2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Lưu ghi chú'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền:'),
                Text(
                  _formatCurrency(_currentBooking!.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0891B2),
                  ),
                ),
              ],
            ),
            if (_currentBooking!.isPaid) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Đã thanh toán',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.pending, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Chưa thanh toán',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_currentBooking!.paymentMethod != null) ...[
              const SizedBox(height: 8),
              Text(
                'Phương thức: ${_currentBooking!.paymentMethod}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

