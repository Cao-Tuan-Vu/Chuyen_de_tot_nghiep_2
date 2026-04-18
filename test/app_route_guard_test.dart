import 'package:btl/app/router/app_route_guard.dart';
import 'package:btl/features/admin/presentation/pages/admin_page.dart';
import 'package:btl/features/auth/presentation/pages/login_page.dart';
import 'package:btl/features/home/presentation/pages/home_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRouteGuard', () {
    test('guest is redirected to login', () {
      final route = AppRouteGuard.resolveNamedRoute(
        requestedRoute: AdminPage.routeName,
        isLoggedIn: false,
        role: null,
      );

      expect(route, LoginPage.routeName);
    });

    test('student cannot access admin route', () {
      final route = AppRouteGuard.resolveNamedRoute(
        requestedRoute: AdminPage.routeName,
        isLoggedIn: true,
        role: 'student',
      );

      expect(route, HomePage.routeName);
    });

    test('admin is kept in admin flow', () {
      final route = AppRouteGuard.resolveNamedRoute(
        requestedRoute: HomePage.routeName,
        isLoggedIn: true,
        role: 'admin',
      );

      expect(route, AdminPage.routeName);
    });

    test('initial route is admin for logged-in admin', () {
      final route = AppRouteGuard.resolveInitialRoute(
        isLoggedIn: true,
        role: 'admin',
      );

      expect(route, AdminPage.routeName);
    });
  });
}

