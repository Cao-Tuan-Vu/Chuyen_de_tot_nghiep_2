import 'package:flutter/material.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/quiz/data/repositories/quiz_repository.dart';
import 'package:btl/features/learning/data/repositories/learning_repository.dart';
import 'package:btl/features/learning/domain/entities/course.dart';
import 'package:btl/features/learning/domain/entities/lesson.dart';
import 'lesson_detail_page.dart';

class LessonListPage extends StatefulWidget {
  LessonListPage({
    super.key,
    required this.controller,
    required this.course,
    LearningRepository? learningRepository,
    QuizRepository? quizRepository,
  })  : learningRepository = learningRepository ?? LearningRepository(),
        quizRepository = quizRepository ?? QuizRepository();

  final AuthController controller;
  final Course course;
  final LearningRepository learningRepository;
  final QuizRepository quizRepository;

  @override
  State<LessonListPage> createState() => _LessonListPageState();
}

class _LessonListPageState extends State<LessonListPage> {
  late Future<List<Lesson>> _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = widget.learningRepository.getLessonsByCourse(widget.course.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title)),
      body: FutureBuilder<List<Lesson>>(
        future: _lessonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final lessons = snapshot.data ?? [];
          if (lessons.isEmpty) {
            return const Center(child: Text('Chua co bai hoc'));
          }

          return ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${lesson.order}')),
                title: Text(lesson.title),
                subtitle: Text(lesson.quizId == null ? 'Ly thuyet' : 'Ly thuyet + Quiz'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LessonDetailPage(
                        controller: widget.controller,
                        courseId: widget.course.id,
                        lesson: lesson,
                        learningRepository: widget.learningRepository,
                        quizRepository: widget.quizRepository,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

