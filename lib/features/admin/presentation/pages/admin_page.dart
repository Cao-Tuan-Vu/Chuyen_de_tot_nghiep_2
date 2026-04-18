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

  static const List<String> _roles = ['student', 'mentor', 'admin'];
  String _selectedRoleFilter = 'all';
  String _searchKeyword = '';
  String? _message;

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
    if (token == null) {
      return Future.error('Phien dang nhap het han');
    }
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
      _message = null;
      _reloadAll();
    });
  }

  Future<void> _changeRole(AppUser user, String role) async {
    final token = widget.controller.token;
    if (token == null) return;

    setState(() => _message = null);
    try {
      await widget.repository.updateUserRole(token: token, userId: user.id, role: role);
      if (!mounted) return;
      setState(() {
        _message = 'Da cap nhat role cho ${user.displayName} -> $role';
        _usersFuture = _loadUsers();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = e.toString());
    }
  }

  List<AppUser> _filterUsers(List<AppUser> users) {
    return users.where((user) {
      if (_selectedRoleFilter != 'all' && user.role != _selectedRoleFilter) {
        return false;
      }

      if (_searchKeyword.isEmpty) {
        return true;
      }

      final keyword = _searchKeyword.toLowerCase();
      return user.displayName.toLowerCase().contains(keyword) ||
          user.email.toLowerCase().contains(keyword) ||
          user.role.toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.controller.currentUser;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin CMS'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tong quan'),
              Tab(text: 'Users'),
              Tab(text: 'Noi dung'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
            IconButton(
              tooltip: 'Dang xuat',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await widget.controller.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed(LoginPage.routeName);
                }
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: TabBarView(
            children: [
              _OverviewTab(
                currentUser: currentUser,
                usersFuture: _usersFuture,
                contentFuture: _contentFuture,
                message: _message,
              ),
              _UsersTab(
                usersFuture: _usersFuture,
                selectedRoleFilter: _selectedRoleFilter,
                onRoleFilterChanged: (value) => setState(() => _selectedRoleFilter = value),
                searchKeyword: _searchKeyword,
                onSearchChanged: (value) => setState(() => _searchKeyword = value),
                filterUsers: _filterUsers,
                roles: _roles,
                onChangeRole: _changeRole,
              ),
              _ContentTab(contentFuture: _contentFuture),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.currentUser,
    required this.usersFuture,
    required this.contentFuture,
    required this.message,
  });

  final AppUser? currentUser;
  final Future<List<AppUser>> usersFuture;
  final Future<_ContentSnapshot> contentFuture;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chao ${currentUser?.displayName ?? 'admin'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text('Trang quan tri tong hop: user, role, course va lesson.'),
                if (message != null) ...[
                  const SizedBox(height: 10),
                  Text(message!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<AppUser>>(
          future: usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ));
            }
            if (snapshot.hasError) {
              return Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(snapshot.error.toString()),
                ),
              );
            }

            final users = snapshot.data ?? [];
            final adminCount = users.where((u) => u.role == 'admin').length;
            final mentorCount = users.where((u) => u.role == 'mentor').length;
            final studentCount = users.where((u) => u.role == 'student').length;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricCard(title: 'Tong user', value: users.length.toString()),
                _MetricCard(title: 'Admin', value: adminCount.toString()),
                _MetricCard(title: 'Mentor', value: mentorCount.toString()),
                _MetricCard(title: 'Student', value: studentCount.toString()),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<_ContentSnapshot>(
          future: contentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            if (snapshot.hasError) {
              return Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(snapshot.error.toString()),
                ),
              );
            }

            final content = snapshot.data;
            if (content == null) {
              return const SizedBox.shrink();
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricCard(title: 'Course', value: content.courses.length.toString()),
                _MetricCard(title: 'Lesson', value: content.totalLessons.toString()),
              ],
            );
          },
        ),
      ],
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quan ly user', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    labelText: 'Tim user theo ten/email/role',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _RoleFilterChip(
                      label: 'all',
                      selected: selectedRoleFilter == 'all',
                      onTap: onRoleFilterChanged,
                    ),
                    ...roles.map(
                      (role) => _RoleFilterChip(
                        label: role,
                        selected: selectedRoleFilter == role,
                        onTap: onRoleFilterChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<AppUser>>(
          future: usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ));
            }

            if (snapshot.hasError) {
              return Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(snapshot.error.toString()),
                ),
              );
            }

            final users = filterUsers(snapshot.data ?? []);
            if (users.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Khong co user phu hop bo loc.'),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danh sach user (${users.length})'),
                    const SizedBox(height: 12),
                    ...users.map(
                      (user) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE6E8EF)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              child: Text(user.displayName.isEmpty ? '?' : user.displayName[0]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.displayName, style: Theme.of(context).textTheme.titleSmall),
                                  const SizedBox(height: 2),
                                  Text(user.email),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('Role: '),
                                      const SizedBox(width: 8),
                                      DropdownButton<String>(
                                        value: user.role,
                                        items: roles
                                            .map((role) => DropdownMenuItem(
                                                  value: role,
                                                  child: Text(role),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          if (value == null || value == user.role) {
                                            return;
                                          }
                                          onChangeRole(user, value);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ContentTab extends StatelessWidget {
  const _ContentTab({required this.contentFuture});

  final Future<_ContentSnapshot> contentFuture;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Quan ly noi dung (doc/kiem tra): danh sach course va lesson hien tai.\n'
              'CRUD noi dung se bo sung o sprint tiep theo.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<_ContentSnapshot>(
          future: contentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ));
            }
            if (snapshot.hasError) {
              return Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(snapshot.error.toString()),
                ),
              );
            }

            final data = snapshot.data;
            if (data == null || data.courses.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chua co course trong he thong.'),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danh sach course (${data.courses.length})'),
                    const SizedBox(height: 12),
                    ...data.courses.map((course) {
                      final lessons = data.lessonsByCourse[course.id] ?? const <Lesson>[];
                      return ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(course.title),
                        subtitle: Text('${course.level} - ${lessons.length} lesson'),
                        children: lessons
                            .map(
                              (lesson) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(lesson.title),
                                subtitle: Text(
                                  lesson.quizId == null
                                      ? 'Ly thuyet'
                                      : 'Ly thuyet + quiz (${lesson.quizId})',
                                ),
                              ),
                            )
                            .toList(),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(label),
    );
  }
}

class _ContentSnapshot {
  const _ContentSnapshot({
    required this.courses,
    required this.lessonsByCourse,
  });

  final List<Course> courses;
  final Map<String, List<Lesson>> lessonsByCourse;

  int get totalLessons {
    var total = 0;
    for (final lessons in lessonsByCourse.values) {
      total += lessons.length;
    }
    return total;
  }
}
