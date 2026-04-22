import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// EMAIL LOGIN
  Future<User?> loginWithEmail(
      String email,
      String password,
      ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Login failed");
    }
  }

  /// REGISTER
  Future<User?> registerWithEmail(
      String email,
      String password,
      ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Register failed");
    }
  }

  /// GOOGLE LOGIN
  Future<User?> signInWithGoogle() async {
    try {
      // serverClientId = Web client ID (client_type: 3) từ google-services.json
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '1060637668034-1o87o6qune23elgh52rht5ch4m7dmt1f.apps.googleusercontent.com',
      );

      // Đảm bảo sign out trước để tránh cache cũ
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null; // user huỷ

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      debugPrint('Google login failed: $e');
      rethrow; // ném lên để UI hiển thị lỗi cụ thể
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}