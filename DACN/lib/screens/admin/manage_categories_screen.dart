// lib/screens/admin/manage_categories_screen.dart
import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/firestore_service.dart';
import 'admin_ui.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  Category? _editingCategory;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final categoryData = Category(
        id: _editingCategory?.id ?? '',
        name: _nameController.text.trim(),
      );

      if (_editingCategory != null) {
        await _firestoreService.updateCategory(categoryData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật danh mục thành công!')),
        );
      } else {
        await _firestoreService.addCategory(categoryData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm danh mục thành công!')),
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
    _editingCategory = null;
  }

  void _editCategory(Category category) {
    setState(() {
      _editingCategory = category;
      _nameController.text = category.name;
    });
  }

  Future<void> _deleteCategory(String categoryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa danh mục này?'),
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
        await _firestoreService.deleteCategory(categoryId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa danh mục thành công!')),
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
      title: 'Quản lý danh mục',
      floatingActionButton: FloatingActionButton(
        onPressed: _clearForm,
        backgroundColor: AdminColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Form
          AdminSection(
            title: _editingCategory != null ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới',
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: adminInputDecoration(
                      'Tên danh mục',
                      hintText: 'Nhập tên danh mục',
                      prefixIcon: const Icon(Icons.category, color: AdminColors.textSecondary),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập tên danh mục';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AdminPrimaryButton(
                          label: _editingCategory != null ? 'Cập nhật' : 'Thêm mới',
                          icon: _editingCategory != null ? Icons.save : Icons.add,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _addOrUpdateCategory,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_editingCategory != null)
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
            child: StreamBuilder<List<Category>>(
              stream: _firestoreService.getCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AdminLoadingCard(message: 'Đang tải danh sách danh mục...');
                }
                
                if (snapshot.hasError) {
                  return AdminEmptyState(
                    title: 'Có lỗi xảy ra',
                    subtitle: 'Không thể tải danh sách danh mục: ${snapshot.error}',
                    icon: Icons.error_outline,
                    action: AdminPrimaryButton(
                      label: 'Thử lại',
                      icon: Icons.refresh,
                      onPressed: () => setState(() {}),
                    ),
                  );
                }
                
                final categories = snapshot.data ?? [];
                
                if (categories.isEmpty) {
                  return AdminEmptyState(
                    title: 'Chưa có danh mục nào',
                    subtitle: 'Hãy thêm danh mục đầu tiên để bắt đầu',
                    icon: Icons.category,
                    action: AdminPrimaryButton(
                      label: 'Thêm danh mục',
                      icon: Icons.add,
                      onPressed: _clearForm,
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return AdminCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                        children: [
                          // Category Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AdminColors.accent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AdminColors.border,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.category,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Category Info
                          Expanded(
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AdminColors.textPrimary,
                              ),
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
                                    onPressed: () => _editCategory(category),
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
                                    onPressed: () => _deleteCategory(category.id),
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
