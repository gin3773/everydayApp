import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<FirebaseUser> signInWithGoogle() async {
  final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

  final String idTokenVar = googleSignInAuthentication.idToken;
  final String accessTokenVar = googleSignInAuthentication.accessToken;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
      idToken: idTokenVar, accessToken: accessTokenVar);

  final AuthResult authResult =
      await firebaseAuth.signInWithCredential(credential);
  final FirebaseUser user = authResult.user;

  print(googleSignInAuthentication.idToken);
  print(googleSignInAuthentication.accessToken);
  print(user.email);

  return user;
}

void logOutfromGoogle() async {
  await googleSignIn.disconnect();
}
