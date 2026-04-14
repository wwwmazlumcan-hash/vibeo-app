import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModerationService {
  static const _banned = [
    'spam', 'hate', 'violence', 'adult', 'nude', 'porn', 'xxx',
    'kill', 'murder', 'terrorist', 'bomb', 'drug', 'cocaine',
  ];

  /// Returns null if clean, returns reason if flagged.
  static String? checkText(String text) {
    final lower = text.toLowerCase();
    for (final word in _banned) {
      if (lower.contains(word)) {
        return 'İçerik uygunsuz ifade içeriyor: "$word"';
      }
    }
    return null;
  }

  /// Reports a post to Firestore.
  static Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('reports')
        .add({
      'postId': postId,
      'reportedBy': uid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    // Increment report count on post
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update({'reportCount': FieldValue.increment(1)});
  }
}
