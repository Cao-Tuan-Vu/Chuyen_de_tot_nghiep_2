import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:btl/features/admin/presentation/controllers/admin_controller.dart';
import 'package:btl/features/quiz/domain/entities/quiz.dart';

class QuizEditorPage extends StatefulWidget {
  final String? quizId;
  final Map? existingData;

  const QuizEditorPage({super.key, this.quizId, this.existingData});

  @override
  State<QuizEditorPage> createState() => _QuizEditorPageState();
}

class _QuizEditorPageState extends State<QuizEditorPage> {
  late TextEditingController _idController;
  late TextEditingController _titleController;
  late TextEditingController _courseIdController;
  late TextEditingController _lessonIdController;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.quizId ?? '');
    _titleController = TextEditingController(text: widget.existingData?['title'] ?? '');
    _courseIdController = TextEditingController(text: widget.existingData?['courseId'] ?? '');
    _lessonIdController = TextEditingController(text: widget.existingData?['lessonId'] ?? '');
    
    if (widget.existingData?['questions'] != null) {
      final qData = widget.existingData!['questions'];
      if (qData is List) {
        _questions = List<Map<String, dynamic>>.from(
          qData.map((e) {
            final q = e is QuizQuestion ? e.toJson() : Map<String, dynamic>.from(e as Map);
            // Ensure fields match what QuizQuestion.fromJson expects
            return {
              'id': q['id'] ?? q['questionId'] ?? '',
              'prompt': q['prompt'] ?? q['question'] ?? '',
              'options': q['options'] ?? [],
              'correctIndex': q['correctIndex'] ?? q['correct'] ?? 0,
              'explanation': q['explanation'] ?? '',
            };
          })
        );
      }
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'id': 'q${_questions.length + 1}',
        'prompt': 'Câu hỏi mới',
        'options': ['Đáp án A', 'Đáp án B', 'Đáp án C', 'Đáp án D'],
        'correctIndex': 0,
        'explanation': '',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizId == null ? 'Tạo Bộ Đề' : 'Sửa Bộ Đề'),
        actions: [
          IconButton(
            onPressed: () {
            final ctrl = context.read<AdminController>();
            final quizId = widget.quizId ?? _idController.text.trim();
            
            if (quizId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập ID Quiz'))
              );
              return;
            }

            final List<QuizQuestion> parsedQuestions = _questions.map((q) {
              return QuizQuestion(
                id: q['id']?.toString() ?? '',
                prompt: q['prompt']?.toString() ?? '',
                options: List<String>.from(q['options'] as List),
                correctIndex: q['correctIndex'] as int?,
                explanation: q['explanation']?.toString(),
              );
            }).toList();

            final quiz = Quiz(
              id: quizId,
              title: _titleController.text,
              courseId: _courseIdController.text,
              lessonId: _lessonIdController.text,
              questions: parsedQuestions,
            );

            ctrl.saveQuiz(quiz);
            Navigator.pop(context);
          },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.quizId == null) ...[
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'ID Quiz (vd: quiz_dart_01)', 
                  border: OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên bộ đề trắc nghiệm', 
                border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _courseIdController,
                    decoration: const InputDecoration(labelText: 'Course ID', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lessonIdController,
                    decoration: const InputDecoration(labelText: 'Lesson ID', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Danh sách câu hỏi (${_questions.length})', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                ),
                ElevatedButton.icon(
                  onPressed: _addQuestion, 
                  icon: const Icon(Icons.add), 
                  label: const Text('Thêm câu')
                ),
              ],
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final q = _questions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(child: Text('${index + 1}')),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                initialValue: q['prompt'],
                                onChanged: (val) => q['prompt'] = val,
                                decoration: const InputDecoration(hintText: 'Nhập câu hỏi...'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => _questions.removeAt(index)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (int i = 0; i < 4; i++)
                          Row(
                            children: [
                              Radio<int>(
                                value: i,
                                groupValue: q['correctIndex'],
                                onChanged: (val) => setState(() => q['correctIndex'] = val),
                              ),
                              Expanded(
                                child: TextFormField(
                                  initialValue: (q['options'] as List)[i],
                                  onChanged: (val) => (q['options'] as List)[i] = val,
                                  decoration: InputDecoration(hintText: 'Đáp án ${i + 1}'),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        TextFormField(
                          initialValue: q['explanation'] ?? '',
                          onChanged: (val) => q['explanation'] = val,
                          decoration: const InputDecoration(
                            labelText: 'Giải thích đáp án',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
