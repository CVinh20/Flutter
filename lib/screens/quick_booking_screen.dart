// lib/screens/quick_booking_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../models/service.dart';
import '../models/stylist.dart';
import '../models/branch.dart';
import '../models/category.dart';
import '../models/voucher.dart';
import '../services/firestore_service.dart';
import '../models/booking.dart';
import '../services/notification_service.dart';
import '../widgets/saved_vouchers_picker.dart';
import '../main.dart';

class QuickBookingScreen extends StatefulWidget {
  final Branch? preSelectedBranch;
  const QuickBookingScreen({super.key, this.preSelectedBranch});

  @override
  State<QuickBookingScreen> createState() => _QuickBookingScreenState();
}

class _QuickBookingScreenState extends State<QuickBookingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  Stylist? selectedStylist;
  Service? selectedService;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  Branch? selectedBranch;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _voucherController = TextEditingController();
  
  Voucher? _appliedVoucher;
  double _discount = 0.0;
  String? _voucherError;

  @override
  void initState() {
    super.initState();
    // Set pre-selected branch if provided
    if (widget.preSelectedBranch != null) {
      selectedBranch = widget.preSelectedBranch;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _voucherError = 'Vui lòng nhập mã voucher';
      });
      return;
    }

    if (selectedService == null) {
      setState(() {
        _voucherError = 'Vui lòng chọn dịch vụ trước';
      });
      return;
    }

    try {
      final voucher = await _firestoreService.getVoucherByCode(code);
      
      if (voucher == null) {
        setState(() {
          _voucherError = 'Mã voucher không tồn tại';
        });
        return;
      }

      if (!voucher.isValid) {
        setState(() {
          _voucherError = 'Mã voucher đã hết hạn hoặc không khả dụng';
        });
        return;
      }

      final orderValue = selectedService!.price;
      if (orderValue < voucher.minOrderValue) {
        setState(() {
          _voucherError = 'Đơn hàng tối thiểu ${voucher.minOrderValue.toStringAsFixed(0)}đ';
        });
        return;
      }

      final discount = voucher.calculateDiscount(orderValue);
      setState(() {
        _appliedVoucher = voucher;
        _discount = discount;
        _voucherError = null;
      });

      EasyLoading.showSuccess('Áp dụng voucher thành công! Giảm ${discount.toStringAsFixed(0)}đ');
    } catch (e) {
      setState(() {
        _voucherError = 'Lỗi khi áp dụng voucher';
      });
    }
  }

  void _removeVoucher() {
    setState(() {
      _appliedVoucher = null;
      _discount = 0.0;
      _voucherController.clear();
      _voucherError = null;
    });
  }

  void _resetForm() {
    setState(() {
      selectedStylist = null;
      selectedService = null;
      selectedDate = null;
      selectedTime = null;
      selectedBranch = null;
    });
  }

  Future<void> _confirmQuickBooking() async {
    if (selectedStylist == null ||
        selectedService == null ||
        selectedDate == null ||
        selectedTime == null ||
        selectedBranch == null ||
        _nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      EasyLoading.showInfo('Vui lòng điền đủ thông tin');
      return;
    }

    await EasyLoading.show(status: 'Đang xử lý...');

    Booking newBooking = Booking(
      id: '',
      service: selectedService!,
      stylist: selectedStylist!,
      dateTime: DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      ),
      status: 'Chờ xác nhận',
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      branchName: selectedBranch!.name,
      amount: _appliedVoucher != null ? selectedService!.price - _discount : selectedService!.price,
      isPaid: false,
      voucherCode: _appliedVoucher?.code,
      discount: _appliedVoucher != null ? _discount : null,
      originalAmount: _appliedVoucher != null ? selectedService!.price : null,
    );

    try {
      final createdBooking = await _firestoreService.addBooking(newBooking);
      await _notificationService.scheduleBookingNotification(createdBooking);
      
      // Nếu có voucher, cập nhật số lượng đã sử dụng
      if (_appliedVoucher != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestoreService.applyVoucher(_appliedVoucher!.id, user.uid);
        }
      }

      if (mounted) {
        EasyLoading.dismiss();
        
        // Show success message and navigate back to home
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đặt lịch thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        // Reset form after showing success message
        _resetForm();
        
        // Navigate back to home screen and switch to bookings tab
        Navigator.pop(context);
        // Add a small delay to ensure Navigator.pop is fully completed
        Future.delayed(Duration(milliseconds: 100), () {
          MainScreenState.navigateToBookings();
        });
      }
    } catch (e) {
      if (mounted) {
        EasyLoading.showError('Lỗi: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0891B2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0891B2), Color(0xFF06B6D4), Color(0xFF22D3EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Hero section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF06B6D4), Color(0xFF22D3EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0891B2).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đặt lịch nhanh',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chọn dịch vụ và thời gian phù hợp',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildFormSection(
                    title: 'Thông tin khách hàng',
                    child: _buildCustomerInfo(),
                  ),
                  const SizedBox(height: 20),
                  _buildFormSection(
                    title: 'Mã giảm giá',
                    child: _buildVoucherSection(),
                  ),
                  const SizedBox(height: 20),
                  _buildFormSection(
                    title: 'Chọn chi nhánh',
                    child: _buildSelectBranch(context),
                  ),
                  const SizedBox(height: 20),
                  _buildFormSection(
                    title: 'Chọn dịch vụ',
                    child: _buildSelectService(context),
                  ),
                  const SizedBox(height: 20),
                  _buildFormSection(
                    title: 'Chọn ngày, giờ & stylist',
                    child: _buildSelectDateTime(context),
                  ),
                  const SizedBox(height: 32),
                  // Enhanced confirm button
                  Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0891B2), Color(0xFF06B6D4), Color(0xFF22D3EE)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0891B2).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _confirmQuickBooking,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'CHỐT GIỜ CẮT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: 'Họ và tên',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.person_outline, color: const Color(0xFF0891B2)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF0891B2), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: 'Số điện thoại',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF0891B2)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF0891B2), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }

  Future<void> _showSavedVouchers() async {
    if (selectedService == null) {
      EasyLoading.showInfo('Vui lòng chọn dịch vụ trước');
      return;
    }

    final Voucher? picked = await showModalBottomSheet<Voucher>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SavedVouchersPicker(
        firestoreService: _firestoreService,
        orderValue: selectedService!.price,
      ),
    );
    
    if (picked != null) {
      setState(() {
        _voucherController.text = picked.code;
      });
      await _applyVoucher();
    }
  }

  Widget _buildVoucherSection() {
    final finalAmount = selectedService != null ? selectedService!.price - _discount : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Button to show saved vouchers - ALWAYS SHOW
        if (_appliedVoucher == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: _showSavedVouchers,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.bookmark, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Xem voucher đã lưu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Voucher input field with apply button
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _voucherController,
                decoration: InputDecoration(
                  hintText: 'Nhập mã voucher',
                  prefixIcon: const Icon(Icons.confirmation_number, color: Color(0xFF0891B2)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0891B2), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                textCapitalization: TextCapitalization.characters,
                enabled: _appliedVoucher == null,
              ),
            ),
            const SizedBox(width: 12),
            _appliedVoucher == null
                ? ElevatedButton(
                    onPressed: _applyVoucher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0891B2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                : IconButton(
                    onPressed: _removeVoucher,
                    icon: const Icon(Icons.close, color: Colors.red),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                    ),
                  ),
          ],
        ),
        
        // Error message
        if (_voucherError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _voucherError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        
        // Applied voucher info
        if (_appliedVoucher != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appliedVoucher!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Giảm ${_discount.toStringAsFixed(0)}đ',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Price summary
        if (selectedService != null) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Giá gốc:',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              Text(
                '${selectedService!.price.toStringAsFixed(0)}đ',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  decoration: _discount > 0 ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Giảm giá:',
                  style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
                ),
                Text(
                  '-${_discount.toStringAsFixed(0)}đ',
                  style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                '${finalAmount.toStringAsFixed(0)}đ',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0891B2),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSelectBranch(BuildContext context) {
    return _selectButton(
      icon: Icons.business_rounded,
      text: selectedBranch?.name ?? 'Chọn chi nhánh',
      isSelected: selectedBranch != null,
      onTap: () async {
        final Branch? picked = await showModalBottomSheet<Branch>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          enableDrag: false,
          builder: (context) => _BranchPicker(firestoreService: _firestoreService),
        );
        if (picked != null) setState(() => selectedBranch = picked);
      },
    );
  }

  Widget _buildSelectService(BuildContext context) {
    return _selectButton(
      icon: Icons.content_cut_rounded,
      text: selectedService?.name ?? 'Chọn dịch vụ',
      isSelected: selectedService != null,
      onTap: () async {
        final Service? picked = await showModalBottomSheet<Service>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          enableDrag: false,
          builder: (context) => _ServicePicker(firestoreService: _firestoreService),
        );
        if (picked != null) setState(() => selectedService = picked);
      },
    );
  }

  Widget _buildSelectDateTime(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _selectButton(
                icon: Icons.event_outlined,
                text: selectedDate == null
                    ? 'Chọn ngày'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                isSelected: selectedDate != null,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 60)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Color(0xFF0891B2),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _selectButton(
                icon: Icons.access_time,
                text: selectedTime == null
                    ? 'Chọn giờ'
                    : '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                isSelected: selectedTime != null,
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Color(0xFF0891B2),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => selectedTime = picked);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _selectButton(
          icon: Icons.person_outline,
          text: selectedStylist?.name ?? 'Chọn stylist',
          isSelected: selectedStylist != null,
          onTap: () async {
            final Stylist? picked = await showModalBottomSheet<Stylist>(
              context: context,
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              isScrollControlled: true,
              enableDrag: false,
              builder: (context) => _StylistPicker(firestoreService: _firestoreService),
            );
            if (picked != null) setState(() => selectedStylist = picked);
          },
        ),
      ],
    );
  }

  Widget _selectButton({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0891B2).withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0891B2) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0891B2) : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF0891B2) : const Color(0xFF64748B),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isSelected ? const Color(0xFF0891B2) : Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// --- PICKER WIDGETS ---

