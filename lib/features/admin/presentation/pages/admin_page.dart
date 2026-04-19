import 'package:flutter/material.dart';
import 'package:btl/features/auth/domain/entities/app_user.dart';
import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/auth/presentation/pages/login_page.dart';
import 'package:btl/features/learning/domain/entities/course.dart';
import 'package:btl/features/learning/domain/entities/lesson.dart';
import 'package:btl/features/admin/data/repositories/admin_repository.dart';

class AdminPage extends StatefulWidget {
  AdminPage({
    super.key,
    required this.controller,
    AdminRepository? repository,
  }) : repository = repository ?? AdminRepository();

  static const String routeName = '/admin';

  final AuthController controller;
  final AdminRepository repository;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<AppUser>> _usersFuture;
  late Future<_ContentSnapshot> _contentFuture;

  static const List<String> _roles = ['student', 'admin'];
  String _selectedRoleFilter = 'all';
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  void _reloadAll() {
    _usersFuture = _loadUsers();
    _contentFuture = _loadContent();
  }

  Future<List<AppUser>> _loadUsers() {
    final token = widget.controller.token;
    if (token == null) return Future.error('Phiên đăng nhập hết hạn');
    return widget.repository.getUsers(token: token);
  }

  Future<_ContentSnapshot> _loadContent() async {
    final courses = await widget.repository.getCourses();
    final lessonsByCourse = <String, List<Lesson>>{};

    for (final course in courses) {
      lessonsByCourse[course.id] = await widget.repository.getLessonsByCourse(course.id);
    }
    return _ContentSnapshot(courses: courses, lessonsByCourse: lessonsByCourse);
  }

  Future<void> _refresh() async {
    setState(() {
      _reloadAll();
    });
  }

  Future<void> _changeRole(AppUser user, String role) async {
    final token = widget.controller.token;
    if (token == null) return;
    try {
      await widget.repository.updateUserRole(token: token, userId: user.id, role: role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật role cho ${user.displayName} -> $role')),
      );
      setState(() => _usersFuture = _loadUsers());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  List<AppUser> _filterUsers(List<AppUser> users) {
    return users.where((user) {
      if (_selectedRoleFilter != 'all' && user.role != _selectedRoleFilter) return false;
      if (_searchKeyword.isEmpty) return true;
      final keyword = _searchKeyword.toLowerCase();
      return user.displayName.toLowerCase().contains(keyword) ||
          user.email.toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // Nền xám nhạt hiện đại
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          title: const Text('Admin Console', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Tổng quan'),
              Tab(text: 'Người dùng'),
              Tab(text: 'Nội dung'),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onPressed: () async {
                await widget.controller.logout();
                if (context.mounted) Navigator.of(context).pushReplacementNamed(LoginPage.routeName);
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _OverviewTab(
              currentUser: widget.controller.currentUser,
              usersFuture: _usersFuture,
              contentFuture: _contentFuture,
            ),
            _UsersTab(
              usersFuture: _usersFuture,
              selectedRoleFilter: _selectedRoleFilter,
              onRoleFilterChanged: (v) => setState(() => _selectedRoleFilter = v),
              searchKeyword: _searchKeyword,
              onSearchChanged: (v) => setState(() => _searchKeyword = v),
              filterUsers: _filterUsers,
              roles: _roles,
              onChangeRole: _changeRole,
            ),
            _ContentTab(contentFuture: _contentFuture),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.currentUser, required this.usersFuture, required this.contentFuture});

  final AppUser? currentUser;
  final Future<List<AppUser>> usersFuture;
  final Future<_ContentSnapshot> contentFuture;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Chào buổi sáng, ${currentUser?.displayName ?? 'Admin'} 👋',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Dưới đây là thống kê hệ thống của bạn hôm nay.', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),
        
        // Metrics Grid
        FutureBuilder(
          future: Future.wait([usersFuture, contentFuture]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = snapshot.data?[0] as List<AppUser>? ?? [];
            final content = snapshot.data?[1] as _ContentSnapshot?;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  title: 'Tổng User',
                  value: users.length.toString(),
                  icon: Icons.people_alt_rounded,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Học viên',
                  value: users.where((u) => u.role == 'student').length.toString(),
                  icon: Icons.school_rounded,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: 'Khóa học',
                  value: content?.courses.length.toString() ?? '0',
                  icon: Icons.auto_stories_rounded,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Bài học',
                  value: content?.totalLessons.toString() ?? '0',
                  icon: Icons.play_lesson_rounded,
                  color: Colors.purple,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({
    required this.usersFuture,
    required this.selectedRoleFilter,
    required this.onRoleFilterChanged,
    required this.searchKeyword,
    required this.onSearchChanged,
    required this.filterUsers,
    required this.roles,
    required this.onChangeRole,
  });
  final Future<List<AppUser>> usersFuture;
  final String selectedRoleFilter;
  final ValueChanged<String> onRoleFilterChanged;
  final String searchKeyword;
  final ValueChanged<String> onSearchChanged;
  final List<AppUser> Function(List<AppUser>) filterUsers;
  final List<String> roles;
  final Future<void> Function(AppUser user, String role) onChangeRole;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tên hoặc email...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF1F3F4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Tất cả',
                      selected: selectedRoleFilter == 'all',
                      onSelected: () => onRoleFilterChanged('all'),
                    ),
                    ...roles.map((role) => _FilterChip(
                                label: role.isNotEmpty ? role[0].toUpperCase() + role.substring(1) : role,
                          selected: selectedRoleFilter == role,
                          onSelected: () => onRoleFilterChanged(role),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<AppUser>>(
            future: usersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = filterUsers(snapshot.data ?? []);
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          child: Text(user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase(),
                              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(user.email, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: user.role,
                              items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) => v != null ? onChangeRole(user, v) : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onSelected});
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: selected ? Theme.of(context).primaryColor : Colors.black87, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selected ? Theme.of(context).primaryColor : Colors.grey.shade300)),
        showCheckmark: false,
      ),
    );
  }
}

class _ContentTab extends StatelessWidget {
  const _ContentTab({required this.contentFuture});
  final Future<_ContentSnapshot> contentFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ContentSnapshot>(
      future: contentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data;
        if (data == null) return const Center(child: Text('Không có dữ liệu'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.courses.length,
          itemBuilder: (context, index) {
            final course = data.courses[index];
            final lessons = data.lessonsByCourse[course.id] ?? [];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: ExpansionTile(
                leading: const Icon(Icons.folder_copy_rounded, color: Colors.blue),
                title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${lessons.length} bài học • ${course.level}', style: const TextStyle(fontSize: 12)),
                children: lessons.map((l) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.play_circle_outline, size: 20),
                  title: Text(l.title),
                  trailing: l.quizId != null ? const Icon(Icons.help_outline, size: 16, color: Colors.orange) : null,
                )).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

class _ContentSnapshot {
  const _ContentSnapshot({required this.courses, required this.lessonsByCourse});
  final List<Course> courses;
  final Map<String, List<Lesson>> lessonsByCourse;
  int get totalLessons => lessonsByCourse.values.fold(0, (sum, list) => sum + list.length);
}
