// lib/screens/admin/manage_services_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service.dart';
import '../../models/category.dart';
import '../../services/firestore_service.dart';
import 'admin_ui.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _imageController = TextEditingController();
  final _ratingController = TextEditingController();
  
  bool _isLoading = false;
  Service? _editingService;
  String? _selectedCategoryId;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _imageController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final serviceData = Service(
        id: _editingService?.id ?? '',
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        duration: _durationController.text.trim(),
        image: _imageController.text.trim(),
        rating: double.parse(_ratingController.text.trim()),
        categoryId: _selectedCategoryId ?? '',
      );

      if (_editingService != null) {
        await _firestoreService.updateService(serviceData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật dịch vụ thành công!')),
        );
      } else {
        await _firestoreService.addService(serviceData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm dịch vụ thành công!')),
        );
      }

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _durationController.clear();
    _imageController.clear();
    _ratingController.clear();
    _selectedCategoryId = null;
    _editingService = null;
  }

  void _editService(Service service) {
    setState(() {
      _editingService = service;
      _nameController.text = service.name;
      _priceController.text = service.price.toString();
      _durationController.text = service.duration;
      _imageController.text = service.image;
      _ratingController.text = service.rating.toString();
      // Chỉ set categoryId nếu nó không rỗng
      _selectedCategoryId = service.categoryId.isNotEmpty ? service.categoryId : null;
    });
  }

  Future<void> _deleteService(String serviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa dịch vụ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('services').doc(serviceId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa dịch vụ thành công!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Quản lý dịch vụ',
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _clearForm();
        },
        backgroundColor: AdminColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Form
          AdminSection(
            title: _editingService != null ? 'Chỉnh sửa dịch vụ' : 'Thêm dịch vụ mới',
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: adminInputDecoration(
                      'Tên dịch vụ',
                      hintText: 'Nhập tên dịch vụ',
                      prefixIcon: const Icon(Icons.build, color: AdminColors.textSecondary),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập tên dịch vụ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySelector(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: adminInputDecoration(
                            'Giá (VNĐ)',
                            hintText: '100000',
                            prefixIcon: const Icon(Icons.attach_money, color: AdminColors.success),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Vui lòng nhập giá';
                            }
                            if (double.tryParse(value!) == null) {
                              return 'Giá không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration: adminInputDecoration(
                            'Thời gian',
                            hintText: '60 phút',
                            prefixIcon: const Icon(Icons.access_time, color: AdminColors.info),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Vui lòng nhập thời gian';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ratingController,
                          keyboardType: TextInputType.number,
                          decoration: adminInputDecoration(
                            'Đánh giá (0-5)',
                            hintText: '4.5',
                            prefixIcon: const Icon(Icons.star, color: AdminColors.warning),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Vui lòng nhập đánh giá';
                            }
                            final rating = double.tryParse(value!);
                            if (rating == null || rating < 0 || rating > 5) {
                              return 'Đánh giá phải từ 0-5';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _imageController,
                          decoration: adminInputDecoration(
                            'URL hình ảnh',
                            hintText: 'https://example.com/image.jpg',
                            prefixIcon: const Icon(Icons.image, color: AdminColors.accent),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Vui lòng nhập URL hình ảnh';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AdminPrimaryButton(
                          label: _editingService != null ? 'Cập nhật' : 'Thêm mới',
                          icon: _editingService != null ? Icons.save : Icons.add,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _addOrUpdateService,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_editingService != null)
                        Expanded(
                          child: AdminDangerButton(
                            label: 'Hủy',
                            icon: Icons.close,
                            onPressed: _clearForm,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AdminLoadingCard(message: 'Đang tải danh sách dịch vụ...');
                }
                
                if (snapshot.hasError) {
                  return AdminEmptyState(
                    title: 'Có lỗi xảy ra',
                    subtitle: 'Không thể tải danh sách dịch vụ: ${snapshot.error}',
                    icon: Icons.error_outline,
                    action: AdminPrimaryButton(
                      label: 'Thử lại',
                      icon: Icons.refresh,
                      onPressed: () => setState(() {}),
                    ),
                  );
                }
                
                final services = snapshot.data?.docs
                    .map((doc) => Service.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
                    .toList() ?? [];
                
                if (services.isEmpty) {
                  return AdminEmptyState(
                    title: 'Chưa có dịch vụ nào',
                    subtitle: 'Hãy thêm dịch vụ đầu tiên để bắt đầu',
                    icon: Icons.build,
                    action: AdminPrimaryButton(
                      label: 'Thêm dịch vụ',
                      icon: Icons.add,
                      onPressed: () {
                        _clearForm();
                      },
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return AdminCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Service Image
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AdminColors.border,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: service.image.isNotEmpty
                                    ? Image.network(
                                        service.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: AdminColors.surfaceAlt,
                                            child: const Icon(
                                              Icons.build,
                                              color: AdminColors.textSecondary,
                                              size: 30,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: AdminColors.surfaceAlt,
                                        child: const Icon(
                                          Icons.build,
                                          color: AdminColors.textSecondary,
                                          size: 30,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Service Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AdminColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.attach_money,
                                        size: 16,
                                        color: AdminColors.success,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${service.price.toStringAsFixed(0)} VNĐ',
                                        style: const TextStyle(
                                          color: AdminColors.textSecondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: AdminColors.info,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        service.duration,
                                        style: const TextStyle(
                                          color: AdminColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AdminColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: AdminColors.info),
                                    onPressed: () => _editService(service),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AdminColors.danger.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: AdminColors.danger),
                                    onPressed: () => _deleteService(service.id),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  Widget _buildCategorySelector() {
    return StreamBuilder<List<Category>>(
      stream: _firestoreService.getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AdminColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.border),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final categories = snapshot.data!;
        if (categories.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.border),
            ),
            child: const Text(
              'Chưa có danh mục nào. Vui lòng tạo danh mục trước.',
              style: TextStyle(color: AdminColors.textSecondary),
            ),
          );
        }

        // Kiểm tra xem selectedCategoryId có tồn tại trong danh sách không
        final validSelectedId = _selectedCategoryId != null && 
            categories.any((cat) => cat.id == _selectedCategoryId) 
            ? _selectedCategoryId 
            : null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AdminColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: validSelectedId != null ? AdminColors.accent : AdminColors.border,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text(
                'Chọn danh mục',
                style: TextStyle(color: AdminColors.textSecondary),
              ),
              value: validSelectedId,
              dropdownColor: AdminColors.surface,
              style: const TextStyle(color: AdminColors.textPrimary),
              onChanged: (value) => setState(() => _selectedCategoryId = value),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

}
