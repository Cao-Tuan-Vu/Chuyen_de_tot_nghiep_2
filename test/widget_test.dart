import 'package:btl/app/presentation/btl_app.dart';
import 'package:btl/features/auth/domain/entities/app_user.dart';
import 'package:btl/features/auth/domain/entities/auth_session.dart';
import 'package:btl/features/auth/domain/repositories/auth_repository.dart';
import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/admin/data/repositories/admin_repository.dart';
import 'package:btl/features/admin/presentation/pages/admin_page.dart';
import 'package:btl/features/home/presentation/pages/home_page.dart';
import 'package:btl/features/learning/data/repositories/learning_repository.dart';
import 'package:btl/features/learning/presentation/pages/course_list_page.dart';
import 'package:btl/features/learning/presentation/pages/lesson_list_page.dart';
import 'package:btl/features/learning/domain/entities/course.dart';
import 'package:btl/features/learning/domain/entities/lesson.dart';
import 'package:btl/features/quiz/data/repositories/quiz_repository.dart';
import 'package:btl/features/quiz/domain/entities/quiz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<void> clearSession() async {}

  @override
  Future<AuthSession?> getSession() async => null;

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProfile({required String displayName}) async {}
}

class _FakeLearningRepository implements LearningRepository {
  @override
  Future<List<Course>> getCourses() async {
    return const [
      Course(
        id: 'course_dart_basic',
        title: 'Dart co ban',
        description: 'Khai niem nen tang',
        level: 'beginner',
      ),
    ];
  }

  @override
  Future<List<Lesson>> getLessonsByCourse(String courseId) async {
    return const [
      Lesson(
        id: 'lesson_variables',
        courseId: 'course_dart_basic',
        title: 'Bien va kieu du lieu',
        order: 1,
        content: 'Noi dung bien va kieu du lieu',
      ),
      Lesson(
        id: 'lesson_conditions',
        courseId: 'course_dart_basic',
        title: 'Cau truc dieu kien',
        order: 2,
        content: 'Noi dung dieu kien',
        quizId: 'quiz_conditions_01',
      ),
    ];
  }

  @override
  Future<Lesson> getLessonDetail(String courseId, String lessonId) async {
    return const Lesson(
      id: 'lesson_conditions',
      courseId: 'course_dart_basic',
      title: 'Cau truc dieu kien',
      order: 2,
      content: 'Ly thuyet chi tiet ve if/else va switch',
      quizId: 'quiz_conditions_01',
    );
  }
}

class _FakeQuizRepository implements QuizRepository {
  @override
  Future<Quiz> getQuiz(String quizId) async {
    return const Quiz(
      id: 'quiz_conditions_01',
      courseId: 'course_dart_basic',
      lessonId: 'lesson_conditions',
      title: 'Quiz: Dieu kien trong Dart',
      questions: [
        QuizQuestion(
          id: 'q1',
          prompt: 'Dart dung tu khoa nao?',
          options: ['if', 'when', 'choose', 'caseif'],
        ),
      ],
    );
  }

  @override
  Future<QuizAttemptResult> submitQuiz({
    required String quizId,
    required String token,
    required Map<String, int> answers,
  }) async {
    return const QuizAttemptResult(
      attemptId: 'att_1',
      quizId: 'quiz_conditions_01',
      userId: 'u_student_001',
      score: 1,
      total: 1,
      submittedAt: '2026-01-01T00:00:00Z',
      review: [
        QuizReviewItem(
          questionId: 'q1',
          selectedIndex: 0,
          correctIndex: 0,
          isCorrect: true,
          explanation: 'if la dap an dung',
        ),
      ],
    );
  }
}

