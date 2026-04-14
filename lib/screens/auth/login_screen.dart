import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/vibeo_button.dart';
import '../../widgets/vibeo_input.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Giriş başarılıysa AuthGate zaten MainNavigation'a yönlendirecek.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Hata: ${e.toString()}"),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill,
                size: 80, color: Colors.cyanAccent),
            const SizedBox(height: 20),
            const Text("VIBEO'YA HOŞ GELDİN",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 40),
            VibeoInput(
                controller: _emailController,
                hintText: "E-posta",
                prefixIcon: Icons.email),
            const SizedBox(height: 15),
            VibeoInput(
                controller: _passwordController,
                hintText: "Şifre",
                prefixIcon: Icons.lock,
                isPassword: true),
            const SizedBox(height: 30),
            VibeoButton(
                text: "GİRİŞ YAP", onPressed: _login, isLoading: _isLoading),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignupScreen())),
              child: const Text("Hesabın yok mu? Kayıt Ol",
                  style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
