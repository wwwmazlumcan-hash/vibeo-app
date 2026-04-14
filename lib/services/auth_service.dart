import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password.trim());
  }

  Future<void> signUp(String email, String password, String username) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password.trim());

    // Firestore'da kullanıcı profili oluştur
    await _db.collection('users').doc(cred.user!.uid).set({
      'email': email.trim(),
      'username': username.trim(),
      'bio': '',
      'profilePicUrl': '',
      'followersCount': 0,
      'followingCount': 0,
      'videosCount': 0,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> signOut() => _auth.signOut();
}
