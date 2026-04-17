import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserService();

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

  /// Follow a user by UID
  Future<void> followUser(String targetUid) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null || targetUid == myUid) return;

    try {
      // Add target user to my following list
      await _db.collection('users').doc(myUid).update({
        'following': FieldValue.arrayUnion([targetUid]),
        'followingCount': FieldValue.increment(1),
      });

      // Add me to target user's followers list
      await _db.collection('users').doc(targetUid).update({
        'followers': FieldValue.arrayUnion([myUid]),
        'followersCount': FieldValue.increment(1),
      });

      await NotificationService.sendFollowNotification(targetUid);
    } catch (e) {
      throw Exception('Error following user: $e');
    }
  }

  /// Unfollow a user by UID
  Future<void> unfollowUser(String targetUid) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null || targetUid == myUid) return;

    try {
      // Remove target user from my following list
      await _db.collection('users').doc(myUid).update({
        'following': FieldValue.arrayRemove([targetUid]),
        'followingCount': FieldValue.increment(-1),
      });

      // Remove me from target user's followers list
      await _db.collection('users').doc(targetUid).update({
        'followers': FieldValue.arrayRemove([myUid]),
        'followersCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Error unfollowing user: $e');
    }
  }

  /// Check if current user is following the target user
  Future<bool> isFollowing(String targetUid) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return false;

    try {
      final doc = await _db.collection('users').doc(myUid).get();
      final following = List<String>.from(doc.data()?['following'] ?? []);
      return following.contains(targetUid);
    } catch (e) {
      return false;
    }
  }

  /// Get list of followers for a user
  Future<List<UserModel>> getFollowersList(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final followers = List<String>.from(doc.data()?['followers'] ?? []);

      if (followers.isEmpty) return [];

      // Get user details for each follower (max 100 at a time for performance)
      final batch = followers.take(100).toList();
      final docs = await Future.wait(
        batch.map((fUid) => _db.collection('users').doc(fUid).get()),
      );

      return docs
          .where((d) => d.exists)
          .map((d) => UserModel.fromDoc(d))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get list of users followed by a user
  Future<List<UserModel>> getFollowingList(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final following = List<String>.from(doc.data()?['following'] ?? []);

      if (following.isEmpty) return [];

      // Get user details for each followed user
      final batch = following.take(100).toList();
      final docs = await Future.wait(
        batch.map((fUid) => _db.collection('users').doc(fUid).get()),
      );

      return docs
          .where((d) => d.exists)
          .map((d) => UserModel.fromDoc(d))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get trending creators (most followers)
  Future<List<UserModel>> getTrendingCreators({int limit = 10}) async {
    try {
      final docs = await _db
          .collection('users')
          .orderBy('followersCount', descending: true)
          .limit(limit)
          .get();

      return docs.docs.map((d) => UserModel.fromDoc(d)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get suggested users (not following, random selection)
  Future<List<UserModel>> getSuggestedUsers({int limit = 5}) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return [];

    try {
      // Get my following list
      final myDoc = await _db.collection('users').doc(myUid).get();
      final following = List<String>.from(myDoc.data()?['following'] ?? []);

      // Get random users not in my following list
      final allUsers = await _db.collection('users').limit(50).get();

      final suggested = allUsers.docs
          .where((d) => d.id != myUid && !following.contains(d.id))
          .map((d) => UserModel.fromDoc(d))
          .take(limit)
          .toList();

      return suggested;
    } catch (e) {
      return [];
    }
  }

  /// Get current user's full profile
  Future<UserModel?> getCurrentUserProfile() async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return null;

    try {
      final doc = await _db.collection('users').doc(myUid).get();
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    } catch (e) {
      return null;
    }
  }

  /// Stream user profile - real-time updates
  Stream<UserModel?> streamUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    });
  }
}
