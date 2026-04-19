import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:btl/features/quiz/presentation/pages/quiz_page.dart';
import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';

class ExercisesPage extends StatefulWidget {
  final AuthController controller;
  const ExercisesPage({Key? key, required this.controller}) : super(key: key);

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final db = FirebaseDatabase.instance.ref();
  bool _loading = true;
  List<_QuizInfo> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadAllQuizzes();
  }

  Future<void> _loadAllQuizzes() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _quizzes = [];
        _loading = false;
      });
      return;
    }
    final uid = user.uid;
    // Get enrolled courses
    final userSnap = await db.child('users/$uid').get();
    final enrolled = <String>[];
    if (userSnap.exists) {
      final data = userSnap.value;
      if (data is Map && data.containsKey('enrolledCourses')) {
        final raw = data['enrolledCourses'];
        if (raw is Map) {
          enrolled.addAll(raw.keys.map((k) => k.toString()));
        } else if (raw is List) {
          for (var v in raw) {
            if (v != null) enrolled.add(v.toString());
          }
        }
      }
    }
    if (enrolled.isEmpty) {
      setState(() {
        _quizzes = [];
        _loading = false;
      });
      return;
    }
    // For each course, get lessons
    final lessonsSnap = await db.child('lessons').get();
    final quizzesSnap = await db.child('quizzes').get();
    final quizzes = <_QuizInfo>[];
    if (lessonsSnap.exists && lessonsSnap.value is Map) {
      final allLessons = Map<String, dynamic>.from(lessonsSnap.value as Map);
      for (final lesson in allLessons.values) {
        if (lesson is Map) {
          final courseId = lesson['courseId'] ?? lesson['course'];
          if (courseId != null && enrolled.contains(courseId.toString())) {
            final quizId = lesson['quizId'] ?? lesson['quiz'];
            if (quizId != null && quizId.toString().isNotEmpty) {
              // Get quiz title if available
              String quizTitle = 'Quiz';
              if (quizzesSnap.exists && quizzesSnap.value is Map) {
                final allQuizzes = Map<String, dynamic>.from(quizzesSnap.value as Map);
                if (allQuizzes.containsKey(quizId)) {
                  final quizData = allQuizzes[quizId];
                  if (quizData is Map && quizData['title'] != null) {
                    quizTitle = quizData['title'];
                  }
                }
              }
              quizzes.add(_QuizInfo(
                quizId: quizId.toString(),
                lessonTitle: lesson['title'] ?? '',
                courseId: courseId.toString(),
                quizTitle: quizTitle,
              ));
            }
          }
        }
      }
    }
    setState(() {
      _quizzes = quizzes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bài tập tổng hợp')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_quizzes.isEmpty
              ? const Center(child: Text('Không có bài tập nào.'))
              : ListView.builder(
                  itemCount: _quizzes.length,
                  itemBuilder: (ctx, i) {
                    final q = _quizzes[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(q.quizTitle),
                        subtitle: Text('Bài học: ${q.lessonTitle}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => QuizPage(
                              controller: widget.controller,
                              quizId: q.quizId,
                            ),
                          ));
                        },
                      ),
                    );
                  },
                )),
    );
  }
}

class _QuizInfo {
  final String quizId;
  final String lessonTitle;
  final String courseId;
  final String quizTitle;
  _QuizInfo({required this.quizId, required this.lessonTitle, required this.courseId, required this.quizTitle});
}

