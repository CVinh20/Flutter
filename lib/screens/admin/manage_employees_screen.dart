// // lib/screens/admin/manage_employees_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import '../../models/employee.dart';
// import '../../models/user.dart';
// import '../../services/mongo_admin_service.dart';
// import 'admin_ui.dart';

// class ManageEmployeesScreen extends StatefulWidget {
//   const ManageEmployeesScreen({super.key});

//   @override
//   State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
// }

// class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
//   // Form controllers
//   final _formKey = GlobalKey<FormState>();
//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _phoneController = TextEditingController();
  
//   String _selectedRole = 'stylist';
//   String? _selectedStylistId;
//   List<Map<String, dynamic>> _availableStylists = [];
//   bool _isLoading = false;
//   Employee? _editingEmployee;

//   @override
//   void initState() {
//     super.initState();
//     _loadAvailableStylists();
//   }

//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadAvailableStylists() async {
//     try {
//       final stylists = await MongoAdminService.getAvailableStylists();
//       if (mounted) {
//         setState(() {
//           _availableStylists = stylists;
//         });
//       }
//     } catch (e) {
//       print('Error loading stylists: $e');
//       if (mounted) {
//         setState(() {
//           _availableStylists = [];
//         });
//       }
//     }

//   Future<void> _createEmployee() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       if (_selectedRole == 'stylist' && _selectedStylistId == null) {
//         EasyLoading.showError('Vui lòng chọn stylist');
//         setState(() => _isLoading = false);
//         return;
//       }
      
//       await MongoAdminService.createStylistAccount(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//         stylistId: _selectedStylistId,
//         stylistName: _fullNameController.text.trim(),
//       );

