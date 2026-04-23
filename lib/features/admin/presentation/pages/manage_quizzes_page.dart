import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:btl/features/admin/presentation/controllers/admin_controller.dart';

class ManageQuizzesPage extends StatelessWidget {
  const ManageQuizzesPage({super.key});

  static const String routeName = '/manage-quizzes';

  @override
  Widget build(BuildContext context) {
    final adminCtrl = context.watch<AdminController>();
    final quizzes = adminCtrl.allQuizzes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ngân hàng Câu hỏi'),
        actions: [
          IconButton(onPressed: () => adminCtrl.initialize(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: adminCtrl.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : quizzes.isEmpty 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có bài trắc nghiệm nào', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withValues(alpha: 0.1),
                      child: const Icon(Icons.help_outline, color: Colors.teal),
                    ),
                    title: Text(quiz.title.isEmpty ? 'Chưa đặt tên' : quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${quiz.id}', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500, fontSize: 12)),
                        Text('Số câu hỏi: ${quiz.questions.length}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.blue),
                          onPressed: () => Navigator.pushNamed(
                            context, 
                            'quiz-editor',
                            arguments: {
                              'quizId': quiz.id, 
                              'existingData': {
                                'title': quiz.title,
                                'courseId': quiz.courseId,
                                'lessonId': quiz.lessonId,
                                'questions': quiz.questions,
                              }
                            }
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDelete(context, adminCtrl, quiz.id),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.pushNamed(
                      context, 
                      'quiz-editor',
                      arguments: {
                        'quizId': quiz.id, 
                        'existingData': {
                          'title': quiz.title,
                          'courseId': quiz.courseId,
                          'lessonId': quiz.lessonId,
                          'questions': quiz.questions,
                        }
                      }
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, 'quiz-editor'),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminController ctrl, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa bộ câu hỏi này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ctrl.deleteQuiz(id);
              Navigator.pop(ctx);
            },
            child: const Text('XÓA'),
          ),
        ],
      ),
    );
  }
}


