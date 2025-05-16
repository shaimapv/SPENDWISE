import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user ??
          (throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'User details not found.',
          ));
    } on FirebaseAuthException catch (e) {
      print("Sign-in error: ${e.message}");
      return null;
    }
  }

  // Register with email and password
  Future<User?> register(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      User? user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User registration failed.',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Registration error: ${e.message}");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Sign-out error: $e");
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Reset Password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return "Password reset email sent!";
    } on FirebaseAuthException catch (e) {
      print("Error sending password reset email: $e");
      return e.message;
    }
  }
}
