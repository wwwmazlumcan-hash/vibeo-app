// Block/Mute service — engelleme ve sessize alma
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockService {
  static Future<void> blockUser(String targetUid) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || me.uid == targetUid) return;
    final ref =
        FirebaseFirestore.instance.collection('users').doc(me.uid);
    await ref.update({
      'blockedUsers': FieldValue.arrayUnion([targetUid]),
    });
  }

  static Future<void> unblockUser(String targetUid) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final ref =
        FirebaseFirestore.instance.collection('users').doc(me.uid);
    await ref.update({
      'blockedUsers': FieldValue.arrayRemove([targetUid]),
    });
  }

  static Future<void> muteUser(String targetUid) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || me.uid == targetUid) return;
    final ref =
        FirebaseFirestore.instance.collection('users').doc(me.uid);
    await ref.update({
      'mutedUsers': FieldValue.arrayUnion([targetUid]),
    });
  }

  static Future<void> unmuteUser(String targetUid) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final ref =
        FirebaseFirestore.instance.collection('users').doc(me.uid);
    await ref.update({
      'mutedUsers': FieldValue.arrayRemove([targetUid]),
    });
  }

  static Future<bool> isBlocked(String targetUid) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(me.uid)
        .get();
    final list = (doc.data()?['blockedUsers'] as List?)?.cast<String>() ?? [];
    return list.contains(targetUid);
  }

  static Stream<List<String>> streamBlockedIds() {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return Stream.value(const []);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(me.uid)
        .snapshots()
        .map((d) =>
            (d.data()?['blockedUsers'] as List?)?.cast<String>() ?? []);
  }

  /// Şikayet (report) — toxic içerik raporu.
  static Future<void> reportUser(String targetUid, String reason) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    await FirebaseFirestore.instance.collection('reports').add({
      'type': 'user',
      'targetUid': targetUid,
      'reason': reason,
      'reporterUid': me.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> reportPost(String postId, String reason) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    await FirebaseFirestore.instance.collection('reports').add({
      'type': 'post',
      'postId': postId,
      'reason': reason,
      'reporterUid': me.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Also increment reportCount on the post
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update({'reportCount': FieldValue.increment(1)});
  }
}
