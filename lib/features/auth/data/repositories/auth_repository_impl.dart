// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource _datasource;

  AuthRepositoryImpl({FirebaseAuthDatasource? datasource})
      : _datasource = datasource ?? FirebaseAuthDatasource();

  @override
  Future<AccessCredentials?> getAccessCredentials() {
    return _datasource.getAccessCredentials();
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _datasource.signInWithEmail(email, password);
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password, {String? displayName}) {
    return _datasource.signUpWithEmail(email, password, displayName: displayName);
  }

  @override
  Future<UserCredential> signInWithGoogle() {
    return _datasource.signInWithGoogle();
  }

  @override
  Future<void> signOut(String? currentUid) => _datasource.signOut(currentUid);

  @override
  User? get currentUser => _datasource.currentUser;

  @override
  Stream<User?> get authStateChanges => _datasource.authStateChanges;

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _datasource.sendPasswordResetEmail(email);
  }
}