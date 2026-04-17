import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String id;
  final String type;
  final String fromUid;
  final String toUid;
  final String fromUsername;
  final String fromProfilePicUrl;
  final String message;
  final String? postId;
  final String? chatId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.toUid,
    required this.fromUsername,
    required this.fromProfilePicUrl,
    required this.message,
    this.postId,
    this.chatId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotificationModel(
      id: doc.id,
      type: (data['type'] ?? '') as String,
      fromUid: (data['fromUid'] ?? '') as String,
      toUid: (data['toUid'] ?? '') as String,
      fromUsername: (data['fromUsername'] ?? 'biri') as String,
      fromProfilePicUrl: (data['fromProfilePicUrl'] ?? '') as String,
      message: (data['message'] ?? '') as String,
      postId: data['postId'] as String?,
      chatId: data['chatId'] as String?,
      isRead: (data['isRead'] ?? false) as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
