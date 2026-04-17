import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String userId;
  final String username;
  final String profilePicUrl;
  final String videoUrl;
  final String description;
  final List<String> hashtags;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy; // user ID listesi
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.profilePicUrl,
    required this.videoUrl,
    required this.description,
    required this.hashtags,
    required this.likesCount,
    required this.commentsCount,
    required this.likedBy,
    required this.createdAt,
  });

  factory VideoModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'anonymous',
      profilePicUrl: data['profilePicUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      description: data['description'] ?? '',
      hashtags: List<String>.from(data['hashtags'] ?? []),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'username': username,
        'profilePicUrl': profilePicUrl,
        'videoUrl': videoUrl,
        'description': description,
        'hashtags': hashtags,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'likedBy': likedBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  VideoModel copyWith({
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
    List<String>? hashtags,
  }) =>
      VideoModel(
        id: id,
        userId: userId,
        username: username,
        profilePicUrl: profilePicUrl,
        videoUrl: videoUrl,
        description: description,
        hashtags: hashtags ?? this.hashtags,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        likedBy: likedBy ?? this.likedBy,
        createdAt: createdAt,
      );
}
