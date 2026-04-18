import 'package:btl/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> updateProfile({
    required String displayName,
  });

  Future<AuthSession?> getSession();

  Future<void> clearSession();
}

