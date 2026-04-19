import 'package:flutter/material.dart';

import 'package:btl/features/admin/presentation/pages/admin_page.dart';
import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/auth/presentation/pages/login_page.dart';
import 'package:btl/features/home/presentation/pages/contact_page.dart';
import 'package:btl/features/home/presentation/pages/home_page.dart';
import 'package:btl/features/courses/presentation/pages/my_courses_page.dart';
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
              seedColor: const Color(0xFFFFD700), // Pokémon Yellow (Pikachu)
              primary: const Color(0xFFFFD700),
              secondary: const Color(0xFF2196F3), // Squirtle Blue
              surface: const Color(0xFFFFF8DC), // Cream/Light Yellow
              surfaceTint: const Color(0xFFFFF8DC),
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFFFFBE6), // Very Light Yellow
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              backgroundColor: Color(0xFFFFD700),
              elevation: 2,
              titleTextStyle: TextStyle(
                color: Color(0xFF333333),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Color(0xFF333333)),
            ),
            cardTheme: CardThemeData(
              elevation: 4,
              shadowColor: const Color(0xFF2196F3).withOpacity(0.2),
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(color: Color(0xFFFF6F00), fontWeight: FontWeight.bold),
              titleLarge: TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(color: Color(0xFF4CAF50)),
              bodyMedium: TextStyle(color: Color(0xFF666666)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFFFF8DC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2196F3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2196F3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF333333),
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
