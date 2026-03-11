import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';
import 'main_menu.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool isLogin = true;

  Future<void> _auth() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      } else {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'playerName': 'Đầu Bếp ${Random().nextInt(9999)}',
          'playerAvatar': '👨‍🍳',
          'bgMusic': 'bgm1.mp3'
        }, SetOptions(merge: true));
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainMenu()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: ${e.toString()}")));
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,
        );
        UserCredential cred = await FirebaseAuth.instance.signInWithCredential(credential);
        
        if (cred.additionalUserInfo?.isNewUser ?? false) {
           await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
            'playerName': cred.user!.displayName ?? 'Đầu Bếp',
            'playerAvatar': '👨‍🍳',
            'bgMusic': 'bgm1.mp3'
          }, SetOptions(merge: true));
        }
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainMenu()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi Google Login: $e"), backgroundColor: Colors.red));
    }
  }  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFFFFCA28)])),
        child: Center(
          child: SingleChildScrollView( 
            child: Card(
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🐾 NHÀ HÀNG THÚ CƯNG', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                  TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _auth, icon: Icon(isLogin ? Icons.login : Icons.person_add, color: Colors.white),
                    label: Text(isLogin ? 'MỞ CỬA TIỆM' : 'ĐĂNG KÝ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 45)), 
                  ),
                  TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? 'Chưa có tài khoản? Đăng ký' : 'Đã có tài khoản? Đăng nhập')),
                  const Divider(thickness: 1, color: Colors.grey),
                  const Text("HOẶC", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 30),
                    label: const Text('Đăng nhập với Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45), backgroundColor: Colors.white),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}