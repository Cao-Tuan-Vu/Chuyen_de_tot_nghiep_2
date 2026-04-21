import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:btl/features/quiz/domain/entities/quiz.dart';

class QuizResultPage extends StatefulWidget {
  const QuizResultPage({
    super.key,
    required this.quiz,
    required this.result,
  });

  final Quiz quiz;
  final QuizAttemptResult result;

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  final _db = FirebaseDatabase.instance.ref();

  String? _readStringField(Map? data, List<String> keys) {
    if (data == null) {
      return null;
    }
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Future<String?> _resolveLessonId() async {
    // 1) Prefer lessonId already attached in loaded quiz object.
    if (widget.quiz.lessonId.isNotEmpty) {
      return widget.quiz.lessonId;
    }

    // 2) Try read from quizzes/{quizId} with both new/legacy keys.
    final quizSnap = await _db.child('quizzes/${widget.quiz.id}').get();
    if (quizSnap.exists && quizSnap.value is Map) {
      final quizData = quizSnap.value as Map;
      final fromQuiz = _readStringField(quizData, const ['lessonId', 'lesson']);
      if (fromQuiz != null) {
        return fromQuiz;
      }
    }

    // 3) Fallback: find lesson by matching lesson.quizId/lesson.quiz == quizId.
    final lessonsSnap = await _db.child('lessons').get();
    if (lessonsSnap.exists && lessonsSnap.value is Map) {
      final lessons = Map<String, dynamic>.from(lessonsSnap.value as Map);
      for (final entry in lessons.entries) {
        if (entry.value is! Map) {
          continue;
        }
        final lessonData = entry.value as Map;
        final quizRef = _readStringField(lessonData, const ['quizId', 'quiz']);
        if (quizRef == widget.quiz.id) {
          final lessonId = _readStringField(lessonData, const ['id', 'lessonId']);
          return lessonId ?? entry.key;
        }
      }
    }

    return null;
  }

  void _goBackToPreviousPage() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  void initState() {
    super.initState();
    _markLessonCompleted();
  }

  /// Mark lesson hoàn thành khi quiz được submit
  Future<void> _markLessonCompleted() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final lessonId = await _resolveLessonId();
      if (lessonId == null || lessonId.isEmpty) {
        return;
      }

      // Mark lesson hoàn thành
      await _db.child('users/$userId/completedLessons/$lessonId').set({
        'completedAt': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = ((widget.result.score / widget.result.total) * 100).toStringAsFixed(1);
    final isPassed = widget.result.score >= (widget.result.total * 0.6); // 60% để pass
    final correctCount = widget.result.review.where((item) => item.isCorrect).length;
    final wrongCount = widget.result.review.where((item) => !item.isCorrect && item.selectedIndex != null).length;
    final unansweredCount = widget.result.review.where((item) => item.selectedIndex == null).length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goBackToPreviousPage();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToPreviousPage,
        ),
        title: const Text('Kết quả Quiz'),
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: Column(
        children: [
          // ==================== SCORE BANNER ====================
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              children: [
                Text(
                  widget.quiz.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Score Display
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.result.score}/${widget.result.total}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isPassed ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPassed ? '✅ Đạt yêu cầu' : '⚠️ Chưa đạt',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MiniSummaryCard(
                        title: 'Đúng',
                        value: '$correctCount',
                        icon: Icons.check_circle_rounded,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniSummaryCard(
                        title: 'Sai',
                        value: '$wrongCount',
                        icon: Icons.cancel_rounded,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniSummaryCard(
                        title: 'Bỏ qua',
                        value: '$unansweredCount',
                        icon: Icons.remove_circle_outline_rounded,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tiến độ tổng kết',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isPassed ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: widget.result.total == 0 ? 0 : widget.result.score / widget.result.total,
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                          color: isPassed ? Colors.green : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==================== DETAILS ====================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.result.review.length,
              itemBuilder: (context, index) {
                final review = widget.result.review[index];
                final question = widget.quiz.questions.firstWhere(
                  (item) => item.id == review.questionId,
                  orElse: () => QuizQuestion(
                    id: '',
                    prompt: '(Câu hỏi không tìm thấy)',
                    options: <String>[],
                  ),
                );

                final hasOptions = question.options.isNotEmpty;
                final validIndex =
                    review.correctIndex >= 0 &&
                    review.correctIndex < question.options.length;
                final correctAnswer = (hasOptions && validIndex)
                    ? question.options[review.correctIndex]
                    : '(không có đáp án)';
                final validSelectedIndex =
                    review.selectedIndex != null &&
                    review.selectedIndex! >= 0 &&
                    review.selectedIndex! < question.options.length;
                final selectedAnswer = validSelectedIndex
                    ? question.options[review.selectedIndex!]
                    : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: review.isCorrect
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Number and Status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Câu ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Icon(
                              review.isCorrect
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: review.isCorrect
                                  ? Colors.green
                                  : Colors.red,
                              size: 28,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Question Text
                        Text(
                          question.prompt,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Status Detail
                        if (review.isCorrect)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Đúng. ${review.explanation}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Sai. ${review.explanation}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.lightbulb,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Đáp án đúng:',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            correctAnswer,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Bạn đã chọn:',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedAnswer ?? '(chưa chọn đáp án)',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ==================== BACK BUTTON ====================
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _goBackToPreviousPage,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại khóa học'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  const _MiniSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

