import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/admin/presentation/controllers/admin_controller.dart';
import 'package:btl/features/auth/presentation/pages/login_page.dart';
import 'package:btl/features/home/presentation/pages/contact_page.dart';
import 'package:btl/features/home/presentation/pages/home_page.dart';
import 'package:btl/features/home/presentation/pages/introduction_page.dart';
import 'package:btl/features/home/presentation/pages/policy_page.dart';
import 'package:btl/features/learning/presentation/pages/course_list_page.dart';
import 'package:btl/features/profile/presentation/pages/profile_page.dart';
import 'package:btl/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:btl/features/admin/presentation/pages/manage_courses_page.dart';
import 'package:btl/features/admin/presentation/pages/manage_users_page.dart';
import 'package:btl/features/admin/presentation/pages/manage_quizzes_page.dart';
import 'package:btl/features/admin/presentation/pages/quiz_editor_page.dart';
import 'package:btl/features/admin/presentation/pages/manage_lessons_page.dart';
import 'package:btl/app/router/app_route_guard.dart';

class BtlApp extends StatefulWidget {
  const BtlApp({super.key, this.authController});

  final AuthController? authController;

  @override
  State<BtlApp> createState() => _BtlAppState();
}

class _BtlAppState extends State<BtlApp> {
  late final AuthController _authController = widget.authController ?? AuthController();

  @override
  void initState() {
    super.initState();
    _authController.loadSession();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final requestedRoute = settings.name ?? LoginPage.routeName;
    final targetRoute = AppRouteGuard.resolveNamedRoute(
      requestedRoute: requestedRoute,
      isLoggedIn: _authController.isLoggedIn,
    );

    return MaterialPageRoute<void>(
      settings: RouteSettings(name: targetRoute, arguments: settings.arguments),
      builder: (_) => _buildPageByRoute(targetRoute, settings),
    );
  }

  Widget _buildPageByRoute(String routeName, [RouteSettings? settings]) {
    switch (routeName) {
      case LoginPage.routeName:
        return LoginPage(controller: _authController);
      case HomePage.routeName:
        return HomePage(controller: _authController);
      case ProfilePage.routeName:
        return ProfilePage(controller: _authController);
      case CourseListPage.routeName:
        return CourseListPage(controller: _authController);
      case ContactPage.routeName:
        return const ContactPage();
      case PolicyPage.routeName:
        return const PolicyPage();
      case IntroductionPage.routeName:
        return const IntroductionPage();
      case AdminDashboardPage.routeName:
        return const AdminDashboardPage();
      case ManageCoursesPage.routeName:
        return const ManageCoursesPage();
      case ManageUsersPage.routeName:
        return const ManageUsersPage();
      case ManageQuizzesPage.routeName:
        return const ManageQuizzesPage();
      case '/manage-lessons':
        final args = settings?.arguments as Map<String, dynamic>?;
        return ManageLessonsPage(
          courseId: args?['courseId'] ?? '',
          courseTitle: args?['courseTitle'] ?? '',
        );
      case 'quiz-editor':
        final args = settings?.arguments as Map<String, dynamic>?;
        return QuizEditorPage(
          quizId: args?['quizId'],
          existingData: args?['existingData'],
        );
      default:
        return LoginPage(controller: _authController);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authController),
        ChangeNotifierProvider(create: (_) => AdminController()),
      ],
      child: AnimatedBuilder(
        animation: _authController,
        builder: (context, _) {
          final initialRoute = AppRouteGuard.resolveInitialRoute(
            isLoggedIn: _authController.isLoggedIn,
          );

          return MaterialApp(
            title: 'EduCode Admin',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4F46E5),
                primary: const Color(0xFF4F46E5),
                secondary: const Color(0xFF10B981),
                surface: Colors.white,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF8F9FA),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                backgroundColor: Color(0xFF4F46E5),
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: IconThemeData(color: Colors.white),
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.05),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            onGenerateRoute: _onGenerateRoute,
            home: _buildPageByRoute(initialRoute),
          );
        },
      ),
    );
  }
}
