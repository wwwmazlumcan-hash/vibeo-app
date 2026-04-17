import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String bio;
  final String profilePicUrl;
  final int followersCount;
  final int followingCount;
  final int videosCount;
  final List<String> followers; // UIDs of people following this user
  final List<String> following; // UIDs of people this user is following
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.bio,
    required this.profilePicUrl,
    required this.followersCount,
    required this.followingCount,
    required this.videosCount,
    required this.followers,
    required this.following,
    required this.createdAt,
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? 'user',
      bio: data['bio'] ?? '',
      profilePicUrl: data['profilePicUrl'] ?? '',
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      videosCount: data['videosCount'] ?? 0,
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'username': username,
        'bio': bio,
        'profilePicUrl': profilePicUrl,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'videosCount': videosCount,
        'followers': followers,
        'following': following,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
