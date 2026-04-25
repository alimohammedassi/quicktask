// lib/features/auth/data/datasources/firebase_auth_datasource.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';

/// Maps Firebase error codes to user-friendly messages
String mapFirebaseError(String code) {
  switch (code) {
    case 'user-not-found':
      return 'البريد الإلكتروني غير مسجل';
    case 'wrong-password':
      return 'كلمة المرور غير صحيحة';
    case 'email-already-in-use':
      return 'البريد مستخدم بالفعل';
    case 'weak-password':
      return 'كلمة المرور ضعيفة جداً';
    case 'network-request-failed':
      return 'تحقق من اتصالك بالإنترنت';
    case 'too-many-requests':
      return 'محاولات كثيرة، حاول لاحقاً';
    case 'invalid-email':
      return 'البريد الإلكتروني غير صالح';
    case 'user-disabled':
      return 'الحساب معطل';
    case 'invalid-credential':
      return 'بيانات الاعتماد غير صالحة';
    case 'popup-closed-by-user':
      return 'تم إغلاق نافذة تسجيل الدخول';
    default:
      return 'حدث خطأ، حاول مرة أخرى';
  }
}

/// Firebase Auth DataSource — all direct Firebase calls live here
class FirebaseAuthDatasource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDatasource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: '559550639683-ugprk5r4hrrsiju9ropsc72q6155na4a.apps.googleusercontent.com',
              scopes: [
                'email',
                'https://www.googleapis.com/auth/calendar',
              ],
            );

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(mapFirebaseError(e.code));
    }
  }

  Future<UserCredential> signUpWithEmail(String email, String password, {String? displayName}) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(mapFirebaseError(e.code));
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('تم إلغاء تسجيل الدخول');
      }

      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(mapFirebaseError(e.code));
    } catch (e) {
      if (e.toString().contains('popup-closed') ||
          e.toString().contains('تم إلغاء')) {
        throw Exception('تم إغلاق نافذة تسجيل الدخول');
      }
      rethrow;
    }
  }

  Future<void> signOut(String? currentUid) async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(mapFirebaseError(e.code));
    }
  }

  Future<AccessCredentials?> getAccessCredentials() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return null;
      final auth = await account.authentication;
      if (auth.accessToken == null) return null;
      return AccessCredentials(
        AccessToken(
          'Bearer',
          auth.accessToken!,
          DateTime.now().add(const Duration(minutes: 50)).toUtc(),
        ),
        auth.idToken,
        ['https://www.googleapis.com/auth/calendar'],
      );
    } catch (_) {
      return null;
    }
  }
}