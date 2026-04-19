import 'package:flutter/material.dart';

class IntroductionPage extends StatelessWidget {
  const IntroductionPage({super.key});

  static const String routeName = '/introduction';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giới thiệu'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded, size: 80, color: Colors.indigo),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Về BTL Learning',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'BTL Learning là một nền tảng học tập trực tuyến hiện đại, được thiết kế đặc biệt để giúp sinh viên và những người mới bắt đầu tiếp cận với lập trình một cách dễ dàng và hiệu quả nhất.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildFeatureSection(
              context,
              icon: Icons.psychology_rounded,
              title: 'Tích hợp AI',
              description: 'Sử dụng trí tuệ nhân tạo để cá nhân hóa lộ trình học tập và giải đáp thắc mắc tức thì.',
            ),
            _buildFeatureSection(
              context,
              icon: Icons.quiz_rounded,
              title: 'Học qua thực hành',
              description: 'Hệ thống bài tập Quiz đa dạng và các dự án thực tế giúp củng cố kiến thức vững chắc.',
            ),
            _buildFeatureSection(
              context,
              icon: Icons.devices_rounded,
              title: 'Mọi lúc mọi nơi',
              description: 'Truy cập nội dung học tập trên nhiều thiết bị, giúp bạn chủ động thời gian của mình.',
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Phiên bản 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection(BuildContext context, {required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.indigo, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
