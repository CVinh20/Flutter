// lib/screens/stylist/stylist_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../models/stylist.dart';
import '../../services/data_service.dart';
import '../../services/mongodb_auth_service.dart';
import '../../screens/login_screen.dart';
import 'stylist_booking_detail_screen.dart';

class StylistDashboardScreen extends StatefulWidget {
  const StylistDashboardScreen({super.key});

  @override
  State<StylistDashboardScreen> createState() => _StylistDashboardScreenState();
}

class _StylistDashboardScreenState extends State<StylistDashboardScreen> {
  final DataService _dataService = DataService();

  String? _stylistId;
  Stylist? _stylist;
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'day'; // 'day' or 'week'
  String _statusFilter = 'all'; // 'all', 'pending', 'confirmed', 'completed'
  bool _isLoading = true;
  List<Booking>? _cachedBookings; // Cache bookings data

  @override
  void initState() {
    super.initState();
    _loadStylistInfo();
  }

  Future<void> _loadStylistInfo() async {
    try {
      final user = await MongoDBAuthService.getCurrentUser();
      if (user.stylistId != null) {
        setState(() {
          _stylistId = user.stylistId;
        });

        // Lấy thông tin stylist
        try {
          final stylists = await _dataService.getStylists();
          final stylist = stylists.firstWhere((s) => s.id == _stylistId);
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

  Future<void> _confirmBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đơn'),
        content: Text(
          'Bạn có chắc chắn muốn xác nhận đơn đặt lịch của ${booking.customerName}?\n\n'
          'Dịch vụ: ${booking.service.name}\n'
          'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm', 'vi').format(booking.dateTime)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dataService.confirmBooking(booking.id, _stylistId!);
        
        // Clear cache để reload dữ liệu mới
        _cachedBookings = null;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xác nhận đơn thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {}); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<List<Booking>> _loadBookings() async {
    try {
      // Load all bookings for this stylist (cache nếu chưa có)
      if (_cachedBookings == null) {
        _cachedBookings = await _dataService.getStylistBookings(_stylistId!);
      }
      
      // Filter by date range
      var filtered = _cachedBookings!.where((booking) {
        final bookingDate = booking.dateTime;
        return bookingDate.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
               bookingDate.isBefore(_endDate.add(const Duration(seconds: 1)));
      }).toList();
      
      // Filter by status
      if (_statusFilter == 'pending') {
        filtered = filtered.where((b) => b.status == 'Chờ xác nhận' || b.status == 'Chờ xử lý' || b.status == 'pending').toList();
      } else if (_statusFilter == 'confirmed') {
        filtered = filtered.where((b) => b.status == 'in_progress' || b.serviceStatus == 'in_progress').toList();
      } else if (_statusFilter == 'completed') {
        filtered = filtered.where((b) => b.status == 'Hoàn tất' || b.status == 'Hoàn thành' || b.serviceStatus == 'completed').toList();
      }
      
      // Sort by date (newest first)
      filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return filtered;
    } catch (e) {
      print('Error loading bookings: $e');
      return [];
    }
  }

  DateTime get _startDate {
    if (_viewMode == 'day') {
      return DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
    } else {
      // Start of week (Monday)
      final weekday = _selectedDate.weekday;
      return _selectedDate.subtract(Duration(days: weekday - 1));
    }
  }

  DateTime get _endDate {
    if (_viewMode == 'day') {
      return DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        23,
        59,
        59,
      );
    } else {
      // End of week (Sunday)
      final weekday = _selectedDate.weekday;
      return _selectedDate
          .add(Duration(days: 7 - weekday))
          .add(const Duration(hours: 23, minutes: 59, seconds: 59));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_stylistId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lịch hẹn'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // Nếu không thể pop, đăng xuất
                _handleLogout(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () => _handleLogout(context),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chưa liên kết tài khoản',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bạn chưa được liên kết với tài khoản stylist. Vui lòng liên hệ admin để được hỗ trợ.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891B2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
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
            _buildStatusFilter(),
            _buildBookingStats(),
            Expanded(child: _buildBookingsList()),
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
                  _selectedDate = _selectedDate.subtract(
                    const Duration(days: 1),
                  );
                } else {
                  _selectedDate = _selectedDate.subtract(
                    const Duration(days: 7),
                  );
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
                      ? DateFormat(
                          'EEEE, dd MMMM yyyy',
                          'vi',
                        ).format(_selectedDate)
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lọc theo trạng thái:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all', Icons.list),
                const SizedBox(width: 8),
                _buildFilterChip('Chờ xác nhận', 'pending', Icons.pending),
                const SizedBox(width: 8),
                _buildFilterChip('Đang thực hiện', 'confirmed', Icons.check_circle),
                const SizedBox(width: 8),
                _buildFilterChip('Đã hoàn tất', 'completed', Icons.done_all),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _statusFilter == value;
    Color color;
    switch (value) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      default:
        color = const Color(0xFF0891B2);
    }

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildBookingStats() {
    // Dùng cached bookings thay vì gọi API mới
    if (_cachedBookings == null) {
      return FutureBuilder<List<Booking>>(
        future: _dataService.getStylistBookings(_stylistId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          
          _cachedBookings = snapshot.data!;
          return _buildStatsContent(_cachedBookings!);
        },
      );
    }
    
    return _buildStatsContent(_cachedBookings!);
  }

  Widget _buildStatsContent(List<Booking> allBookings) {
    final pendingCount = allBookings.where((b) => 
      b.status == 'Chờ xác nhận' || b.status == 'Chờ xử lý' || b.status == 'pending'
    ).length;
    final confirmedCount = allBookings.where((b) => b.status == 'in_progress' || b.serviceStatus == 'in_progress').length;
    final completedCount = allBookings.where((b) => 
      b.status == 'Hoàn tất' || b.status == 'Hoàn thành'
    ).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Chờ xác nhận', pendingCount, Colors.orange),
          _buildStatItem('Đang thực hiện', confirmedCount, Colors.blue),
          _buildStatItem('Hoàn tất', completedCount, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList() {
    return FutureBuilder<List<Booking>>(
      future: _loadBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0891B2)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Có lỗi xảy ra',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
    final dateFormatFull = DateFormat('dd/MM/yyyy HH:mm', 'vi');

    Color statusColor;
    IconData statusIcon;
    String statusText = booking.status;
    bool showConfirmButton = false;

    if (booking.status == 'Chờ xử lý') {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Chờ xác nhận';
      showConfirmButton = true;
    } else if (booking.serviceStatus == 'completed') {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  StylistBookingDetailScreen(booking: booking),
            ),
          );
          // Clear cache if data was changed
          if (result == true) {
            setState(() {
              _cachedBookings = null;
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Customer info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF0891B2).withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: const Color(0xFF0891B2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              booking.customerPhone,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
              const SizedBox(height: 12),
              // Service info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.content_cut, size: 18, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.service.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                          Text(
                            '${NumberFormat.currency(locale: 'vi', symbol: '₫').format(booking.service.price)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    dateFormatFull.format(booking.dateTime),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
                      style: TextStyle(fontSize: 14, color: Colors.green[700]),
                    ),
                  ],
                ),
              ],
              
              // Nút xác nhận đơn cho stylist
              if (showConfirmButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmBooking(booking),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Xác nhận đơn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.store, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.branchName,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              if (booking.stylistNotes != null &&
                  booking.stylistNotes!.isNotEmpty) ...[
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
        await MongoDBAuthService.logout();
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
