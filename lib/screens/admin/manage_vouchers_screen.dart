// lib/screens/admin/manage_vouchers_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/voucher.dart';
import '../../services/firestore_service.dart';
import 'admin_ui.dart';

class ManageVouchersScreen extends StatefulWidget {
  const ManageVouchersScreen({super.key});

  @override
  State<ManageVouchersScreen> createState() => _ManageVouchersScreenState();
}

class _ManageVouchersScreenState extends State<ManageVouchersScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Quản lý Voucher',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVoucherDialog(),
        backgroundColor: AdminColors.accent,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Voucher>>(
        stream: _firestoreService.getVouchers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final vouchers = snapshot.data ?? [];

          if (vouchers.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có voucher nào',
                style: TextStyle(color: AdminColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final voucher = vouchers[index];
              return _buildVoucherCard(voucher);
            },
          );
        },
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    final isExpired = voucher.validTo.isBefore(DateTime.now());
    final isOutOfStock = voucher.remainingQuantity <= 0;
    
    return AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AdminColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.accent),
                        ),
                        child: Text(
                          voucher.code,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AdminColors.accent,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (!voucher.isActive)
                      const AdminStatusChip(label: 'Tạm dừng', color: Colors.grey)
                    else if (isExpired)
                      const AdminStatusChip(label: 'Hết hạn', color: Colors.red)
                    else if (isOutOfStock)
                      const AdminStatusChip(label: 'Hết lượt', color: Colors.orange)
                    else
                      const AdminStatusChip(label: 'Hoạt động', color: Colors.green),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              voucher.description,
              style: const TextStyle(
                color: AdminColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.discount, 'Giảm giá', '${voucher.discount}%'),
            if (voucher.maxDiscount != null)
              _buildInfoRow(Icons.money_off, 'Giảm tối đa', 
                  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(voucher.maxDiscount)),
            _buildInfoRow(Icons.shopping_cart, 'Đơn tối thiểu', 
                NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(voucher.minOrderValue)),
            _buildInfoRow(Icons.calendar_today, 'Hiệu lực', 
                '${DateFormat('dd/MM/yyyy').format(voucher.validFrom)} - ${DateFormat('dd/MM/yyyy').format(voucher.validTo)}'),
            _buildInfoRow(Icons.inventory, 'Số lượng', 
                '${voucher.usedQuantity}/${voucher.totalQuantity} (Còn ${voucher.remainingQuantity})'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AdminPrimaryButton(
                    label: 'Sửa',
                    icon: Icons.edit,
                    onPressed: () => _showEditVoucherDialog(voucher),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminPrimaryButton(
                    label: voucher.isActive ? 'Tạm dừng' : 'Kích hoạt',
                    icon: voucher.isActive ? Icons.pause : Icons.play_arrow,
                    onPressed: () => _toggleVoucherStatus(voucher),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminDangerButton(
                    label: 'Xóa',
                    icon: Icons.delete,
                    onPressed: () => _deleteVoucher(voucher),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AdminColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AdminColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AdminColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVoucherDialog() {
    _showVoucherDialog();
  }

  void _showEditVoucherDialog(Voucher voucher) {
    _showVoucherDialog(voucher: voucher);
  }

  void _showVoucherDialog({Voucher? voucher}) {
    final isEdit = voucher != null;
    final codeController = TextEditingController(text: voucher?.code ?? '');
    final nameController = TextEditingController(text: voucher?.name ?? '');
    final descController = TextEditingController(text: voucher?.description ?? '');
    final discountController = TextEditingController(text: voucher?.discount.toString() ?? '');
    final maxDiscountController = TextEditingController(text: voucher?.maxDiscount?.toString() ?? '');
    final minOrderController = TextEditingController(text: voucher?.minOrderValue.toString() ?? '');
    final quantityController = TextEditingController(text: voucher?.totalQuantity.toString() ?? '');
    
    DateTime validFrom = voucher?.validFrom ?? DateTime.now();
    DateTime validTo = voucher?.validTo ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AdminColors.surface,
          title: Text(
            isEdit ? 'Chỉnh sửa Voucher' : 'Thêm Voucher mới',
            style: const TextStyle(color: AdminColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã voucher (VD: SALE50)',
                    prefixIcon: Icon(Icons.code),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên voucher',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: discountController,
                  decoration: const InputDecoration(
                    labelText: 'Phần trăm giảm (%)',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxDiscountController,
                  decoration: const InputDecoration(
                    labelText: 'Giảm tối đa (đ) - Để trống nếu không giới hạn',
                    prefixIcon: Icon(Icons.money_off),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minOrderController,
                  decoration: const InputDecoration(
                    labelText: 'Giá trị đơn hàng tối thiểu (đ)',
                    prefixIcon: Icon(Icons.shopping_cart),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Số lượng',
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Ngày bắt đầu'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(validFrom)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: validFrom,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => validFrom = date);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Ngày kết thúc'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(validTo)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: validTo,
                      firstDate: validFrom,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => validTo = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: AdminColors.textSecondary)),
            ),
            AdminPrimaryButton(
              label: isEdit ? 'Cập nhật' : 'Thêm',
              icon: isEdit ? Icons.save : Icons.add,
              onPressed: () async {
                if (codeController.text.trim().isEmpty ||
                    nameController.text.trim().isEmpty ||
                    discountController.text.trim().isEmpty ||
                    minOrderController.text.trim().isEmpty ||
                    quantityController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin!')),
                  );
                  return;
                }

                final newVoucher = Voucher(
                  id: voucher?.id ?? '',
                  code: codeController.text.trim().toUpperCase(),
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  discount: double.parse(discountController.text.trim()),
                  maxDiscount: maxDiscountController.text.trim().isNotEmpty
                      ? double.parse(maxDiscountController.text.trim())
                      : null,
                  minOrderValue: double.parse(minOrderController.text.trim()),
                  totalQuantity: int.parse(quantityController.text.trim()),
                  usedQuantity: voucher?.usedQuantity ?? 0,
                  validFrom: validFrom,
                  validTo: validTo,
                  isActive: voucher?.isActive ?? true,
                  usedBy: voucher?.usedBy,
                );

                try {
                  if (isEdit) {
                    await _firestoreService.updateVoucher(newVoucher);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cập nhật voucher thành công!')),
                      );
                    }
                  } else {
                    await _firestoreService.addVoucher(newVoucher);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thêm voucher thành công!')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleVoucherStatus(Voucher voucher) async {
    try {
      await _firestoreService.updateVoucher(
        voucher.copyWith(isActive: !voucher.isActive),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(voucher.isActive ? 'Đã tạm dừng voucher' : 'Đã kích hoạt voucher'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _deleteVoucher(Voucher voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa voucher "${voucher.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteVoucher(voucher.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa voucher thành công!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }
}
