// lib/screens/admin/manage_stylists_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/stylist.dart';
import 'admin_ui.dart';

class ManageStylistsScreen extends StatefulWidget {
  const ManageStylistsScreen({super.key});

  @override
  State<ManageStylistsScreen> createState() => _ManageStylistsScreenState();
}

class _ManageStylistsScreenState extends State<ManageStylistsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _ratingController = TextEditingController();
  final _experienceController = TextEditingController();
  
  bool _isLoading = false;
  Stylist? _editingStylist;

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _ratingController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateStylist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final stylistData = {
        'name': _nameController.text.trim(),
        'image': _imageController.text.trim(),
        'rating': double.parse(_ratingController.text.trim()),
        'experience': _experienceController.text.trim(),
      };

      if (_editingStylist != null) {
        await _firestore.collection('stylists').doc(_editingStylist!.id).update(stylistData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật stylist thành công!')),
        );
      } else {
        await _firestore.collection('stylists').add(stylistData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm stylist thành công!')),
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
    _imageController.clear();
    _ratingController.clear();
    _experienceController.clear();
    _editingStylist = null;
  }

  void _editStylist(Stylist stylist) {
    setState(() {
      _editingStylist = stylist;
      _nameController.text = stylist.name;
      _imageController.text = stylist.image;
      _ratingController.text = stylist.rating.toString();
      _experienceController.text = stylist.experience;
    });
  }

  Future<void> _deleteStylist(String stylistId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa stylist này?'),
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
        await _firestore.collection('stylists').doc(stylistId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa stylist thành công!')),
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
      title: 'Quản lý Stylist',
      body: Column(
        children: [
          // Form
          AdminSection(
            title: _editingStylist != null ? 'Chỉnh sửa Stylist' : 'Thêm Stylist mới',
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: adminInputDecoration(
                      'Tên stylist',
                      hintText: 'Nhập tên stylist',
                      prefixIcon: const Icon(Icons.person, color: AdminColors.textSecondary),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập tên stylist';
                      }
                      return null;
                    },
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
                          controller: _experienceController,
                          decoration: adminInputDecoration(
                            'Kinh nghiệm',
                            hintText: '3 năm kinh nghiệm',
                            prefixIcon: const Icon(Icons.work, color: AdminColors.info),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Vui lòng nhập kinh nghiệm';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AdminPrimaryButton(
                          label: _editingStylist != null ? 'Cập nhật' : 'Thêm mới',
                          icon: _editingStylist != null ? Icons.save : Icons.add,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _addOrUpdateStylist,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_editingStylist != null)
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
              stream: _firestore.collection('stylists').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AdminLoadingCard(message: 'Đang tải danh sách stylist...');
                }
                
                if (snapshot.hasError) {
                  return AdminEmptyState(
                    title: 'Có lỗi xảy ra',
                    subtitle: 'Không thể tải danh sách stylist: ${snapshot.error}',
                    icon: Icons.error_outline,
                    action: AdminPrimaryButton(
                      label: 'Thử lại',
                      icon: Icons.refresh,
                      onPressed: () => setState(() {}),
                    ),
                  );
                }
                
                final stylists = snapshot.data?.docs
                    .map((doc) => Stylist.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
                    .toList() ?? [];
                
                if (stylists.isEmpty) {
                  return AdminEmptyState(
                    title: 'Chưa có stylist nào',
                    subtitle: 'Hãy thêm stylist đầu tiên để bắt đầu',
                    icon: Icons.person,
                    action: AdminPrimaryButton(
                      label: 'Thêm stylist',
                      icon: Icons.add,
                      onPressed: () {
                        _clearForm();
                      },
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: stylists.length,
                  itemBuilder: (context, index) {
                    final stylist = stylists[index];
                    return AdminCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Stylist Image
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AdminColors.border,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: stylist.image.isNotEmpty
                                    ? Image.network(
                                        stylist.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: AdminColors.surfaceAlt,
                                            child: const Icon(
                                              Icons.person,
                                              color: AdminColors.textSecondary,
                                              size: 30,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: AdminColors.surfaceAlt,
                                        child: const Icon(
                                          Icons.person,
                                          color: AdminColors.textSecondary,
                                          size: 30,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Stylist Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stylist.name,
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
                                        Icons.work,
                                        size: 16,
                                        color: AdminColors.info,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        stylist.experience,
                                        style: const TextStyle(
                                          color: AdminColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: AdminColors.warning,
                                      ),
                                      const SizedBox(width: 6),
                            Text(
                                        '${stylist.rating.toStringAsFixed(1)}/5',
                                        style: const TextStyle(
                                          color: AdminColors.textSecondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
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
                              onPressed: () => _editStylist(stylist),
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
                              onPressed: () => _deleteStylist(stylist.id),
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
}
