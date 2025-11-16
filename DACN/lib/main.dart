// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/account_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/quick_booking_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/stylist/stylist_dashboard_screen.dart';
import 'services/notification_service.dart';
import 'services/admin_service.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'utils/google_signin_validator.dart';
import 'utils/firebase_config_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo locale data cho tiếng Việt
  // Cần thiết khi sử dụng DateFormat với locale 'vi'
  try {
    await initializeDateFormatting('vi', null);
  } catch (e) {
    print('Warning: Could not initialize date formatting for locale vi: $e');
    // Continue execution even if locale initialization fails
  }
  
  await NotificationService().init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Tạo tài khoản admin mặc định
  await AdminService().createDefaultAdmin();
  
  // Kiểm tra cấu hình Google Sign-In (chỉ trong debug mode)
  if (kDebugMode) {
    GoogleSignInValidator.validateAndPrint();
    FirebaseConfigChecker.checkAndroidConfig();
    FirebaseConfigChecker.checkGoogleSignInConfig();
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
      routes: {
        '/home': (_) => const MainScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/login': (_) => const LoginScreen(),
        '/auth': (_) => const AuthWrapper(),
      },
      builder: EasyLoading.init(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0891B2),
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            return const AuthWrapper();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AdminService _adminService = AdminService();
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
      final user = await _adminService.getCurrentUser();
      if (mounted) {
        setState(() {
          _isAdmin = user?.isAdmin ?? false;
          _isStylist = user?.isStylist ?? false;
          _isLoading = false;
        });
        print('User role checked: isAdmin = $_isAdmin, isStylist = $_isStylist');
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
          child: CircularProgressIndicator(
            color: Color(0xFF0891B2),
          ),
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
  final GlobalKey<ConvexAppBarState> _appBarKey = GlobalKey<ConvexAppBarState>();

  final List<Widget> _actualScreens = [
    const HomeScreen(),
    const ShopScreen(),
    const MyBookingsScreen(),
    const AccountScreen(),
  ];

  // Method to navigate to MyBookings tab
  void navigateToMyBookings() {
    print('navigateToMyBookings called, current _selectedIndex: $_selectedIndex');
    setState(() {
      _selectedIndex = 3; // Lịch sử tab index (index 3 in the bottom bar)
    });
    print('_selectedIndex updated to: $_selectedIndex');
    _appBarKey.currentState?.animateTo(3); // Index 3 in the bottom bar
    print('animateTo(3) called');
  }

  // Static instance để có thể gọi từ bên ngoài
  static MainScreenState? _instance;
  
  @override
  void initState() {
    super.initState();
    _instance = this;
  }

  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }

  // Static method để navigate đến MyBookings từ bên ngoài
  static void navigateToBookings() {
    print('navigateToBookings called, _instance: $_instance');
    _instance?.navigateToMyBookings();
  }

  @override
  Widget build(BuildContext context) {
    int mapIndexToScreen(int tabIndex) {
      if (tabIndex < 2) return tabIndex;        // 0,1 → 0,1
      if (tabIndex == 2) return 0;              // 2 (Đặt lịch) → không map
      if (tabIndex == 3) return 2;              // 3 → 2 (Bookings)
      if (tabIndex == 4) return 3;              // 4 → 3 (Account)
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

        style: TabStyle.reactCircle,
        backgroundColor: Colors.white,
        color: Colors.grey.shade400,
        activeColor: const Color(0xFF0891B2),
        height: 60,
        initialActiveIndex: _selectedIndex,
        items: [
          TabItem(icon: Icons.home_rounded, title: 'Trang chủ'),
          TabItem(icon: Icons.shopping_bag_rounded, title: 'Cửa hàng'),
          TabItem(icon: Icons.add, title: 'Đặt lịch'),
          TabItem(icon: Icons.history_rounded, title: 'Lịch sử'),
          TabItem(icon: Icons.person_rounded, title: 'Tài khoản'),
        ],
        onTap: (int index) async {
          if (index == 2) {
            // Khi nhấn "Đặt lịch", chúng ta điều hướng đến màn hình mới
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QuickBookingScreen()),
            );
            // === PHẦN SỬA LỖI 3: Đồng bộ lại AppBar sau khi quay về ===
            // Sau khi quay lại, dùng key để "ra lệnh" cho AppBar
            // nhảy về đúng tab đang được chọn (_selectedIndex)
            _appBarKey.currentState?.animateTo(_selectedIndex);
          } else {
            // Khi nhấn các tab khác, cập nhật trạng thái như bình thường
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),
    );
  }
}