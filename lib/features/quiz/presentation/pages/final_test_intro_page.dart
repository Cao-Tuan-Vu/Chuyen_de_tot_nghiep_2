import 'package:flutter/material.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/quiz/data/repositories/quiz_repository.dart';
import 'package:btl/features/quiz/presentation/pages/quiz_page.dart';

class FinalTestIntroPage extends StatelessWidget {
  FinalTestIntroPage({
    super.key,
    required this.controller,
    required this.quizId,
    required this.courseTitle,
    QuizRepository? repository,
  }) : repository = repository ?? QuizRepository();

  final AuthController controller;
  final String quizId;
  final String courseTitle;
  final QuizRepository repository;

  void _start(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizPage(
          controller: controller,
          quizId: quizId,
          repository: repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primary = Color(0xFF4F46E5);
    const secondary = Color(0xFF6366F1);
    const tertiary = Color(0xFF818CF8);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text('Test Tổng Hợp'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primary, secondary, tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 46),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Bài Test Tổng Hợp',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      courseTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _InfoCard(
                icon: Icons.flag_circle_rounded,
                title: 'Mục tiêu',
                subtitle: 'Đánh giá tổng hợp kiến thức của toàn bộ khóa học.',
                accentColor: primary,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.fact_check_rounded,
                title: 'Điều kiện đạt',
                subtitle: 'Hoàn thành từ 60% trở lên để được xem là đạt yêu cầu.',
                accentColor: secondary,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.leaderboard_rounded,
                title: 'Ảnh hưởng BXH',
                subtitle: 'Điểm bài test cuối sẽ chiếm trọng số lớn nhất trong xếp hạng.',
                accentColor: tertiary,
              ),
              const SizedBox(height: 20),
              Text(
                'Nội dung ôn tập',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              const _BulletItem(text: 'Dart cơ bản và cú pháp cốt lõi'),
              const _BulletItem(text: 'OOP: class, object, kế thừa, đa hình'),
              const _BulletItem(text: 'Flutter UI và cách tổ chức widget'),
              const _BulletItem(text: 'Tư duy giải bài, đọc hiểu yêu cầu, chọn đáp án đúng'),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => _start(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: const Text(
                  'Bắt đầu kiểm tra',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bạn có thể quay lại sau khi xem kết quả để ôn thêm.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}


