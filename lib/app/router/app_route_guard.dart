import 'package:btl/features/auth/presentation/pages/login_page.dart';
import 'package:btl/features/home/presentation/pages/home_page.dart';

class AppRouteGuard {
  static String resolveInitialRoute({
    required bool isLoggedIn,
  }) {
    if (!isLoggedIn) {
      return LoginPage.routeName;
    }

    return HomePage.routeName;
  }

  static String resolveNamedRoute({
    required String requestedRoute,
    required bool isLoggedIn,
  }) {
    if (!isLoggedIn) {
      return LoginPage.routeName;
    }

    if (requestedRoute == LoginPage.routeName) {
      return HomePage.routeName;
    }

    return requestedRoute;
  }
}

