// lib/screens/admin/manage_employees_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../models/employee.dart';
import '../../services/admin_service.dart';
import 'admin_ui.dart';

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  final AdminService _adminService = AdminService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedRole = 'stylist';
  String? _selectedStylistId;
  List<Map<String, dynamic>> _availableStylists = [];
  bool _isLoading = false;
  Employee? _editingEmployee;

  @override
  void initState() {
    super.initState();
    _loadAvailableStylists();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableStylists() async {
    try {
      final stylists = await _adminService.getAvailableStylists();
      setState(() {
        _availableStylists = stylists;
      });
    } catch (e) {
      print('Error loading stylists: $e');
    }
  }

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _adminService.createEmployeeAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
        role: _selectedRole,
        stylistId: _selectedRole == 'stylist' ? _selectedStylistId : null,
      );

      if (mounted) {
        EasyLoading.showSuccess('Tạo tài khoản nhân viên thành công!');
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        EasyLoading.showError('Lỗi: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateEmployee() async {
    if (_editingEmployee == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _adminService.updateEmployee(
        employeeId: _editingEmployee!.id,
        data: {
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim().isNotEmpty 
              ? _phoneController.text.trim() 
              : null,
          'role': _selectedRole,
          'stylistId': _selectedRole == 'stylist' ? _selectedStylistId : null,
        },
      );

      if (mounted) {
        EasyLoading.showSuccess('Cập nhật nhân viên thành công!');
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        EasyLoading.showError('Lỗi: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _fullNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    setState(() {
      _selectedRole = 'stylist';
      _selectedStylistId = null;
      _editingEmployee = null;
    });
  }

  void _editEmployee(Employee employee) {
    setState(() {
      _editingEmployee = employee;
      _fullNameController.text = employee.fullName;
      _emailController.text = employee.email;
      _phoneController.text = employee.phoneNumber ?? '';
      _selectedRole = employee.role;
      _selectedStylistId = employee.stylistId;
    });
  }

  Future<void> _toggleEmployeeStatus(Employee employee) async {
    try {
      if (employee.isActive) {
        await _adminService.deactivateEmployee(employee.id);
        EasyLoading.showSuccess('Đã vô hiệu hóa nhân viên');
      } else {
        await _adminService.activateEmployee(employee.id);
        EasyLoading.showSuccess('Đã kích hoạt nhân viên');
      }
    } catch (e) {
      EasyLoading.showError('Lỗi: $e');
    }
  }

  Future<void> _deleteEmployee(String employeeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa nhân viên này?\n'
          'Lưu ý: Tài khoản đăng nhập của nhân viên sẽ vẫn tồn tại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteEmployee(employeeId);
        EasyLoading.showSuccess('Xóa nhân viên thành công!');
      } catch (e) {
        EasyLoading.showError('Lỗi: $e');
      }
    }
  }

  Future<void> _migrateStylistUsers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Di chuyển dữ liệu'),
        content: const Text(
          'Chức năng này sẽ tự động di chuyển các tài khoản stylist cũ '
          'từ hệ thống cũ sang hệ thống quản lý nhân viên mới.\n\n'
          'Bạn có muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        EasyLoading.show(status: 'Đang di chuyển dữ liệu...');
        final count = await _adminService.migrateUsersToEmployees();
        EasyLoading.dismiss();
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Hoàn thành'),
              content: Text('Đã di chuyển $count tài khoản stylist thành công!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        EasyLoading.showError('Lỗi: $e');
      }
    }
  }

  Future<String> _getStylistName(String? stylistId) async {
    if (stylistId == null) return 'N/A';
    try {
      final doc = await _firestore.collection('stylists').doc(stylistId).get();
      if (doc.exists) {
        return doc.data()?['name'] ?? 'N/A';
      }
    } catch (e) {
      print('Error getting stylist name: $e');
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Quản lý Nhân viên',
      body: Column(
        children: [
          // Form đăng ký/chỉnh sửa
          AdminSection(
            title: _editingEmployee != null 
                ? 'Chỉnh sửa Nhân viên' 
                : 'Đăng ký Tài khoản Nhân viên',
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Họ tên
                  TextFormField(
                    controller: _fullNameController,
                    decoration: adminInputDecoration(
                      'Họ và tên',
                      hintText: 'Nhập họ và tên nhân viên',
                      prefixIcon: const Icon(Icons.person, color: AdminColors.textSecondary),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Email & Password (chỉ hiện khi tạo mới)
                  if (_editingEmployee == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: adminInputDecoration(
                              'Email',
                              hintText: 'email@example.com',
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Số điện thoại
                  TextFormField(
                    controller: _phoneController,
                    decoration: adminInputDecoration(
                      'Số điện thoại (tùy chọn)',
                      hintText: '0123456789',
                      prefixIcon: const Icon(Icons.phone, color: AdminColors.textSecondary),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  
                  // Vai trò
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: adminInputDecoration(
                      'Vai trò',
                      prefixIcon: const Icon(Icons.work, color: AdminColors.info),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'stylist', child: Text('Stylist')),
                      DropdownMenuItem(value: 'manager', child: Text('Quản lý')),
                      DropdownMenuItem(value: 'receptionist', child: Text('Lễ tân')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                        if (_selectedRole != 'stylist') {
                          _selectedStylistId = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Chọn stylist (nếu vai trò là stylist)
                  if (_selectedRole == 'stylist') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedStylistId,
                      decoration: adminInputDecoration(
                        'Liên kết với Stylist',
                        prefixIcon: const Icon(Icons.person_pin, color: AdminColors.accent),
                      ),
                      hint: const Text('Chọn stylist'),
                      items: _availableStylists.map((stylist) {
                        return DropdownMenuItem<String>(
                          value: stylist['id'] as String,
                          child: Text(stylist['name'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStylistId = value;
                        });
                      },
                      validator: (value) {
                        if (_selectedRole == 'stylist' && value == null) {
                          return 'Vui lòng chọn stylist';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AdminPrimaryButton(
                          label: _editingEmployee != null ? 'Cập nhật' : 'Đăng ký',
                          icon: _editingEmployee != null ? Icons.save : Icons.person_add,
                          isLoading: _isLoading,
                          onPressed: _isLoading 
                              ? null 
                              : (_editingEmployee != null 
                                  ? _updateEmployee 
                                  : _createEmployee),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_editingEmployee != null)
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
          
          // Danh sách nhân viên
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _adminService.getEmployeesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AdminLoadingCard(message: 'Đang tải danh sách nhân viên...');
                }
                
                if (snapshot.hasError) {
                  return AdminEmptyState(
                    title: 'Có lỗi xảy ra',
                    subtitle: 'Không thể tải danh sách nhân viên: ${snapshot.error}',
                    icon: Icons.error_outline,
                    action: AdminPrimaryButton(
                      label: 'Thử lại',
                      icon: Icons.refresh,
                      onPressed: () => setState(() {}),
                    ),
                  );
                }
                
                final employees = snapshot.data?.docs
                    .map((doc) => Employee.fromFirestore(
                        doc as DocumentSnapshot<Map<String, dynamic>>))
                    .toList() ?? [];
                
                if (employees.isEmpty) {
                  return AdminEmptyState(
                    title: 'Chưa có nhân viên nào',
                    subtitle: 'Hãy đăng ký tài khoản nhân viên đầu tiên hoặc di chuyển dữ liệu cũ',
                    icon: Icons.people,
                    action: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AdminPrimaryButton(
                          label: 'Đăng ký nhân viên',
                          icon: Icons.person_add,
                          onPressed: _clearForm,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _migrateStylistUsers,
                          icon: const Icon(Icons.sync_alt),
                          label: const Text('Di chuyển dữ liệu cũ'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AdminColors.accent,
                            side: const BorderSide(color: AdminColors.accent),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  children: [
                    // Header với nút migration
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Danh sách nhân viên (${employees.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _migrateStylistUsers,
                            icon: const Icon(Icons.sync_alt, size: 18),
                            label: const Text('Di chuyển dữ liệu'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminColors.accent,
                              side: const BorderSide(color: AdminColors.accent),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          final employee = employees[index];
                          return AdminCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: employee.isActive 
                                                ? AdminColors.success 
                                                : AdminColors.textTertiary,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: employee.photoURL != null
                                              ? Image.network(
                                                  employee.photoURL!,
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
                                      
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    employee.fullName,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: employee.isActive 
                                                          ? AdminColors.textPrimary 
                                                          : AdminColors.textTertiary,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: employee.isActive
                                                        ? AdminColors.success.withOpacity(0.1)
                                                        : AdminColors.textTertiary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    employee.isActive ? 'Hoạt động' : 'Vô hiệu',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: employee.isActive
                                                          ? AdminColors.success
                                                          : AdminColors.textTertiary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.email,
                                                  size: 14,
                                                  color: AdminColors.textSecondary,
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    employee.email,
                                                    style: const TextStyle(
                                                      color: AdminColors.textSecondary,
                                                      fontSize: 14,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (employee.phoneNumber != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.phone,
                                                    size: 14,
                                                    color: AdminColors.textSecondary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    employee.phoneNumber!,
                                                    style: const TextStyle(
                                                      color: AdminColors.textSecondary,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.work,
                                                  size: 14,
                                                  color: AdminColors.info,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  employee.roleDisplayName,
                                                  style: const TextStyle(
                                                    color: AdminColors.info,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (employee.isStylist && employee.stylistId != null) ...[
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: FutureBuilder<String>(
                                                      future: _getStylistName(employee.stylistId),
                                                      builder: (context, snapshot) {
                                                        return Text(
                                                          '• ${snapshot.data ?? "..."}',
                                                          style: const TextStyle(
                                                            color: AdminColors.textSecondary,
                                                            fontSize: 13,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Actions row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Toggle status
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _toggleEmployeeStatus(employee),
                                          icon: Icon(
                                            employee.isActive ? Icons.block : Icons.check_circle,
                                            size: 18,
                                          ),
                                          label: Text(
                                            employee.isActive ? 'Vô hiệu hóa' : 'Kích hoạt',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: employee.isActive
                                                ? AdminColors.warning
                                                : AdminColors.success,
                                            side: BorderSide(
                                              color: employee.isActive
                                                  ? AdminColors.warning
                                                  : AdminColors.success,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // Edit button
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AdminColors.info.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.edit, color: AdminColors.info),
                                          tooltip: 'Chỉnh sửa',
                                          onPressed: () => _editEmployee(employee),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // Delete button
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AdminColors.danger.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.delete, color: AdminColors.danger),
                                          tooltip: 'Xóa',
                                          onPressed: () => _deleteEmployee(employee.id),
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
        ],
      ),
    );
  }
}
