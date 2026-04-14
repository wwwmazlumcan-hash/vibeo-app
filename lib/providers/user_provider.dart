import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  UserModel? _user;
  UserModel? get user => _user;

  Future<void> fetchCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _user = await _userService.getUser(uid);
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? username,
    String? bio,
    String? profilePicUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _userService.updateProfile(
      uid: uid,
      username: username,
      bio: bio,
      profilePicUrl: profilePicUrl,
    );
    await fetchCurrentUser();
  }
}