//       if (mounted) {
//         EasyLoading.showSuccess('Tạo tài khoản nhân viên thành công!');
//         _clearForm();
//       }
//     } catch (e) {
//       if (mounted) {
//         EasyLoading.showError('Lỗi: $e');
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _updateEmployee() async {
//     if (_editingEmployee == null) return;
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       // TODO: Implement update user via MongoAdminService
//       await MongoAdminService.updateUser(
//         _editingEmployee!.id,
//         {
//           'displayName': _fullNameController.text.trim(),
//           'role': _selectedRole,
//           'stylistId': _selectedRole == 'stylist' ? _selectedStylistId : null,
//         },
//       );

//       if (mounted) {
//         EasyLoading.showSuccess('Cập nhật nhân viên thành công!');
//         _clearForm();
//       }
//     } catch (e) {
//       if (mounted) {
//         EasyLoading.showError('Lỗi: $e');
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _clearForm() {
//     _fullNameController.clear();
//     _emailController.clear();
//     _passwordController.clear();
//     _phoneController.clear();
//     setState(() {
//       _selectedRole = 'stylist';
//       _selectedStylistId = null;
//       _editingEmployee = null;
//     });
//   }

//   void _editEmployee(Employee employee) {
//     setState(() {
//       _editingEmployee = employee;
//       _fullNameController.text = employee.fullName;
//       _emailController.text = employee.email;
//       _phoneController.text = employee.phoneNumber ?? '';
//       _selectedRole = employee.role;
//       _selectedStylistId = employee.stylistId;
//     });
//   }

//   Future<void> _toggleEmployeeStatus(Employee employee) async {
//     try {
//       // TODO: Implement user status toggle via MongoAdminService
//       await MongoAdminService.updateUser(
//         employee.id,
//         {'isActive': !employee.isActive},
//       );
//       EasyLoading.showSuccess(employee.isActive ? 'Đã vô hiệu hóa nhân viên' : 'Đã kích hoạt nhân viên');
//     } catch (e) {
//       EasyLoading.showError('Lỗi: $e');
//     }
//   }

//   Future<void> _deleteEmployee(String employeeId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Xác nhận xóa'),
//         content: const Text(
//           'Bạn có chắc chắn muốn xóa nhân viên này?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Hủy'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Xóa'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await MongoAdminService.deleteUser(employeeId);
//         EasyLoading.showSuccess('Xóa nhân viên thành công!');
//       } catch (e) {
//         EasyLoading.showError('Lỗi: $e');
//       }
//     }
//   }

//   Future<void> _migrateStylistUsers() async {
//     // TODO: Not implemented - requires backend migration API
//     EasyLoading.showInfo('Chức năng này chưa được triển khai');
//   }

//   Future<String> _getStylistName(String? stylistId) async {
//     if (stylistId == null) return 'N/A';
//     try {
//       final stylists = await MongoAdminService.getAllStylists();
//       final stylist = stylists.firstWhere((s) => s.id == stylistId, orElse: () => throw Exception('Not found'));
//       return stylist.name;
//     } catch (e) {
//       print('Error getting stylist name: $e');
//     }
//     return 'N/A';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AdminScaffold(
//       title: 'Quản lý Nhân viên',
//       body: Column(
//         children: [
//           // Form đăng ký/chỉnh sửa
//           AdminSection(
//             title: _editingEmployee != null 
//                 ? 'Chỉnh sửa Nhân viên' 
//                 : 'Đăng ký Tài khoản Nhân viên',
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Họ tên
//                   TextFormField(
//                     controller: _fullNameController,
//                     decoration: adminInputDecoration(
//                       'Họ và tên',
//                       hintText: 'Nhập họ và tên nhân viên',
//                       prefixIcon: const Icon(Icons.person, color: AdminColors.textSecondary),
//                     ),
//                     validator: (value) {
//                       if (value?.isEmpty ?? true) {
//                         return 'Vui lòng nhập họ và tên';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
                  
//                   // Email & Password (chỉ hiện khi tạo mới)
//                   if (_editingEmployee == null) ...[
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextFormField(
//                             controller: _emailController,
//                             decoration: adminInputDecoration(
//                               'Email',
//                               hintText: 'email@example.com',
//                               prefixIcon: const Icon(Icons.email, color: AdminColors.textSecondary),
//                             ),
//                             keyboardType: TextInputType.emailAddress,
//                             validator: (value) {
//                               if (value?.isEmpty ?? true) {
//                                 return 'Vui lòng nhập email';
//                               }
//                               if (!value!.contains('@')) {
//                                 return 'Email không hợp lệ';
//                               }
//                               return null;
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: TextFormField(
//                             controller: _passwordController,
//                             decoration: adminInputDecoration(
//                               'Mật khẩu',
//                               hintText: 'Tối thiểu 6 ký tự',
//                               prefixIcon: const Icon(Icons.lock, color: AdminColors.textSecondary),
//                             ),
//                             obscureText: true,
//                             validator: (value) {
//                               if (value?.isEmpty ?? true) {
//                                 return 'Vui lòng nhập mật khẩu';
//                               }
//                               if (value!.length < 6) {
//                                 return 'Mật khẩu phải có ít nhất 6 ký tự';
//                               }
//                               return null;
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                   ],
                  
//                   // Số điện thoại
//                   TextFormField(
//                     controller: _phoneController,
//                     decoration: adminInputDecoration(
//                       'Số điện thoại (tùy chọn)',
//                       hintText: '0123456789',
//                       prefixIcon: const Icon(Icons.phone, color: AdminColors.textSecondary),
//                     ),
//                     keyboardType: TextInputType.phone,
//                   ),
//                   const SizedBox(height: 16),
                  
//                   // Vai trò
//                   DropdownButtonFormField<String>(
//                     value: _selectedRole,
//                     decoration: adminInputDecoration(
//                       'Vai trò',
//                       prefixIcon: const Icon(Icons.work, color: AdminColors.info),
//                     ),
//                     items: const [
//                       DropdownMenuItem(value: 'stylist', child: Text('Stylist')),
//                       DropdownMenuItem(value: 'manager', child: Text('Quản lý')),
//                       DropdownMenuItem(value: 'receptionist', child: Text('Lễ tân')),
//                     ],
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedRole = value!;
//                         if (_selectedRole != 'stylist') {
//                           _selectedStylistId = null;
//                         }
//                       });
//                     },
//                   ),
//                   const SizedBox(height: 16),
                  
//                   // Chọn stylist (nếu vai trò là stylist)
//                   if (_selectedRole == 'stylist') ...[
//                     DropdownButtonFormField<String>(
//                       value: _selectedStylistId,
//                       decoration: adminInputDecoration(
//                         'Liên kết với Stylist',
//                         prefixIcon: const Icon(Icons.person_pin, color: AdminColors.accent),
//                       ),
//                       hint: const Text('Chọn stylist'),
//                       items: _availableStylists.map((stylist) {
//                         return DropdownMenuItem<String>(
//                           value: stylist['id'] as String,
//                           child: Text(stylist['name'] as String),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedStylistId = value;
//                         });
//                       },
//                       validator: (value) {
//                         if (_selectedRole == 'stylist' && value == null) {
//                           return 'Vui lòng chọn stylist';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                   ],
                  
//                   // Buttons
//                   Row(
//                     children: [
//                       Expanded(
//                         child: AdminPrimaryButton(
//                           label: _editingEmployee != null ? 'Cập nhật' : 'Đăng ký',
//                           icon: _editingEmployee != null ? Icons.save : Icons.person_add,
//                           isLoading: _isLoading,
//                           onPressed: _isLoading 
//                               ? null 
//                               : (_editingEmployee != null 
//                                   ? _updateEmployee 
//                                   : _createEmployee),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       if (_editingEmployee != null)
//                         Expanded(
//                           child: AdminDangerButton(
//                             label: 'Hủy',
//                             icon: Icons.close,
//                             onPressed: _clearForm,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
          
//           // Danh sách người dùng
//           Expanded(
//             child: FutureBuilder<List<UserModel>>(
//               future: MongoAdminService.getAllUsers(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const AdminLoadingCard(message: 'Đang tải danh sách người dùng...');
//                 }
                
//                 if (snapshot.hasError) {
//                   return AdminEmptyState(
//                     title: 'Có lỗi xảy ra',
//                     subtitle: 'Không thể tải danh sách: ${snapshot.error}',
//                     icon: Icons.error_outline,
//                     action: AdminPrimaryButton(
//                       label: 'Thử lại',
//                       icon: Icons.refresh,
//                       onPressed: () => setState(() {}),
//                     ),
//                   );
//                 }
                
//                 final users = snapshot.data ?? [];
                
//                 if (users.isEmpty) {
//                   return const AdminEmptyState(
//                     title: 'Chưa có người dùng nào',
//                     subtitle: 'Danh sách người dùng trống',
//                     icon: Icons.people,
//                   );
//                 }
                
//                 return Column(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.people, color: AdminColors.accent),
//                           const SizedBox(width: 8),
//                           Text(
//                             'Danh sách người dùng (${users.length})',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: AdminColors.textPrimary,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       child: ListView.builder(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         itemCount: users.length,
//                         itemBuilder: (context, index) {
//                           final user = users[index];
//                           return AdminCard(
//                             child: ListTile(
//                               leading: CircleAvatar(
//                                 child: Text(user.displayName[0].toUpperCase()),
//                               ),
//                               title: Text(user.displayName),
//                               subtitle: Text('${user.email}\nRole: ${user.role}'),
//                               isThreeLine: true,
//                               trailing: user.isAdmin 
//                                   ? const Icon(Icons.admin_panel_settings, color: AdminColors.accent)
//                                   : null,
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
