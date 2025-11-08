import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service.dart';
import '../models/stylist.dart';
import '../models/booking.dart';
import '../models/branch.dart';
import '../models/category.dart';
import '../models/voucher.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- LẤY DỮ LIỆU ---

  Stream<List<Service>> getServices() {
    return _db.collection('services').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList());
  }

  Stream<List<Stylist>> getStylists() {
    return _db.collection('stylists').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Stylist.fromFirestore(doc)).toList());
  }

  Stream<List<Branch>> getBranches() {
    return _db.collection('branches').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Branch.fromFirestore(doc)).toList());
  }

  Stream<List<Category>> getCategories() {
    return _db
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
  }

  Stream<List<Service>> getServicesByCategory(String categoryId) {
    return _db
        .collection('services')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList());
  }

  Stream<List<Booking>> getUserBookings() {
  final user = _auth.currentUser;
  if (user == null) return Stream.value([]);

  return _db
      .collection('bookings')
      .where('userId', isEqualTo: user.uid)
      .orderBy('dateTime', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final List<Booking> bookings = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      try {
        final serviceDoc =
            await _db.collection('services').doc(data['serviceId']).get();
        final stylistDoc =
            await _db.collection('stylists').doc(data['stylistId']).get();

        if (serviceDoc.exists && stylistDoc.exists) {
          bookings.add(Booking(
            id: doc.id,
            service: Service.fromFirestore(serviceDoc),
            stylist: Stylist.fromFirestore(stylistDoc),
            dateTime: (data['dateTime'] as Timestamp).toDate(),
            status: data['status'],
            note: data['note'] ?? "",
            customerName: data['customerName'] ?? 'Không rõ',
            customerPhone: data['customerPhone'] ?? 'Không rõ',
            branchName: data['branchName'] ?? 'Không rõ',
            paymentMethod: data['paymentMethod'],
            amount: (data['amount'] ?? 0.0).toDouble(),
            isPaid: data['isPaid'] ?? false,
            voucherCode: data['voucherCode'],
            discount: data['discount']?.toDouble(),
            originalAmount: data['originalAmount']?.toDouble(),
            stylistNotes: data['stylistNotes'],
            checkInTime: data['checkInTime'] != null ? (data['checkInTime'] as Timestamp).toDate() : null,
            serviceStatus: data['serviceStatus'],
          ));
        }
      } catch (e) {
        print('Error fetching booking details: $e');
      }
    }
    return bookings;
  });
}

  Stream<List<Service>> getFavoriteServices() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db.collection('users').doc(user.uid).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists || userDoc.data()?['favoriteServices'] == null) {
        return [];
      }
      List<String> favoriteIds = List<String>.from(userDoc.data()!['favoriteServices']);
      if (favoriteIds.isEmpty) return [];

      final servicesQuery = await _db.collection('services').where(FieldPath.documentId, whereIn: favoriteIds).get();
      return servicesQuery.docs.map((doc) => Service.fromFirestore(doc)).toList();
    });
  }


  // --- GHI DỮ LIỆU ---

  Future<Booking> addBooking(Booking booking) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Bạn cần đăng nhập để đặt lịch");

    final docRef = await _db.collection('bookings').add({
      'userId': user.uid,
      'serviceId': booking.service.id,
      'stylistId': booking.stylist.id,
      'dateTime': Timestamp.fromDate(booking.dateTime),
      'status': booking.status,
      'note': booking.note,
      'customerName': booking.customerName,
      'customerPhone': booking.customerPhone,
      'branchName': booking.branchName,
      'paymentMethod': booking.paymentMethod,
      'amount': booking.amount,
      'isPaid': booking.isPaid,
      'voucherCode': booking.voucherCode,
      'discount': booking.discount,
      'originalAmount': booking.originalAmount,
      'stylistNotes': booking.stylistNotes,
      'checkInTime': booking.checkInTime != null ? Timestamp.fromDate(booking.checkInTime!) : null,
      'serviceStatus': booking.serviceStatus ?? 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Trả về booking với ID đã được tạo
    return booking.copyWith(id: docRef.id);
  }

  Future<void> cancelBooking(String bookingId) {
    return _db.collection('bookings').doc(bookingId).update({
      'status': 'Đã hủy',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBooking(Booking booking) {
    final updates = <String, dynamic>{
      'status': booking.status,
      'paymentMethod': booking.paymentMethod,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (booking.stylistNotes != null) {
      updates['stylistNotes'] = booking.stylistNotes;
    }
    
    if (booking.checkInTime != null) {
      updates['checkInTime'] = Timestamp.fromDate(booking.checkInTime!);
    }
    
    if (booking.serviceStatus != null) {
      updates['serviceStatus'] = booking.serviceStatus;
    }
    
    return _db.collection('bookings').doc(booking.id).update(updates);
  }
  
  Future<void> toggleFavoriteService(String serviceId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final userRef = _db.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
       await userRef.set({
           'favoriteServices': [serviceId]
       });
       return;
    }

    List<String> favoriteIds = userDoc.data()?['favoriteServices'] != null
        ? List<String>.from(userDoc.data()!['favoriteServices'])
        : [];

    if (favoriteIds.contains(serviceId)) {
      userRef.update({
        'favoriteServices': FieldValue.arrayRemove([serviceId])
      });
    } else {
      userRef.update({
        'favoriteServices': FieldValue.arrayUnion([serviceId])
      });
    }
  }

  // --- XÓA BOOKING ---
  Future<void> deleteBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).delete();
  }

  // --- QUẢN LÝ DANH MỤC ---

  Future<Category> addCategory(Category category) async {
    final docRef = await _db.collection('categories').add(category.toFirestore());
    return category.copyWith(id: docRef.id);
  }

  Future<void> updateCategory(Category category) async {
    await _db.collection('categories').doc(category.id).update(category.toFirestore());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db.collection('categories').doc(categoryId).delete();
  }

  // --- QUẢN LÝ DỊCH VỤ (CẬP NHẬT) ---
  
  Future<Service> addService(Service service) async {
    final docRef = await _db.collection('services').add(service.toFirestore());
    return service.copyWith(id: docRef.id);
  }

  Future<void> updateService(Service service) async {
    await _db.collection('services').doc(service.id).update(service.toFirestore());
  }

  Future<void> deleteService(String serviceId) async {
    await _db.collection('services').doc(serviceId).delete();
  }

  // --- QUẢN LÝ VOUCHER ---

  // Lấy tất cả voucher
  Stream<List<Voucher>> getVouchers() {
    return _db
        .collection('vouchers')
        .orderBy('validTo', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Voucher.fromFirestore(doc)).toList());
  }

  // Lấy các voucher còn hiệu lực
  Stream<List<Voucher>> getActiveVouchers() {
    final now = DateTime.now();
    return _db
        .collection('vouchers')
        .where('isActive', isEqualTo: true)
        .where('validTo', isGreaterThan: Timestamp.fromDate(now))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Voucher.fromFirestore(doc))
              .where((voucher) => voucher.isValid)
              .toList();
        });
  }

  // Thêm voucher mới
  Future<Voucher> addVoucher(Voucher voucher) async {
    final docRef = await _db.collection('vouchers').add(voucher.toFirestore());
    return voucher.copyWith(id: docRef.id);
  }

  // Cập nhật voucher
  Future<void> updateVoucher(Voucher voucher) async {
    await _db.collection('vouchers').doc(voucher.id).update(voucher.toFirestore());
  }

  // Xóa voucher
  Future<void> deleteVoucher(String voucherId) async {
    await _db.collection('vouchers').doc(voucherId).delete();
  }

  // Áp dụng voucher cho booking
  Future<bool> applyVoucher(String voucherId, String userId) async {
    try {
      final voucherDoc = await _db.collection('vouchers').doc(voucherId).get();
      if (!voucherDoc.exists) return false;

      final voucher = Voucher.fromFirestore(voucherDoc);
      
      // Kiểm tra voucher còn hợp lệ
      if (!voucher.isValid) return false;

      // Kiểm tra user đã sử dụng voucher này chưa
      if (voucher.usedBy != null && voucher.usedBy!.contains(userId)) {
        return false;
      }

      // Cập nhật số lượng đã sử dụng và thêm userId vào danh sách
      await _db.collection('vouchers').doc(voucherId).update({
        'usedQuantity': FieldValue.increment(1),
        'usedBy': FieldValue.arrayUnion([userId]),
      });

      return true;
    } catch (e) {
      print('Error applying voucher: $e');
      return false;
    }
  }

  // Kiểm tra voucher theo mã
  Future<Voucher?> getVoucherByCode(String code) async {
    try {
      final snapshot = await _db
          .collection('vouchers')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return Voucher.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error getting voucher by code: $e');
      return null;
    }
  }

  // --- STYLIST METHODS ---

  // Lấy bookings của stylist theo stylistId
  Stream<List<Booking>> getStylistBookings(String stylistId) {
    return _db
        .collection('bookings')
        .where('stylistId', isEqualTo: stylistId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Booking> bookings = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        try {
          final serviceDoc =
              await _db.collection('services').doc(data['serviceId']).get();
          final stylistDoc =
              await _db.collection('stylists').doc(data['stylistId']).get();

          if (serviceDoc.exists && stylistDoc.exists) {
            bookings.add(Booking(
              id: doc.id,
              service: Service.fromFirestore(serviceDoc),
              stylist: Stylist.fromFirestore(stylistDoc),
              dateTime: (data['dateTime'] as Timestamp).toDate(),
              status: data['status'],
              note: data['note'] ?? "",
              customerName: data['customerName'] ?? 'Không rõ',
              customerPhone: data['customerPhone'] ?? 'Không rõ',
              branchName: data['branchName'] ?? 'Không rõ',
              paymentMethod: data['paymentMethod'],
              amount: (data['amount'] ?? 0.0).toDouble(),
              isPaid: data['isPaid'] ?? false,
              voucherCode: data['voucherCode'],
              discount: data['discount']?.toDouble(),
              originalAmount: data['originalAmount']?.toDouble(),
              stylistNotes: data['stylistNotes'],
              checkInTime: data['checkInTime'] != null ? (data['checkInTime'] as Timestamp).toDate() : null,
              serviceStatus: data['serviceStatus'],
            ));
          }
        } catch (e) {
          print('Error fetching booking details: $e');
        }
      }
      return bookings;
    });
  }

  // Lấy bookings của stylist trong khoảng thời gian (ngày/tuần)
  // Sử dụng filter và sort ở client side để tránh cần composite index
  Stream<List<Booking>> getStylistBookingsByDateRange(
    String stylistId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _db
        .collection('bookings')
        .where('stylistId', isEqualTo: stylistId)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Booking> bookings = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        try {
          final bookingDate = (data['dateTime'] as Timestamp).toDate();
          
          // Filter theo date range ở client side
          if (bookingDate.isBefore(startDate) || bookingDate.isAfter(endDate)) {
            continue;
          }
          
          final serviceDoc =
              await _db.collection('services').doc(data['serviceId']).get();
          final stylistDoc =
              await _db.collection('stylists').doc(data['stylistId']).get();

          if (serviceDoc.exists && stylistDoc.exists) {
            bookings.add(Booking(
              id: doc.id,
              service: Service.fromFirestore(serviceDoc),
              stylist: Stylist.fromFirestore(stylistDoc),
              dateTime: bookingDate,
              status: data['status'],
              note: data['note'] ?? "",
              customerName: data['customerName'] ?? 'Không rõ',
              customerPhone: data['customerPhone'] ?? 'Không rõ',
              branchName: data['branchName'] ?? 'Không rõ',
              paymentMethod: data['paymentMethod'],
              amount: (data['amount'] ?? 0.0).toDouble(),
              isPaid: data['isPaid'] ?? false,
              voucherCode: data['voucherCode'],
              discount: data['discount']?.toDouble(),
              originalAmount: data['originalAmount']?.toDouble(),
              stylistNotes: data['stylistNotes'],
              checkInTime: data['checkInTime'] != null ? (data['checkInTime'] as Timestamp).toDate() : null,
              serviceStatus: data['serviceStatus'],
            ));
          }
        } catch (e) {
          print('Error fetching booking details: $e');
        }
      }
      // Sort theo dateTime ở client side
      bookings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return bookings;
    });
  }

  // Check-in khách hàng
  Future<void> checkInBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'checkInTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cập nhật trạng thái dịch vụ
  Future<void> updateServiceStatus(String bookingId, String serviceStatus) async {
    await _db.collection('bookings').doc(bookingId).update({
      'serviceStatus': serviceStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      // Nếu hoàn tất, cập nhật status
      if (serviceStatus == 'completed') 'status': 'Đã hoàn tất',
    });
  }

  // Cập nhật ghi chú của stylist
  Future<void> updateStylistNotes(String bookingId, String notes) async {
    await _db.collection('bookings').doc(bookingId).update({
      'stylistNotes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cập nhật booking bởi stylist (tổng hợp các thao tác trên)
  Future<void> updateBookingByStylist({
    required String bookingId,
    String? serviceStatus,
    String? stylistNotes,
    bool? checkIn,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (checkIn == true) {
      updates['checkInTime'] = FieldValue.serverTimestamp();
    }

    if (serviceStatus != null) {
      updates['serviceStatus'] = serviceStatus;
      if (serviceStatus == 'completed') {
        updates['status'] = 'Đã hoàn tất';
      } else if (serviceStatus == 'in_progress') {
        updates['status'] = 'Đang thực hiện';
      }
    }

    if (stylistNotes != null) {
      updates['stylistNotes'] = stylistNotes;
    }

    await _db.collection('bookings').doc(bookingId).update(updates);
  }
}
