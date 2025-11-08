// lib/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Đếm tổng số dịch vụ
  Future<int> getServicesCount() async {
    final snapshot = await _firestore.collection('services').get();
    return snapshot.docs.length;
  }

  // Đếm tổng số chi nhánh
  Future<int> getBranchesCount() async {
    final snapshot = await _firestore.collection('branches').get();
    return snapshot.docs.length;
  }

  // Đếm tổng số stylist
  Future<int> getStylistsCount() async {
    final snapshot = await _firestore.collection('stylists').get();
    return snapshot.docs.length;
  }

  // Đếm số đơn đặt lịch trong ngày
  Future<int> getTodayBookingsCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('bookings')
        .where('bookingDate', isGreaterThanOrEqualTo: startOfDay)
        .where('bookingDate', isLessThanOrEqualTo: endOfDay)
        .get();
    
    return snapshot.docs.length;
  }

  // Tạo tài khoản admin mặc định
  Future<void> createDefaultAdmin() async {
    try {
      final adminEmail = 'admin@gmail.com';
      final adminPassword = '@123456';
      
      // Kiểm tra xem admin đã tồn tại chưa bằng cách tìm theo email
      final adminQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .where('isAdmin', isEqualTo: true)
          .get();
      
      if (adminQuery.docs.isEmpty) {
        // Kiểm tra xem đã có user với email này chưa
        try {
          final existingUser = await _auth.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
          
          // Nếu đăng nhập thành công, cập nhật thông tin admin
          final adminUser = UserModel(
            id: existingUser.user!.uid,
            email: adminEmail,
            displayName: 'Admin',
            isAdmin: true,
            createdAt: DateTime.now(),
          );
          
          await _firestore.collection('users').doc(existingUser.user!.uid).set(adminUser.toFirestore());
          await _auth.signOut(); // Đăng xuất để user có thể đăng nhập lại
          
          print('Admin account updated successfully with UID: ${existingUser.user!.uid}');
        } catch (e) {
          // Nếu không đăng nhập được, tạo tài khoản mới
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
          
          // Cập nhật display name
          await userCredential.user?.updateDisplayName('Admin');
          
          // Lưu thông tin admin vào Firestore với UID thực tế
          final adminUser = UserModel(
            id: userCredential.user!.uid,
            email: adminEmail,
            displayName: 'Admin',
            isAdmin: true,
            createdAt: DateTime.now(),
          );
          
          await _firestore.collection('users').doc(userCredential.user!.uid).set(adminUser.toFirestore());
          await _auth.signOut(); // Đăng xuất để user có thể đăng nhập lại
          
          print('Admin account created successfully with UID: ${userCredential.user!.uid}');
        }
      } else {
        print('Admin account already exists');
      }
    } catch (e) {
      print('Error creating admin account: $e');
    }
  }

  // Kiểm tra quyền admin
  Future<bool> isAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        return user.isAdmin;
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Lấy thông tin user hiện tại
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Cập nhật thông tin user sau khi đăng nhập
  Future<void> updateUserAfterLogin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final userData = {
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      };

      // ĐƠN GIẢN: nếu email là admin@gmail.com thì đánh dấu là admin ngay
      if ((user.email ?? '').toLowerCase() == 'admin@gmail.com') {
        userData['isAdmin'] = true;
      }
      
      await _firestore.collection('users').doc(user.uid).set(
        userData,
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error updating user after login: $e');
    }
  }

  // Lấy danh sách tất cả users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  // Cập nhật quyền admin của user
  Future<void> updateAdminStatus(String userId, bool isAdmin) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': isAdmin,
      });
    } catch (e) {
      print('Error updating admin status: $e');
    }
  }
}
