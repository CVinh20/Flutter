// lib/screens/admin/manage_branches_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/branch.dart';
import '../../services/branch_service.dart';
import '../../services/image_upload_service.dart';
import 'admin_ui.dart';

class ManageBranchesScreen extends StatefulWidget {
  const ManageBranchesScreen({super.key});

  @override
  State<ManageBranchesScreen> createState() => _ManageBranchesScreenState();
}

class _ManageBranchesScreenState extends State<ManageBranchesScreen> {
  final BranchService _branchService = BranchService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _hoursController = TextEditingController();
  final _imageController = TextEditingController();
  final _ratingController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  Branch? _editingBranch;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    _imageController.dispose();
    _ratingController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateBranch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl = _imageController.text.trim();
      
      // Upload image if a new one was selected
      if (_selectedImage != null) {
        imageUrl = await ImageUploadService.uploadImage(_selectedImage!);
      }

      final branch = Branch(
        id: _editingBranch?.id ?? '',
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        hours: _hoursController.text.trim(),
        image: imageUrl,
        rating: double.parse(_ratingController.text.trim()),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
      );

      if (_editingBranch != null) {
        await _branchService.updateBranch(_editingBranch!.id, branch);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật chi nhánh thành công!')),
          );
        }
      } else {
        await _branchService.createBranch(branch);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm chi nhánh thành công!')),
          );
        }
      }

      _clearForm();
      setState(() {}); // Refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _addressController.clear();
    _hoursController.clear();
    _imageController.clear();
    _ratingController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _editingBranch = null;
    _selectedImage = null;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageController.text = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  void _editBranch(Branch branch) {
    setState(() {
      _editingBranch = branch;
      _nameController.text = branch.name;
      _addressController.text = branch.address;
      _hoursController.text = branch.hours;
      _imageController.text = branch.image;
      _ratingController.text = branch.rating.toString();
      _latitudeController.text = branch.latitude.toString();
      _longitudeController.text = branch.longitude.toString();
    });
  }

  Future<void> _deleteBranch(String branchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa chi nhánh này?'),
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
        await _branchService.deleteBranch(branchId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa chi nhánh thành công!')),
          );
          setState(() {}); // Refresh list
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

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Quản lý chi nhánh',
      body: Column(
        children: [
          // Form
          AdminSection(
            title: _editingBranch != null ? 'Chỉnh sửa Chi nhánh' : 'Thêm Chi nhánh mới',
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: adminInputDecoration(
                      'Tên chi nhánh',
                      hintText: 'Nhập tên chi nhánh',
                      prefixIcon: const Icon(Icons.store, color: AdminColors.textSecondary),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập tên chi nhánh';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: adminInputDecoration(
                      'Địa chỉ',
                      hintText: 'Nhập địa chỉ chi nhánh',
                      prefixIcon: const Icon(Icons.location_on, color: AdminColors.textSecondary),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập địa chỉ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _hoursController,
                          decoration: adminInputDecoration(
                            'Giờ hoạt động',
                            hintText: '8:00 - 22:00',
                            prefixIcon: const Icon(Icons.access_time, color: AdminColors.info),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Vui lòng nhập giờ hoạt động';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          keyboardType: TextInputType.number,
                          decoration: adminInputDecoration(
                            'Vĩ độ',
                            hintText: '10.762622',
                            prefixIcon: const Icon(Icons.my_location, color: AdminColors.accent),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Vui lòng nhập vĩ độ';
                            }
                            if (double.tryParse(value!) == null) {
                              return 'Vĩ độ không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          keyboardType: TextInputType.number,
                          decoration: adminInputDecoration(
                            'Kinh độ',
                            hintText: '106.660172',
                            prefixIcon: const Icon(Icons.my_location, color: AdminColors.accent),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Vui lòng nhập kinh độ';
                            }
                            if (double.tryParse(value!) == null) {
                              return 'Kinh độ không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Image picker section
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: Text(_selectedImage != null ? 'Đã chọn ảnh' : 'Chọn ảnh từ thư viện'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: _selectedImage != null ? AdminColors.success : AdminColors.border,
                            ),
                            foregroundColor: _selectedImage != null ? AdminColors.success : AdminColors.textSecondary,
                          ),
                        ),
                      ),
                      if (_selectedImage != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AdminColors.border),
                            image: DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AdminPrimaryButton(
                          label: _editingBranch != null ? 'Cập nhật' : 'Thêm mới',
                          icon: _editingBranch != null ? Icons.save : Icons.add,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _addOrUpdateBranch,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_editingBranch != null)
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
            child: FutureBuilder<List<Branch>>(
              future: _branchService.getAllBranches(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Lỗi: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                
                final branches = snapshot.data ?? [];
                
                if (branches.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có chi nhánh nào',
                      style: TextStyle(color: AdminColors.textSecondary),
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    return AdminCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Branch Image
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
                                child: branch.image.isNotEmpty
                                    ? Image.network(
                                        branch.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: AdminColors.surfaceAlt,
                                            child: const Icon(
                                              Icons.store,
                                              color: AdminColors.textSecondary,
                                              size: 30,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: AdminColors.surfaceAlt,
                                        child: const Icon(
                                          Icons.store,
                                          color: AdminColors.textSecondary,
                                          size: 30,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Branch Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    branch.name,
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
                                        Icons.location_on,
                                        size: 16,
                                        color: AdminColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          branch.address,
                                          style: const TextStyle(
                                            color: AdminColors.textSecondary,
                                            fontSize: 14,
                                          ),
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
                                        branch.hours,
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
                                    onPressed: () => _editBranch(branch),
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
                                    onPressed: () => _deleteBranch(branch.id),
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
