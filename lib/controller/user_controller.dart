import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/widgets.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

// ignore: must_be_immutable
class UserController extends InheritedWidget {
  FirebaseUser user;

  // OneSignal player ID
  //
  // https://documentation.onesignal.com/docs/flutter-sdk#postnotification
  String playerId;

  UserController({Key key, Widget child})
      : super(
          key: key,
          child: child,
        );

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoggedIn() {
    return user != null;
  }

  Future<FirebaseUser> checkIsLoggedIn() async {
    if (isLoggedIn()) {
      return user;
    }

    user = await _auth.currentUser();

    return user;
  }

  Future<FirebaseUser> signIn() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    user = (await _auth.signInWithCredential(credential)).user;

    return user;
  }

  Future<void> signOut() async {
    user = null;

    // Desconectar para que quando for fazer o login
    // apareca a selecao de conta que vai se conectar
    await _googleSignIn.disconnect();

    await _auth.signOut();
  }

  static UserController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UserController>();
  }

  @override
  bool updateShouldNotify(UserController oldWidget) {
    return false;
  }
}
