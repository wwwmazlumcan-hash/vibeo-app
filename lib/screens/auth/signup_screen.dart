import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/vibeo_button.dart';
import '../../widgets/vibeo_input.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signup() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Tüm alanları doldur.');
      return;
    }
    if (username.length < 3) {
      _showError('Kullanıcı adı en az 3 karakter olmalı.');
      return;
    }
    if (password.length < 6) {
      _showError('Şifre en az 6 karakter olmalı.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'email': email,
        'username': username,
        'profilePicUrl': '',
        'bio': '',
        'followersCount': 0,
        'followingCount': 0,
        'videosCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError(_parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  String _parseError(String raw) {
    if (raw.contains('email-already-in-use')) return 'Bu email zaten kullanımda.';
    if (raw.contains('invalid-email')) return 'Geçersiz email adresi.';
    if (raw.contains('weak-password')) return 'Şifre çok zayıf.';
    return 'Kayıt başarısız. Tekrar dene.';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'YENİ HESAP OLUŞTUR',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 40),
            VibeoInput(
              controller: _usernameController,
              hintText: 'Kullanıcı adı',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 15),
            VibeoInput(
              controller: _emailController,
              hintText: 'E-posta',
              prefixIcon: Icons.email,
            ),
            const SizedBox(height: 15),
            VibeoInput(
              controller: _passwordController,
              hintText: 'Şifre (min. 6 karakter)',
              prefixIcon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 30),
            VibeoButton(
              text: 'KAYIT OL',
              onPressed: _signup,
              isLoading: _isLoading,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
