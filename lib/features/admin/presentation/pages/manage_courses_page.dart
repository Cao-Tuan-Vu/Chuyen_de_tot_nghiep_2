import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:btl/features/admin/presentation/controllers/admin_controller.dart';
import 'package:btl/features/learning/presentation/theme/course_visuals.dart';
import 'package:btl/features/learning/domain/entities/course.dart';

class ManageCoursesPage extends StatelessWidget {
  const ManageCoursesPage({super.key});

  static const String routeName = '/manage-courses';

  @override
  Widget build(BuildContext context) {
    final adminCtrl = context.watch<AdminController>();
    final courses = adminCtrl.allCourses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Khóa Học'),
        actions: [
          IconButton(onPressed: () => adminCtrl.initialize(), icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () => _showCourseForm(context, adminCtrl), 
            icon: const Icon(Icons.add_circle_outline_rounded, size: 28)
          ),
        ],
      ),
      body: adminCtrl.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : courses.isEmpty 
          ? const Center(child: Text('Chưa có khóa học nào trên hệ thống'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final style = courseVisualStyleFor(course.id);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: style.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(style.icon, color: style.primary),
                    ),
                    title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${course.level} • ID: ${course.id}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showCourseForm(context, adminCtrl, course: course);
                        } else if (val == 'delete') {
                          _confirmDelete(context, adminCtrl, course.id, course.title);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                        const PopupMenuItem(value: 'delete', child: Text('Xóa khóa học', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                    onTap: () => Navigator.pushNamed(
                      context, 
                      '/manage-lessons',
                      arguments: {'courseId': course.id, 'courseTitle': course.title}
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showCourseForm(BuildContext context, AdminController ctrl, {Course? course}) {
    final idCtrl = TextEditingController(text: course?.id);
    final titleCtrl = TextEditingController(text: course?.title);
    final descCtrl = TextEditingController(text: course?.description);
    final levelCtrl = TextEditingController(text: course?.level ?? 'Cơ bản');
    final quizCtrl = TextEditingController(text: course?.comprehensiveQuizId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course == null ? 'Thêm Khóa Học Mới' : 'Chỉnh Sửa Khóa Học',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (course == null) ...[
                TextField(
                  controller: idCtrl, 
                  decoration: const InputDecoration(
                    labelText: 'ID Khóa học (vd: python_basics)',
                    helperText: 'Nên dùng snake_case, không dấu, không khoảng trắng',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tên khóa học')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả ngắn')),
              const SizedBox(height: 12),
               DropdownButtonFormField<String>(
                 initialValue: levelCtrl.text,
                items: const [
                  DropdownMenuItem(value: 'Cơ bản', child: Text('Cơ bản')),
                  DropdownMenuItem(value: 'Trung cấp', child: Text('Trung cấp')),
                  DropdownMenuItem(value: 'Nâng cao', child: Text('Nâng cao')),
                ],
                onChanged: (val) => levelCtrl.text = val ?? 'Cơ bản',
                decoration: const InputDecoration(labelText: 'Cấp độ'),
              ),
              const SizedBox(height: 12),
              TextField(controller: quizCtrl, decoration: const InputDecoration(labelText: 'ID Bài thi cuối khóa')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final courseId = course?.id ?? idCtrl.text.trim();
                    if (courseId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập ID khóa học'))
                      );
                      return;
                    }

                    final newCourse = Course(
                      id: courseId,
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      level: levelCtrl.text,
                      comprehensiveQuizId: quizCtrl.text,
                    );
                    if (course == null) {
                      ctrl.addCourse(newCourse);
                    } else {
                      ctrl.updateCourse(newCourse);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(course == null ? 'TẠO MỚI' : 'LƯU THAY ĐỔI'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminController ctrl, String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa khóa học "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ctrl.deleteCourse(id);
              Navigator.pop(ctx);
            },
            child: const Text('XÓA'),
          ),
        ],
      ),
    );
  }
}

