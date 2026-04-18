import 'package:flutter/material.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/quiz/data/repositories/quiz_repository.dart';
import 'package:btl/features/learning/data/repositories/learning_repository.dart';
import 'package:btl/features/learning/domain/entities/course.dart';
import 'lesson_list_page.dart';

class CourseListPage extends StatefulWidget {
  CourseListPage({
    super.key,
    required this.controller,
    LearningRepository? learningRepository,
    QuizRepository? quizRepository,
  }) : learningRepository = learningRepository ?? LearningRepository(),
       quizRepository = quizRepository ?? QuizRepository();

  static const String routeName = '/courses';

  final AuthController controller;
  final LearningRepository learningRepository;
  final QuizRepository quizRepository;

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  late Future<List<Course>> _coursesFuture;

  void _reloadCourses() {
    setState(() {
      _coursesFuture = widget.learningRepository.getCourses();
    });
  }

  @override
  void initState() {
    super.initState();
    _coursesFuture = widget.learningRepository.getCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khoa hoc')),
      body: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reloadCourses,
                      child: const Text('Thu lai'),
                    ),
                  ],
                ),
              ),
            );
          }

          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return const Center(child: Text('Chua co khoa hoc'));
          }

          return ListView.separated(
            itemCount: courses.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final course = courses[index];
              return ListTile(
                title: Text(course.title),
                subtitle: Text('${course.level} - ${course.description}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LessonListPage(
                        controller: widget.controller,
                        course: course,
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
