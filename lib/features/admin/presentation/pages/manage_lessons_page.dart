import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:btl/features/admin/presentation/controllers/admin_controller.dart';
import 'package:btl/features/learning/domain/entities/lesson.dart';

class ManageLessonsPage extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const ManageLessonsPage({super.key, required this.courseId, required this.courseTitle});

  @override
  State<ManageLessonsPage> createState() => _ManageLessonsPageState();
}

class _ManageLessonsPageState extends State<ManageLessonsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AdminController>().fetchLessonsForCourse(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminCtrl = context.watch<AdminController>();
    final lessons = adminCtrl.currentCourseLessons;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bài học: ${widget.courseTitle}'),
        actions: [
          IconButton(
            onPressed: () => _showLessonForm(context, adminCtrl), 
            icon: const Icon(Icons.add_box_outlined)
          ),
        ],
      ),
      body: adminCtrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : lessons.isEmpty
              ? const Center(child: Text('Khóa học này chưa có nội dung bài học.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${lesson.order}')),
                        title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Quiz ID: ${lesson.quizId ?? "Không có"}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showLessonForm(context, adminCtrl, lesson: lesson),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => adminCtrl.deleteLesson(lesson.id, widget.courseId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showLessonForm(BuildContext context, AdminController ctrl, {Lesson? lesson}) {
    final idCtrl = TextEditingController(text: lesson?.id);
    final titleCtrl = TextEditingController(text: lesson?.title);
    final orderCtrl = TextEditingController(text: lesson?.order.toString() ?? '1');
    final contentCtrl = TextEditingController(text: lesson?.content);
    final quizCtrl = TextEditingController(text: lesson?.quizId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lesson == null ? 'Thêm bài học mới' : 'Sửa bài học', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (lesson == null) ...[
                TextField(
                  controller: idCtrl, 
                  decoration: const InputDecoration(
                    labelText: 'ID Bài học (vd: py_l01)',
                    helperText: 'Dùng snake_case, duy nhất trong khóa học',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tiêu đề bài học')),
              TextField(controller: orderCtrl, decoration: const InputDecoration(labelText: 'Thứ tự hiển thị (số)'), keyboardType: TextInputType.number),
              TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Link Video / Lý thuyết'), maxLines: 2),
              TextField(controller: quizCtrl, decoration: const InputDecoration(labelText: 'Mã Quiz đi kèm (Nếu có)')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final lessonId = lesson?.id ?? idCtrl.text.trim();
                  if (lessonId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập ID bài học')));
                    return;
                  }

                  final newLesson = Lesson(
                    id: lessonId,
                    courseId: widget.courseId,
                    title: titleCtrl.text,
                    order: int.tryParse(orderCtrl.text) ?? 1,
                    content: contentCtrl.text,
                    theory: contentCtrl.text,
                    quizId: quizCtrl.text.isEmpty ? null : quizCtrl.text,
                  );
                  ctrl.saveLesson(newLesson);
                  Navigator.pop(ctx);
                },
                child: const Text('LƯU BÀI HỌC'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
