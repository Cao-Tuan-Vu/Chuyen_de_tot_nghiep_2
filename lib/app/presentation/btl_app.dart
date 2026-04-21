import 'package:flutter/material.dart';

import 'package:btl/features/admin/presentation/pages/admin_page.dart';
import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/auth/presentation/pages/login_page.dart';
import 'package:btl/features/home/presentation/pages/contact_page.dart';
import 'package:btl/features/home/presentation/pages/home_page.dart';
import 'package:btl/features/home/presentation/pages/introduction_page.dart';
import 'package:btl/features/home/presentation/pages/policy_page.dart';
import 'package:btl/features/learning/presentation/pages/course_list_page.dart';
import 'package:btl/features/profile/presentation/pages/profile_page.dart';
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
      role: _authController.currentUser?.role,
    );

    return MaterialPageRoute<void>(
      settings: RouteSettings(name: targetRoute),
      builder: (_) => _buildPageByRoute(targetRoute),
    );
  }

  Widget _buildPageByRoute(String routeName) {
    switch (routeName) {
      case LoginPage.routeName:
        return LoginPage(controller: _authController);
      case HomePage.routeName:
        return HomePage(controller: _authController);
      case ProfilePage.routeName:
        return ProfilePage(controller: _authController);
      case CourseListPage.routeName:
        // Keep existing CourseListPage route for compatibility
        return CourseListPage(controller: _authController);
      case AdminPage.routeName:
        return AdminPage(controller: _authController);
      case ContactPage.routeName:
        return const ContactPage();
      case PolicyPage.routeName:
        return const PolicyPage();
      case IntroductionPage.routeName:
        return const IntroductionPage();
      default:
        return LoginPage(controller: _authController);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _authController,
      builder: (context, _) {
        final initialRoute = AppRouteGuard.resolveInitialRoute(
          isLoggedIn: _authController.isLoggedIn,
          role: _authController.currentUser?.role,
        );

        return MaterialApp(
          title: 'BTL Learning App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              primary: const Color(0xFF4F46E5),
              secondary: const Color(0xFF6366F1),
              surface: Colors.white,
              surfaceTint: const Color(0xFFEFF2FF),
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F7FF),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              backgroundColor: Color(0xFF4F46E5),
              elevation: 2,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardTheme: CardThemeData(
              elevation: 4,
              shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.18),
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold),
              titleLarge: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(color: Color(0xFF0F172A)),
              bodyMedium: TextStyle(color: Color(0xFF475569)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF8FAFF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          onGenerateRoute: _onGenerateRoute,
          home: _buildPageByRoute(initialRoute),
        );
      },
    );
  }
}
