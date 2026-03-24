// DEPRECATED: This service has been replaced by MongoDB services
// - Use mongodb_auth_service.dart for authentication
// - Use api_service.dart for API calls
// - Use data_service.dart for data operations
//
// This file is kept for backward compatibility but all methods are deprecated.
// Please update your code to use the new MongoDB services.

import '../models/service.dart';
import '../models/stylist.dart';
import '../models/booking.dart';
import '../models/branch.dart';
import '../models/category.dart';
import '../models/voucher.dart';
import './api_service.dart';

@deprecated
class FirestoreService {
  @deprecated
  Stream<List<Service>> getServices() {
    throw UnimplementedError('Use DataService.getServices() instead');
  }

  @deprecated
  Stream<List<Stylist>> getStylists() {
    throw UnimplementedError('Use DataService.getStylists() instead');
  }

  @deprecated
  Stream<List<Branch>> getBranches() {
    throw UnimplementedError('Use DataService.getBranches() instead');
  }

  @deprecated
  Stream<List<Category>> getCategories() {
    throw UnimplementedError('Use DataService.getCategories() instead');
  }

  @deprecated
  Stream<List<Booking>> getUserBookings() {
    throw UnimplementedError('Use DataService.getUserBookings() instead');
  }

  @deprecated
  Future<Booking> addBooking(Booking booking) async {
    throw UnimplementedError('Use DataService.createBooking() instead');
  }

  @deprecated
  Future<void> cancelBooking(String bookingId) {
    throw UnimplementedError('Use DataService.cancelBooking() instead');
  }

  @deprecated
  Stream<List<Voucher>> getVouchers() {
    throw UnimplementedError('Use DataService.getVouchers() instead');
  }

  @deprecated
  Stream<List<Voucher>> getActiveVouchers() {
    throw UnimplementedError('Use DataService.getActiveVouchers() instead');
  }
}
