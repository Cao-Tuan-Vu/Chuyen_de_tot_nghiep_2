import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key, required this.controller});

  static const String routeName = '/student-profile';

  final AuthController controller;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  static const String _avatarPrefsPrefix = 'local_avatar_path_';

  late final TextEditingController _displayNameController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingAvatar = false;
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.controller.currentUser?.displayName ?? '',
    );
    _loadLocalAvatar();
  }

  String _avatarKeyForUser(String userId) => '$_avatarPrefsPrefix$userId';

  Future<void> _loadLocalAvatar() async {
    final userId = widget.controller.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_avatarKeyForUser(userId));
    if (savedPath == null || savedPath.isEmpty) {
      return;
    }

    final file = File(savedPath);
    if (await file.exists()) {
      if (!mounted) return;
      setState(() {
        _localAvatarPath = savedPath;
      });
      return;
    }

    await prefs.remove(_avatarKeyForUser(userId));
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
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (image == null) {
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory('${appDir.path}/avatars');
      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }

      final savedFilePath = '${avatarsDir.path}/$userId.jpg';
      final sourceFile = File(image.path);
      await sourceFile.copy(savedFilePath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarKeyForUser(userId), savedFilePath);

      if (!mounted) {
        return;
      }
      setState(() {
        _localAvatarPath = savedFilePath;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu ảnh đại diện trên thiết bị này'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu ảnh. Vui lòng thử lại.')),
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
    final userId = widget.controller.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final existingPath = prefs.getString(_avatarKeyForUser(userId));

    if (existingPath != null && existingPath.isNotEmpty) {
      final file = File(existingPath);
      if (await file.exists()) {
        await file.delete();
      }
      await prefs.remove(_avatarKeyForUser(userId));
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _localAvatarPath = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa ảnh đại diện trên thiết bị này')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ImageProvider<Object>? avatarImage = _localAvatarPath != null
        ? FileImage(File(_localAvatarPath!))
        : (user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null);

    return Scaffold(
      appBar: AppBar(
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
                  if (_localAvatarPath != null)
                    TextButton.icon(
                      onPressed: _isUploadingAvatar ? null : _removeLocalAvatar,
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      label: const Text(
                        'Xóa ảnh thiết bị',
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

