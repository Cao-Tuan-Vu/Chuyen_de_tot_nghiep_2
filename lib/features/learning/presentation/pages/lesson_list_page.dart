import 'package:flutter/material.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/quiz/data/repositories/quiz_repository.dart';
import 'package:btl/features/quiz/presentation/pages/final_test_intro_page.dart';
import 'package:btl/features/learning/data/repositories/learning_repository.dart';
import 'package:btl/features/learning/domain/entities/course.dart';
import 'package:btl/features/learning/domain/entities/lesson.dart';
import 'package:btl/features/learning/presentation/theme/course_visuals.dart';
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
  late Future<Set<String>> _completedLessonIdsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = widget.learningRepository.getLessonsByCourse(widget.course.id);
    _completedLessonIdsFuture = _loadCompletedLessonIds();
  }

  Future<Set<String>> _loadCompletedLessonIds() async {
    final userId = widget.controller.currentUser?.id;
    if (userId == null) {
      return <String>{};
    }

    final completed = await widget.learningRepository.getCompletedLessons(userId);
    return completed.toSet();
  }

  void _refreshCompletionState() {
    setState(() {
      _completedLessonIdsFuture = _loadCompletedLessonIds();
    });
  }

  void _startComprehensiveQuiz(String quizId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FinalTestIntroPage(
          controller: widget.controller,
          quizId: quizId,
          courseTitle: widget.course.title,
          repository: widget.quizRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final courseStyle = courseVisualStyleFor(widget.course.id);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(courseStyle),
          FutureBuilder<List<Lesson>>(
            future: _lessonsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Lỗi: ${snapshot.error}')));
              }

              final lessons = snapshot.data ?? [];
              if (lessons.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('Chưa có bài học nào trong khóa học này.')));
              }

              return FutureBuilder<Set<String>>(
                future: _completedLessonIdsFuture,
                builder: (context, completedSnapshot) {
                  final completedLessonIds = completedSnapshot.data ?? <String>{};
                  final requiredQuizLessons = lessons
                      .where((lesson) => lesson.quizId != null && lesson.quizId!.isNotEmpty)
                      .map((lesson) => lesson.id)
                      .toList();

                  final canShowFinalQuiz =
                      widget.course.comprehensiveQuizId != null &&
                      requiredQuizLessons.isNotEmpty &&
                      requiredQuizLessons.every(completedLessonIds.contains);

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < lessons.length) {
                            final lesson = lessons[index];
                            final isCompleted = completedLessonIds.contains(lesson.id);
                            return _buildModernLessonCard(
                              context, 
                              lesson, 
                              index == lessons.length - 1 && !canShowFinalQuiz, 
                              isCompleted, 
                              isDarkMode, 
                              courseStyle
                            );
                          }

                          if (canShowFinalQuiz) {
                            return _buildFinalQuizBanner(context, isDarkMode);
                          }
                          return null;
                        },
                        childCount: lessons.length + (canShowFinalQuiz ? 1 : 0),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(CourseVisualStyle courseStyle) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: courseStyle.primary,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          widget.course.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            shadows: [Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [courseStyle.primary, courseStyle.primary.withBlue(200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Icon(courseStyle.icon, size: 200, color: Colors.white.withOpacity(0.1)),
            ),
            Center(
              child: Hero(
                tag: 'course_icon_${widget.course.id}',
                child: Icon(courseStyle.icon, size: 80, color: Colors.white.withOpacity(0.9)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernLessonCard(BuildContext context, Lesson lesson, bool isLast, bool isCompleted, bool isDarkMode, CourseVisualStyle style) {
    final isQuiz = lesson.quizId != null && lesson.quizId!.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline logic
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF10B981) : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isCompleted ? [
                    BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))
                  ] : [],
                ),
                child: Center(
                  child: isCompleted 
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text('${lesson.order}', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted ? const Color(0xFF10B981).withOpacity(0.5) : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
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
                  if (mounted) _refreshCompletionState();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isCompleted ? Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 1) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800, 
                                fontSize: 16,
                                color: isDarkMode ? Colors.white : Colors.indigo[900],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  isQuiz ? Icons.assignment_turned_in_rounded : Icons.menu_book_rounded,
                                  size: 14,
                                  color: isQuiz ? Colors.orange : style.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isQuiz ? 'Lý thuyết + Bài tập' : 'Chỉ lý thuyết',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalQuizBanner(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 30),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'THỬ THÁCH CUỐI CÙNG',
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w900, 
              fontSize: 20, 
              letterSpacing: 1.5
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn đã hoàn thành tất cả bài học! Hãy chinh phục bài thi tổng kết để nhận chứng chỉ.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (widget.course.comprehensiveQuizId != null) {
                  _startComprehensiveQuiz(widget.course.comprehensiveQuizId!);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'BẮT ĐẦU THI NGAY', 
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)
              ),
            ),
          ),
        ],
      ),
    );
  }
}
