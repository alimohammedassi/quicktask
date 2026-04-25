// lib/features/auth/presentation/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/database/user_model.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    datasource: ref.watch(firebaseAuthDatasourceProvider),
  );
});

final authStateStreamProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

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

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthInitial());

  Future<void> signInWithEmail(String email, String password) async {
    state = AuthLoading();
    try {
      final credential = await _repo.signInWithEmail(email, password);
      await _persistUser(credential.user!);
    } on Exception catch (e) {
      state = AuthError(_extractMessage(e));
    }
  }

  Future<void> signUpWithEmail(String email, String password, {String? displayName}) async {
    state = AuthLoading();
    try {
      final credential = await _repo.signUpWithEmail(email, password, displayName: displayName);
      await _persistUser(credential.user!);
    } on Exception catch (e) {
      state = AuthError(_extractMessage(e));
    }
  }

  Future<void> signInWithGoogle() async {
    state = AuthLoading();
    try {
      final credential = await _repo.signInWithGoogle();
      await _persistUser(credential.user!);
    } on Exception catch (e) {
      state = AuthError(_extractMessage(e));
    }
  }

  Future<void> signOut() async {
    state = AuthLoading();
    try {
      // Get current Firebase user UID before sign-out
      final currentUid = _repo.currentUser?.uid;
      await _repo.signOut(currentUid);
      if (currentUid != null) {
        await DatabaseService.deleteUser(currentUid);
        await DatabaseService.deleteTasksForUser(currentUid);
      }
      state = AuthUnauthenticated();
    } on Exception catch (e) {
      state = AuthError(_extractMessage(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = AuthLoading();
    try {
      await _repo.sendPasswordResetEmail(email);
    } on Exception catch (e) {
      state = AuthError(_extractMessage(e));
    }
  }

  void resetState() {
    state = AuthUnauthenticated();
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
    state = AuthAuthenticated(user); // ← trigger navigation to /home
  }

  String _extractMessage(Exception e) {
    return e.toString().replaceFirst('Exception: ', '');
  }
}