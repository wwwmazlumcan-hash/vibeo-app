import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimeCapsuleService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> scheduleCapsule({
    required String postId,
    required String prompt,
    required DateTime revealAt,
    required String note,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || postId.isEmpty) return;

    await _db.collection('time_capsules').add({
      'userId': uid,
      'postId': postId,
      'prompt': prompt,
      'note': note,
      'revealAt': Timestamp.fromDate(revealAt),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'scheduled',
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamMine() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _db
        .collection('time_capsules')
        .where('userId', isEqualTo: uid)
        .orderBy('revealAt')
        .snapshots();
  }

  static String formatReveal(Timestamp? revealAt) {
    final date = revealAt?.toDate();
    if (date == null) return 'Belirsiz';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
