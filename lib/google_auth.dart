import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Import Firestore

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

                       /// Sign in with Google ///
  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;  /// If the user cancels the sign-in
      }


      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        /// Store user data in Firestore
        await _storeUserInFirestore(user);
      }

      return user;
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }
                       /// Sign out ///
  Future<void> _signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

                 /// Store user data in Firestore

  Future<void> _storeUserInFirestore(User user) async {
    try {
      /// Reference to the 'users' collection in Firestore
      final userRef = _firestore.collection('users').doc(user.uid);

      // Store the email and other user data
      await userRef.set({
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'lastSignIn': user.metadata.lastSignInTime,
      });

      print("User stored in Firestore!");
    } catch (e) {
      print("Error storing user in Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  const Text("Google Sign-In with Firebase"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            User? user = await _signInWithGoogle();
            if (user != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Welcome, ${user.displayName}")),
              );
            }
          },
          child: const Text("Sign in with Google"),
        ),
      ),
    );
  }
}
