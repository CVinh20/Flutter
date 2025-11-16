// lib/screens/profile/profile_info_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'change_password_screen.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  User? _user;
  bool _isLoading = true;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  String? _gender;
  String? _photoUrl;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadUserData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    _user = _auth.currentUser;
    if (_user != null) {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      final data = doc.data();

      _nameController.text = data?['displayName'] ?? _user!.displayName ?? '';
      _phoneController.text = data?['phoneNumber'] ?? _user!.phoneNumber ?? '';
      _dobController.text = data?['dateOfBirth'] ?? '';
      _gender = data?['gender'];
      _photoUrl = data?['photoURL'] ?? _user!.photoURL;
    }
    setState(() => _isLoading = false);
    _animationController.forward();
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    setState(() => _isLoading = true);
    
    try {
      final ref = _storage.ref().child('profile_pictures').child('${_user!.uid}.jpg');
      await ref.putFile(file);
      final newPhotoUrl = await ref.getDownloadURL();
      
      await _firestore.collection('users').doc(_user!.uid).set({'photoURL': newPhotoUrl}, SetOptions(merge: true));
      await _user!.updatePhotoURL(newPhotoUrl);

      setState(() => _photoUrl = newPhotoUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cập nhật ảnh thành công!'),
          backgroundColor: const Color(0xFF0891B2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải ảnh: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(_user!.uid).set({
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'gender': _gender,
      }, SetOptions(merge: true));

      if (_user!.displayName != _nameController.text.trim()) {
        await _user!.updateDisplayName(_nameController.text.trim());
      }

      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cập nhật thông tin thành công!'),
          backgroundColor: const Color(0xFF0891B2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0891B2),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      _dobController.text = DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_isEditing) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF0891B2),
              ),
              const SizedBox(height: 16),
              Text(
                'Đang tải thông tin...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Header với gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0891B2),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0891B2),
                      Color(0xFF06B6D4),
                      Color(0xFF22D3EE),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Profile Avatar
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Colors.white, Color(0xFFE0F7FA)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white,
                                    backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                                    child: _photoUrl == null 
                                        ? const Icon(Icons.person, size: 50, color: Color(0xFF0891B2)) 
                                        : null,
                                  ),
                                ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0891B2),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _nameController.text.isNotEmpty ? _nameController.text : 'Chưa cập nhật',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? 'Chưa cập nhật',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: TextButton(
                  onPressed: _isEditing ? _saveChanges : () => setState(() => _isEditing = true),
                  style: TextButton.styleFrom(
                    backgroundColor: _isEditing ? Colors.green : Colors.white.withOpacity(0.2),
                    foregroundColor: _isEditing ? Colors.white : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'Lưu' : 'Chỉnh sửa',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Thông tin cá nhân
                      _buildInfoCard(
                        title: 'Thông tin cá nhân',
                        icon: Icons.person_outline,
                        children: [
                          _buildInfoField(
                            label: 'Họ và tên',
                            controller: _nameController,
                            icon: Icons.person,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoField(
                            label: 'Số điện thoại',
                            controller: _phoneController,
                            icon: Icons.phone,
                            enabled: _isEditing,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _buildDateField(),
                          const SizedBox(height: 16),
                          _buildGenderField(),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Thông tin tài khoản
                      _buildInfoCard(
                        title: 'Thông tin tài khoản',
                        icon: Icons.account_circle_outlined,
                        children: [
                          _buildAccountInfoField(
                            label: 'Email',
                            value: _user?.email ?? 'Chưa cập nhật',
                            icon: Icons.email,
                          ),
                          const SizedBox(height: 16),
                          _buildAccountInfoField(
                            label: 'Ngày tạo tài khoản',
                            value: _user?.metadata.creationTime != null 
                                ? DateFormat('dd/MM/yyyy').format(_user!.metadata.creationTime!)
                                : 'Chưa xác định',
                            icon: Icons.calendar_today,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Các tùy chọn
                      _buildInfoCard(
                        title: 'Tùy chọn',
                        icon: Icons.settings_outlined,
                        children: [
                          _buildOptionTile(
                            title: 'Đổi mật khẩu',
                            subtitle: 'Thay đổi mật khẩu tài khoản',
                            icon: Icons.lock_outline,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                            ),
                          ),
                          const Divider(height: 1),
                          _buildOptionTile(
                            title: 'Xóa tài khoản',
                            subtitle: 'Xóa vĩnh viễn tài khoản này',
                            icon: Icons.delete_outline,
                            iconColor: Colors.red,
                            onTap: () => _showDeleteAccountDialog(),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0891B2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF0891B2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF0891B2)),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0891B2), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ngày sinh',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isEditing ? _selectDate : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _isEditing ? Colors.grey.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF0891B2)),
                const SizedBox(width: 12),
                Text(
                  _dobController.text.isNotEmpty ? _dobController.text : 'Chọn ngày sinh',
                  style: TextStyle(
                    fontSize: 16,
                    color: _dobController.text.isNotEmpty ? const Color(0xFF1E293B) : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới tính',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _isEditing ? () => setState(() => _gender = 'Nam') : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _gender == 'Nam' ? const Color(0xFF0891B2) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _gender == 'Nam' ? const Color(0xFF0891B2) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    'Nam',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _gender == 'Nam' ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _isEditing ? () => setState(() => _gender = 'Nữ') : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _gender == 'Nữ' ? const Color(0xFF0891B2) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _gender == 'Nữ' ? const Color(0xFF0891B2) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    'Nữ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _gender == 'Nữ' ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0891B2), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: iconColor ?? const Color(0xFF0891B2),
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF64748B),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa tài khoản'),
        content: const Text('Bạn có chắc chắn muốn xóa tài khoản này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete account
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
