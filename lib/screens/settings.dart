import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:haochi_app/screens/auth_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// could add this but java version too high rn and im lazy

// basic settings page stub: sign out of google
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // _loadTheme();
  }

  // _loadTheme() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     _isDarkMode = prefs.getBool('isDarkMode') ?? false;
  //   });
  // }

  // _toggleTheme(bool value) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     _isDarkMode = value;
  //   });
  //   prefs.setBool('isDarkMode', _isDarkMode);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Center(
        child: Column(
          mainAxisSize:  MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SwitchListTile(
              title: Text('Dark Mode'),
              value: _isDarkMode,
              onChanged: (_) => {},
            ),
            const SizedBox(height: 30,),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  GoogleSignIn().signOut();
                  Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => AuthScreen()),
                  );
                } catch (e) {
                  // log(e);
                  Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => AuthScreen()),
                  );
                }
              },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Sign out of Google",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      )
    );
  }
}