import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:haochi_app/firebase_options.dart';
import 'package:haochi_app/screens/auth_screen.dart';

class FeederApp extends StatelessWidget {

  const FeederApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feeder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    FeederApp()
  );
}
