import 'package:flutter/foundation.dart';

import 'package:btl/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:btl/features/auth/domain/entities/auth_session.dart';
import 'package:btl/features/auth/domain/entities/app_user.dart';
import 'package:btl/features/auth/domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository}) : _repository = repository ?? AuthRepositoryImpl();

  final AuthRepository _repository;

  AppUser? currentUser;
  String? token;
  bool isLoading = false;
  String? error;

  bool get isLoggedIn => currentUser != null && token != null;

  Future<void> loadSession() async {
    final AuthSession? session = await _repository.getSession();
    if (session != null) {
      token = session.token;
      currentUser = session.user;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final session = await _repository.login(email: email, password: password);
      token = session.token;
      currentUser = session.user;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final session = await _repository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      token = session.token;
      currentUser = session.user;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> updateDisplayName(String displayName) async {
    if (token == null) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repository.updateProfile(displayName: displayName);
      final AuthSession? session = await _repository.getSession();
      if (session != null) {
        token = session.token;
        currentUser = session.user;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.clearSession();
    token = null;
    currentUser = null;
    error = null;
    notifyListeners();
  }
}
