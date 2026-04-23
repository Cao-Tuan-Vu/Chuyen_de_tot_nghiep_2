import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/quiz/data/repositories/quiz_repository.dart';
import 'package:btl/features/quiz/domain/entities/quiz.dart';
import 'quiz_result_page.dart';
import 'quizzes_debug_page.dart';

class QuizPage extends StatefulWidget {
  QuizPage({
    super.key,
    required this.controller,
    required this.quizId,
    this.generatedQuiz,
    this.attemptType,
    this.level,
    this.quizTitle,
    QuizRepository? repository,
  }) : repository = repository ?? QuizRepository();

  final AuthController controller;
  final String quizId;
  final Quiz? generatedQuiz;
  final String? attemptType;
  final String? level;
  final String? quizTitle;
  final QuizRepository repository;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late Future<Quiz> _quizFuture;
  final Map<String, int> _answers = {};
  bool _isSubmitting = false;
  int _currentQuestionIndex = 0;
  late PageController _pageController;
  
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimeUp = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _quizFuture = widget.generatedQuiz != null
        ? Future.value(widget.generatedQuiz!)
        : widget.repository.getQuiz(widget.quizId);
    
    _quizFuture.then((quiz) {
      _startTimer(quiz.questions.length);
    });
  }

  void _startTimer(int questionCount) {
    _remainingSeconds = questionCount * 60; // 1 phút mỗi câu
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _onTimeUp();
      }
    });
  }

  void _onTimeUp() {
    if (_isSubmitting) return;
    setState(() => _isTimeUp = true);
    
    // Hiện thông báo và tự động nộp bài
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã hết thời gian làm bài! Hệ thống đang tự động nộp bài...'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    
    _quizFuture.then((quiz) => _submit(quiz, autoSubmit: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submit(Quiz quiz, {bool autoSubmit = false}) async {
    if (!autoSubmit && _answers.length < quiz.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng hoàn thành tất cả các câu hỏi!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _timer?.cancel();

    final token = widget.controller.token;
    if (token == null) {
      setState(() => _error = 'Phiên đăng nhập hết hạn');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final result = await widget.repository.submitQuiz(
        quizId: quiz.id,
        token: token,
        answers: _answers,
        quizData: widget.generatedQuiz,
        attemptType: widget.attemptType,
        level: widget.level,
        quizTitle: widget.quizTitle,
      );

      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => QuizResultPage(quiz: quiz, result: result),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _nextPage(int total) {
    if (_currentQuestionIndex < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarTitle = (widget.quizTitle != null && widget.quizTitle!.trim().isNotEmpty)
        ? widget.quizTitle!.trim()
        : 'Làm bài trắc nghiệm';

    if (_isTimeUp) {
      return _buildTimeUpState();
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          children: [
            Text(appBarTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 14, color: _remainingSeconds < 60 ? Colors.red : (isDark ? Colors.grey[400] : Colors.grey[600])),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    color: _remainingSeconds < 60 ? Colors.red : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Thoát bài thi?'),
                content: const Text('Tiến trình của bạn sẽ không được lưu. Bạn có chắc chắn muốn thoát?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                  TextButton(onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }, child: const Text('Thoát', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
        ),
      ),
      body: FutureBuilder<Quiz>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final quiz = snapshot.data;
          if (quiz == null) {
            return const Center(child: Text('Không tìm thấy bài trắc nghiệm'));
          }

          final progress = quiz.questions.isNotEmpty 
              ? (_answers.length / quiz.questions.length) 
              : 0.0;

          return Column(
            children: [
              _buildProgressBar(progress, isDark, quiz.questions.length),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: quiz.questions.length,
                  onPageChanged: (index) => setState(() => _currentQuestionIndex = index),
                  itemBuilder: (context, index) {
                    final question = quiz.questions[index];
                    return _buildQuestionCard(question, index, quiz.questions.length, isDark);
                  },
                ),
              ),
              _buildBottomBar(quiz, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(double progress, bool isDark, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? Colors.grey[900]! : Colors.grey[100]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu ${_currentQuestionIndex + 1} / $total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              Text(
                'Đã làm: ${_answers.length} câu',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question, int index, int total, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.prompt,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.4,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(question.options.length, (optionIndex) {
            final isSelected = _answers[question.id] == optionIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (_isSubmitting) return;
                    setState(() {
                      _answers[question.id] = optionIndex;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.blue.withValues(alpha: isDark ? 0.2 : 0.08) 
                          : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.blue[600]! 
                            : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                        width: 2,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.blue[600] : (isDark ? Colors.grey[800] : Colors.grey[100]),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + optionIndex),
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            question.options[optionIndex],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected 
                                  ? Colors.blue[700] 
                                  : (isDark ? Colors.grey[300] : const Color(0xFF334155)),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: Colors.blue[600], size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Quiz quiz, bool isDark) {
    final isLastQuestion = _currentQuestionIndex == quiz.questions.length - 1;
    
    return Container(
      padding: EdgeInsets.only(
        left: 20, 
        right: 20, 
        top: 20, 
        bottom: MediaQuery.of(context).padding.bottom + 20
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: TextButton(
                onPressed: _previousPage,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Quay lại', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () {
                if (isLastQuestion) {
                  _submit(quiz);
                } else {
                  _nextPage(quiz.questions.length);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastQuestion ? const Color(0xFF10B981) : Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _isSubmitting 
                    ? 'Đang nộp...' 
                    : (isLastQuestion ? 'Nộp bài & Kết thúc' : 'Câu tiếp theo'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUpState() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_off_outlined, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Hết thời gian!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Hệ thống đang tự động nộp bài...'),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 80),
            const SizedBox(height: 24),
            Text(
              'Đã xảy ra lỗi!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            if (kDebugMode)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const QuizzesDebugPage()),
                  );
                },
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text('Xem danh sách quizzes (Debug)'),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}
