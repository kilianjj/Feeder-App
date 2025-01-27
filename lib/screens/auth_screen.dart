import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:haochi_app/screens/home_page.dart';
import 'package:haochi_app/screens/toast.dart';

// auth screen that appears when running app for first time or after logging out
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSignIn(); // make it run after building to prevent error
    });
  }

  _checkSignIn() async {
    if (FirebaseAuth.instance.currentUser != null) {
      _navigateToHome();
    }
  }

  // authenticate with google, then redirect to main page
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        ToastHelper.getToastBar("Sign-in failed"),
      );
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          children: [
            Text(
              "Sign in with Google",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20), // Add space between text and button
            FloatingActionButton(
              onPressed: _signInWithGoogle,
              child: Icon(Icons.login), // Use an icon instead of text for better aesthetics
            ),
          ],
        ),
      ),
    );
  }
}