import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:btl/features/quiz/domain/entities/quiz.dart';

class QuizRepository {
  late final FirebaseDatabase _database = _buildDatabase();

  DatabaseReference get _quizzesRef => _database.ref('quizzes');
  DatabaseReference get _attemptsRef => _database.ref('attempts');

  Future<Quiz> getQuiz(String quizId) async {
    final snapshot = await _quizzesRef.child(quizId).get();
    if (!snapshot.exists || snapshot.value == null) {
      if (kDebugMode) {
        // Helpful debug log when a quiz is not found during development
        // ignore: avoid_print
        print('QuizRepository.getQuiz: quizId=$quizId not found; snapshot.exists=${snapshot.exists}; value=${snapshot.value}');
        try {
          final app = Firebase.app();
          // ignore: avoid_print
          print('Firebase.app().options.databaseURL=${app.options.databaseURL}');
        } catch (_) {}
        try {
          final all = await _quizzesRef.get();
          // ignore: avoid_print
          print('Quizzes node exists=${all.exists}; sample=${all.value}');
        } catch (e) {
          // ignore
        }
      }
      throw Exception('Tai quiz that bai (404): $quizId');
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

  /// Static debug helper - list all quizzes under /quizzes as a map.
  /// Returns an empty map if the node does not exist.
  /// This is static so test fakes that implement QuizRepository do not need to
  /// implement this debug helper.
  static Future<Map<String, dynamic>> listAllQuizzesStatic() async {
    try {
      final app = Firebase.app();
      final databaseUrl = app.options.databaseURL;
      final db = (databaseUrl != null && databaseUrl.isNotEmpty)
          ? FirebaseDatabase.instanceFor(app: app, databaseURL: databaseUrl)
          : FirebaseDatabase.instance;
      final snapshot = await db.ref('quizzes').get();
      if (!snapshot.exists || snapshot.value == null) {
        return {};
      }
      if (snapshot.value is Map<String, dynamic>) {
        return snapshot.value as Map<String, dynamic>;
      }
      if (snapshot.value is Map) {
        return (snapshot.value as Map).map((k, v) => MapEntry(k.toString(), v));
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  FirebaseDatabase _buildDatabase() {
    try {
      final app = Firebase.app();
      final databaseUrl = app.options.databaseURL;
      if (databaseUrl != null && databaseUrl.isNotEmpty) {
        return FirebaseDatabase.instanceFor(app: app, databaseURL: databaseUrl);
      }
    } catch (_) {
      // ignore and fall back to default instance
    }
    return FirebaseDatabase.instance;
  }
}

