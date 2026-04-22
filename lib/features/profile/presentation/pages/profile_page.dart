import 'package:flutter/material.dart';

import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/profile/presentation/pages/student_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.controller});

  static const String routeName = '/profile';

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return StudentProfilePage(controller: controller);
  }
}
