import 'package:flutter/material.dart';

class CourseVisualStyle {
  const CourseVisualStyle({
    required this.courseId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  final String courseId;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  Color get primary => gradient.first;
}

CourseVisualStyle courseVisualStyleFor(String courseId) {
  final normalized = _normalizeCourseId(courseId);

  switch (normalized) {
    case 'dart_basics':
      return const CourseVisualStyle(
        courseId: 'dart_basics',
        title: 'Dart Basics',
        subtitle: 'Nền tảng ngôn ngữ Dart',
        icon: Icons.code_rounded,
        gradient: [Color(0xFF1D4ED8), Color(0xFF6366F1), Color(0xFF8B5CF6)],
      );
    case 'oop':
      return const CourseVisualStyle(
        courseId: 'oop',
        title: 'Object Oriented',
        subtitle: 'Tư duy hướng đối tượng',
        icon: Icons.schema_rounded,
        gradient: [Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFF2DD4BF)],
      );
    case 'flutter_ui':
      return const CourseVisualStyle(
        courseId: 'flutter_ui',
        title: 'Flutter UI',
        subtitle: 'Thiết kế giao diện đẹp',
        icon: Icons.phone_iphone_rounded,
        gradient: [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFF97316)],
      );
    case 'laravel':
      return const CourseVisualStyle(
        courseId: 'laravel',
        title: 'Laravel',
        subtitle: 'Backend framework PHP',
        icon: Icons.webhook_rounded,
        gradient: [Color(0xFFB91C1C), Color(0xFFEF4444), Color(0xFFF97316)],
      );
    case 'firebase_fundamentals':
      return const CourseVisualStyle(
        courseId: 'firebase_fundamentals',
        title: 'Firebase',
        subtitle: 'Auth, DB, Storage cơ bản',
        icon: Icons.local_fire_department_rounded,
        gradient: [Color(0xFFEA580C), Color(0xFFF59E0B), Color(0xFF84CC16)],
      );
    case 'php_basics':
      return const CourseVisualStyle(
        courseId: 'php_basics',
        title: 'PHP Basics',
        subtitle: 'Nền tảng backend PHP',
        icon: Icons.terminal_rounded,
        gradient: [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF8B5CF6)],
      );
    case 'python_basics':
      return const CourseVisualStyle(
        courseId: 'python_basics',
        title: 'Python Basics',
        subtitle: 'Lập trình Python từ đầu',
        icon: Icons.smart_toy_rounded,
        gradient: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFFFACC15)],
      );
    case 'java_core':
      return const CourseVisualStyle(
        courseId: 'java_core',
        title: 'Java Core',
        subtitle: 'Nắm chắc Java và OOP',
        icon: Icons.coffee_rounded,
        gradient: [Color(0xFFB45309), Color(0xFFF97316), Color(0xFFFB7185)],
      );
    case 'sql_fundamentals':
      return const CourseVisualStyle(
        courseId: 'sql_fundamentals',
        title: 'SQL Fundamentals',
        subtitle: 'Truy vấn dữ liệu hiệu quả',
        icon: Icons.storage_rounded,
        gradient: [Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFF06B6D4)],
      );
    default:
      return CourseVisualStyle(
        courseId: normalized.isEmpty ? courseId : normalized,
        title: courseId,
        subtitle: 'Học lập trình từng bước',
        icon: Icons.auto_stories_rounded,
        gradient: const [Color(0xFF334155), Color(0xFF475569), Color(0xFF64748B)],
      );
  }
}

String _normalizeCourseId(String courseId) {
  final normalized = courseId.trim().toLowerCase();
  if (normalized.startsWith('course_')) {
    return normalized.substring('course_'.length);
  }
  return normalized;
}

