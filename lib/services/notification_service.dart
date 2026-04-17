import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_notification_model.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _db.collection('users').doc(uid).collection('notifications');
  }

  static Future<String> _currentUsername() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'biri';
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    return (data?['username'] ?? 'biri') as String;
  }

  static Future<String> _currentProfilePicUrl() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    return (data?['profilePicUrl'] ?? '') as String;
  }

  static Future<void> sendNotification({
    required String toUid,
    required String type,
    required String message,
    String? postId,
    String? chatId,
  }) async {
    final fromUid = _auth.currentUser?.uid;
    if (fromUid == null || toUid.isEmpty || fromUid == toUid) return;

    final fromUsername = await _currentUsername();
    final fromProfilePicUrl = await _currentProfilePicUrl();
    await _collection(toUid).add({
      'type': type,
      'fromUid': fromUid,
      'toUid': toUid,
      'fromUsername': fromUsername,
      'fromProfilePicUrl': fromProfilePicUrl,
      'message': message,
      'postId': postId,
      'chatId': chatId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendFollowNotification(String toUid) {
    return sendNotification(
      toUid: toUid,
      type: 'follow',
      message: 'seni takip etmeye başladı.',
    );
  }

  static Future<void> sendLikeNotification({
    required String toUid,
    required String postId,
  }) {
    return sendNotification(
      toUid: toUid,
      type: 'like',
      message: 'gönderini beğendi.',
      postId: postId,
    );
  }

  static Future<void> sendCommentNotification({
    required String toUid,
    required String postId,
    required String commentText,
  }) {
    final preview = commentText.length > 40
        ? '${commentText.substring(0, 40)}...'
        : commentText;
    return sendNotification(
      toUid: toUid,
      type: 'comment',
      message: 'gönderine yorum yaptı: "$preview"',
      postId: postId,
    );
  }

  static Future<void> sendMessageNotification({
    required String toUid,
    required String chatId,
    required String text,
  }) {
    final preview = text.length > 40 ? '${text.substring(0, 40)}...' : text;
    return sendNotification(
      toUid: toUid,
      type: 'message',
      message: 'sana mesaj gönderdi: "$preview"',
      chatId: chatId,
    );
  }

  static Stream<List<AppNotificationModel>> streamNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _collection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotificationModel.fromDoc(doc))
            .toList());
  }

  static Stream<int> streamUnreadCount() {
    return streamNotifications().map(
      (items) => items.where((item) => !item.isRead).length,
    );
  }

  static Future<void> markAsRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _collection(uid).doc(notificationId).update({'isRead': true});
  }

  static Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snapshot =
        await _collection(uid).where('isRead', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
