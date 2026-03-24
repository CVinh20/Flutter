// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/account_screen.dart';
import 'screens/branch_screen.dart';
import 'screens/quick_booking_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/stylist/stylist_dashboard_screen.dart';
import 'services/notification_service.dart';
import 'services/mongodb_auth_service.dart';
import 'services/mongo_admin_service.dart'; // Import MongoDB admin service
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo locale data cho tiếng Việt
  try {
    await initializeDateFormatting('vi', null);
  } catch (e) {
    print('Warning: Could not initialize date formatting for locale vi: $e');
  }

  // Khởi tạo notification service
  await NotificationService().init();

  // Khởi tạo MongoDB auth service
  await MongoDBAuthService.initialize();

  if (kDebugMode) {
    print('MongoDB Auth initialized successfully');
  }

  runApp(MyApp());
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.wave
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.white
    ..backgroundColor = const Color(0xFF0891B2)
    ..indicatorColor = Colors.white
    ..textColor = Colors.white
    ..maskColor = Colors.black.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gentlemen\'s Grooming',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        primaryColor: const Color(0xFF0891B2),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
        fontFamily: 'Roboto',
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0891B2),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0891B2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF0891B2).withOpacity(0.3),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
      routes: {
        '/home': (_) => const MainScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/change-password': (_) => const ChangePasswordScreen(),
        '/login': (_) => const LoginScreen(),
        '/auth': (_) => const AuthWrapper(),
        '/admin-dashboard': (_) => const AdminDashboard(),
        '/stylist-dashboard': (_) => const StylistDashboardScreen(),
      },
      builder: EasyLoading.init(),
      home: const AuthCheck(),
    );
  }
}

/// Kiểm tra xem user đã đăng nhập hay chưa (dùng token từ MongoDB)
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final user = MongoDBAuthService.currentUser;
      if (mounted) {
        setState(() {
          _isLoggedIn = user != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking login status: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0891B2)),
        ),
      );
    }

    if (_isLoggedIn) {
      return const AuthWrapper();
    }
    return const LoginScreen();
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final MongoAdminService _adminService = MongoAdminService();
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isStylist = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final currentUser = MongoDBAuthService.currentUser;
      if (mounted) {
        setState(() {
          _isAdmin = currentUser?.role == 'admin';
          _isStylist = currentUser?.role == 'stylist';
          _isLoading = false;
        });
        print(
          'User role checked: isAdmin = $_isAdmin, isStylist = $_isStylist',
        );
      }
    } catch (e) {
      print('Error checking user role: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isStylist = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0891B2)),
        ),
      );
    }

    print('Building AuthWrapper: isAdmin = $_isAdmin, isStylist = $_isStylist');

    if (_isAdmin) {
      return const AdminDashboard();
    } else if (_isStylist) {
      return const StylistDashboardScreen();
    } else {
      return const MainScreen();
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // === PHẦN SỬA LỖI 1: Tạo GlobalKey ===
  // Key này sẽ cho phép chúng ta truy cập và điều khiển ConvexAppBar
  final GlobalKey<ConvexAppBarState> _appBarKey =
      GlobalKey<ConvexAppBarState>();

  // GlobalKey for MyBookingsScreen to access its state
  final GlobalKey<MyBookingsScreenState> _bookingsScreenKey =
      GlobalKey<MyBookingsScreenState>();

  late final List<Widget> _actualScreens;

  @override
  void initState() {
    super.initState();
    _instance = this;
    
    // Initialize screens with keys where needed
    _actualScreens = [
      const HomeScreen(),
      const BranchScreen(),
      MyBookingsScreen(key: _bookingsScreenKey),
      const AccountScreen(),
    ];
  }

  // Method to navigate to MyBookings tab and refresh
  void navigateToMyBookings() {
    print(
      'navigateToMyBookings called, current _selectedIndex: $_selectedIndex',
    );
    setState(() {
      _selectedIndex = 3; // Lịch sử tab index (index 3 in the bottom bar)
    });
    print('_selectedIndex updated to: $_selectedIndex');
    _appBarKey.currentState?.animateTo(3); // Index 3 in the bottom bar
    print('animateTo(3) called');
    
    // Refresh bookings data
    Future.delayed(const Duration(milliseconds: 300), () {
      _bookingsScreenKey.currentState?.refresh();
    });
  }

  // Alias for navigateToBookings (same as navigateToMyBookings)
  static void navigateToBookings() {
    _instance?.navigateToMyBookings();
  }

  // Static instance để có thể gọi từ bên ngoài
  static MainScreenState? _instance;

  // ← NEW: Getter public để truy cập từ các screen khác
  static MainScreenState? get instance => _instance;

  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int mapIndexToScreen(int tabIndex) {
      if (tabIndex < 2) return tabIndex; // 0,1 → 0,1 (Home, Branch)
      if (tabIndex == 2) return 0; // 2 (Đặt lịch) → không map
      if (tabIndex == 3) return 2; // 3 → 2 (Bookings)
      if (tabIndex == 4) return 3; // 4 → 3 (Account)
      return 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: mapIndexToScreen(_selectedIndex),
        children: _actualScreens,
      ),
      bottomNavigationBar: ConvexAppBar(
        // === PHẦN SỬA LỖI 2: Gán Key cho AppBar ===
        key: _appBarKey,

        style: TabStyle.fixedCircle,
        backgroundColor: Colors.white,
        color: Colors.grey.shade400,
        activeColor: const Color(0xFF0891B2),
        height: 56,
        initialActiveIndex: mapIndexToScreen(_selectedIndex),
        items: [
          TabItem(icon: Icons.home_rounded, title: 'Trang chủ'),
          TabItem(icon: Icons.business_rounded, title: 'Chi nhánh'),
          TabItem(icon: Icons.add, title: 'Đặt lịch'),
          TabItem(icon: Icons.history_rounded, title: 'Lịch sử'),
          TabItem(icon: Icons.person_rounded, title: 'Tài khoản'),
        ],
        onTap: (int index) async {
          if (index == 2) {
            // Khi nhấn "Đặt lịch", chúng ta điều hướng đến màn hình mới
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QuickBookingScreen(),
              ),
            );
            // === PHẦN SỬA LỖI 3: Đồng bộ lại AppBar sau khi quay về ===
            // Sau khi quay lại, dùng key để "ra lệnh" cho AppBar
            // nhảy về đúng tab đang được chọn (_selectedIndex)
            _appBarKey.currentState?.animateTo(
              mapIndexToScreen(_selectedIndex),
            );
          } else {
            // Map ConvexAppBar index to screen index
            // Tab 0 (Home) -> Screen 0
            // Tab 1 (Chi nhánh) -> Screen 1
            // Tab 2 (Đặt lịch) -> Navigate to QuickBookingScreen
            // Tab 3 (Lịch sử) -> Screen 2 (MyBookings)
            // Tab 4 (Tài khoản) -> Screen 3 (Account)
            
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),
    );
  }
}
