// lib/screens/stylist/stylist_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/booking.dart';
import '../../models/stylist.dart';
import '../../services/firestore_service.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../screens/login_screen.dart';
import 'stylist_booking_detail_screen.dart';

class StylistDashboardScreen extends StatefulWidget {
  const StylistDashboardScreen({super.key});

  @override
  State<StylistDashboardScreen> createState() => _StylistDashboardScreenState();
}

class _StylistDashboardScreenState extends State<StylistDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _stylistId;
  Stylist? _stylist;
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'day'; // 'day' or 'week'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStylistInfo();
  }

  Future<void> _loadStylistInfo() async {
    try {
      final user = await _adminService.getCurrentUser();
      if (user?.stylistId != null) {
        setState(() {
          _stylistId = user!.stylistId;
        });
        
        // Lấy thông tin stylist
        try {
          final stylists = await _firestoreService.getStylists().first;
          final stylist = stylists.firstWhere(
            (s) => s.id == _stylistId,
          );
          setState(() {
            _stylist = stylist;
            _isLoading = false;
          });
        } catch (e) {
          print('Error loading stylist: $e');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stylist info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime get _startDate {
    if (_viewMode == 'day') {
      return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    } else {
      // Start of week (Monday)
      final weekday = _selectedDate.weekday;
      return _selectedDate.subtract(Duration(days: weekday - 1));
    }
  }

  DateTime get _endDate {
    if (_viewMode == 'day') {
      return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
    } else {
      // End of week (Sunday)
      final weekday = _selectedDate.weekday;
      return _selectedDate.add(Duration(days: 7 - weekday)).add(const Duration(hours: 23, minutes: 59, seconds: 59));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_stylistId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lịch hẹn'),
        ),
        body: const Center(
          child: Text('Bạn chưa được liên kết với tài khoản stylist. Vui lòng liên hệ admin.'),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: true,
              pinned: true,
              backgroundColor: const Color(0xFF0891B2),
              actions: [
                // Nút đăng xuất
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Đăng xuất',
                    onPressed: () => _handleLogout(context),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _stylist?.name ?? 'Stylist',
                  style: const TextStyle(
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: Icon(
                          Icons.content_cut_rounded,
                          size: 60,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            _buildDateSelector(),
            _buildViewModeSelector(),
            Expanded(
              child: _buildBookingsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                if (_viewMode == 'day') {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                } else {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                }
              });
            },
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            child: Column(
              children: [
                Text(
                  _viewMode == 'day'
                      ? DateFormat('EEEE, dd MMMM yyyy', 'vi').format(_selectedDate)
                      : 'Tuần ${_getWeekNumber(_selectedDate)}, ${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0891B2),
                  ),
                ),
                if (_viewMode == 'week')
                  Text(
                    '${DateFormat('dd/MM', 'vi').format(_startDate)} - ${DateFormat('dd/MM/yyyy', 'vi').format(_endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                if (_viewMode == 'day') {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                } else {
                  _selectedDate = _selectedDate.add(const Duration(days: 7));
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: const Text('Theo ngày'),
              selected: _viewMode == 'day',
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _viewMode = 'day';
                  });
                }
              },
              selectedColor: const Color(0xFF0891B2),
              labelStyle: TextStyle(
                color: _viewMode == 'day' ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ChoiceChip(
              label: const Text('Theo tuần'),
              selected: _viewMode == 'week',
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _viewMode = 'week';
                  });
                }
              },
              selectedColor: const Color(0xFF0891B2),
              labelStyle: TextStyle(
                color: _viewMode == 'week' ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    return StreamBuilder<List<Booking>>(
      stream: _firestoreService.getStylistBookingsByDateRange(
        _stylistId!,
        _startDate,
        _endDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0891B2),
            ),
          );
        }

        if (snapshot.hasError) {
          // Xử lý lỗi một cách graceful
          final error = snapshot.error.toString();
          if (error.contains('index') || error.contains('failed-precondition')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.orange[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Đang tải dữ liệu...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0891B2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng đợi trong giây lát',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Có lỗi xảy ra',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.length > 100 ? '${error.substring(0, 100)}...' : error,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Lịch trống',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Không có lịch hẹn nào trong khoảng thời gian này',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildBookingCard(booking);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final dateFormat = DateFormat('HH:mm', 'vi');
    final dateFormatFull = DateFormat('dd/MM/yyyy HH:mm', 'vi');
    
    Color statusColor;
    IconData statusIcon;
    String statusText = booking.status;

    if (booking.serviceStatus == 'completed') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Đã hoàn tất';
    } else if (booking.serviceStatus == 'in_progress') {
      statusColor = Colors.orange;
      statusIcon = Icons.access_time;
      statusText = 'Đang thực hiện';
    } else if (booking.checkInTime != null) {
      statusColor = Colors.blue;
      statusIcon = Icons.login;
      statusText = 'Đã check-in';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.pending;
      statusText = booking.status;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StylistBookingDetailScreen(booking: booking),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.service.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
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
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    dateFormatFull.format(booking.dateTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              if (booking.checkInTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.login, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Check-in: ${dateFormatFull.format(booking.checkInTime!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    booking.customerPhone,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.store, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    booking.branchName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              if (booking.stylistNotes != null && booking.stylistNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.stylistNotes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi đăng xuất: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

