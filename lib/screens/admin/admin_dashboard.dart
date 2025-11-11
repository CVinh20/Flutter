// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'admin_ui.dart';
import 'manage_services_screen.dart';
import 'manage_branches_screen.dart';
import 'manage_stylists_screen.dart';
import 'manage_bookings_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_vouchers_screen.dart';
import 'manage_employees_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _adminService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: AdminLoadingCard(message: 'Đang tải thông tin...'),
        ),
      );
    }

    // Guard: Only allow admins
    if (_currentUser!.isAdmin != true) {
      return Scaffold(
        backgroundColor: AdminColors.background,
        appBar: AppBar(
          title: const Text('Quyền truy cập'),
          backgroundColor: AdminColors.surface,
        ),
        body: Center(
          child: AdminEmptyState(
            title: 'Không có quyền truy cập',
            subtitle: 'Bạn không có quyền truy cập khu vực admin này',
            icon: Icons.lock_outline,
            action: AdminPrimaryButton(
              label: 'Về trang chủ',
              icon: Icons.home,
              onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
            ),
          ),
        ),
      );
    }

    return AdminScaffold(
      title: 'Admin Dashboard',
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AdminColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout, color: AdminColors.danger),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Welcome Section
            AdminCard(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: AdminColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AdminColors.accent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chào mừng Admin!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentUser?.displayName ?? 'Admin',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AdminColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quản lý hệ thống salon',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AdminColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Stats Section
            const Text(
              'Thống kê tổng quan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AdminColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: constraints.maxWidth > 600 ? 1.4 : 1.2,
                  children: [
                    FutureBuilder<int>(
                      future: _adminService.getServicesCount(),
                      builder: (context, snapshot) {
                        return AdminStatsCard(
                          title: 'Tổng dịch vụ',
                          value: snapshot.data?.toString() ?? '...',
                          icon: Icons.build_circle_outlined,
                          color: AdminColors.accent,
                          subtitle: snapshot.hasError ? 'Lỗi tải dữ liệu' : 'Dịch vụ có sẵn',
                        );
                      },
                    ),
                    FutureBuilder<int>(
                      future: _adminService.getBranchesCount(),
                      builder: (context, snapshot) {
                        return AdminStatsCard(
                          title: 'Chi nhánh',
                          value: snapshot.data?.toString() ?? '...',
                          icon: Icons.storefront_outlined,
                          color: AdminColors.info,
                          subtitle: snapshot.hasError ? 'Lỗi tải dữ liệu' : 'Đang hoạt động',
                        );
                      },
                    ),
                    FutureBuilder<int>(
                      future: _adminService.getStylistsCount(),
                      builder: (context, snapshot) {
                        return AdminStatsCard(
                          title: 'Stylist',
                          value: snapshot.data?.toString() ?? '...',
                          icon: Icons.person_outline,
                          color: AdminColors.success,
                          subtitle: snapshot.hasError ? 'Lỗi tải dữ liệu' : 'Stylist đang làm việc',
                        );
                      },
                    ),
                    FutureBuilder<int>(
                      future: _adminService.getEmployeesCount(),
                      builder: (context, snapshot) {
                        return AdminStatsCard(
                          title: 'Nhân viên',
                          value: snapshot.data?.toString() ?? '...',
                          icon: Icons.badge_outlined,
                          color: const Color(0xFF6B46C1),
                          subtitle: snapshot.hasError ? 'Lỗi tải dữ liệu' : 'Nhân viên đang hoạt động',
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Management Section
            const Text(
              'Quản lý hệ thống',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AdminColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: constraints.maxWidth > 600 ? 1.3 : 1.1,
                  children: [
                    _buildManagementCard(
                      icon: Icons.category_outlined,
                      title: 'Danh mục',
                      subtitle: 'Quản lý danh mục',
                      color: AdminColors.accent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageCategoriesScreen(),
                        ),
                      ),
                    ),
                    _buildManagementCard(
                      icon: Icons.build_circle_outlined,
                      title: 'Dịch vụ',
                      subtitle: 'Quản lý dịch vụ',
                      color: AdminColors.info,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageServicesScreen(),
                        ),
                      ),
                    ),
                    _buildManagementCard(
                      icon: Icons.storefront_outlined,
                      title: 'Chi nhánh',
                      subtitle: 'Quản lý chi nhánh',
                      color: AdminColors.success,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageBranchesScreen(),
                        ),
                      ),
                    ),
                    _buildManagementCard(
                      icon: Icons.badge_outlined,
                      title: 'Nhân viên',
                      subtitle: 'Quản lý tài khoản nhân viên',
                      color: const Color(0xFF6B46C1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageEmployeesScreen(),
                        ),
                      ),
                    ),
                    _buildManagementCard(
                      icon: Icons.person_outline,
                      title: 'Stylist',
                      subtitle: 'Quản lý stylist',
                      color: AdminColors.warning,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageStylistsScreen(),
                        ),
                      ),
                    ),
                    _buildManagementCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Đơn đặt lịch',
                      subtitle: 'Quản lý đơn đặt lịch',
                      color: const Color(0xFFEC4899),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageBookingsScreen(),
                        ),
                      ),
                    ),
                    _buildManagementCard(
                      icon: Icons.local_offer_outlined,
                      title: 'Voucher',
                      subtitle: 'Quản lý voucher',
                      color: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageVouchersScreen(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 20), // Extra padding at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AdminCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AdminColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: AdminColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quản lý',
                  style: TextStyle(
                    fontSize: 8,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
