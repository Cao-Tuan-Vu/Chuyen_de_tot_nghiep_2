import 'package:flutter/material.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key, required this.controller});

  static const String routeName = '/admin-profile';

  final AuthController controller;

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thong tin tai khoan', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text('Email: ${user?.email ?? ''}'),
                  const SizedBox(height: 8),
                  Text('Role: ${user?.role ?? ''}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ban co quyen truy cap vao Admin CMS de quan tri he thong.\n'
                    'Vui long vao Home va nhap Admin Mode.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Quay lai'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

