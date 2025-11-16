// lib/screens/debug_vouchers_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/voucher.dart';
import '../services/firestore_service.dart';

class DebugVouchersScreen extends StatelessWidget {
  const DebugVouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Vouchers'),
        backgroundColor: const Color(0xFF0891B2),
      ),
      body: StreamBuilder<List<Voucher>>(
        stream: firestoreService.getVouchers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final allVouchers = snapshot.data ?? [];

          return StreamBuilder<List<Voucher>>(
            stream: firestoreService.getActiveVouchers(),
            builder: (context, activeSnapshot) {
              final activeVouchers = activeSnapshot.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng số voucher: ${allVouchers.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Voucher đang hoạt động: ${activeVouchers.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tất cả Vouchers:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (allVouchers.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Không có voucher nào trong database.\n'
                          'Hãy vào Admin Dashboard để tạo voucher mới.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  else
                    ...allVouchers.map((voucher) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              voucher.isValid ? Icons.check_circle : Icons.cancel,
                              color: voucher.isValid ? Colors.green : Colors.red,
                            ),
                            title: Text(voucher.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Code: ${voucher.code}'),
                                Text('Giảm: ${voucher.discount.toInt()}%'),
                                Text(
                                  'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.validFrom)} - ${DateFormat('dd/MM/yyyy').format(voucher.validTo)}',
                                ),
                                Text('Còn: ${voucher.remainingQuantity}/${voucher.totalQuantity}'),
                                Text(
                                  'Status: ${voucher.isActive ? "Active" : "Inactive"} | Valid: ${voucher.isValid ? "Yes" : "No"}',
                                  style: TextStyle(
                                    color: voucher.isValid ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
