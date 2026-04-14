import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  Future<void> updateProfile({
    required String uid,
    String? username,
    String? bio,
    String? profilePicUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    if (profilePicUrl != null) updates['profilePicUrl'] = profilePicUrl;
    if (updates.isEmpty) return;
    await _db.collection('users').doc(uid).update(updates);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final snap = await _db
        .collection('users')
        .orderBy('username')
        .startAt([query]).endAt(['$query\uf8ff']).get();
    return snap.docs.map(UserModel.fromDoc).toList();
  }
}
