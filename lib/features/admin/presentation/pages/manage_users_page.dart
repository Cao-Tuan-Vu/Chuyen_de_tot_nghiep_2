import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:btl/features/admin/presentation/controllers/admin_controller.dart';
import 'package:btl/features/admin/presentation/pages/user_detail_page.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  static const String routeName = '/manage-users';

  @override
  Widget build(BuildContext context) {
    final adminCtrl = context.watch<AdminController>();
    final users = adminCtrl.allUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        actions: [
          IconButton(onPressed: () => adminCtrl.initialize(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: adminCtrl.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : users.isEmpty 
          ? const Center(child: Text('Không có người dùng nào'))
          : ListView.separated(
              itemCount: users.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = users[index];
                final isAdmin = user.role == 'admin' || user.email == 'admin@gmail.com';
                final email = user.email;
                final userId = user.id;
                
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailPage(user: user),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? Colors.red[50] : Colors.blue[50],
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: isAdmin ? Colors.red : Colors.blue,
                    ),
                  ),
                  title: Text(
                    user.displayName.isNotEmpty ? user.displayName : 'Học viên',
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(email),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'role') {
                        _showRoleDialog(context, adminCtrl, userId, user.role);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'role',
                        child: Text(isAdmin ? 'Gỡ quyền Admin' : 'Cấp quyền Admin'),
                      ),
                      const PopupMenuItem(value: 'lock', child: Text('Khóa tài khoản')),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showRoleDialog(BuildContext context, AdminController ctrl, String uid, String currentRole) {
    final newRole = currentRole == 'admin' ? 'student' : 'admin';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc muốn đổi vai trò người dùng này thành $newRole?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              ctrl.changeUserRole(uid, newRole);
              Navigator.pop(ctx);
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }
}
