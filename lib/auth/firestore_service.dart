import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseApi {
  User? user = FirebaseAuth.instance.currentUser;

  Future<User> login({email, password}) async {
    try {
      final credentials = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return credentials.user!;
    } catch (e) {
      print(e.toString());
      throw Exception('Invalid login details');
    }
  }

  Future<User> signUp({email, password, username}) async {
    try {
      final credentials =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      credentials.user!.updateDisplayName(username);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credentials.user!.uid)
          .set({
        'username': username,
        'email': email,
        'password': password,
        "image_url": credentials.user!.photoURL,
        "display_name": credentials.user!.displayName ?? username,
        "userId": credentials.user!.uid,
        "online": true,
        "following": [],
        "followers": []
      });
      return credentials.user!;
    } catch (e) {
      print(e.toString());
      throw Exception('Failed to register user');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e.toString());
      throw Exception('Failed to send password reset email');
    }
  }
}
