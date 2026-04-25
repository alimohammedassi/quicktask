// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/auth_io.dart';

/// Abstract auth repository interface
abstract class AuthRepository {
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signUpWithEmail(String email, String password, {String? displayName});
  Future<UserCredential> signInWithGoogle();
  Future<void> signOut(String? currentUid);
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<void> sendPasswordResetEmail(String email);
  Future<AccessCredentials?> getAccessCredentials();
}
