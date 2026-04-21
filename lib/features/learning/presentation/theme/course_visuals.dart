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

