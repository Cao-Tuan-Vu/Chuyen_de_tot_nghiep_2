import 'package:flutter/material.dart';

class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  static const String routeName = '/policy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chính sách & Điều khoản'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Thu thập thông tin',
              'Chúng tôi thu thập thông tin cơ bản như tên và email khi bạn đăng ký tài khoản để quản lý tiến độ học tập của bạn.',
            ),
            _buildSection(
              '2. Sử dụng thông tin',
              'Thông tin của bạn được sử dụng để cá nhân hóa trải nghiệm học tập, gửi thông báo về khóa học mới và cải thiện chất lượng dịch vụ AI.',
            ),
            _buildSection(
              '3. Bảo mật dữ liệu',
              'Dữ liệu của bạn được bảo mật an toàn trên nền tảng Firebase của Google. Chúng tôi cam kết không chia sẻ thông tin cá nhân của bạn cho bên thứ ba.',
            ),
            _buildSection(
              '4. Trách nhiệm người dùng',
              'Người dùng có trách nhiệm bảo mật mật khẩu tài khoản và không sử dụng ứng dụng cho các mục đích vi phạm pháp luật hoặc phá hoại hệ thống.',
            ),
            const SizedBox(height: 20),
            const Text(
              'Cập nhật lần cuối: Tháng 10/2023',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }
}