class _ServicePicker extends StatefulWidget {
  final FirestoreService firestoreService;
  const _ServicePicker({required this.firestoreService});

  @override
  State<_ServicePicker> createState() => _ServicePickerState();
}

class _ServicePickerState extends State<_ServicePicker> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Category> _categories = [];
  List<Service> _allServices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load categories
    widget.firestoreService.getCategories().listen((categories) {
      if (mounted) {
        setState(() {
          _categories = categories;
          _tabController = TabController(length: _categories.length + 1, vsync: this);
        });
      }
    });

    // Load services
    widget.firestoreService.getServices().listen((services) {
      if (mounted) {
        setState(() {
          _allServices = services;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 50,
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF0891B2).withOpacity(0.6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Chọn dịch vụ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            if (_categories.isNotEmpty) ...[
              SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Color(0xFF0891B2),
                labelColor: Color(0xFF0891B2),
                unselectedLabelColor: Colors.grey.shade600,
                tabs: [
                  Tab(text: 'Tất cả'),
                  ..._categories.map((category) => Tab(text: category.name)),
                ],
              ),
            ],
            SizedBox(height: 16),
            Expanded(
              child: _categories.isEmpty
                  ? StreamBuilder<List<Service>>(
                      stream: widget.firestoreService.getServices(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        return _buildServicesList(snapshot.data!, controller);
                      },
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildServicesList(_allServices, controller),
                        ..._categories.map((category) => 
                            _buildServicesList(_getServicesByCategory(category.id), controller)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList(List<Service> services, ScrollController controller) {
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build_circle_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có dịch vụ nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: services.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final s = services[index];
        return Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0891B2).withOpacity(0.1),
                      Color(0xFF0891B2).withOpacity(0.05),
                    ],
                  ),
                ),
                child: s.image.isNotEmpty
                    ? Image.network(
                        s.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.build_circle_outlined,
                          color: Color(0xFF0891B2),
                          size: 30,
                        ),
                      )
                    : Icon(
                        Icons.build_circle_outlined,
                        color: Color(0xFF0891B2),
                        size: 30,
                      ),
              ),
            ),
            title: Text(
              s.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Text(
                      s.duration,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  '${s.price.toStringAsFixed(0)}đ',
                  style: TextStyle(
                    color: Color(0xFF0891B2),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF0891B2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF0891B2),
              ),
            ),
            onTap: () => Navigator.pop(context, s),
          ),
        );
      },
    );
  }

  List<Service> _getServicesByCategory(String categoryId) {
    return _allServices.where((service) => service.categoryId == categoryId).toList();
  }
}

