import 'package:btl/features/admin/presentation/pages/admin_page.dart';
import 'package:btl/features/auth/presentation/pages/login_page.dart';
import 'package:btl/features/home/presentation/pages/home_page.dart';

class AppRouteGuard {
  static bool isAdmin(String? role) => role == 'admin';

  static String resolveInitialRoute({
    required bool isLoggedIn,
    required String? role,
  }) {
    if (!isLoggedIn) {
      return LoginPage.routeName;
    }

    return isAdmin(role) ? AdminPage.routeName : HomePage.routeName;
  }

  static String resolveNamedRoute({
    required String requestedRoute,
    required bool isLoggedIn,
    required String? role,
  }) {
    if (!isLoggedIn) {
      return LoginPage.routeName;
    }

    final admin = isAdmin(role);

    if (requestedRoute == LoginPage.routeName) {
      return admin ? AdminPage.routeName : HomePage.routeName;
    }

    if (admin) {
      // Admin stays in management flow only.
      return AdminPage.routeName;
    }

    if (requestedRoute == AdminPage.routeName) {
      return HomePage.routeName;
    }

    return requestedRoute;
  }
}

