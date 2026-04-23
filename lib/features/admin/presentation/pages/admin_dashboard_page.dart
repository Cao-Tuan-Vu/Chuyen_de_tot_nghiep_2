import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:btl/features/admin/presentation/controllers/admin_controller.dart';
import 'package:btl/features/admin/presentation/pages/manage_courses_page.dart';
import 'package:btl/features/admin/presentation/pages/manage_users_page.dart';
import 'package:btl/features/admin/presentation/pages/manage_quizzes_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  static const String routeName = '/admin-dashboard';

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Gọi khởi tạo dữ liệu khi vào trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final adminCtrl = context.watch<AdminController>();

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Hệ Thống Quản Trị', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => adminCtrl.initialize(), 
            icon: const Icon(Icons.refresh_rounded)
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: adminCtrl.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => adminCtrl.initialize(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào Admin!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDarkMode ? Colors.white : Colors.indigo[900],
                    ),
                  ),
                  const Text('Tổng quan về hệ thống EduCode.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),

                  // Các chỉ số lấy từ adminCtrl
                  Row(
                    children: [
                      Expanded(child: _buildSimpleStatCard(
                        'Học Viên', 
                        adminCtrl.totalStudents.toString(), 
                        Icons.people_alt_rounded, 
                        Colors.blue
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSimpleStatCard(
                        'Lượt Học', 
                        adminCtrl.totalAttempts.toString(),
                        Icons.trending_up_rounded, 
                        const Color(0xFF10B981)
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildSimpleStatCard(
                        'Khóa Học', 
                        adminCtrl.coursesPublished.toString(), 
                        Icons.auto_stories_rounded, 
                        Colors.orange
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSimpleStatCard(
                        'Tỉ Lệ Đạt', 
                        '${adminCtrl.platformAverageScore * 10}%', 
                        Icons.verified_rounded, 
                        Colors.purple
                      )),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Text('Công cụ quản trị', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  _buildMenuAction(
                    context,
                    title: 'Khoá Học & Bài Giảng',
                    desc: 'Quản lý lộ trình và nội dung học tập',
                    icon: Icons.layers_rounded,
                    color: Colors.indigo,
                    onTap: () => Navigator.pushNamed(context, ManageCoursesPage.routeName),
                  ),
                  _buildMenuAction(
                    context,
                    title: 'Ngân Hàng Câu Hỏi',
                    desc: 'Tạo và chỉnh sửa bộ đề thi trắc nghiệm',
                    icon: Icons.quiz_rounded,
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, ManageQuizzesPage.routeName),
                  ),
                  _buildMenuAction(
                    context,
                    title: 'Người Dùng & Phân Quyền',
                    desc: 'Kiểm soát tài khoản và vai trò',
                    icon: Icons.manage_accounts_rounded,
                    color: Colors.redAccent,
                    onTap: () => Navigator.pushNamed(context, ManageUsersPage.routeName),
                  ),
                  
                  if (adminCtrl.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(adminCtrl.error!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSimpleStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMenuAction(BuildContext context, {required String title, required String desc, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }
}


