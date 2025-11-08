// lib/models/booking.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service.dart';
import 'stylist.dart';

class Booking {
  final String id;
  final Service service;
  final Stylist stylist;
  final DateTime dateTime;
  final String status;
  final String note;
  final String customerName;
  final String customerPhone;
  final String branchName;
  final String? paymentMethod;
  final double amount;      // Thêm trường số tiền
  final bool isPaid;        // Thêm trường trạng thái thanh toán
  final String? voucherCode; // Mã voucher đã áp dụng
  final double? discount;    // Số tiền giảm giá từ voucher
  final double? originalAmount; // Số tiền gốc trước khi giảm

  Booking({
    required this.id,
    required this.service,
    required this.stylist,
    required this.dateTime,
    required this.status,
    this.note = "",
    required this.customerName,
    required this.customerPhone,
    required this.branchName,
    this.paymentMethod,
    required this.amount,
    this.isPaid = false,
    this.voucherCode,
    this.discount,
    this.originalAmount,
  });

  Booking copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? branchName,
    String? status,
    String? paymentMethod,
    double? amount,
    bool? isPaid,
    String? voucherCode,
    double? discount,
    double? originalAmount,
  }) {
    return Booking(
      id: id ?? this.id,
      service: service,
      stylist: stylist,
      dateTime: dateTime,
      status: status ?? this.status,
      note: note,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      branchName: branchName ?? this.branchName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      voucherCode: voucherCode ?? this.voucherCode,
      discount: discount ?? this.discount,
      originalAmount: originalAmount ?? this.originalAmount,
    );
  }

  factory Booking.fromMap(Map<String, dynamic> map, {required Service service, required Stylist stylist}) {
    return Booking(
      id: map['id'] ?? '',
      service: service,
      stylist: stylist,
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      status: map['status'] ?? '',
      note: map['note'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      branchName: map['branchName'] ?? '',
      paymentMethod: map['paymentMethod'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      voucherCode: map['voucherCode'],
      discount: map['discount']?.toDouble(),
      originalAmount: map['originalAmount']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceId': service.id,
      'stylistId': stylist.id,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'note': note,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'branchName': branchName,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'isPaid': isPaid,
      'voucherCode': voucherCode,
      'discount': discount,
      'originalAmount': originalAmount,
    };
  }
}