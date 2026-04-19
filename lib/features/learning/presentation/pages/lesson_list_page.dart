import 'package:flutter/material.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/quiz/data/repositories/quiz_repository.dart';
import 'package:btl/features/quiz/presentation/pages/quiz_page.dart';
import 'package:btl/features/learning/data/repositories/learning_repository.dart';
import 'package:btl/features/learning/domain/entities/course.dart';
import 'package:btl/features/learning/domain/entities/lesson.dart';
import 'lesson_detail_page.dart';

class LessonListPage extends StatefulWidget {
  LessonListPage({
    super.key,
    required this.controller,
    required this.course,
    LearningRepository? learningRepository,
    QuizRepository? quizRepository,
  })  : learningRepository = learningRepository ?? LearningRepository(),
        quizRepository = quizRepository ?? QuizRepository();

  final AuthController controller;
  final Course course;
  final LearningRepository learningRepository;
  final QuizRepository quizRepository;

  @override
  State<LessonListPage> createState() => _LessonListPageState();
}

class _LessonListPageState extends State<LessonListPage> {
  late Future<List<Lesson>> _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = widget.learningRepository.getLessonsByCourse(widget.course.id);
  }

  void _startComprehensiveQuiz(String quizId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizPage(
          controller: widget.controller,
          quizId: quizId,
          repository: widget.quizRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF6366F1),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.course.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF818CF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.auto_stories_rounded, size: 80, color: Colors.white24),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<Lesson>>(
            future: _lessonsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text(snapshot.error.toString())));
              }

              final lessons = snapshot.data ?? [];
              if (lessons.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('Chưa có bài học')));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < lessons.length) {
                        final lesson = lessons[index];
                        final isQuiz = lesson.quizId != null;
                        return _buildLessonCard(context, lesson, index, isQuiz, isDarkMode);
                      }

                      // Final Quiz Button
                      if (widget.course.comprehensiveQuizId != null) {
                        return _buildFinalQuizBanner(context, isDarkMode);
                      }
                      return null;
                    },
                    childCount: lessons.length + (widget.course.comprehensiveQuizId != null ? 1 : 0),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, Lesson lesson, int index, bool isQuiz, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (isQuiz ? Colors.amber : Colors.indigo).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${lesson.order}',
              style: TextStyle(
                color: isQuiz ? Colors.orange[800] : Colors.indigo,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            Icon(
              isQuiz ? Icons.quiz_outlined : Icons.menu_book_rounded,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              isQuiz ? 'Bài học + Trắc nghiệm' : 'Lý thuyết',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LessonDetailPage(
                controller: widget.controller,
                courseId: widget.course.id,
                lesson: lesson,
                learningRepository: widget.learningRepository,
                quizRepository: widget.quizRepository,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinalQuizBanner(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'CHÚC MỪNG!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bạn đã sẵn sàng cho bài thi tổng kết?',
            style: TextStyle(color: Colors.white, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (widget.course.comprehensiveQuizId != null) {
                _startComprehensiveQuiz(widget.course.comprehensiveQuizId!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange[900],
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('BẮT ĐẦU KIỂM TRA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

