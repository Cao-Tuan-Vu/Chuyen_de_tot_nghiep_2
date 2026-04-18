import 'package:flutter/material.dart';

import 'package:btl/features/admin/presentation/pages/admin_page.dart';
import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/auth/presentation/pages/login_page.dart';
import 'package:btl/features/learning/presentation/pages/course_list_page.dart';
import 'package:btl/features/profile/presentation/pages/profile_page.dart';
import 'contact_page.dart';
import 'policy_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  static const String routeName = '/home';

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('BTL Learning'),
        elevation: 0,
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            onPressed: () async {
              await controller.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(LoginPage.routeName);
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      drawer: _buildDrawer(context, user, isAdmin),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header Profile Section
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.indigo, Colors.indigoAccent],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person, color: Colors.indigo, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào ${user?.displayName ?? 'bạn'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isAdmin ? 'Quản Trị Viên' : 'Học Viên',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
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
            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Cards
                  Text(
                    'Thông Tin Học Tập',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.school,
                    title: 'Khóa Học',
                    description: 'Tham gia các khóa học lập trình',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.quiz_outlined,
                    title: 'Quiz & Bài Tập',
                    description: 'Làm quiz và kiểm tra kiến thức',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.trending_up,
                    title: 'Theo Dõi Tiến Độ',
                    description: 'Xem lịch sử học tập của bạn',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 24),
                  // Admin Section
                  if (isAdmin)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Công Cụ Quản Trị',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          color: Colors.red.shade50,
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings_outlined,
                                        color: Colors.red.shade700, size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Quản Trị Hệ Thống',
                                            style: Theme.of(context).textTheme.titleSmall
                                                ?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const Text(
                                            'Quản lý người dùng, khóa học và nội dung',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(AdminPage.routeName);
                                  },
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text('Mở Trang Quản Trị'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic user, bool isAdmin) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.indigo,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.person, color: Colors.indigo, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? 'Người Dùng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'email@example.com',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Trang Chủ'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Hồ Sơ'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(ProfilePage.routeName);
            },
          ),
          if (!isAdmin)
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Khóa Học'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(CourseListPage.routeName);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.contact_mail_outlined),
            title: const Text('Liên Hệ'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(ContactPage.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Chính Sách & Điều Khoản'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(PolicyPage.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Về Chúng Tôi'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng Xuất', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await controller.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(LoginPage.routeName);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'BTL Learning',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 48, color: Colors.indigo),
      children: [
        const SizedBox(height: 16),
        const Text(
          'BTL Learning là ứng dụng học lập trình cơ bản, cung cấp bài giảng, quiz và bài tập thực hành với hỗ trợ AI.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Phiên bản: 1.0.0\nPlatform: Flutter\nNhà phát triển: BTL Team',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
