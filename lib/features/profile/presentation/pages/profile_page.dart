import 'package:flutter/material.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/profile/presentation/pages/admin_profile_page.dart';
import 'package:btl/features/profile/presentation/pages/student_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.controller});

  static const String routeName = '/profile';

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    final isAdmin = user?.role == 'admin';

    if (isAdmin) {
      return AdminProfilePage(controller: controller);
    } else {
      return StudentProfilePage(controller: controller);
    }
  }
}
