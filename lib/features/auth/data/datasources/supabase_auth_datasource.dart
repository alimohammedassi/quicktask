import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';

String mapSupabaseError(String code) {
  if (code.contains('user_not_found') || code.contains('Invalid login credentials')) return 'البريد الإلكتروني غير مسجل أو كلمة المرور غير صحيحة';
  if (code.contains('user_already_exists')) return 'البريد مستخدم بالفعل';
  if (code.contains('weak_password')) return 'كلمة المرور ضعيفة جداً';
  if (code.contains('network')) return 'تحقق من اتصالك بالإنترنت';
  if (code.contains('invalid_email')) return 'البريد الإلكتروني غير صالح';
  return 'حدث خطأ، حاول مرة أخرى';
}

class SupabaseAuthDatasource {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  SupabaseAuthDatasource({
    SupabaseClient? supabase,
    GoogleSignIn? googleSignIn,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: '163260633151-ssgd243cjrc9plnbfk8rd37u7q95lns9.apps.googleusercontent.com',
              scopes: [
                'email',
                'https://www.googleapis.com/auth/calendar',
              ],
            );

  Stream<User?> get authStateChanges => _supabase.auth.onAuthStateChange.map((event) => event.session?.user);
  
  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(mapSupabaseError(e.message));
    }
  }

  Future<AuthResponse> signUpWithEmail(String email, String password, {String? displayName}) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
    } on AuthException catch (e) {
      throw Exception(mapSupabaseError(e.message));
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('تم إلغاء تسجيل الدخول');
      }

      final googleAuth = await account.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('حدث خطأ في جلب بيانات جوجل');
      }

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      if (e.toString().contains('popup-closed') || e.toString().contains('تم إلغاء')) {
        throw Exception('تم إغلاق نافذة تسجيل الدخول');
      }
      rethrow;
    }
  }

  Future<void> signOut(String? currentUid) async {
    await Future.wait([
      _supabase.auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(mapSupabaseError(e.message));
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
