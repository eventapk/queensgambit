import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:queens_gambit/homePage.dart';
import 'package:queens_gambit/screens/user/registrationScreen.dart';
import 'package:queens_gambit/screens/admin/adminhomepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}
