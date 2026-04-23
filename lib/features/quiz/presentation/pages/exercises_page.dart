import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:btl/features/quiz/presentation/pages/quiz_page.dart';
import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/quiz/domain/entities/quiz.dart';

class ExercisesPage extends StatefulWidget {
  final AuthController controller;
  const ExercisesPage({super.key, required this.controller});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  static const int _questionCountPerTest = 10;
  final db = FirebaseDatabase.instance.ref();
  bool _loading = true;
  Map<String, _LevelPool> _poolsByLevel = {
    'easy': const _LevelPool(level: 'easy', questions: []),
    'medium': const _LevelPool(level: 'medium', questions: []),
    'hard': const _LevelPool(level: 'hard', questions: []),
  };

  @override
  void initState() {
    super.initState();
    _loadAllQuizzes();
  }

  Future<void> _loadAllQuizzes() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final coursesSnap = await db.child('courses').get();
      final lessonsSnap = await db.child('lessons').get();
      final quizzesSnap = await db.child('quizzes').get();

      final courseLevels = <String, String>{};
      if (coursesSnap.exists && coursesSnap.value is Map) {
        final allCourses = Map<String, dynamic>.from(coursesSnap.value as Map);
        for (final entry in allCourses.entries) {
          final value = entry.value;
          if (value is Map) {
            courseLevels[entry.key] = _normalizeLevel(value['level']?.toString() ?? '');
          }
        }
      }

      final pools = {'easy': <QuizQuestion>[], 'medium': <QuizQuestion>[], 'hard': <QuizQuestion>[]};
      final allLessons = lessonsSnap.exists && lessonsSnap.value is Map ? Map<String, dynamic>.from(lessonsSnap.value as Map) : <String, dynamic>{};
      final allQuizzes = quizzesSnap.exists && quizzesSnap.value is Map ? Map<String, dynamic>.from(quizzesSnap.value as Map) : <String, dynamic>{};

      for (final lesson in allLessons.values) {
        if (lesson is! Map) continue;
        final courseId = (lesson['courseId'] ?? lesson['course'] ?? '').toString();
        final quizId = (lesson['quizId'] ?? lesson['quiz'] ?? '').toString();
        if (quizId.isEmpty || !allQuizzes.containsKey(quizId)) continue;

        final rawQuiz = allQuizzes[quizId];
        if (rawQuiz is! Map) continue;

        final quizJson = Map<String, dynamic>.from(rawQuiz);
        quizJson.putIfAbsent('id', () => quizId);
        quizJson.putIfAbsent('title', () => lesson['title']?.toString() ?? 'Quiz');
        final parsedQuiz = Quiz.fromJson(quizJson);

        final level = _normalizeLevel(lesson['level']?.toString() ?? quizJson['level']?.toString() ?? courseLevels[courseId] ?? 'medium');
        for (int i = 0; i < parsedQuiz.questions.length; i++) {
          final q = parsedQuiz.questions[i];
          pools[level]!.add(QuizQuestion(
            id: '${quizId}_${q.id}_$i',
            prompt: q.prompt,
            options: List<String>.from(q.options),
            correctIndex: q.correctIndex,
            explanation: q.explanation,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _poolsByLevel = {
            'easy': _LevelPool(level: 'easy', questions: pools['easy'] ?? []),
            'medium': _LevelPool(level: 'medium', questions: pools['medium'] ?? []),
            'hard': _LevelPool(level: 'hard', questions: pools['hard'] ?? []),
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _normalizeLevel(String raw) {
    final n = raw.trim().toLowerCase();
    if (n == 'easy' || n == 'beginner' || n.contains('cơ bản')) return 'easy';
    if (n == 'hard' || n == 'advanced' || n.contains('nâng cao')) return 'hard';
    if (n == 'medium' || n == 'intermediate' || n.contains('trung bình')) return 'medium';
    return 'medium';
  }

  Future<void> _startLevelTest(String level) async {
    final pool = _poolsByLevel[level];
    if (pool == null || pool.questions.isEmpty) return;

    final selected = List<QuizQuestion>.from(pool.questions)..shuffle(Random());
    final finalSelected = selected.take(_questionCountPerTest).toList();

    final sessionQuestions = <QuizQuestion>[];
    for (int i = 0; i < finalSelected.length; i++) {
      final q = finalSelected[i];
      sessionQuestions.add(QuizQuestion(
        id: 'test_${level}_${i}_${q.id}',
        prompt: q.prompt,
        options: q.options,
        correctIndex: q.correctIndex,
        explanation: q.explanation,
      ));
    }

    final testId = '${level}_random_${DateTime.now().millisecondsSinceEpoch}';
    final testTitle = 'Kiểm tra ${level.toUpperCase()}';
    final generatedQuiz = Quiz(
      id: testId,
      courseId: 'random_mix',
      lessonId: 'random_$level',
      title: '$testTitle (${sessionQuestions.length} câu)',
      questions: sessionQuestions,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizPage(
          controller: widget.controller,
          quizId: testId,
          generatedQuiz: generatedQuiz,
          attemptType: 'level_test',
          level: level,
          quizTitle: testTitle,
        ),
      ),
    );
    _loadAllQuizzes();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    int totalQuestions = _poolsByLevel.values.fold(0, (sum, pool) => sum + pool.questions.length);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(isDarkMode, totalQuestions),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chọn mức độ thử thách',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDarkMode ? Colors.white : Colors.indigo[900],
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hệ thống sẽ trộn ngẫu nhiên câu hỏi từ tất cả các khóa học phù hợp với trình độ của bạn.',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildModernLevelCard(
                        'easy',
                        'Cơ bản',
                        'Dành cho người mới bắt đầu hoặc muốn ôn lại kiến thức nền tảng.',
                        [const Color(0xFF10B981), const Color(0xFF059669)],
                        Icons.child_care_rounded,
                      ),
                      const SizedBox(height: 20),
                      _buildModernLevelCard(
                        'medium',
                        'Trung bình',
                        'Thử thách khả năng vận dụng kiến thức vào các bài toán thực tế.',
                        [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                        Icons.psychology_rounded,
                      ),
                      const SizedBox(height: 20),
                      _buildModernLevelCard(
                        'hard',
                        'Nâng cao',
                        'Dành cho những chuyên gia muốn chinh phục những kiến thức khó nhất.',
                        [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                        Icons.workspace_premium_rounded,
                      ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar(bool isDarkMode, int totalQuestions) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: Colors.indigo[700],
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
        ),
      ),
      centerTitle: true,
      title: const Text('Luyện tập tự do', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.indigo[800]!, Colors.indigo[500]!],
                ),
              ),
            ),
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(Icons.quiz_rounded, size: 180, color: Colors.white.withOpacity(0.1)),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatChip(Icons.library_books_rounded, '$totalQuestions câu hỏi có sẵn'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildModernLevelCard(String level, String title, String desc, List<Color> colors, IconData icon) {
    final pool = _poolsByLevel[level];
    final count = pool?.questions.length ?? 0;
    final bool canStart = count >= 5;

    return GestureDetector(
      onTap: canStart ? () => _startLevelTest(level) : () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cần ít nhất 5 câu hỏi để bắt đầu mức độ $title.')),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(color: colors.last.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.15)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$count câu hỏi', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      if (canStart)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            'Bắt đầu học',
                            style: TextStyle(color: colors.last, fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        )
                      else
                        const Text('Chưa đủ dữ liệu', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPool {
  const _LevelPool({required this.level, required this.questions});
  final String level;
  final List<QuizQuestion> questions;
}



