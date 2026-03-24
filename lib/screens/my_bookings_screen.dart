import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  MyBookingsScreenState createState() => MyBookingsScreenState();
}

class MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final DataService _dataService = DataService();
  Future<List<Booking>>? _bookingsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _bookingsFuture = _dataService.getUserBookings();
    });
    await _bookingsFuture;
  }

  // Public method to refresh bookings from external screens
  void refresh() {
    _loadBookings();
  }

  // Helper: Convert status từ tiếng Anh sang tiếng Việt
  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'chờ xác nhận':
      case 'chờ xử lý':
        return 'Chờ xác nhận';
      case 'confirmed':
      case 'đã xác nhận':
        return 'Đã xác nhận';
      case 'in_progress':
      case 'đang thực hiện':
        return 'Đang thực hiện';
      case 'completed':
      case 'hoàn tất':
      case 'hoàn thành':
        return 'Hoàn thành';
      case 'cancelled':
      case 'đã hủy':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  // Helper: Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'chờ xác nhận':
      case 'chờ xử lý':
        return Colors.orange;
      case 'confirmed':
      case 'đã xác nhận':
        return Colors.blue;
      case 'in_progress':
      case 'đang thực hiện':
        return Colors.purple;
      case 'completed':
      case 'hoàn tất':
      case 'hoàn thành':
        return Colors.green;
      case 'cancelled':
      case 'đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Must call super for AutomaticKeepAliveClientMixin
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: true,
              pinned: true,
              backgroundColor: const Color(0xFF0891B2),
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
                      Icons.event_note_rounded,
                      size: 60,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: [
                  Tab(icon: Icon(Icons.upcoming_rounded), text: 'Sắp tới'),
                  Tab(icon: Icon(Icons.history_rounded), text: 'Lịch sử'),
                ],
              ),
            ),
          ];
        },
        body: Container(
          color: const Color(0xFFF8FAFC),
          child: RefreshIndicator(
            onRefresh: _loadBookings,
            child: FutureBuilder<List<Booking>>(
              future: _bookingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang tải đơn đặt...'),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          "Lỗi: ${snapshot.error}",
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadBookings,
                          child: Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                
                final bookings = snapshot.data ?? [];
                print('📋 Total bookings loaded: ${bookings.length}');
                
                if (bookings.isEmpty) {
                  return TabBarView(
                    controller: _tabController,
                    children: [_buildEmptyState(true), _buildEmptyState(false)],
                  );
                }

                // Phân loại bookings theo status
                // Tab "Sắp tới": pending, confirmed, in_progress, Chờ xác nhận, Đã xác nhận
                // Tab "Lịch sử": completed, cancelled, Hoàn tất, Hoàn thành, Đã hủy
                final upcomingBookings = bookings
                    .where((b) {
                      final status = b.status.toLowerCase();
                      return status == 'pending' || 
                             status == 'confirmed' || 
                             status == 'in_progress' ||
                             status == 'chờ xác nhận' ||
                             status == 'đã xác nhận' ||
                             status == 'đang thực hiện';
                    })
                    .toList();
                    
                final pastBookings = bookings
                    .where((b) {
                      final status = b.status.toLowerCase();
                      return status == 'completed' || 
                             status == 'cancelled' ||
                             status == 'hoàn tất' ||
                             status == 'hoàn thành' ||
                             status == 'đã hủy';
                    })
                    .toList();
                    
                print('📊 Bookings split: ${upcomingBookings.length} upcoming, ${pastBookings.length} history');

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingList(upcomingBookings, isUpcoming: true),
                    _buildBookingList(pastBookings, isUpcoming: false),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, {required bool isUpcoming}) {
    if (bookings.isEmpty) {
      return _buildEmptyState(isUpcoming);
    }
    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: bookings.length,
      itemBuilder: (ctx, i) => Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: _buildBookingCard(bookings[i], isUpcoming: isUpcoming),
      ),
    );
  }

  Widget _buildEmptyState(bool isUpcoming) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0891B2).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUpcoming ? Icons.event_busy_rounded : Icons.history_rounded,
              size: 64,
              color: const Color(0xFF0891B2),
            ),
          ),
          SizedBox(height: 20),
          Text(
            isUpcoming ? 'Chưa có lịch hẹn sắp tới' : 'Chưa có lịch sử',
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            isUpcoming
                ? 'Hãy đặt lịch dịch vụ ngay!'
                : 'Các lịch hẹn đã hoàn thành sẽ hiện ở đây',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, {required bool isUpcoming}) {
    Widget buildImage() {
      final url = booking.service.image;
      if (url.isNotEmpty && url.startsWith('http')) {
        return Image.network(
          url,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.event_note_rounded,
            size: 40,
            color: Color(0xFF94A3B8),
          ),
        );
      }
      return const Icon(
        Icons.event_note_rounded,
        size: 40,
        color: Color(0xFF94A3B8),
      );
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BookingDetailScreen(booking: booking, isUpcoming: isUpcoming),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: buildImage(),
                      ),
                    ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                booking.service.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(booking.status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getStatusColor(booking.status)
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getStatusLabel(booking.status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(booking.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: const Color(0xFF0891B2),
                            ),
                            SizedBox(width: 6),
                            Text(
                              booking.stylist.name,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 16,
                              color: const Color(0xFF0891B2),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                booking.branchName,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

            Container(
              padding: EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: Color(0xFF0891B2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy, HH:mm',
                            ).format(booking.dateTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'vi_VN',
                          symbol: 'đ',
                        ).format(booking.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0891B2),
                        ),
                      ),
                    ],
                  ),

                  if (isUpcoming) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Stop event propagation
                              _showCancelDialog(booking);
                            },
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('Hủy lịch'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade400,
                              side: BorderSide(color: Colors.red.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showRescheduleDialog(booking);
                            },
                            icon: const Icon(
                              Icons.edit_calendar_rounded,
                              size: 18,
                            ),
                            label: const Text('Đổi lịch'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0891B2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 3,
                              shadowColor: const Color(
                                0xFF0891B2,
                              ).withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showDeleteDialog(booking);
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Xóa'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade400,
                              side: BorderSide(color: Colors.red.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tính năng đặt lại đang được phát triển',
                                  ),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Đặt lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0891B2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 3,
                              shadowColor: const Color(
                                0xFF0891B2,
                              ).withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cancel_outlined,
                  color: Colors.red.shade400,
                  size: 48,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Hủy lịch hẹn?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Bạn có chắc chắn muốn hủy lịch hẹn này không?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Không',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await NotificationService().cancelNotification(
                            booking.id,
                          );
                          await _dataService.cancelBooking(booking.id);
                          await _loadBookings();
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã hủy lịch hẹn'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Hủy lịch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade400,
                  size: 48,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Xóa lịch hẹn?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Bạn có chắc chắn muốn xóa lịch hẹn này khỏi lịch sử không?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Không',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          // Xóa booking khỏi database
                          await _dataService.deleteBooking(booking.id);
                          await _loadBookings();
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã xóa lịch hẹn'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Xóa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show reschedule dialog
  void _showRescheduleDialog(Booking booking) {
    DateTime? newDate;
    TimeOfDay? newTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0891B2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_calendar_rounded,
                    color: Color(0xFF0891B2),
                    size: 48,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Đổi lịch hẹn',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Chọn ngày và giờ mới cho lịch hẹn',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                SizedBox(height: 20),
                
                // Date picker button
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: booking.dateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 90)),
                    );
                    if (picked != null) {
                      setState(() => newDate = picked);
                    }
                  },
                  icon: Icon(Icons.calendar_today),
                  label: Text(
                    newDate == null
                        ? 'Chọn ngày'
                        : DateFormat('dd/MM/yyyy').format(newDate!),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                
                // Time picker button
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(booking.dateTime),
                    );
                    if (picked != null) {
                      setState(() => newTime = picked);
                    }
                  },
                  icon: Icon(Icons.access_time),
                  label: Text(
                    newTime == null
                        ? 'Chọn giờ'
                        : '${newTime!.hour.toString().padLeft(2, '0')}:${newTime!.minute.toString().padLeft(2, '0')}',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (newDate != null && newTime != null)
                            ? () async {
                                try {
                                  final newDateTime = DateTime(
                                    newDate!.year,
                                    newDate!.month,
                                    newDate!.day,
                                    newTime!.hour,
                                    newTime!.minute,
                                  );
                                  
                                  await _dataService.updateBooking(
                                    booking.id,
                                    {'dateTime': newDateTime.toIso8601String()},
                                  );
                                  await _loadBookings();
                                  
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đã đổi lịch thành công'),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Lỗi: $e'),
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
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF0891B2),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Xác nhận',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
