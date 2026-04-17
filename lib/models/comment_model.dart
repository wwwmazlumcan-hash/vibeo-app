import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String username;
  final String profilePicUrl;
  final String text;
  final DateTime createdAt;
  final Map<String, String> reactions; // userId -> emoji

  CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.profilePicUrl,
    required this.text,
    required this.createdAt,
    this.reactions = const {},
  });

  factory CommentModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'anonymous',
      profilePicUrl: data['profilePicUrl'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: Map<String, String>.from(data['reactions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'username': username,
        'profilePicUrl': profilePicUrl,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        'reactions': reactions,
      };
}
