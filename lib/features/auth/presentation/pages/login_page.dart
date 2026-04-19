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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
        title: Text(_isRegisterMode ? 'Tạo Tài Khoản' : 'Đăng Nhập'),
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
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.school, color: Colors.indigo, size: 44),
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          _isRegisterMode ? 'Tạo Tài Khoản' : 'Chào Mừng Bạn Trở Lại',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                        const SizedBox(height: 32),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Nhập email của bạn',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                          (value == null || !value.contains('@')) ? 'Email không hợp lệ' : null,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mật Khẩu',
                            hintText: 'Nhập mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.length < 6
                              ? 'Mật khẩu phải có ít nhất 6 ký tự'
                              : null,
                        ),

                        // Nhớ mật khẩu + Quên mật khẩu
                        if (!_isRegisterMode) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                    activeColor: Colors.indigo,
                                  ),
                                  const Text('Nhớ mật khẩu'),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Xử lý quên mật khẩu
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Chức năng quên mật khẩu đang được phát triển')),
                                  );
                                },
                                child: const Text('Quên mật khẩu?'),
                              ),
                            ],
                          ),
                        ],

                        // Tên hiển thị khi đăng ký
                        if (_isRegisterMode) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(
                              labelText: 'Tên Hiển Thị',
                              hintText: 'Tên của bạn',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty
                                ? 'Vui lòng nhập tên hiển thị'
                                : null,
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Nút Đăng nhập / Đăng ký
                        ElevatedButton(
                          onPressed: controller.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: controller.isLoading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                              : Text(_isRegisterMode ? 'TẠO TÀI KHOẢN' : 'ĐĂNG NHẬP'),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
                          child: Text(
                            _isRegisterMode
                                ? 'Đã Có Tài Khoản? Đăng Nhập'
                                : 'Chưa Có Tài Khoản? Đăng Ký',
                          ),
                        ),

                        // Error
                        if (controller.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                controller.error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
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
      ),
    );
  }
}