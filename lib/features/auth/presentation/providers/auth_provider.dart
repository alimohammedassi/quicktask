import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/database/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

// ─── Auth States ─────────────────────────────────────────────────────────────

sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────

class AuthNotifier extends ChangeNotifier {
  final AuthRepository _repo;
  StreamSubscription<User?>? _authSub;
  
  AuthState _state = AuthInitial();
  AuthState get state => _state;

  User? _user;
  User? get user => _user;

  AuthNotifier(this._repo) {
    _authSub = _repo.authStateChanges.listen((user) {
      _user = user;
      if (user != null) {
        _state = AuthAuthenticated(user);
      } else {
        _state = AuthUnauthenticated();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> signInWithEmail(String email, String password) async {
    _state = AuthLoading();
    notifyListeners();
    try {
      final credential = await _repo.signInWithEmail(email, password);
      await _persistUser(credential.user!);
    } on Exception catch (e) {
      _state = AuthError(_extractMessage(e));
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password, {String? displayName}) async {
    _state = AuthLoading();
    notifyListeners();
    try {
      final credential = await _repo.signUpWithEmail(email, password, displayName: displayName);
      await _persistUser(credential.user!);
    } on Exception catch (e) {
      _state = AuthError(_extractMessage(e));
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _state = AuthLoading();
    notifyListeners();
    try {
      final credential = await _repo.signInWithGoogle();
      await _persistUser(credential.user!);
    } on Exception catch (e) {
      _state = AuthError(_extractMessage(e));
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _state = AuthLoading();
    notifyListeners();
    try {
      final currentUid = _repo.currentUser?.uid;
      await _repo.signOut(currentUid);
      if (currentUid != null) {
        await DatabaseService.deleteUser(currentUid);
        await DatabaseService.deleteTasksForUser(currentUid);
      }
      // state updates automatically via authStateChanges listener
    } on Exception catch (e) {
      _state = AuthError(_extractMessage(e));
      notifyListeners();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _state = AuthLoading();
    notifyListeners();
    try {
      await _repo.sendPasswordResetEmail(email);
      _state = AuthUnauthenticated();
      notifyListeners();
    } on Exception catch (e) {
      _state = AuthError(_extractMessage(e));
      notifyListeners();
    }
  }

  void resetState() {
    _state = AuthUnauthenticated();
    notifyListeners();
  }

  Future<void> _persistUser(User user) async {
    final provider = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : 'email';
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      provider: provider,
      createdAt: DateTime.now(),
    );
    await DatabaseService.saveUser(userModel);
    // state updates automatically via authStateChanges listener
  }

  String _extractMessage(Exception e) {
    return e.toString().replaceFirst('Exception: ', '');
  }
}