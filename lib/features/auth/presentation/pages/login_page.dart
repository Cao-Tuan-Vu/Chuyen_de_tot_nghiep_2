import 'package:flutter/material.dart';

import 'package:btl/features/admin/presentation/pages/admin_page.dart';
import 'package:btl/features/home/presentation/pages/home_page.dart';
import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});

  static const String routeName = '/login';

  final AuthController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isRegisterMode) {
      await widget.controller.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _displayNameController.text.trim(),
      );
    } else {
      await widget.controller.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (!mounted) return;
    if (widget.controller.isLoggedIn) {
      final isAdmin = widget.controller.currentUser?.role == 'admin';
      Navigator.of(context).pushReplacementNamed(
        isAdmin ? AdminPage.routeName : HomePage.routeName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Nhập'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.school, color: Colors.indigo, size: 40),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isRegisterMode ? 'Tạo Tài Khoản' : 'Chào Mừng Bạn Trở Lại',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegisterMode
                            ? 'Nhập thông tin để bắt đầu học.'
                            : 'Đăng nhập để tiếp tục khóa học.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Nhập email của bạn',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mật Khẩu',
                          hintText: 'Nhập mật khẩu',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      if (_isRegisterMode) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            labelText: 'Tên Hiển Thị',
                            hintText: 'Tên của bạn',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: controller.isLoading ? null : _submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            _isRegisterMode ? 'Tạo Tài Khoản' : 'Đăng Nhập',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
                        child: Text(
                          _isRegisterMode
                              ? 'Đã Có Tài Khoản? Đăng Nhập'
                              : 'Chưa Có Tài Khoản? Đăng Ký',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      if (controller.error != null)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            controller.error!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
