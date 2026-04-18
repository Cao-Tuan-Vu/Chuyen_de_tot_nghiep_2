import 'package:firebase_database/firebase_database.dart';

import 'package:btl/features/auth/domain/entities/app_user.dart';
import 'package:btl/features/learning/domain/entities/course.dart';
import 'package:btl/features/learning/domain/entities/lesson.dart';

class AdminRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference get _usersRef => _database.ref('users');
  DatabaseReference get _profilesRef => _database.ref('profiles');
  DatabaseReference get _sessionsRef => _database.ref('sessions');
  DatabaseReference get _coursesRef => _database.ref('courses');
  DatabaseReference get _lessonsRef => _database.ref('lessons');

  Future<List<AppUser>> getUsers({required String token}) async {
    await _ensureAdmin(token);

    final snapshot = await _usersRef.get();
    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final data = _asMap(snapshot.value);
    return data.entries.map((entry) {
      final item = _asMap(entry.value);
      item.putIfAbsent('id', () => entry.key);
      return AppUser.fromJson(item);
    }).toList();
  }

  Future<List<Course>> getCourses() async {
    final snapshot = await _coursesRef.get();
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
    final snapshot = await _lessonsRef.orderByChild('courseId').equalTo(courseId).get();
    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final data = _asMap(snapshot.value);
    final lessons = data.entries.map((entry) {
      final item = _asMap(entry.value);
      item.putIfAbsent('id', () => entry.key);
      return Lesson.fromJson(item);
    }).toList();

    lessons.sort((a, b) => a.order.compareTo(b.order));
    return lessons;
  }

  Future<AppUser> updateUserRole({
    required String token,
    required String userId,
    required String role,
  }) async {
    await _ensureAdmin(token);

    final snapshot = await _usersRef.child(userId).get();
    if (!snapshot.exists || snapshot.value == null) {
      throw Exception('Khong tim thay user');
    }

    final userData = _asMap(snapshot.value);
    userData['id'] = userId;
    userData['role'] = role;
    userData['updatedAt'] = DateTime.now().toUtc().toIso8601String();

    final updatedUser = AppUser.fromJson(userData);
    await _usersRef.child(userId).update(updatedUser.toJson());
    await _profilesRef.child(userId).update({
      'role': role,
      'updatedAt': updatedUser.updatedAt,
    });
    await _sessionsRef.child(userId).update({
      'role': role,
      'lastSeenAt': updatedUser.updatedAt,
    });

    return updatedUser;
  }

  Future<void> _ensureAdmin(String token) async {
    final snapshot = await _usersRef.child(token).get();
    if (!snapshot.exists || snapshot.value == null) {
      throw Exception('Khong co quyen truy cap');
    }

    final user = AppUser.fromJson(_asMap(snapshot.value)..putIfAbsent('id', () => token));
    if (user.role != 'admin') {
      throw Exception('Chi admin moi duoc phep thao tac');
    }
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
}
