import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:btl/features/quiz/domain/entities/quiz.dart';

class QuizRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference get _quizzesRef => _database.ref('quizzes');
  DatabaseReference get _attemptsRef => _database.ref('attempts');
  DatabaseReference get _leaderboardRef => _database.ref('leaderboard');

  Future<bool> _isFinalQuiz(String quizId) async {
    try {
      final coursesSnap = await _database.ref('courses').get();
      if (!coursesSnap.exists || coursesSnap.value == null) {
        return false;
      }

      final courses = _asMap(coursesSnap.value);
      for (final course in courses.values) {
        final courseMap = _asMap(course);
        if (courseMap['finalQuiz']?.toString() == quizId) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<Quiz> getQuiz(String quizId) async {
    final snapshot = await _quizzesRef.child(quizId).get();
    if (!snapshot.exists || snapshot.value == null) {
      throw Exception('Tai quiz that bai (404): $quizId');
    }

    final data = _asMap(snapshot.value);
    data.putIfAbsent('id', () => quizId);
    final quiz = Quiz.fromJson(data);

    // Xác định số lượng câu hỏi mục tiêu: 10 cho Final Exam, 5 cho bài học thường
    final isFinal = await _isFinalQuiz(quizId);
    final targetCount = isFinal ? 10 : 5;

    if (quiz.questions.length == targetCount) return quiz;

    if (quiz.questions.length > targetCount) {
      return Quiz(
        id: quiz.id,
        courseId: quiz.courseId,
        lessonId: quiz.lessonId,
        title: quiz.title,
        questions: quiz.questions.take(targetCount).toList(),
      );
    }

    // Nếu thiếu câu hỏi, lấy thêm từ các quiz khác
    try {
      final allQuizzesSnap = await _quizzesRef.get();
      final List<QuizQuestion> additionalQuestions = [];
      if (allQuizzesSnap.exists && allQuizzesSnap.value is Map) {
        final all = _asMap(allQuizzesSnap.value);
        for (final qData in all.values) {
          final otherQuiz = Quiz.fromJson(_asMap(qData));
          for (final q in otherQuiz.questions) {
            if (!quiz.questions.any((existing) => existing.prompt == q.prompt)) {
              additionalQuestions.add(q);
            }
          }
        }
      }
      
      additionalQuestions.shuffle();
      final combined = [...quiz.questions, ...additionalQuestions].take(targetCount).toList();
      
      // Đảm bảo ID duy nhất cho phiên làm bài này để tránh lỗi UI tự chọn đáp án
      final sessionQuestions = <QuizQuestion>[];
      for (int i = 0; i < combined.length; i++) {
        final q = combined[i];
        sessionQuestions.add(QuizQuestion(
          id: 's${i}_${q.id}', 
          prompt: q.prompt,
          options: q.options,
          correctIndex: q.correctIndex,
          explanation: q.explanation,
        ));
      }

      return Quiz(
        id: quiz.id,
        courseId: quiz.courseId,
        lessonId: quiz.lessonId,
        title: quiz.title,
        questions: sessionQuestions,
      );
    } catch (_) {
      return quiz;
    }
  }

  Future<QuizAttemptResult> submitQuiz({
    required String quizId,
    required String token,
    required Map<String, int> answers,
    Quiz? quizData,
    String? attemptType,
    String? level,
    String? quizTitle,
  }) async {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    final userId = (authUid != null && authUid.isNotEmpty) ? authUid : token;

    final quiz = quizData ?? await getQuiz(quizId);
    final isFinalQuiz = attemptType == null ? await _isFinalQuiz(quizId) : attemptType == 'final';
    final normalizedAttemptType = attemptType ?? (isFinalQuiz ? 'final' : 'learning');
    final normalizedLevel = _normalizeLevel(level);
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
    final percentage = total > 0 ? (correctCount / total) * 100 : 0.0;
    final passedThisAttempt = percentage >= 60;
    final askedQuestionIds = quiz.questions
        .map((question) => question.id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    // 1 câu đúng = 1 điểm (không tính percentage)
    final score = correctCount;
    final submittedAt = DateTime.now().toUtc().toIso8601String();
    final attemptId = _attemptsRef.push().key ?? '${quizId}_$submittedAt';

    final result = QuizAttemptResult(
      attemptId: attemptId,
      quizId: quizId,
      userId: userId,
      score: score,
      total: total,
      submittedAt: submittedAt,
      review: review,
    );

    await _attemptsRef.child(attemptId).set(result.toJson());
    final attemptExtraData = <String, dynamic>{
      'attemptType': normalizedAttemptType,
    };
    if (normalizedLevel != null) {
      attemptExtraData['level'] = normalizedLevel;
    }
    if (normalizedAttemptType == 'level_test' && askedQuestionIds.isNotEmpty) {
      attemptExtraData['questionIds'] = askedQuestionIds;
    }
    final normalizedTitle = (quizTitle ?? quiz.title).trim();
    if (normalizedTitle.isNotEmpty) {
      attemptExtraData['quizTitle'] = normalizedTitle;
    }

    await _attemptsRef.child(attemptId).update(attemptExtraData);
    await _database.ref('users').child(userId).child('quizAttempts').child(attemptId).set({
      'attemptId': attemptId,
      'quizId': quizId,
      'submittedAt': submittedAt,
      'score': score,
      'total': total,
      'percentage': percentage,
      'isFinalQuiz': isFinalQuiz,
      ...attemptExtraData,
    });

    // Update leaderboard aggregate for ranking page.
    try {
      final leaderboardNode = _leaderboardRef.child(userId);
      final leaderboardSnap = await leaderboardNode.get();
      final leaderboardData = _asMap(leaderboardSnap.value);
      final currentUser = FirebaseAuth.instance.currentUser;

      final learningQuizzes = _asMap(leaderboardData['learningQuizzes']);
      final finalExam = _asMap(leaderboardData['finalExam']);
      final levelTests = _asMap(leaderboardData['levelTests']);

      if (normalizedAttemptType == 'level_test') {
        final levelKey = normalizedLevel ?? 'medium';
        final current = _asMap(levelTests[levelKey]);
        final previousBest = (current['percentage'] as num?)?.toDouble() ?? -1;
        if (percentage >= previousBest) {
          levelTests[levelKey] = {
            'quizId': quizId,
            'attemptId': attemptId,
            'score': score,
            'total': total,
            'percentage': percentage,
            'passed': passedThisAttempt,
            'submittedAt': submittedAt,
            'attemptType': normalizedAttemptType,
            'level': levelKey,
            if ((quizTitle ?? quiz.title).trim().isNotEmpty)
              'quizTitle': (quizTitle ?? quiz.title).trim(),
          };
        }
        leaderboardData['levelTests'] = levelTests;
      } else if (isFinalQuiz) {
        final previousBest = (finalExam['percentage'] as num?)?.toDouble() ?? -1;
        if (percentage >= previousBest) {
          leaderboardData['finalExam'] = {
            'quizId': quizId,
            'attemptId': attemptId,
            'score': score,
            'total': total,
            'percentage': percentage,
            'passed': passedThisAttempt,
            'submittedAt': submittedAt,
            'attemptType': normalizedAttemptType,
          };
        }
      } else {
        final current = _asMap(learningQuizzes[quizId]);
        final previousBest = (current['percentage'] as num?)?.toDouble() ?? -1;
        if (percentage >= previousBest) {
          learningQuizzes[quizId] = {
            'quizId': quizId,
            'attemptId': attemptId,
            'score': score,
            'total': total,
            'percentage': percentage,
            'passed': passedThisAttempt,
            'submittedAt': submittedAt,
            'attemptType': normalizedAttemptType,
          };
        }
        leaderboardData['learningQuizzes'] = learningQuizzes;
      }

      final normalizedLearning = _asMap(leaderboardData['learningQuizzes']);
      final learningValues = normalizedLearning.values.map(_asMap).toList();
      final learningQuizCount = learningValues.length;
      final learningPassCount = learningValues.where((item) => item['passed'] == true).length;
      final learningAverageScore = learningQuizCount > 0
          ? learningValues
                  .map((item) => (item['percentage'] as num?)?.toDouble() ?? 0.0)
                  .reduce((a, b) => a + b) /
              learningQuizCount
          : 0.0;

      final finalData = _asMap(leaderboardData['finalExam']);
      final normalizedLevelTests = _asMap(leaderboardData['levelTests']);
      final easyScore = (_asMap(normalizedLevelTests['easy'])['percentage'] as num?)?.toDouble() ?? 0.0;
      final mediumScore = (_asMap(normalizedLevelTests['medium'])['percentage'] as num?)?.toDouble() ?? 0.0;
      final hardScore = (_asMap(normalizedLevelTests['hard'])['percentage'] as num?)?.toDouble() ?? 0.0;
      final hasEasyAttempt = normalizedLevelTests['easy'] != null;
      final hasMediumAttempt = normalizedLevelTests['medium'] != null;
      final hasHardAttempt = normalizedLevelTests['hard'] != null;
      final levelScores = [easyScore, mediumScore, hardScore].where((value) => value > 0).toList();
      final levelAverageScore =
          levelScores.isEmpty ? 0.0 : levelScores.reduce((a, b) => a + b) / levelScores.length;
      final finalTestScore = (finalData['percentage'] as num?)?.toDouble() ?? 0.0;
      final finalQuizPassed = finalData['passed'] == true;
      final totalScore = (learningAverageScore * 0.4) + (finalTestScore * 0.6);
      final activityCount = learningQuizCount + (finalData.isNotEmpty ? 1 : 0);

      await leaderboardNode.set({
        'userId': userId,
        'displayName':
            leaderboardData['displayName'] ??
            currentUser?.displayName ??
            currentUser?.email?.split('@').first ??
            'Học viên',
        'learningScore': learningAverageScore,
        'learningQuizCount': learningQuizCount,
        'learningPassCount': learningPassCount,
        'finalTestScore': finalTestScore,
        'easyTestScore': easyScore,
        'mediumTestScore': mediumScore,
        'hardTestScore': hardScore,
        'hasEasyAttempt': hasEasyAttempt,
        'hasMediumAttempt': hasMediumAttempt,
        'hasHardAttempt': hasHardAttempt,
        'levelAverageScore': levelAverageScore,
        'finalQuizPassed': finalQuizPassed,
        'totalScore': totalScore,
        'activityCount': activityCount,
        'passedCount': learningPassCount + (finalQuizPassed ? 1 : 0),
        'updatedAt': submittedAt,
        'learningQuizzes': normalizedLearning,
        if (normalizedLevelTests.isNotEmpty) 'levelTests': normalizedLevelTests,
        if (finalData.isNotEmpty) 'finalExam': finalData,
      });
    } catch (_) {
      // Do not block quiz flow if leaderboard path is not available yet.
    }

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

  String? _normalizeLevel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final normalized = value.trim().toLowerCase();
    if (normalized == 'easy' || normalized == 'beginner') {
      return 'easy';
    }
    if (normalized == 'medium' || normalized == 'intermediate') {
      return 'medium';
    }
    if (normalized == 'hard' || normalized == 'advanced') {
      return 'hard';
    }
    return null;
  }

  /// Static debug helper - list all quizzes under /quizzes as a map.
  /// Returns an empty map if the node does not exist.
  /// This is static so test fakes that implement QuizRepository do not need to
  /// implement this debug helper.
  static Future<Map<String, dynamic>> listAllQuizzesStatic() async {
    try {
      final db = FirebaseDatabase.instance;
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

}

