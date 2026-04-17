import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SparkService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<bool> hasSparked(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || postId.isEmpty) return false;
    final doc = await _db.collection('posts').doc(postId).get();
    final sparkedBy =
        List<String>.from(doc.data()?['sparkedBy'] ?? const <String>[]);
    return sparkedBy.contains(uid);
  }

  static Future<void> toggleSpark({
    required String postId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || postId.isEmpty) return;
    final ref = _db.collection('posts').doc(postId);
    final doc = await ref.get();
    final sparkedBy =
        List<String>.from(doc.data()?['sparkedBy'] ?? const <String>[]);
    final hasSpark = sparkedBy.contains(uid);

    await ref.set({
      'sparkedBy': hasSpark
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
      'sparksCount': FieldValue.increment(hasSpark ? -1 : 1),
    }, SetOptions(merge: true));
  }

  static String buildConversationStarter(String prompt) {
    final base = prompt.trim();
    if (base.isEmpty) {
      return 'Aynı şeye bakınca sizce ilk fark ettiğiniz detay ne olurdu?';
    }
    return 'Bu paylaşımdaki en güçlü fikir ne, en zayıf tarafı ne? "$base" üzerinden başlayın.';
  }
}
