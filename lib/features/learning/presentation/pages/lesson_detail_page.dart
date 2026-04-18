import 'package:flutter/material.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/quiz/data/repositories/quiz_repository.dart';
import 'package:btl/features/quiz/presentation/pages/quiz_page.dart';
import 'package:btl/features/learning/data/repositories/learning_repository.dart';
import 'package:btl/features/learning/domain/entities/lesson.dart';

class LessonDetailPage extends StatefulWidget {
  LessonDetailPage({
    super.key,
    required this.controller,
    required this.courseId,
    required this.lesson,
    LearningRepository? learningRepository,
    QuizRepository? quizRepository,
  })  : learningRepository = learningRepository ?? LearningRepository(),
        quizRepository = quizRepository ?? QuizRepository();

  final AuthController controller;
  final String courseId;
  final Lesson lesson;
  final LearningRepository learningRepository;
  final QuizRepository quizRepository;

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  late Future<Lesson> _lessonFuture;

  @override
  void initState() {
    super.initState();
    _lessonFuture = widget.learningRepository.getLessonDetail(widget.courseId, widget.lesson.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: FutureBuilder<Lesson>(
        future: _lessonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final lesson = snapshot.data;
          if (lesson == null) {
            return const Center(child: Text('Khong tim thay bai hoc'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Expanded(child: SingleChildScrollView(child: Text(lesson.content))),
                if (lesson.quizId != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => QuizPage(
                              controller: widget.controller,
                              quizId: lesson.quizId!,
                              repository: widget.quizRepository,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.quiz),
                      label: const Text('Lam quiz bai nay'),
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

