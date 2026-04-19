import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/quiz/data/repositories/quiz_repository.dart';
import 'package:btl/features/quiz/presentation/pages/quiz_page.dart';
import 'package:btl/features/learning/data/repositories/learning_repository.dart';
import 'package:btl/features/learning/domain/entities/lesson.dart';

class LessonDetailPage extends StatefulWidget {
  LessonDetailPage({
    super.key,
    required this.controller,
    required this.courseId,
    required this.lesson,
    LearningRepository? learningRepository,
    QuizRepository? quizRepository,
  })  : learningRepository = learningRepository ?? LearningRepository(),
        quizRepository = quizRepository ?? QuizRepository();

  final AuthController controller;
  final String courseId;
  final Lesson lesson;
  final LearningRepository learningRepository;
  final QuizRepository quizRepository;

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  late Future<Lesson> _lessonFuture;

  @override
  void initState() {
    super.initState();
    _lessonFuture = widget.learningRepository.getLessonDetail(widget.courseId, widget.lesson.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      body: FutureBuilder<Lesson>(
        future: _lessonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final lesson = snapshot.data;
          if (lesson == null) {
            return const Center(child: Text('Không tìm thấy bài học'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Placeholder or Header Image
                      Container(
                        width: double.infinity,
                        height: 200,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF334155)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white70),
                        ),
                      ),
                      
                      Text(
                        lesson.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Markdown Content
                      (lesson.theory != null && lesson.theory!.isNotEmpty)
                          ? MarkdownBody(
                              data: lesson.theory!,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                p: TextStyle(fontSize: 16, height: 1.6, color: isDarkMode ? Colors.white70 : Colors.black87),
                                h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                code: TextStyle(
                                  backgroundColor: isDarkMode ? Colors.white10 : Colors.grey[200],
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: isDarkMode ? Colors.black26 : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey[300]!),
                                ),
                              ),
                            )
                          : Text(
                              lesson.content,
                              style: TextStyle(fontSize: 16, height: 1.6, color: isDarkMode ? Colors.white70 : Colors.black87),
                            ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Bar
              if (lesson.quizId != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => QuizPage(
                                controller: widget.controller,
                                quizId: lesson.quizId!,
                                repository: widget.quizRepository,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz_rounded),
                            SizedBox(width: 12),
                            Text(
                              'LÀM BÀI TRẮC NGHIỆM',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

