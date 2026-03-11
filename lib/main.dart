import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'main_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Lỗi Firebase: $e");
  }
  runApp(const HappyPetShopApp());
}

class HappyPetShopApp extends StatelessWidget {
  const HappyPetShopApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Comic Sans MS',
        scaffoldBackgroundColor: const Color(0xFFE8F5E9), 
      ),
      home: FirebaseAuth.instance.currentUser == null ? const AuthScreen() : const MainMenu(),
    );
  }
}