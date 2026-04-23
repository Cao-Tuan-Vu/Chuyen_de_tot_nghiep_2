import 'package:flutter/material.dart';

class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  static const String routeName = '/policy';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text('Chính sách & Điều khoản', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF1A237E), const Color(0xFF121212)]
                : [Colors.indigo.shade800, Colors.grey.shade50],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildSection(
                        context,
                        '1. Thu thập thông tin',
                        'Chúng tôi thu thập thông tin cơ bản như tên và email khi bạn đăng ký tài khoản để quản lý tiến độ học tập của bạn.',
                        Icons.info_outline_rounded,
                      ),
                      const Divider(height: 32),
                      _buildSection(
                        context,
                        '2. Sử dụng thông tin',
                        'Thông tin của bạn được sử dụng để cá nhân hóa trải nghiệm học tập, gửi thông báo về khóa học mới và cải thiện chất lượng dịch vụ AI.',
                        Icons.settings_suggest_outlined,
                      ),
                      const Divider(height: 32),
                      _buildSection(
                        context,
                        '3. Bảo mật dữ liệu',
                        'Dữ liệu của bạn được bảo mật an toàn trên nền tảng Firebase của Google. Chúng tôi cam kết không chia sẻ thông tin cá nhân của bạn cho bên thứ ba.',
                        Icons.security_rounded,
                      ),
                      const Divider(height: 32),
                      _buildSection(
                        context,
                        '4. Trách nhiệm người dùng',
                        'Người dùng có trách nhiệm bảo mật mật khẩu tài khoản và không sử dụng ứng dụng cho các mục đích vi phạm pháp luật hoặc phá hoại hệ thống.',
                        Icons.person_pin_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Cập nhật lần cuối: Tháng 10/2023',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.indigo, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.indigo.shade300 : Colors.indigo.shade900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 36.0),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}



