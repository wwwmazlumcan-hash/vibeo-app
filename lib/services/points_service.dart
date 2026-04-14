import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// XP / Points system for Kazandırıyor feature.
class PointsService {
  static const int pointsPerPost = 10;
  static const int pointsPerLikeReceived = 2;
  static const int pointsPerComment = 3;
  static const int pointsPerDailyLogin = 5;

  static Future<void> award(int points, {String reason = ''}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    await ref.update({
      'points': FieldValue.increment(points),
      'pointsHistory': FieldValue.arrayUnion([
        {
          'amount': points,
          'reason': reason,
          'at': DateTime.now().toIso8601String(),
        }
      ]),
    });
  }

  static Future<int> getPoints() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return (doc.data()?['points'] ?? 0) as int;
  }

  /// Badge thresholds.
  static String getBadge(int points) {
    if (points >= 5000) return '👑 Legend';
    if (points >= 2000) return '💎 Diamond';
    if (points >= 1000) return '🥇 Gold';
    if (points >= 500) return '🥈 Silver';
    if (points >= 100) return '🥉 Bronze';
    return '🌱 Starter';
  }
}
