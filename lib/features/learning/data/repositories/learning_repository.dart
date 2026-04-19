import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:btl/features/learning/domain/entities/course.dart';
import 'package:btl/features/learning/domain/entities/lesson.dart';

class LearningRepository {
  late final FirebaseDatabase _database = _buildDatabase();
  static const Duration _requestTimeout = Duration(seconds: 15);

  DatabaseReference get _coursesRef => _database.ref('courses');
  DatabaseReference get _lessonsRef => _database.ref('lessons');

  Future<List<Course>> getCourses() async {
    final snapshot = await _getWithTimeout(
      _coursesRef,
      errorContext: 'Tai danh sach khoa hoc that bai',
    );
    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final data = _asMap(snapshot.value);
    return data.entries.map((entry) {
      final item = _asMap(entry.value);
      item.putIfAbsent('id', () => entry.key);
      return Course.fromJson(item);
    }).toList();
  }

  Future<List<Lesson>> getLessonsByCourse(String courseId) async {
    final snapshot = await _getWithTimeout(
      _lessonsRef,
      errorContext: 'Tai danh sach bai hoc that bai',
    );
    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final data = _asMap(snapshot.value);
    final lessons = data.entries
        .map((entry) {
          final item = _asMap(entry.value);
          item.putIfAbsent('id', () => entry.key);
          return Lesson.fromJson(item);
        })
        .where((lesson) => lesson.courseId == courseId)
        .toList();

    lessons.sort((a, b) => a.order.compareTo(b.order));
    return lessons;
  }

  Future<Lesson> getLessonDetail(String courseId, String lessonId) async {
    final snapshot = await _getWithTimeout(
      _lessonsRef.child(lessonId),
      errorContext: 'Tai chi tiet bai hoc that bai',
    );
    if (!snapshot.exists || snapshot.value == null) {
      throw Exception('Tai chi tiet bai hoc that bai (404)');
    }

    final data = _asMap(snapshot.value);
    data.putIfAbsent('id', () => lessonId);
    final lesson = Lesson.fromJson(data);
    if (lesson.courseId != courseId) {
      throw Exception('Bai hoc khong thuoc khoa hoc nay');
    }
    return lesson;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  Future<DataSnapshot> _getWithTimeout(
    Query query, {
    required String errorContext,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception('$errorContext: phien dang nhap da het han, vui long dang nhap lai');
    }

    try {
      return await query.get().timeout(_requestTimeout);
    } on TimeoutException {
      throw Exception(
        '$errorContext: ket noi Firebase qua cham, vui long thu lai',
      );
    } on FirebaseException catch (error) {
      throw Exception('$errorContext: ${error.message ?? error.code}');
    }
  }

  FirebaseDatabase _buildDatabase() {
    final app = Firebase.app();
    final databaseUrl = app.options.databaseURL;
    if (databaseUrl != null && databaseUrl.isNotEmpty) {
      return FirebaseDatabase.instanceFor(app: app, databaseURL: databaseUrl);
    }

    return FirebaseDatabase.instance;
  }
}
