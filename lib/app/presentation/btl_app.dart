import 'package:flutter/material.dart';

import 'package:btl/features/admin/presentation/pages/admin_page.dart';
import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/auth/presentation/pages/login_page.dart';
import 'package:btl/features/home/presentation/pages/contact_page.dart';
import 'package:btl/features/home/presentation/pages/home_page.dart';
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
        return CourseListPage(controller: _authController);
      case AdminPage.routeName:
        return AdminPage(controller: _authController);
      case ContactPage.routeName:
        return const ContactPage();
      case PolicyPage.routeName:
        return const PolicyPage();
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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF6F7FB),
            appBarTheme: const AppBarTheme(centerTitle: false),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD8DCE8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.indigo),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          onGenerateRoute: _onGenerateRoute,
          home: _buildPageByRoute(initialRoute),
        );
      },
    );
  }
}
