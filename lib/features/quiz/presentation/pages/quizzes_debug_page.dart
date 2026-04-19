import 'package:flutter/material.dart';

import 'package:btl/features/quiz/data/repositories/quiz_repository.dart';

class QuizzesDebugPage extends StatefulWidget {
  const QuizzesDebugPage({super.key, this.repository});

  final QuizRepository? repository;

  @override
  State<QuizzesDebugPage> createState() => _QuizzesDebugPageState();
}

class _QuizzesDebugPageState extends State<QuizzesDebugPage> {
  late final QuizRepository _repo = widget.repository ?? QuizRepository();
  late Future<Map<String, dynamic>> _allFuture;

  @override
  void initState() {
    super.initState();
    // Use static helper so fakes don't have to implement instance method.
    _allFuture = QuizRepository.listAllQuizzesStatic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug: Quizzes')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _allFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final map = snapshot.data ?? {};
          if (map.isEmpty) {
            return const Center(child: Text('No quizzes found'));
          }

          final entries = map.entries.toList();
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = entries[index];
              return ListTile(
                title: Text(e.key),
                subtitle: Text(e.value.toString()),
              );
            },
          );
        },
      ),
    );
  }
}

