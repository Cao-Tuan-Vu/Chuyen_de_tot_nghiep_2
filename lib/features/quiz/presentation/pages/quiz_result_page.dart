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
    if (data == null) return null;
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  Future<String?> _resolveLessonId() async {
    if (widget.quiz.lessonId.isNotEmpty) return widget.quiz.lessonId;

    final quizSnap = await _db.child('quizzes/${widget.quiz.id}').get();
    if (quizSnap.exists && quizSnap.value is Map) {
      final quizData = quizSnap.value as Map;
      final fromQuiz = _readStringField(quizData, const ['lessonId', 'lesson']);
      if (fromQuiz != null) return fromQuiz;
    }

    final lessonsSnap = await _db.child('lessons').get();
    if (lessonsSnap.exists && lessonsSnap.value is Map) {
      final lessons = Map<String, dynamic>.from(lessonsSnap.value as Map);
      for (final entry in lessons.entries) {
        if (entry.value is! Map) continue;
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
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _markLessonCompleted();
  }

  Future<void> _markLessonCompleted() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      final lessonId = await _resolveLessonId();
      if (lessonId == null || lessonId.isEmpty) return;

      await _db.child('users/$userId/completedLessons/$lessonId').set({
        'completedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreRatio = widget.result.total == 0 ? 0.0 : widget.result.score / widget.result.total;
    final percentage = (scoreRatio * 100).toStringAsFixed(1);
    final isPassed = scoreRatio >= 0.6;
    
    final correctCount = widget.result.review.where((item) => item.isCorrect).length;
    final wrongCount = widget.result.review.where((item) => !item.isCorrect && item.selectedIndex != null).length;
    final unansweredCount = widget.result.review.where((item) => item.selectedIndex == null).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text('Kết quả bài thi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isPassed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildScoreBanner(isPassed, percentage, scoreRatio, isDark),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSummaryRow(correctCount, wrongCount, unansweredCount),
                  const SizedBox(height: 24),
                  _buildReviewList(isDark),
                  const SizedBox(height: 24),
                  _buildActionButtons(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBanner(bool isPassed, String percentage, double scoreRatio, bool isDark) {
    final baseColor = isPassed ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
      child: Column(
        children: [
          Icon(
            isPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'XUẤT SẮC!' : 'CỐ GẮNG HƠN NHÉ!',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            isPassed ? 'Bạn đã hoàn thành bài thi đạt yêu cầu.' : 'Bạn cần đạt tối thiểu 60% để vượt qua.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: scoreRatio,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percentage%',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${widget.result.score}/${widget.result.total}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(int correct, int wrong, int unanswered) {
    return Row(
      children: [
        _SummaryCard(label: 'Đúng', value: '$correct', color: const Color(0xFF10B981), icon: Icons.check_circle_rounded),
        const SizedBox(width: 12),
        _SummaryCard(label: 'Sai', value: '$wrong', color: const Color(0xFFEF4444), icon: Icons.cancel_rounded),
        const SizedBox(width: 12),
        _SummaryCard(label: 'Bỏ qua', value: '$unanswered', color: const Color(0xFF64748B), icon: Icons.remove_circle_outline_rounded),
      ],
    );
  }

  Widget _buildReviewList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xem lại đáp án',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...List.generate(widget.result.review.length, (index) {
          final review = widget.result.review[index];
          final question = widget.quiz.questions.firstWhere((q) => q.id == review.questionId, 
              orElse: () => QuizQuestion(id: '', prompt: 'Câu hỏi không tồn tại', options: []));
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: review.isCorrect 
                    ? const Color(0xFF10B981).withValues(alpha: 0.3) 
                    : const Color(0xFFEF4444).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (review.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Câu ${index + 1}',
                        style: TextStyle(
                          color: review.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      review.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: review.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question.prompt,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                if (!review.isCorrect) ...[
                  _AnswerInfo(
                    label: 'Bạn chọn:', 
                    value: review.selectedIndex != null ? question.options[review.selectedIndex!] : 'Chưa chọn',
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 8),
                ],
                _AnswerInfo(
                  label: 'Đáp án đúng:', 
                  value: question.options[review.correctIndex],
                  color: const Color(0xFF10B981),
                ),
                if (review.explanation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Giải thích: ${review.explanation}',
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.blue),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _goBackToPreviousPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text('QUAY LẠI KHÓA HỌC', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: Text(
            'Về trang chủ',
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _AnswerInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AnswerInfo({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }
}
