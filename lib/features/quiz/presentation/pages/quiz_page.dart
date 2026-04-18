import 'package:flutter/material.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/quiz/data/repositories/quiz_repository.dart';
import 'package:btl/features/quiz/domain/entities/quiz.dart';
import 'quiz_result_page.dart';

class QuizPage extends StatefulWidget {
  QuizPage({
    super.key,
    required this.controller,
    required this.quizId,
    QuizRepository? repository,
  }) : repository = repository ?? QuizRepository();

  final AuthController controller;
  final String quizId;
  final QuizRepository repository;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late Future<Quiz> _quizFuture;
  final Map<String, int> _answers = {};
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quizFuture = widget.repository.getQuiz(widget.quizId);
  }

  Future<void> _submit(Quiz quiz) async {
    final token = widget.controller.token;
    if (token == null) {
      setState(() => _error = 'Phien dang nhap het han');
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
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => QuizResultPage(quiz: quiz, result: result),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: FutureBuilder<Quiz>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final quiz = snapshot.data;
          if (quiz == null) {
            return const Center(child: Text('Khong tim thay quiz'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(quiz.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: quiz.questions.length,
                    itemBuilder: (context, index) {
                      final question = quiz.questions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${index + 1}. ${question.prompt}'),
                              const SizedBox(height: 8),
                              RadioGroup<int>(
                                groupValue: _answers[question.id],
                                onChanged: (value) {
                                  if (_isSubmitting || value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _answers[question.id] = value;
                                  });
                                },
                                child: Column(
                                  children: List.generate(question.options.length, (optionIndex) {
                                    return RadioListTile<int>(
                                      title: Text(question.options[optionIndex]),
                                      value: optionIndex,
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _submit(quiz),
                    child: Text(_isSubmitting ? 'Dang nop...' : 'Nop bai'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
