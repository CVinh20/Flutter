// lib/screens/admin/manage_stylists_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/stylist.dart';
import '../../services/mongo_admin_service.dart';
import '../../services/image_upload_service.dart';
import 'admin_ui.dart';

class ManageStylistsScreen extends StatefulWidget {
  const ManageStylistsScreen({super.key});

  @override
  State<ManageStylistsScreen> createState() => _ManageStylistsScreenState();
}

class _ManageStylistsScreenState extends State<ManageStylistsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _experienceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Controllers for account creation
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _accountFormKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  Stylist? _editingStylist;
  File? _selectedImage;
  String? _selectedBranchId;
  String? _selectedBranchName;
  Key _refreshKey = UniqueKey();
  List<Map<String, dynamic>> _branches = [];
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await MongoAdminService.getAllBranches();
      if (mounted) {
        setState(() {
          _branches = branches.map((b) => {
            'id': b.id,
            'name': b.name,
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách chi nhánh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _experienceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateStylist() async {
    print('🔍 DEBUG: _selectedBranchId = $_selectedBranchId');
    print('🔍 DEBUG: _selectedBranchName = $_selectedBranchName');
    print('🔍 DEBUG: _branches length = ${_branches.length}');
    
    if (!_formKey.currentState!.validate()) return;

    // Validate branch selection
    if (_selectedBranchId == null || _selectedBranchName == null || 
        _selectedBranchId!.isEmpty || _selectedBranchName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn chi nhánh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _imageController.text.trim();
      
      // Upload image if a new one was selected
      if (_selectedImage != null) {
        imageUrl = await ImageUploadService.uploadImage(_selectedImage!);
      }

      final stylistData = {
        'name': _nameController.text.trim(),
        'image': imageUrl,
        'rating': 5.0,
        'experience': _experienceController.text.trim(),
        'branchId': _selectedBranchId!,
        'branchName': _selectedBranchName!,
      };

      print('📤 Sending stylist data: $stylistData');

      if (_editingStylist != null) {
        // Update existing stylist
        await MongoAdminService.updateStylist(_editingStylist!.id, stylistData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật stylist thành công!')),
          );
        }
      } else {
        // Create new stylist
        final newStylist = await MongoAdminService.createStylist(stylistData);
        
        // Tự động tạo tài khoản nếu có email và password
        if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
          try {
            await MongoAdminService.createStylistAccount(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              stylistId: newStylist.id,
              stylistName: _nameController.text.trim(),
            );
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thêm stylist và tạo tài khoản thành công!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            print('Error creating account: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thêm stylist thành công nhưng tạo tài khoản thất bại: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thêm stylist thành công!')),
            );
          }
        }
      }

      _clearForm();
      setState(() {}); // Refresh UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _imageController.clear();
    _experienceController.clear();
    _emailController.clear();
    _passwordController.clear();
    _selectedImage = null;
    _selectedBranchId = null;
    _selectedBranchName = null;
    setState(() {
      _editingStylist = null;
      _showForm = false;
    });
  }

  void _showAddStylist() {
    _clearForm();
    setState(() {
      _showForm = true;
    });
  }

  void _editStylist(Stylist stylist) {
    setState(() {
      _editingStylist = stylist;
      _nameController.text = stylist.name;
      _experienceController.text = stylist.experience;
      _imageController.text = stylist.image;
      _selectedBranchId = stylist.branchId;
      _selectedBranchName = stylist.branchName;
      _showForm = true;
    });
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
        await MongoAdminService.deleteStylist(stylistId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa stylist thành công!')),
        );
        setState(() {}); // Refresh UI
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _showCreateAccountDialog(Stylist stylist) async {
    _emailController.clear();
    _passwordController.clear();
    
    final accountUser = await MongoAdminService.getStylistUser(stylist.id);
    final hasAccount = accountUser != null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasAccount ? 'Thông tin tài khoản' : 'Tạo tài khoản cho Stylist'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasAccount) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AdminColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stylist đã có tài khoản',
                          style: TextStyle(
                            color: AdminColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Email: ${accountUser.email}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Tên: ${accountUser.displayName}'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AdminDangerButton(
                    label: 'Hủy liên kết tài khoản',
                    icon: Icons.link_off,
                    onPressed: () async {
                      Navigator.pop(context);
                      await _unlinkAccount(stylist.id);
                    },
                  ),
                ),
              ] else ...[
                Form(
                  key: _accountFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: adminInputDecoration(
                          'Email',
                          hintText: 'stylist@example.com',
                          prefixIcon: const Icon(Icons.email, color: AdminColors.textSecondary),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Vui lòng nhập email';
                          }
                          if (!value!.contains('@')) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: adminInputDecoration(
                          'Mật khẩu',
                          hintText: 'Tối thiểu 6 ký tự',
                          prefixIcon: const Icon(Icons.lock, color: AdminColors.textSecondary),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          if (value!.length < 6) {
                            return 'Mật khẩu phải có ít nhất 6 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lưu ý: Nếu email đã tồn tại, hệ thống sẽ liên kết tài khoản hiện có với stylist này.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (!hasAccount)
            AdminPrimaryButton(
              label: 'Tạo tài khoản',
              icon: Icons.person_add,
              onPressed: () async {
                if (_accountFormKey.currentState?.validate() ?? false) {
                  Navigator.pop(context);
                  await _createAccount(stylist);
                }
              },
            ),
        ],
      ),
    );
  }

  Future<void> _createAccount(Stylist stylist) async {
    try {
      await EasyLoading.show(status: 'Đang tạo tài khoản...');
      
      await MongoAdminService.createStylistAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        stylistId: stylist.id,
        stylistName: stylist.name,
      );
      
      await EasyLoading.dismiss();
      EasyLoading.showSuccess('Tạo tài khoản thành công!');
      
      // Refresh list
      setState(() {
        _refreshKey = UniqueKey();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tài khoản đã được tạo với email: ${_emailController.text.trim()}'),
            backgroundColor: AdminColors.success,
          ),
        );
      }
    } catch (e) {
      await EasyLoading.dismiss();
      EasyLoading.showError('Lỗi: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo tài khoản: $e'),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _unlinkAccount(String stylistId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa tài khoản này? Stylist sẽ không thể đăng nhập nữa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await EasyLoading.show(status: 'Đang xử lý...');
        // Delete the user account associated with this stylist
        final user = await MongoAdminService.getStylistUser(stylistId);
        if (user != null) {
          await MongoAdminService.deleteUser(user.id);
          EasyLoading.showSuccess('Xóa tài khoản thành công!');
        } else {
          EasyLoading.showInfo('Không tìm thấy tài khoản');
        }
        await EasyLoading.dismiss();
      } catch (e) {
        await EasyLoading.dismiss();
        EasyLoading.showError('Lỗi: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return AdminScaffold(
      title: 'Quản lý Stylist',
      body: Column(
        children: [
          // Form thêm/sửa stylist
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _editingStylist != null ? Icons.edit : Icons.person_add,
                          color: const Color(0xFF6366F1),
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _editingStylist != null ? 'Chỉnh sửa Stylist' : 'Thêm Stylist mới',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            if (!isMobile) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Điền thông tin để thêm stylist mới',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  
                  // Responsive layout
                  if (isMobile) ...[
                    // Mobile: Stack vertically
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên stylist',
                        hintText: 'Nhập tên đầy đủ',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        isDense: true,
                      ),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Nhập tên' : null,
                    ),
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _experienceController,
                      decoration: InputDecoration(
                        labelText: 'Kinh nghiệm',
                        hintText: 'VD: 5 năm',
                        prefixIcon: const Icon(Icons.work_outline, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        isDense: true,
                      ),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Nhập KN' : null,
                    ),
                    const SizedBox(height: 12),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedBranchId,
                      decoration: InputDecoration(
                        labelText: 'Chi nhánh',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        isDense: true,
                      ),
                      items: _branches.map((b) => DropdownMenuItem<String>(
                        value: b['id'] as String,
                        child: Text(b['name'] as String, style: const TextStyle(fontSize: 14)),
                      )).toList(),
                      onChanged: (v) => setState(() {
                        _selectedBranchId = v;
                        _selectedBranchName = _branches.firstWhere((b) => b['id'] == v)['name'] as String?;
                      }),
                      validator: (v) => v == null ? 'Chọn CN' : null,
                    ),
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(
                          _selectedImage != null ? Icons.check_circle : Icons.image_outlined,
                          color: _selectedImage != null ? Colors.green : const Color(0xFF6366F1),
                          size: 20,
                        ),
                        label: Text(
                          _selectedImage != null ? 'Đã chọn ảnh' : 'Chọn ảnh',
                          style: TextStyle(
                            color: _selectedImage != null ? Colors.green : const Color(0xFF6366F1),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: _selectedImage != null ? Colors.green : const Color(0xFF6366F1),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Desktop: 2 columns
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Tên stylist',
                              hintText: 'Nhập tên đầy đủ',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (v) => (v?.isEmpty ?? true) ? 'Vui lòng nhập tên' : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _experienceController,
                            decoration: InputDecoration(
                              labelText: 'Kinh nghiệm',
                              hintText: 'VD: 5 năm',
                              prefixIcon: const Icon(Icons.work_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (v) => (v?.isEmpty ?? true) ? 'Vui lòng nhập kinh nghiệm' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _selectedBranchId,
                            decoration: InputDecoration(
                              labelText: 'Chi nhánh',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: _branches.map((b) => DropdownMenuItem<String>(
                              value: b['id'] as String,
                              child: Text(b['name'] as String),
                            )).toList(),
                            onChanged: (v) => setState(() {
                              _selectedBranchId = v;
                              _selectedBranchName = _branches.firstWhere((b) => b['id'] == v)['name'] as String?;
                            }),
                            validator: (v) => v == null ? 'Vui lòng chọn chi nhánh' : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(
                              _selectedImage != null ? Icons.check_circle : Icons.image_outlined,
                              color: _selectedImage != null ? Colors.green : const Color(0xFF6366F1),
                            ),
                            label: Text(
                              _selectedImage != null ? 'Đã chọn ảnh' : 'Chọn ảnh',
                              style: TextStyle(
                                color: _selectedImage != null ? Colors.green : const Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                              side: BorderSide(
                                color: _selectedImage != null ? Colors.green : const Color(0xFF6366F1),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  SizedBox(height: isMobile ? 16 : 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      if (!isMobile) const Spacer(),
                      if (_editingStylist != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearForm,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Hủy'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 24,
                                vertical: isMobile ? 12 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: _editingStylist != null ? 1 : (isMobile ? 1 : 0),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _addOrUpdateStylist,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(_editingStylist != null ? Icons.save : Icons.add, size: 20),
                          label: Text(
                            _editingStylist != null ? 'Cập nhật' : 'Thêm Stylist',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 28,
                              vertical: isMobile ? 12 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Danh sách stylist ở dưới
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: FutureBuilder<List<Stylist>>(
                key: _refreshKey,
                future: MongoAdminService.getAllStylists(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 12),
                            Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => setState(() {}),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final stylists = snapshot.data ?? [];
                  
                  if (stylists.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: isMobile ? 60 : 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có stylist nào',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Điền form phía trên để thêm stylist',
                              style: TextStyle(color: Colors.grey[500], fontSize: isMobile ? 13 : 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Row(
                          children: [
                            Text(
                              'Danh sách Stylist',
                              style: TextStyle(
                                fontSize: isMobile ? 15 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${stylists.length} người',
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 16 : 24,
                            0,
                            isMobile ? 16 : 24,
                            isMobile ? 16 : 24,
                          ),
                          itemCount: stylists.length,
                          itemBuilder: (context, index) {
                            final stylist = stylists[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 14 : 20),
                                child: isMobile
                                    ? Column(
                                        children: [
                                          Row(
                                            children: [
                                              // Avatar
                                              Stack(
                                                children: [
                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: stylist.userId != null 
                                                            ? const Color(0xFF10B981) 
                                                            : Colors.grey[300]!,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: ClipOval(
                                                      child: stylist.image.isNotEmpty
                                                          ? Image.network(
                                                              stylist.image,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (_, __, ___) => Container(
                                                                color: Colors.grey[100],
                                                                child: Icon(Icons.person, size: 24, color: Colors.grey[400]),
                                                              ),
                                                            )
                                                          : Container(
                                                              color: Colors.grey[100],
                                                              child: Icon(Icons.person, size: 24, color: Colors.grey[400]),
                                                            ),
                                                    ),
                                                  ),
                                                  if (stylist.userId != null)
                                                    Positioned(
                                                      right: 0,
                                                      bottom: 0,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(3),
                                                        decoration: const BoxDecoration(
                                                          color: Color(0xFF10B981),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.check, size: 10, color: Colors.white),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(width: 12),
                                              
                                              // Info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      stylist.name,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF1F2937),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.work_outline, size: 13, color: Colors.grey[600]),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            stylist.experience,
                                                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: stylist.userId != null 
                                                        ? const Color(0xFF10B981).withOpacity(0.1)
                                                        : Colors.orange.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        stylist.userId != null ? Icons.check_circle : Icons.info_outline,
                                                        size: 12,
                                                        color: stylist.userId != null ? const Color(0xFF10B981) : Colors.orange,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          stylist.userId != null ? 'Đã có tài khoản' : 'Chưa có tài khoản',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: stylist.userId != null ? const Color(0xFF10B981) : Colors.orange,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          
                                          // Actions
                                          Row(
                                            children: [
                                              Expanded(
                                                child: IconButton(
                                                  onPressed: () => _showCreateAccountDialog(stylist),
                                                  icon: Icon(
                                                    stylist.userId != null ? Icons.person : Icons.person_add,
                                                    color: stylist.userId != null ? const Color(0xFF10B981) : Colors.orange,
                                                    size: 20,
                                                  ),
                                                  tooltip: stylist.userId != null ? 'Xem TK' : 'Tạo TK',
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: (stylist.userId != null 
                                                        ? const Color(0xFF10B981) 
                                                        : Colors.orange).withOpacity(0.1),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: IconButton(
                                                  onPressed: () => _editStylist(stylist),
                                                  icon: const Icon(Icons.edit, color: Color(0xFF6366F1), size: 20),
                                                  tooltip: 'Sửa',
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: IconButton(
                                                  onPressed: () => _deleteStylist(stylist.id),
                                                  icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 20),
                                                  tooltip: 'Xóa',
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          // Desktop layout (unchanged)
                                          Stack(
                                            children: [
                                              Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: stylist.userId != null 
                                                        ? const Color(0xFF10B981) 
                                                        : Colors.grey[300]!,
                                                    width: 3,
                                                  ),
                                                ),
                                                child: ClipOval(
                                                  child: stylist.image.isNotEmpty
                                                      ? Image.network(
                                                          stylist.image,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => Container(
                                                            color: Colors.grey[100],
                                                            child: Icon(Icons.person, size: 35, color: Colors.grey[400]),
                                                          ),
                                                        )
                                                      : Container(
                                                          color: Colors.grey[100],
                                                          child: Icon(Icons.person, size: 35, color: Colors.grey[400]),
                                                        ),
                                                ),
                                              ),
                                              if (stylist.userId != null)
                                                Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(5),
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF10B981),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  stylist.name,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      stylist.experience,
                                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: stylist.userId != null 
                                                            ? const Color(0xFF10B981).withOpacity(0.1)
                                                            : Colors.orange.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            stylist.userId != null ? Icons.check_circle : Icons.info_outline,
                                                            size: 14,
                                                            color: stylist.userId != null ? const Color(0xFF10B981) : Colors.orange,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            stylist.userId != null ? 'Đã có tài khoản' : 'Chưa có tài khoản',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                              color: stylist.userId != null ? const Color(0xFF10B981) : Colors.orange,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: () => _showCreateAccountDialog(stylist),
                                                icon: Icon(
                                                  stylist.userId != null ? Icons.person : Icons.person_add,
                                                  color: stylist.userId != null ? const Color(0xFF10B981) : Colors.orange,
                                                ),
                                                tooltip: stylist.userId != null ? 'Xem tài khoản' : 'Tạo tài khoản',
                                                style: IconButton.styleFrom(
                                                  backgroundColor: (stylist.userId != null 
                                                      ? const Color(0xFF10B981) 
                                                      : Colors.orange).withOpacity(0.1),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                onPressed: () => _editStylist(stylist),
                                                icon: const Icon(Icons.edit, color: Color(0xFF6366F1)),
                                                tooltip: 'Chỉnh sửa',
                                                style: IconButton.styleFrom(
                                                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                onPressed: () => _deleteStylist(stylist.id),
                                                icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                                                tooltip: 'Xóa',
                                                style: IconButton.styleFrom(
                                                  backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
