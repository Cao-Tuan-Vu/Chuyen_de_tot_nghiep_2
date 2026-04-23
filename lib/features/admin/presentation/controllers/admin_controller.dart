import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:btl/features/learning/domain/entities/course.dart';
import 'package:btl/features/auth/domain/entities/app_user.dart';
import 'package:btl/features/learning/domain/entities/lesson.dart';
import 'package:btl/features/quiz/domain/entities/quiz.dart';
import 'package:btl/features/learning/data/repositories/learning_repository.dart';

class AdminController extends ChangeNotifier {
  final LearningRepository _learningRepository = LearningRepository();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  bool isLoading = false;
  String? error;

  // --- Data States ---
  List<AppUser> allUsers = [];
  List<Course> allCourses = [];
  List<Quiz> allQuizzes = [];
  List<Lesson> currentCourseLessons = [];

  // --- Analytics Stats ---
  int totalStudents = 0;
  int coursesPublished = 0;
  int totalAttempts = 0;
  double platformAverageScore = 0.0;
  List<double> userGrowthData = [0, 0, 0, 0, 0, 0, 0];

  Future<void> initialize() async {
    if (isLoading) return;
    
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      await Future.wait([
        fetchAllCourses(),
        fetchAllUsers(),
        fetchAllQuizzes(),
        fetchAllAttempts(),
      ]);
      _calculateStats();
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        error = "⚠️ Lỗi: Chưa cấu hình Rules Firebase.";
      } else {
        error = "Lỗi tải dữ liệu: ${e.toString()}";
      }
      debugPrint("❌ AdminController Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Course Operations ---
  Future<void> fetchAllCourses() async {
    allCourses = await _learningRepository.getCourses();
    coursesPublished = allCourses.length;
    notifyListeners();
  }

  Future<void> addCourse(Course course) async {
    try {
      final ref = _database.ref('courses/${course.id}');
      final courseData = {
        'id': course.id,
        'title': course.title,
        'desc': course.description,
        'level': course.level,
        'finalQuiz': course.comprehensiveQuizId,
      };
      await ref.set(courseData);
      await fetchAllCourses();
    } catch (e) {
      error = "Lỗi thêm khóa học: $e";
      notifyListeners();
    }
  }

  Future<void> updateCourse(Course course) async {
    try {
      await _database.ref('courses/${course.id}').update({
        'title': course.title,
        'desc': course.description,
        'level': course.level,
        'finalQuiz': course.comprehensiveQuizId,
      });
      await fetchAllCourses();
    } catch (e) {
      error = "Lỗi cập nhật khóa học: $e";
      notifyListeners();
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await _database.ref('courses/$courseId').remove();
      allCourses.removeWhere((c) => c.id == courseId);
      coursesPublished = allCourses.length;
      notifyListeners();
    } catch (e) {
      error = "Không thể xóa khóa học: $e";
      notifyListeners();
    }
  }

  // --- Quiz Management ---
  Future<void> fetchAllQuizzes() async {
    try {
      final snapshot = await _database.ref('quizzes').get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map;
        allQuizzes = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          if (map['id'] == null) map['id'] = e.key;
          return Quiz.fromJson(map);
        }).toList();
      } else {
        allQuizzes = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching quizzes: $e");
    }
  }

  Future<void> saveQuiz(Quiz quiz) async {
    try {
      final quizData = quiz.toJson();
      await _database.ref('quizzes/${quiz.id}').set(quizData);
      await fetchAllQuizzes();
    } catch (e) {
      error = "Lỗi lưu quiz: $e";
      notifyListeners();
    }
  }

  // Support for legacy quiz editor
  Future<void> addQuiz(String title, List<dynamic> questions) async {
    try {
      final newRef = _database.ref('quizzes').push();
      final id = newRef.key!;
      final List<QuizQuestion> parsedQuestions = questions.map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map))).toList();
      final quiz = Quiz(id: id, title: title, questions: parsedQuestions, courseId: '', lessonId: '');
      await saveQuiz(quiz);
    } catch (e) {
      error = "Lỗi thêm quiz: $e";
      notifyListeners();
    }
  }

  Future<void> updateQuiz(String quizId, String title, List<dynamic> questions) async {
    try {
      final List<QuizQuestion> parsedQuestions = questions.map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map))).toList();
      final quiz = Quiz(id: quizId, title: title, questions: parsedQuestions, courseId: '', lessonId: '');
      await saveQuiz(quiz);
    } catch (e) {
      error = "Lỗi cập nhật quiz: $e";
      notifyListeners();
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    try {
      await _database.ref('quizzes/$quizId').remove();
      allQuizzes.removeWhere((q) => q.id == quizId);
      notifyListeners();
    } catch (e) {
      error = "Lỗi xóa quiz: $e";
      notifyListeners();
    }
  }

  // --- Lesson Management ---
  Future<void> fetchLessonsForCourse(String courseId) async {
    isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _database.ref('lessons').get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map;
        currentCourseLessons = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          if (map['id'] == null) map['id'] = e.key;
          return Lesson.fromJson(map);
        }).where((lesson) => lesson.courseId == courseId).toList();

        currentCourseLessons.sort((a, b) => a.order.compareTo(b.order));
      } else {
        currentCourseLessons = [];
      }
    } catch (e) {
      debugPrint("Error fetching lessons: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveLesson(Lesson lesson) async {
    try {
      final ref = lesson.id.isEmpty 
          ? _database.ref('lessons').push() 
          : _database.ref('lessons/${lesson.id}');
      
      final data = lesson.toJson();
      if (lesson.id.isEmpty) data['id'] = ref.key;

      await ref.set(data);
      await fetchLessonsForCourse(lesson.courseId);
    } catch (e) {
      error = "Lỗi lưu bài học: $e";
      notifyListeners();
    }
  }

  Future<void> deleteLesson(String lessonId, String courseId) async {
    try {
      await _database.ref('lessons/$lessonId').remove();
      await fetchLessonsForCourse(courseId);
    } catch (e) {
      error = "Lỗi xóa bài học: $e";
      notifyListeners();
    }
  }

  // --- User Management ---
  Future<void> fetchAllUsers() async {
    final snapshot = await _database.ref('users').get();
    if (snapshot.exists && snapshot.value != null) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      allUsers = data.entries.map((entry) {
        final userData = Map<String, dynamic>.from(entry.value as Map);
        return AppUser.fromJson(userData);
      }).toList();
    }
  }

  Future<void> changeUserRole(String userId, String newRole) async {
    try {
      await _database.ref('users/$userId/role').set(newRole);
      final index = allUsers.indexWhere((u) => u.id == userId);
      if (index != -1) {
        allUsers[index] = allUsers[index].copyWith(role: newRole);
      }
      notifyListeners();
    } catch (e) {
      error = "Lỗi phân quyền: $e";
      notifyListeners();
    }
  }

  Future<void> fetchAllAttempts() async {
    try {
      final snapshot = await _database.ref('attempts').get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map;
        totalAttempts = data.length;
        
        double totalRatio = 0;
        int count = 0;
        
        for (var entry in data.values) {
          final map = Map<String, dynamic>.from(entry as Map);
          final score = (map['score'] as num?)?.toDouble() ?? 0.0;
          final total = (map['total'] as num?)?.toDouble() ?? 1.0;
          totalRatio += (score / (total > 0 ? total : 1.0));
          count++;
        }
        
        if (count > 0) {
          platformAverageScore = (totalRatio / count) * 10; // Chuyển về thang điểm 10
        } else {
          platformAverageScore = 0.0;
        }
      } else {
        totalAttempts = 0;
        platformAverageScore = 0.0;
      }
    } catch (e) {
      debugPrint("Error fetching attempts: $e");
    }
  }

  void _calculateStats() {
    totalStudents = allUsers.length;
    coursesPublished = allCourses.length;
    
    // Giữ nguyên logic growth data hoặc tùy chỉnh theo ngày thực tế nếu cần
    if (allUsers.isNotEmpty) {
      userGrowthData = [10, 25, 45, 70, 95, 110, totalStudents.toDouble()];
    }
  }
}
