// lib/screens/profile/transaction_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../services/firestore_service.dart';

// Lớp Widget chính, kế thừa từ StatefulWidget
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

// Lớp State, chứa toàn bộ logic và giao diện
class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NumberFormat currencyFormat =
      NumberFormat.currency(symbol: 'đ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử giao dịch')),
      body: StreamBuilder<List<Booking>>(
        stream: _firestoreService.getUserBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          }
          
          final allBookings = snapshot.data ?? [];
          final transactions = allBookings.where((b) => b.dateTime.isBefore(DateTime.now())).toList();

          if (transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có giao dịch nào hoàn thành',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = transactions[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cut,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    booking.service.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy, HH:mm').format(booking.dateTime),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-${currencyFormat.format(booking.service.price)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hoàn thành',
                         style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}