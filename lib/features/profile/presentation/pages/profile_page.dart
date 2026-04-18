import 'package:flutter/material.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.controller});

  static const String routeName = '/profile';

  final AuthController controller;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
    if (widget.controller.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cap nhat profile thanh cong')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
          if (isAdmin)
            Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Tai khoan admin khong su dung chuc nang profile hoc vien.\n'
                  'Vui long quay lai Home va vao Admin CMS de quan tri he thong.',
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Cap nhat ho so', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(labelText: 'Ten hien thi'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: widget.controller.isLoading ? null : _saveProfile,
                      child: const Text('Luu thay doi'),
                    ),
                    if (widget.controller.error != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.controller.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
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
