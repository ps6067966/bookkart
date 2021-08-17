import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nb_utils/nb_utils.dart';

class LoginService {
  static FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<Map> signInWithGoogle() async {
    GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential authResult = await _auth.signInWithCredential(credential);
      final User user = authResult.user!;

      assert(!user.isAnonymous);

      final User currentUser = _auth.currentUser!;
      assert(user.uid == currentUser.uid);

      signOutGoogle();

      String firstName = '';
      String lastName = '';

      if (currentUser.displayName.validate().split(' ').length >= 1) firstName = currentUser.displayName.splitBefore(' ');
      if (currentUser.displayName.validate().split(' ').length >= 2) lastName = currentUser.displayName.splitAfter(' ');

      setStringAsync(PROFILE_IMAGE, currentUser.photoURL!);

      Map req = {
        "email": currentUser.email,
        "firstName": firstName,
        "lastName": lastName,
        "photoURL": currentUser.photoURL,
        "accessToken": googleSignInAuthentication.accessToken,
        "loginType": 'google',
      };
      return req;
    } else {
      throw errorSomethingWentWrong;
    }
  }

  Future<void> signOutGoogle() async {
    await googleSignIn.signOut();
  }
}
