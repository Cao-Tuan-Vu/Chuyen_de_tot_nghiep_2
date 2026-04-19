import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:btl/features/auth/domain/entities/auth_session.dart';
import 'package:btl/features/auth/domain/entities/app_user.dart';
import 'package:btl/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference get _usersRef => _database.ref('users');
  DatabaseReference get _profilesRef => _database.ref('profiles');
  DatabaseReference get _sessionsRef => _database.ref('sessions');

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Dang nhap that bai');
    }

    final user = await _loadOrCreateUser(firebaseUser, fallbackRole: 'student');
    final String token = firebaseUser.uid;
    await _saveUserToFirebase(user, isNewSession: false);
    await _saveSession(token, user);
    return AuthSession(token: token, user: user);
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Dang ky that bai');
    }

    await firebaseUser.updateDisplayName(displayName);
    await firebaseUser.reload();

    final now = DateTime.now().toUtc().toIso8601String();
    final user = AppUser(
      id: firebaseUser.uid,
      email: email,
      displayName: displayName,
      role: 'student',
      createdAt: now,
      updatedAt: now,
    );

    final String token = firebaseUser.uid;
    await _saveUserToFirebase(user, isNewSession: true);
    await _saveSession(token, user);
    return AuthSession(token: token, user: user);
  }

  @override
  Future<void> updateProfile({
    required String displayName,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('Chua dang nhap');
    }

    await firebaseUser.updateDisplayName(displayName);
    await firebaseUser.reload();

    final existing = await _loadOrCreateUser(firebaseUser, fallbackRole: 'student');
    final now = DateTime.now().toUtc().toIso8601String();
    final updated = existing.copyWith(
      displayName: displayName,
      updatedAt: now,
    );

    await _saveUserToFirebase(updated, isNewSession: false);
    await _saveSession(firebaseUser.uid, updated);
  }

  Future<void> _saveSession(String token, AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<AppUser> _loadOrCreateUser(User firebaseUser, {required String fallbackRole}) async {
    final snapshot = await _usersRef.child(firebaseUser.uid).get();
    if (snapshot.exists && snapshot.value != null) {
      final data = _asMap(snapshot.value);
      return AppUser.fromJson(data);
    }

    final now = DateTime.now().toUtc().toIso8601String();
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User',
      role: fallbackRole,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _saveUserToFirebase(
    AppUser user, {
    required bool isNewSession,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final payload = user.copyWith(updatedAt: now).toJson();

    // 🔧 Dùng .update() để không xóa enrolledCourses
    await _usersRef.child(user.id).update(payload);
    await _profilesRef.child(user.id).set({
      'userId': user.id,
      'displayName': user.displayName,
      'avatarUrl': user.avatarUrl,
      'bio': user.bio,
      'updatedAt': now,
    });
    await _sessionsRef.child(user.id).update({
      'userId': user.id,
      'email': user.email,
      'role': user.role,
      'isActive': true,
      'provider': 'firebase_auth',
      'lastSeenAt': now,
      if (isNewSession) 'lastLoginAt': now,
    });
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry(key.toString(), item));
    }

    return <String, dynamic>{};
  }

  @override
  Future<AuthSession?> getSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final String token = firebaseUser.uid;
      final user = await _loadOrCreateUser(firebaseUser, fallbackRole: 'student');
      await _saveUserToFirebase(user, isNewSession: false);
      await _saveSession(token, user);
      return AuthSession(token: token, user: user);
    }

    // Firebase Realtime Database rules rely on auth token, so local-only
    // cached session is not enough to keep app requests working.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    return null;
  }

  @override
  Future<void> clearSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _sessionsRef.child(firebaseUser.uid).update({
        'isActive': false,
        'lastSeenAt': DateTime.now().toUtc().toIso8601String(),
      });
    }
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
