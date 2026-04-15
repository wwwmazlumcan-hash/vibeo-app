import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Tracks user's online presence via periodic lastActive heartbeat.
class PresenceService {
  static Timer? _timer;

  /// Threshold after which a user is considered offline.
  static const offlineThreshold = Duration(minutes: 5);

  static void start() {
    _timer?.cancel();
    _update(); // immediate
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _update());
  }

  static void stop() => _timer?.cancel();

  static Future<void> _update() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'lastActive': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  static bool isOffline(DateTime? lastActive) {
    if (lastActive == null) return true;
    return DateTime.now().difference(lastActive) > offlineThreshold;
  }
}
