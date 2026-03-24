// lib/widgets/saved_vouchers_picker.dart
import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../services/data_service.dart';

class SavedVouchersPicker extends StatelessWidget {
  final DataService dataService;
  final double orderValue;
  
  const SavedVouchersPicker({
    super.key,
    required this.dataService,
    required this.orderValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 6,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Voucher đã lưu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn voucher phù hợp với đơn hàng ${orderValue.toStringAsFixed(0)}đ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Voucher>>(
                future: dataService.getActiveVouchers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEC4899),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Có lỗi xảy ra',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final vouchers = snapshot.data ?? [];

                  if (vouchers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Chưa có voucher nào được lưu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Lưu voucher yêu thích để sử dụng nhanh',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: vouchers.length,
                    itemBuilder: (context, index) {
                      final voucher = vouchers[index];
                      final isValid = voucher.isValid;
                      final meetsMinOrder = orderValue >= voucher.minOrderValue;
                      final canUse = isValid && meetsMinOrder;
                      final discount = voucher.calculateDiscount(orderValue);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: canUse ? () => Navigator.pop(context, voucher) : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Opacity(
                            opacity: canUse ? 1.0 : 0.5,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: canUse
                                      ? [const Color(0xFFEC4899), const Color(0xFFF472B6), const Color(0xFFFBBF24)]
                                      : [Colors.grey.shade400, Colors.grey.shade500],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: canUse
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFEC4899).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          voucher.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (canUse)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Description
                                  Text(
                                    voucher.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.95),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Discount badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'GIẢM ${voucher.discount.toInt()}% (${discount.toStringAsFixed(0)}đ)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Code
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      voucher.code,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEC4899),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  
                                  // Warning messages
                                  if (!isValid || !meetsMinOrder) ...[
                                    const SizedBox(height: 8),
                                    if (!isValid)
                                      Text(
                                        '⚠️ Voucher đã hết hạn hoặc hết lượt',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    if (!meetsMinOrder)
                                      Text(
                                        '⚠️ Đơn hàng tối thiểu ${voucher.minOrderValue.toStringAsFixed(0)}đ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
