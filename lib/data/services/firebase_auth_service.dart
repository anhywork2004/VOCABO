import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// LOGIN
  Future<UserCredential?> login(
      String email,
      String password,
      ) async {
    try {

      return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

    } on FirebaseAuthException catch (e) {

      print(e.message);
      return null;

    }
  }

  /// REGISTER
  Future<UserCredential?> register(
      String email,
      String password,
      ) async {

    try {

      return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

    } on FirebaseAuthException catch (e) {

      print(e.message);
      return null;

    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// FORGOT PASSWORD
  Future<void> resetPassword(String email) async {

    try {

      await _auth.sendPasswordResetEmail(
          email: email
      );

    } catch (e) {

      print(e.toString());

    }
  }

  /// PHONE VERIFY
  Future<void> verifyPhone(
      String phone,
      Function(String verificationId) codeSent,
      ) async {

    await _auth.verifyPhoneNumber(

      phoneNumber: phone,

      verificationCompleted:
          (PhoneAuthCredential credential) async {

        await _auth.signInWithCredential(
            credential
        );

      },

      verificationFailed:
          (FirebaseAuthException e) {

        print(e.message);

      },

      codeSent:
          (String verificationId, int? resendToken) {

        codeSent(verificationId);

      },

      codeAutoRetrievalTimeout:
          (String verificationId) {},

    );
  }

  /// VERIFY OTP
  Future<UserCredential?> signInWithOTP(
      String verificationId,
      String smsCode,
      ) async {

    try {

      PhoneAuthCredential credential =
      PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode
      );

      return await _auth.signInWithCredential(
          credential
      );

    } catch (e) {

      print(e.toString());
      return null;

    }
  }

}