class _StylistPicker extends StatelessWidget {
  final FirestoreService firestoreService;
  const _StylistPicker({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, controller) => Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 50,
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF0891B2).withOpacity(0.6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Chọn stylist',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF0891B2),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Stylist>>(
                stream: firestoreService.getStylists(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final stylists = snapshot.data!;
                  return ListView.separated(
                    controller: controller,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: stylists.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final st = stylists[index];
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              st.image,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Color(0xFF0891B2).withOpacity(0.1),
                                child: Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF0891B2),
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            st.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                st.rating.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF0891B2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Color(0xFF0891B2),
                            ),
                          ),
                          onTap: () => Navigator.pop(context, st),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchPicker extends StatelessWidget {
  final FirestoreService firestoreService;
  const _BranchPicker({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 250, 248, 248),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, controller) => Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 50,
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF0891B2).withOpacity(0.6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Chọn chi nhánh',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF0891B2),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Branch>>(
                stream: firestoreService.getBranches(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final branches = snapshot.data!;
                  return ListView.separated(
                    controller: controller,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: branches.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              branch.image,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Color(0xFF0891B2).withOpacity(0.1),
                                child: Icon(
                                  Icons.business_rounded,
                                  color: Color(0xFF0891B2),
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            branch.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                branch.address,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF0891B2),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 14, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text(
                                    branch.rating.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF0891B2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Color(0xFF0891B2),
                            ),
                          ),
                          onTap: () => Navigator.pop(context, branch),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}