class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository() {
    _users = [
      const AppUser(
        id: 'u_admin_001',
        email: 'admin@example.com',
        displayName: 'Admin',
        role: 'admin',
      ),
      const AppUser(
        id: 'u_student_001',
        email: 'student@example.com',
        displayName: 'Student Demo',
        role: 'student',
      ),
    ];
  }

  late List<AppUser> _users;

  @override
  Future<List<AppUser>> getUsers({required String token}) async {
    return _users;
  }

  @override
  Future<List<Course>> getCourses() async {
    return const [
      Course(
        id: 'course_dart_basic',
        title: 'Dart co ban',
        description: 'Khai niem nen tang',
        level: 'beginner',
      ),
    ];
  }

  @override
  Future<List<Lesson>> getLessonsByCourse(String courseId) async {
    return const [
      Lesson(
        id: 'lesson_conditions',
        courseId: 'course_dart_basic',
        title: 'Cau truc dieu kien',
        order: 1,
        content: 'Noi dung demo',
        quizId: 'quiz_conditions_01',
      ),
    ];
  }

  @override
  Future<AppUser> updateUserRole({
    required String token,
    required String userId,
    required String role,
  }) async {
    final index = _users.indexWhere((user) => user.id == userId);
    final updated = AppUser(
      id: _users[index].id,
      email: _users[index].email,
      displayName: _users[index].displayName,
      role: role,
    );
    _users[index] = updated;
    return updated;
  }
}

void main() {
  testWidgets('Shows login screen on startup', (WidgetTester tester) async {
    await tester.pumpWidget(BtlApp(authController: AuthController(repository: _FakeAuthRepository())));

    expect(find.text('Đăng Nhập'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('Home -> Course -> Lesson -> Quiz navigation works', (WidgetTester tester) async {
    final controller = AuthController(repository: _FakeAuthRepository())
      ..currentUser = const AppUser(
        id: 'u_student_001',
        email: 'student@example.com',
        displayName: 'Student Demo',
        role: 'student',
      )
      ..token = 'test-token';

    final learningRepository = _FakeLearningRepository();
    final quizRepository = _FakeQuizRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          controller: controller,
          learningRepository: learningRepository,
          quizRepository: quizRepository,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_shopping_cart_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Dart co ban'), findsOneWidget);

    final courseInList = find.descendant(
      of: find.byType(CourseListPage),
      matching: find.text('Dart co ban'),
    );
    await tester.ensureVisible(courseInList);
    await tester.tap(courseInList);
    await tester.pumpAndSettle();
    expect(find.text('Cau truc dieu kien'), findsOneWidget);

    final lessonInList = find.descendant(
      of: find.byType(LessonListPage),
      matching: find.text('Cau truc dieu kien'),
    );
    await tester.ensureVisible(lessonInList);
    await tester.tap(lessonInList);
    await tester.pumpAndSettle();
    expect(find.text('Lam quiz bai nay'), findsOneWidget);

    await tester.ensureVisible(find.text('Lam quiz bai nay'));
    await tester.tap(find.text('Lam quiz bai nay'));
    await tester.pumpAndSettle();
    expect(find.text('Quiz: Dieu kien trong Dart'), findsOneWidget);
    expect(find.text('1. Dart dung tu khoa nao?'), findsOneWidget);
  });

  testWidgets('Admin dashboard shows users and can navigate from Home', (WidgetTester tester) async {
    final controller = AuthController(repository: _FakeAuthRepository())
      ..currentUser = const AppUser(
        id: 'u_admin_001',
        email: 'admin@example.com',
        displayName: 'Admin',
        role: 'admin',
      )
      ..token = 'test-token';

    final adminRepository = _FakeAdminRepository();
    final learningRepository = _FakeLearningRepository();
    final quizRepository = _FakeQuizRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          controller: controller,
          learningRepository: learningRepository,
          quizRepository: quizRepository,
        ),
        routes: {
          AdminPage.routeName: (_) => AdminPage(
                controller: controller,
                repository: adminRepository,
              ),
        },
      ),
    );

    final adminButton = find.byIcon(Icons.admin_panel_settings);
    expect(adminButton, findsOneWidget);
    await tester.tap(adminButton);
    await tester.pumpAndSettle();

    expect(find.text('Admin Console'), findsOneWidget);
    await tester.tap(find.text('Người dùng'));
    await tester.pumpAndSettle();
    expect(find.text('admin@example.com'), findsOneWidget);
    expect(find.text('student@example.com'), findsOneWidget);
  });
}
