import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.controller.currentUser?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
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

  // Placeholder cho chức năng đổi ảnh (bạn có thể kết nối sau)
  Future<void> _changeAvatar() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng chọn ảnh sẽ được thêm sau')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          backgroundImage: user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          backgroundColor: Colors.grey[300],
                          child: user?.avatarUrl == null
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
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 22, color: Color(0xFFFFD700)),
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
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85)),
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
                          _infoRow('Vai trò', user?.role?.toUpperCase() ?? 'Học viên'),
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

                  const SizedBox(height: 30),

                  // Logout button
                  OutlinedButton.icon(
                    onPressed: () async {
                      await widget.controller.logout();
                      if (mounted) Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
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