import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key, required this.controller});

  static const String routeName = '/student-profile';

  final AuthController controller;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  late final TextEditingController _displayNameController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.controller.currentUser?.displayName ?? '',
    );
  }

  Future<void> _saveProfile() async {
    await widget.controller.updateDisplayName(_displayNameController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cập nhật thông tin thành công'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _changeAvatar() async {
    if (_isUploadingAvatar || widget.controller.isLoading) {
      return;
    }

    final currentUser = widget.controller.currentUser;
    final userId = currentUser?.id;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin tài khoản.')),
      );
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Nén mạnh để chuỗi Base64 không quá dài
      maxWidth: 400,    // Kích thước nhỏ đủ dùng cho avatar
      maxHeight: 400,
    );

    if (image == null) {
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      // Đọc ảnh dưới dạng bytes và chuyển sang Base64
      final bytes = await image.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Lưu lên Firebase thông qua Controller
      await widget.controller.updateAvatarUrl(base64String);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật ảnh đại diện thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _removeLocalAvatar() async {
    if (widget.controller.isLoading) return;
    
    await widget.controller.updateAvatarUrl(''); // Xóa avatar
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa ảnh đại diện')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Xử lý hiển thị ảnh từ URL hoặc chuỗi Base64
    ImageProvider? avatarImage;
    if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      if (user.avatarUrl!.startsWith('data:image')) {
        try {
          // Giải mã chuỗi base64
          final base64Data = user.avatarUrl!.split(',').last;
          avatarImage = MemoryImage(base64Decode(base64Data));
        } catch (_) {}
      } else {
        avatarImage = NetworkImage(user.avatarUrl!);
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text('Trang Cá Nhân'),
        elevation: 0,
        backgroundColor: isDark ? Colors.black : const Color(0xFFFFD700),
        foregroundColor: isDark ? Colors.white : const Color(0xFF333333),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==================== HEADER WITH AVATAR ====================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 40, bottom: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Color(0xFF4F46E5), Color(0xFF7C3AED)]
                      : [Color(0xFFFFD700), Color(0xFF2196F3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 62,
                          backgroundImage: avatarImage,
                          backgroundColor: Colors.grey[300],
                          child: (avatarImage == null)
                              ? Text(
                                  ((user?.displayName ?? '').isNotEmpty ? (user?.displayName ?? '')[0] : 'U').toUpperCase(),
                                  style: const TextStyle(fontSize: 55, fontWeight: FontWeight.bold, color: Color(0xFF2196F3)),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _changeAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8),
                              ],
                            ),
                            child: _isUploadingAvatar
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.camera_alt_rounded, size: 22, color: Color(0xFFFFD700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'Học viên',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                    TextButton.icon(
                      onPressed: _isUploadingAvatar ? null : _removeLocalAvatar,
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      label: const Text(
                        'Xóa ảnh đại diện',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),

            // ==================== BODY ====================
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin tài khoản
                  _buildSectionTitle('Thông tin tài khoản'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _infoRow('Email', user?.email ?? 'Chưa có'),
                          const Divider(height: 24),
                          _infoRow('Vai trò', user?.role.toUpperCase() ?? 'Học viên'),
                          const Divider(height: 24),
                          _infoRow('Ngày tham gia', 'Chưa cập nhật'), // Có thể thêm sau
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Chỉnh sửa thông tin
                  _buildSectionTitle('Chỉnh sửa thông tin'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _displayNameController,
                            decoration: InputDecoration(
                              labelText: 'Tên hiển thị',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2196F3)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: widget.controller.isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: widget.controller.isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Lưu thay đổi', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (widget.controller.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          widget.controller.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

