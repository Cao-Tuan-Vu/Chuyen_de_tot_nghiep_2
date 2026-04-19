import 'package:flutter/material.dart';

import 'package:btl/features/quiz/domain/entities/quiz.dart';

class QuizResultPage extends StatelessWidget {
  const QuizResultPage({
    super.key,
    required this.quiz,
    required this.result,
  });

  final Quiz quiz;
  final QuizAttemptResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ket qua quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quiz.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Diem: ${result.score}/${result.total}'),
            const SizedBox(height: 16),
            const Text('Chi tiet:'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: result.review.length,
                itemBuilder: (context, index) {
                  final review = result.review[index];
                  final question = quiz.questions.firstWhere(
                    (item) => item.id == review.questionId,
                    orElse: () => QuizQuestion(id: '', prompt: '(Cau hoi khong tim thay)', options: <String>[]),
                  );

                  // Safeguard: ensure options and correctIndex are valid before indexing
                  final String detailText;
                  if (review.isCorrect) {
                    detailText = 'Dung. ${review.explanation}';
                  } else {
                    final hasOptions = question.options.isNotEmpty;
                    final validIndex = review.correctIndex >= 0 && review.correctIndex < question.options.length;
                    final correctAnswer = (hasOptions && validIndex) ? question.options[review.correctIndex] : '(khong co dap an)';
                    detailText = 'Sai. Dap an dung: $correctAnswer. ${review.explanation}';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${index + 1}. ${question.prompt}'),
                        subtitle: Text(detailText),
                      trailing: Icon(
                        review.isCorrect ? Icons.check_circle : Icons.cancel,
                        color: review.isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

