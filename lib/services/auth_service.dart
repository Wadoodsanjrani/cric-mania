import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── CURRENT USER ───
  User? get currentUser => _auth.currentUser;

  // ─── AUTH STATE STREAM ───
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ═══════════════════════════════════════════════════════════
  // SIGN UP WITH EMAIL + PASSWORD
  // ═══════════════════════════════════════════════════════════
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create account
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = result.user;
      if (user == null) {
        return "Sign up failed. Please try again.";
      }

      // 2. Send verification email
      await user.sendEmailVerification();

      // 3. Create basic user document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'userId': user.uid,
        'email': user.email,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null; // null = success
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      return "An error occurred. Please try again.";
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LOGIN WITH EMAIL + PASSWORD
  // ═══════════════════════════════════════════════════════════
  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      return "An error occurred. Please try again.";
    }
  }

  // ═══════════════════════════════════════════════════════════
  // GOOGLE SIGN-IN
  // ═══════════════════════════════════════════════════════════
  Future<String?> signInWithGoogle() async {
    try {
      // 1. Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return "cancelled";
      }

      // 2. Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      UserCredential result = await _auth.signInWithCredential(credential);

      User? user = result.user;
      if (user == null) {
        return "Google sign-in failed. Please try again.";
      }

      // 5. Create/update Firestore user document
      await _firestore.collection('users').doc(user.uid).set({
        'userId': user.uid,
        'email': user.email,
        'name': user.displayName ?? '',
        'profilePhotoUrl': user.photoURL ?? '',
        'emailVerified': true, // Google emails are pre-verified
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      return "Google sign-in failed. Please try again.";
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════════════
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SEND PASSWORD RESET EMAIL
  // ═══════════════════════════════════════════════════════════
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      return "Failed to send reset email. Please try again.";
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SEND EMAIL VERIFICATION (re-send)
  // ═══════════════════════════════════════════════════════════
  Future<String?> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return "No user logged in.";
      if (user.emailVerified) return "Email already verified.";

      await user.sendEmailVerification();
      return null; // success
    } catch (e) {
      return "Failed to send verification email. Please try again.";
    }
  }

  // ═══════════════════════════════════════════════════════════
  // RELOAD USER (to check email verification status)
  // ═══════════════════════════════════════════════════════════
  Future<bool> reloadUser() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CHECK IF EMAIL IS VERIFIED
  // ═══════════════════════════════════════════════════════════
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ═══════════════════════════════════════════════════════════
  // ERROR MESSAGE HELPER (English only)
  // ═══════════════════════════════════════════════════════════
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "This email is already registered. Please login instead.";
      case 'invalid-email':
        return "Invalid email address. Please check and try again.";
      case 'weak-password':
        return "Password is too weak. Use at least 6 characters.";
      case 'user-not-found':
        return "No account found with this email. Please sign up first.";
      case 'wrong-password':
        return "Incorrect password. Please try again.";
      case 'user-disabled':
        return "This account has been disabled. Contact support.";
      case 'too-many-requests':
        return "Too many attempts. Please try again later.";
      case 'operation-not-allowed':
        return "This sign-in method is not enabled.";
      case 'network-request-failed':
        return "Network error. Please check your internet connection.";
      case 'invalid-credential':
        return "Invalid credentials. Please check and try again.";
      default:
        return e.message ?? "Authentication failed. Please try again.";
    }
  }
}