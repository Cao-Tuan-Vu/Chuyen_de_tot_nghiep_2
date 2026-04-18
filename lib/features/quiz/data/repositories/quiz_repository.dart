import 'package:firebase_database/firebase_database.dart';

import 'package:btl/features/quiz/domain/entities/quiz.dart';

class QuizRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference get _quizzesRef => _database.ref('quizzes');
  DatabaseReference get _attemptsRef => _database.ref('attempts');

  Future<Quiz> getQuiz(String quizId) async {
    final snapshot = await _quizzesRef.child(quizId).get();
    if (!snapshot.exists || snapshot.value == null) {
      throw Exception('Tai quiz that bai (404)');
    }

    final data = _asMap(snapshot.value);
    data.putIfAbsent('id', () => quizId);
    return Quiz.fromJson(data);
  }

  Future<QuizAttemptResult> submitQuiz({
    required String quizId,
    required String token,
    required Map<String, int> answers,
  }) async {
    final quiz = await getQuiz(quizId);
    final review = <QuizReviewItem>[];
    var correctCount = 0;

    for (final question in quiz.questions) {
      final selectedIndex = answers[question.id];
      final correctIndex = question.correctIndex;
      if (correctIndex == null) {
        throw Exception('Quiz khong co correctIndex');
      }

      final isCorrect = selectedIndex != null && selectedIndex == correctIndex;
      if (isCorrect) {
        correctCount++;
      }

      review.add(
        QuizReviewItem(
          questionId: question.id,
          selectedIndex: selectedIndex,
          correctIndex: correctIndex,
          isCorrect: isCorrect,
          explanation: question.explanation ?? '',
        ),
      );
    }

    final total = quiz.questions.length;
    final score = total == 0 ? 0 : ((correctCount / total) * 100).round();
    final submittedAt = DateTime.now().toUtc().toIso8601String();
    final attemptId = _attemptsRef.push().key ?? '${quizId}_$submittedAt';

    final result = QuizAttemptResult(
      attemptId: attemptId,
      quizId: quizId,
      userId: token,
      score: score,
      total: total,
      submittedAt: submittedAt,
      review: review,
    );

    await _attemptsRef.child(attemptId).set(result.toJson());
    await _database.ref('users').child(token).child('quizAttempts').child(attemptId).set({
      'attemptId': attemptId,
      'quizId': quizId,
      'submittedAt': submittedAt,
      'score': score,
      'total': total,
    });

    return result;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }
}

