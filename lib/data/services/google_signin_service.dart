import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '1060637668034-1o87o6qune23elgh52rht5ch4m7dmt1f.apps.googleusercontent.com',
  );

  Future<UserCredential> signInWithGoogle() async {

    final googleUser = await _googleSignIn.signIn();

    final googleAuth = await googleUser!.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(
        credential
    );
  }
}