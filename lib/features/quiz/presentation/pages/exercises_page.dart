import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
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
    if (!mounted) {
      return;
    }
    setState(() => _loading = true);
    final coursesSnap = await db.child('courses').get();
    final lessonsSnap = await db.child('lessons').get();
    final quizzesSnap = await db.child('quizzes').get();

    final courseLevels = <String, String>{};
    if (coursesSnap.exists && coursesSnap.value is Map) {
      final allCourses = Map<String, dynamic>.from(coursesSnap.value as Map);
      for (final entry in allCourses.entries) {
        final value = entry.value;
        if (value is Map) {
          final level = value['level']?.toString() ?? '';
          courseLevels[entry.key] = _normalizeLevel(level);
        }
      }
    }

    final pools = {
      'easy': <QuizQuestion>[],
      'medium': <QuizQuestion>[],
      'hard': <QuizQuestion>[],
    };

    final allLessons = lessonsSnap.exists && lessonsSnap.value is Map
        ? Map<String, dynamic>.from(lessonsSnap.value as Map)
        : <String, dynamic>{};
    final allQuizzes = quizzesSnap.exists && quizzesSnap.value is Map
        ? Map<String, dynamic>.from(quizzesSnap.value as Map)
        : <String, dynamic>{};

    for (final lesson in allLessons.values) {
      if (lesson is! Map) {
        continue;
      }
      final courseId = (lesson['courseId'] ?? lesson['course'] ?? '').toString();
      if (courseId.isEmpty) {
        continue;
      }
      final quizId = (lesson['quizId'] ?? lesson['quiz'] ?? '').toString();
      if (quizId.isEmpty || !allQuizzes.containsKey(quizId)) {
        continue;
      }

      final rawQuiz = allQuizzes[quizId];
      if (rawQuiz is! Map) {
        continue;
      }

      final quizJson = Map<String, dynamic>.from(rawQuiz);
      quizJson.putIfAbsent('id', () => quizId);
      quizJson.putIfAbsent('title', () => lesson['title']?.toString() ?? 'Quiz');
      final parsedQuiz = Quiz.fromJson(quizJson);

      final level = _normalizeLevel(
        lesson['level']?.toString() ??
            quizJson['level']?.toString() ??
            courseLevels[courseId] ??
            'medium',
      );
      for (int i = 0; i < parsedQuiz.questions.length; i++) {
        final question = parsedQuiz.questions[i];
        pools[level]!.add(QuizQuestion(
          id: '${quizId}_${question.id}_$i',
          prompt: question.prompt,
          options: List<String>.from(question.options),
          correctIndex: question.correctIndex,
          explanation: question.explanation,
        ));
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _poolsByLevel = {
        'easy': _LevelPool(level: 'easy', questions: pools['easy'] ?? []),
        'medium': _LevelPool(level: 'medium', questions: pools['medium'] ?? []),
        'hard': _LevelPool(level: 'hard', questions: pools['hard'] ?? []),
      };
      _loading = false;
    });
  }

  String _normalizeLevel(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'easy' || normalized == 'beginner') {
      return 'easy';
    }
    if (normalized == 'hard' || normalized == 'advanced') {
      return 'hard';
    }
    return 'medium';
  }

  String _levelTitle(String level) {
    switch (level) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return level;
    }
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

  Set<String> _extractQuestionIds(Object? value) {
    final result = <String>{};
    if (value is List) {
      for (final item in value) {
        if (item is Map) {
          final map = _asMap(item);
          final id = map['questionId']?.toString();
          if (id != null && id.trim().isNotEmpty) {
            result.add(id.trim());
          }
          continue;
        }

        final id = item?.toString();
        if (id != null && id.trim().isNotEmpty && id != 'null') {
          result.add(id.trim());
        }
      }
    }
    return result;
  }

  Future<Set<String>> _loadSeenQuestionIdsForLevel(String level) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return <String>{};
    }

    final seen = <String>{};
    final needFallbackAttemptIds = <String>[];
    final attemptsIndexSnap = await db.child('users/${user.uid}/quizAttempts').get();
    final attemptsIndex = _asMap(attemptsIndexSnap.value);

    for (final entry in attemptsIndex.entries) {
      final basic = _asMap(entry.value);
      final attemptType = basic['attemptType']?.toString();
      final attemptLevel = _normalizeLevel((basic['level'] ?? '').toString());
      if (attemptType != 'level_test' || attemptLevel != level) {
        continue;
      }

      final fromIndex = _extractQuestionIds(basic['questionIds']);
      if (fromIndex.isNotEmpty) {
        seen.addAll(fromIndex);
      } else {
        needFallbackAttemptIds.add(entry.key);
      }
    }

    if (needFallbackAttemptIds.isEmpty) {
      return seen;
    }

    final attemptsDetailSnap = await db.child('attempts').get();
    final attemptsDetail = _asMap(attemptsDetailSnap.value);
    for (final attemptId in needFallbackAttemptIds) {
      final detail = _asMap(attemptsDetail[attemptId]);
      final detailAttemptType = detail['attemptType']?.toString();
      final detailLevel = _normalizeLevel((detail['level'] ?? '').toString());
      if (detailAttemptType != 'level_test' || detailLevel != level) {
        continue;
      }

      final fromDetails = _extractQuestionIds(detail['questionIds']);
      if (fromDetails.isNotEmpty) {
        seen.addAll(fromDetails);
        continue;
      }

      seen.addAll(_extractQuestionIds(detail['review']));
    }

    return seen;
  }

  List<QuizQuestion> _selectQuestionsForAttempt(List<QuizQuestion> pool, Set<String> seenQuestionIds) {
    final unseen = <QuizQuestion>[];
    final seen = <QuizQuestion>[];

    for (final question in pool) {
      if (seenQuestionIds.contains(question.id)) {
        seen.add(question);
      } else {
        unseen.add(question);
      }
    }

    unseen.shuffle(Random());
    seen.shuffle(Random());
    final merged = <QuizQuestion>[...unseen, ...seen];
    return merged.take(min(_questionCountPerTest, merged.length)).toList();
  }

  Future<void> _startLevelTest(String level) async {
    final pool = _poolsByLevel[level];
    if (pool == null || pool.questions.isEmpty) {
      return;
    }

    final seenQuestionIds = await _loadSeenQuestionIdsForLevel(level);
    if (!mounted) {
      return;
    }
    final selected = _selectQuestionsForAttempt(pool.questions, seenQuestionIds);
    final testId = '${level}_assessment_${DateTime.now().millisecondsSinceEpoch}';
    final testTitle = 'Kiểm tra ${_levelTitle(level)}';
    final generatedQuiz = Quiz(
      id: testId,
      courseId: 'all_courses',
      lessonId: 'level_test_$level',
      title: '$testTitle (${selected.length} câu)',
      questions: selected,
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

    if (!mounted) {
      return;
    }
    _loadAllQuizzes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm tra random toàn hệ thống')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildLevelCard('easy', Colors.green.shade600),
                const SizedBox(height: 10),
                _buildLevelCard('medium', Colors.orange.shade700),
                const SizedBox(height: 10),
                _buildLevelCard('hard', Colors.red.shade700),
              ],
            ),
    );
  }

  Widget _buildLevelCard(String level, Color color) {
    final pool = _poolsByLevel[level] ?? _LevelPool(level: level, questions: const []);
    final count = pool.questions.length;
    final canStart = count > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fact_check_rounded, color: color),
                const SizedBox(width: 8),
                Text(
                  'Kiểm tra ${_levelTitle(level)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Ngân hàng câu hỏi: $count câu'),
            Text('Trộn câu hỏi từ toàn bộ khóa học, random tối đa $_questionCountPerTest câu/lần.'),
            const Text('Ưu tiên câu bạn chưa từng gặp ở mức này.'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canStart ? () => _startLevelTest(level) : null,
                child: Text(canStart ? 'Bắt đầu kiểm tra ${_levelTitle(level)}' : 'Chưa đủ dữ liệu'),
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

