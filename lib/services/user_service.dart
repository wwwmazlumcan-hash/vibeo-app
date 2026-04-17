import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class UserPreview {
  final String username;
  final String profileImageUrl;

  const UserPreview({
    required this.username,
    required this.profileImageUrl,
  });
}

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UserService();

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  Future<UserPreview> getUserPreview(
    String uid, {
    String fallbackUsername = 'anonim',
  }) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? <String, dynamic>{};
      final username = (data['username'] as String?)?.trim();
      final profilePicUrl =
          ((data['profilePicUrl'] ?? data['avatarUrl']) as String?)?.trim();

      return UserPreview(
        username:
            username == null || username.isEmpty ? fallbackUsername : username,
        profileImageUrl: profilePicUrl ?? '',
      );
    } catch (_) {
      return UserPreview(
        username: fallbackUsername,
        profileImageUrl: '',
      );
    }
  }

  Future<String> getUsername(
    String uid, {
    String fallbackUsername = 'anonim',
  }) async {
    final preview = await getUserPreview(
      uid,
      fallbackUsername: fallbackUsername,
    );
    return preview.username;
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

  Future<void> deleteCurrentUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Aktif kullanıcı bulunamadı.');
    }

    final uid = user.uid;
    await _cleanupUserGeneratedContent(uid);
    await _cleanupSocialGraph(uid);
    await _cleanupStorage(uid);
    await _deleteUserDocument(uid);

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Güvenlik nedeniyle hesabı silmeden önce tekrar giriş yapman gerekiyor.',
        );
      }
      throw Exception('Hesap silinemedi: ${e.message ?? e.code}');
    }
  }

  Future<void> _cleanupUserGeneratedContent(String uid) async {
    await Future.wait([
      _deleteQueryBatch(
          _db.collection('posts').where('userId', isEqualTo: uid)),
      _deleteQueryBatch(
          _db.collection('stories').where('userId', isEqualTo: uid)),
      _deleteQueryBatch(
        _db.collection('challenge_entries').where('userId', isEqualTo: uid),
      ),
      _deleteQueryBatch(
          _db.collection('battles').where('user1', isEqualTo: uid)),
      _deleteQueryBatch(
          _db.collection('battles').where('user2', isEqualTo: uid)),
    ]);
  }

  Future<void> _cleanupSocialGraph(String uid) async {
    final myDoc = await _db.collection('users').doc(uid).get();
    final myData = myDoc.data() ?? <String, dynamic>{};
    final followers = List<String>.from(myData['followers'] ?? const []);
    final following = List<String>.from(myData['following'] ?? const []);

    await Future.wait([
      for (final followerUid in followers)
        _db.collection('users').doc(followerUid).set({
          'following': FieldValue.arrayRemove([uid]),
          'followingCount': FieldValue.increment(-1),
        }, SetOptions(merge: true)),
      for (final followingUid in following)
        _db.collection('users').doc(followingUid).set({
          'followers': FieldValue.arrayRemove([uid]),
          'followersCount': FieldValue.increment(-1),
        }, SetOptions(merge: true)),
    ]);

    await _deleteQueryBatch(
      _db.collectionGroup('notifications').where('fromUid', isEqualTo: uid),
    );
    await _deleteSubcollection(
      _db.collection('users').doc(uid).collection('notifications'),
    );
  }

  Future<void> _cleanupStorage(String uid) async {
    await Future.wait([
      _deleteStorageFolder('profiles/$uid'),
      _deleteStorageFolder('videos/$uid'),
    ]);
  }

  Future<void> _deleteUserDocument(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Future<void> _deleteQueryBatch(Query<Map<String, dynamic>> query) async {
    while (true) {
      final snapshot = await query.limit(100).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < 100) return;
    }
  }

  Future<void> _deleteSubcollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(100).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < 100) return;
    }
  }

  Future<void> _deleteStorageFolder(String path) async {
    try {
      final listing = await _storage.ref(path).listAll();
      await Future.wait([
        for (final item in listing.items) item.delete(),
        for (final prefix in listing.prefixes)
          _deleteStorageFolder(prefix.fullPath),
      ]);
    } catch (_) {
      // Ignore missing folders and continue account cleanup.
    }
  }
}
