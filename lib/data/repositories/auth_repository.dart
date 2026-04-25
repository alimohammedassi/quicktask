// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Request Calendar scope during sign-in
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await account.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Store the access token for Calendar API calls
      final userCredential = await _auth.signInWithCredential(credential);

      if (googleAuth.accessToken != null) {
        await _storeAccessToken(googleAuth.accessToken!);
      }

      return userCredential;
    } catch (e) {
      throw Exception('Sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Store token in Firestore (user-scoped)
  Future<void> _storeAccessToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .set({'calendarAccessToken': token}, SetOptions(merge: true));
  }

  Future<String?> getAccessToken() async {
    try {
      final account = await _googleSignIn.signInSilently();
      final auth = await account?.authentication;
      if (auth?.accessToken != null) {
        await _storeAccessToken(auth!.accessToken!);
      }
      return auth?.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<AccessCredentials?> getAccessCredentials() async {
    try {
      // First try to re-authenticate silently with the required scopes
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        // Try interactive sign-in if silent fails
        final interactiveAccount = await _googleSignIn.signIn();
        if (interactiveAccount == null) return null;

        final auth = await interactiveAccount.authentication;
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
      }

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
    } catch (e) {
      return null;
    }
  }

  // Email/Password Authentication
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email.');
        case 'wrong-password':
          throw Exception('Incorrect password.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        default:
          throw Exception('Sign-in failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Sign-in failed: $e');
    }
  }

  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      if (credential.user != null) {
        await _db.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('An account already exists with this email.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        case 'weak-password':
          throw Exception('Password is too weak. Use at least 6 characters.');
        default:
          throw Exception('Sign-up failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Sign-up failed: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        default:
          throw Exception('Password reset failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  bool get isGoogleUser {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData
        .any((provider) => provider.providerId == 'google.com');
  }
}
