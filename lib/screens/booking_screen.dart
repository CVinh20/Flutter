// lib/screens/booking_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/service.dart';
import '../models/booking.dart';
import '../models/stylist.dart';
import '../models/branch.dart';
import '../models/voucher.dart';
import '../services/firestore_service.dart';
import '../widgets/saved_vouchers_picker.dart';
import '../main.dart';

class BookingScreen extends StatefulWidget {
  final Service? service;
  final Branch? initialBranch;
  
  const BookingScreen({
    super.key,
    this.service,
    this.initialBranch,
  });

  @override
  BookingScreenState createState() => BookingScreenState();
}

class BookingScreenState extends State<BookingScreen> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  Service? selectedService; // Thêm biến để lưu service được chọn
  Stylist? selectedStylist;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  Branch? selectedBranch;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _voucherController = TextEditingController();
  late AnimationController _controller;
  bool _isLoading = false;
  List<Service> _services = []; // Thêm danh sách services
  Voucher? _appliedVoucher;
  double _discount = 0.0;
  String? _voucherError;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    // Khởi tạo các giá trị từ widget
    selectedService = widget.service;
    selectedBranch = widget.initialBranch;

    // Lấy thông tin user
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }

    // Load danh sách services nếu chưa có service được chọn
    if (selectedService == null) {
      _loadServices();
    }
  }

  Future<void> _loadServices() async {
    try {
      _firestoreService.getServices().listen((services) {
        if (mounted) {
          setState(() {
            _services = services;
          });
        }
      });
    } catch (e) {
      print('Lỗi khi tải danh sách dịch vụ: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher(Service service) async {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _voucherError = 'Vui lòng nhập mã voucher';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _voucherError = null;
    });

    try {
      final voucher = await _firestoreService.getVoucherByCode(code);
      
      if (voucher == null) {
        setState(() {
          _voucherError = 'Mã voucher không tồn tại';
          _isLoading = false;
        });
        return;
      }

      if (!voucher.isValid) {
        setState(() {
          _voucherError = 'Mã voucher đã hết hạn hoặc không khả dụng';
          _isLoading = false;
        });
        return;
      }

      final orderValue = service.price;
      if (orderValue < voucher.minOrderValue) {
        setState(() {
          _voucherError = 'Đơn hàng tối thiểu ${voucher.minOrderValue.toStringAsFixed(0)}đ';
          _isLoading = false;
        });
        return;
      }

      final discount = voucher.calculateDiscount(orderValue);
      setState(() {
        _appliedVoucher = voucher;
        _discount = discount;
        _voucherError = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Áp dụng voucher thành công! Giảm ${discount.toStringAsFixed(0)}đ'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      setState(() {
        _voucherError = 'Lỗi khi áp dụng voucher';
        _isLoading = false;
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
  
  Future<void> _confirmBooking(Service service) async {
    if (selectedBranch == null || selectedStylist == null || selectedDate == null || selectedTime == null || 
        _nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    final newBooking = Booking(
      id: '',
      service: service,
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
      amount: _appliedVoucher != null ? service.price - _discount : service.price,
      isPaid: false,
      voucherCode: _appliedVoucher?.code,
      discount: _appliedVoucher != null ? _discount : null,
      originalAmount: _appliedVoucher != null ? service.price : null,
    );
    
    try {
      await _firestoreService.addBooking(newBooking);
      
      // Nếu có voucher, cập nhật số lượng đã sử dụng
      if (_appliedVoucher != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestoreService.applyVoucher(_appliedVoucher!.id, user.uid);
        }
      }
      
      if(mounted) {
        print('Booking created successfully, navigating...');
        
        // Show success message and navigate back to home
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đặt lịch thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        // Navigate back to home screen and switch to bookings tab
        Navigator.pop(context);
        print('Navigator.pop completed, calling navigateToBookings...');
        // Add a small delay to ensure Navigator.pop is fully completed
        Future.delayed(Duration(milliseconds: 100), () {
          MainScreenState.navigateToBookings();
          print('navigateToBookings called');
        });
      }
    } catch(e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ModalRoute.of(context)!.settings.arguments as Service;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF0891B2),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
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
                    Icons.calendar_month_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceInfo(service),
                    const SizedBox(height: 28),
                    
                    _buildSectionTitle('Thông tin khách hàng', Icons.person_outline),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Họ và tên',
                      icon: Icons.person_outline,
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    
                    SizedBox(height: 28),
                    _buildSectionTitle('Mã giảm giá', Icons.local_offer_outlined),
                    SizedBox(height: 16),
                    _buildVoucherSection(service),
                    
                    SizedBox(height: 28),
                    _buildSectionTitle('Chọn chi nhánh', Icons.business_rounded),
                    SizedBox(height: 16),
                    _buildBranchSelector(),
                    
                    SizedBox(height: 28),
                    _buildSectionTitle('Chọn stylist', Icons.person_pin_outlined),
                    SizedBox(height: 16),
                    _buildStylistSelector(),
                    
                    SizedBox(height: 28),
                    _buildSectionTitle('Chọn thời gian', Icons.access_time_outlined),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDatePicker(context)),
                        SizedBox(width: 12),
                        Expanded(child: _buildTimePicker(context)),
                      ],
                    ),
                    
                    SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0891B2),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFF0891B2).withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : () => _confirmBooking(service),
                        icon: _isLoading 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.check_circle_outline, size: 24),
                        label: Text(
                          _isLoading ? 'Đang xử lý...' : 'Xác nhận đặt lịch',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
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
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
      ],
    );
  }

  Widget _buildServiceInfo(Service service) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              service.image,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: const Color(0xFF0891B2)),
                    const SizedBox(width: 4),
                    Text(
                      service.duration,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${service.price.toStringAsFixed(0)}đ',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF0891B2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStylistSelector() {
    return StreamBuilder<List<Stylist>>(
      stream: _firestoreService.getStylists(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final stylists = snapshot.data!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selectedStylist != null ? const Color(0xFF0891B2) : Colors.grey.shade300,
              width: selectedStylist != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Stylist>(
              isExpanded: true,
              hint: Text('Chọn stylist của bạn', style: TextStyle(color: Colors.grey.shade500)),
              value: selectedStylist,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Color(0xFF1E293B)),
              onChanged: (val) => setState(() => selectedStylist = val),
              items: stylists.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          s.image,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey.shade800,
                            child: Icon(
                              Icons.person_outline,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  s.rating.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(Duration(days: 1)),
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
      child: _buildSelectBox(
        icon: Icons.calendar_today_rounded,
        text: selectedDate == null
            ? 'Chọn ngày'
            : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
        isSelected: selectedDate != null,
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: 9, minute: 0),
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
      child: _buildSelectBox(
        icon: Icons.access_time_rounded,
        text: selectedTime == null
            ? 'Chọn giờ'
            : '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}',
        isSelected: selectedTime != null,
      ),
    );
  }

  Widget _buildSelectBox({
    required IconData icon,
    required String text,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0891B2).withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isSelected ? const Color(0xFF0891B2) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF0891B2) : Colors.grey.shade500,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF0891B2) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: const Color(0xFF0891B2)),
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
    );
  }

  Future<void> _showSavedVouchers(Service service) async {
    final Voucher? picked = await showModalBottomSheet<Voucher>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SavedVouchersPicker(
        firestoreService: _firestoreService,
        orderValue: service.price,
      ),
    );
    
    if (picked != null) {
      setState(() {
        _voucherController.text = picked.code;
      });
      await _applyVoucher(service);
    }
  }

  Widget _buildVoucherSection(Service service) {
    final finalAmount = service.price - _discount;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Button to show saved vouchers
        if (_appliedVoucher == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _showSavedVouchers(service),
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
        
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0891B2).withOpacity(0.1),
                const Color(0xFF22D3EE).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0891B2).withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          onPressed: _isLoading ? null : () => _applyVoucher(service),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0891B2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    '${service.price.toStringAsFixed(0)}đ',
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
          ),
        ),
      ],
    );
  }

  Widget _buildBranchSelector() {
    return InkWell(
      onTap: () async {
        final Branch? picked = await showModalBottomSheet<Branch>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          enableDrag: false,
          builder: (context) => _BranchPicker(
            firestoreService: _firestoreService,
          ),
        );
        if (picked != null) setState(() => selectedBranch = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selectedBranch != null ? const Color(0xFF0891B2).withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedBranch != null ? const Color(0xFF0891B2) : Colors.grey.shade300,
            width: selectedBranch != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.business_rounded,
              color: selectedBranch != null ? const Color(0xFF0891B2) : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                selectedBranch?.name ?? 'Chọn chi nhánh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: selectedBranch != null ? const Color(0xFF0891B2) : const Color(0xFF64748B),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: selectedBranch != null ? const Color(0xFF0891B2) : Colors.grey.shade400,
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
        border: Border.all(color: Colors.grey.shade200),
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
                                      color: Color(0xFF64748B),
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