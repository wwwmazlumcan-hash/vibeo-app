import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import '../services/storage_service.dart';

enum FeedMode { forYou, following, trending }

class VideoProvider extends ChangeNotifier {
  final VideoService _videoService = VideoService();
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _feedLoading = false;
  FeedMode _feedMode = FeedMode.forYou;
  Set<String> _followingIds = <String>{};
  Set<String> _savedPostIds = <String>{};
  Set<String> _viewedPostIds = <String>{};
  Map<String, int> _preferredHashtags = <String, int>{};
  Map<String, int> _preferredCreators = <String, int>{};

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  bool get isFeedLoading => _feedLoading;
  FeedMode get feedMode => _feedMode;

  void setFeedMode(FeedMode mode) {
    if (_feedMode == mode) return;
    _feedMode = mode;
    notifyListeners();
  }

  Future<void> refreshFeedPreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _feedLoading = true;
    notifyListeners();

    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? <String, dynamic>{};
      _followingIds = Set<String>.from(userData['following'] ?? const []);
      _savedPostIds = Set<String>.from(userData['saved'] ?? const []);
      _viewedPostIds = Set<String>.from(userData['viewedPostIds'] ?? const []);

      final likedPosts = await _db
          .collection('posts')
          .where('likedBy', arrayContains: uid)
          .limit(25)
          .get();

      final hashtags = <String, int>{};
      final creators = <String, int>{};
      for (final doc in likedPosts.docs) {
        final data = doc.data();
        final authorId = (data['userId'] ?? '') as String;
        if (authorId.isNotEmpty) {
          creators[authorId] = (creators[authorId] ?? 0) + 1;
        }

        final tags = List<String>.from(data['hashtags'] ?? const []);
        for (final tag in tags) {
          hashtags[tag] = (hashtags[tag] ?? 0) + 1;
        }
      }

      _preferredHashtags = hashtags;
      _preferredCreators = creators;
    } finally {
      _feedLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerPostView({
    required String postId,
    required List<String> hashtags,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || postId.isEmpty || _viewedPostIds.contains(postId)) {
      return;
    }

    _viewedPostIds.add(postId);
    notifyListeners();

    await _db.collection('users').doc(uid).set({
      'viewedPostIds': FieldValue.arrayUnion([postId]),
      'viewedHashtags': FieldValue.arrayUnion(hashtags),
    }, SetOptions(merge: true));
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> rankPostDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final working =
        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);

    if (_feedMode == FeedMode.following) {
      return working
          .where((doc) =>
              _followingIds.contains((doc.data()['userId'] ?? '') as String))
          .toList();
    }

    working.sort((a, b) {
      final scoreB = _scoreDoc(b, uid);
      final scoreA = _scoreDoc(a, uid);
      return scoreB.compareTo(scoreA);
    });

    return working;
  }

  List<String> buildRecommendationReasons(Map<String, dynamic> data) {
    final reasons = <String>[];
    final authorId = (data['userId'] ?? '') as String;
    final hashtags = List<String>.from(data['hashtags'] ?? const []);
    final likesCount = (data['likesCount'] ?? 0) as int;

    if (_feedMode == FeedMode.following && _followingIds.contains(authorId)) {
      reasons.add('Bu üreticiyi takip ediyorsun.');
    }

    if (_feedMode == FeedMode.trending) {
      reasons.add('Trend akışındasın ve bu içerik etkileşim alıyor.');
    }

    if (_followingIds.contains(authorId)) {
      reasons.add('Takip ettiğin bir üreticiden geldi.');
    }

    final matchedTags = hashtags.where(_preferredHashtags.containsKey).toList();
    if (matchedTags.isNotEmpty) {
      reasons.add(
          'İlgi gösterdiğin etiketlerle eşleşiyor: ${matchedTags.take(2).map((tag) => '#$tag').join(', ')}');
    }

    if ((_preferredCreators[authorId] ?? 0) > 0) {
      reasons.add('Bu üreticinin içerikleriyle daha önce etkileşime girdin.');
    }

    if (_savedPostIds.contains((data['id'] ?? '') as String)) {
      reasons.add('Benzer içerikleri daha önce kaydetmişsin.');
    }

    if (likesCount >= 8) {
      reasons.add('Topluluk içinde güçlü etkileşim alıyor.');
    }

    if (reasons.isEmpty) {
      reasons.add('Yeni ve çeşitli içerikler göstermek için önerildi.');
    }

    return reasons;
  }

  double _scoreDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String? uid,
  ) {
    final data = doc.data();
    final authorId = (data['userId'] ?? '') as String;
    final likesCount = (data['likesCount'] ?? 0) as int;
    final hashtags = List<String>.from(data['hashtags'] ?? const []);
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    if (_feedMode == FeedMode.trending) {
      return _freshnessScore(createdAt) + (likesCount * 4).toDouble();
    }

    double score = 0;

    if (_followingIds.contains(authorId)) {
      score += 70;
    }

    score += (_preferredCreators[authorId] ?? 0) * 24;
    score += likesCount * 1.8;
    score += _freshnessScore(createdAt);

    for (final tag in hashtags) {
      score += (_preferredHashtags[tag] ?? 0) * 10;
    }

    if (_savedPostIds.contains(doc.id)) {
      score += 18;
    }

    if (_viewedPostIds.contains(doc.id)) {
      score -= 15;
    }

    final likedBy = List<String>.from(data['likedBy'] ?? const []);
    if (uid != null && likedBy.contains(uid)) {
      score -= 8;
    }

    return score;
  }

  double _freshnessScore(DateTime? createdAt) {
    if (createdAt == null) return 0;
    final hours = DateTime.now().difference(createdAt).inHours;
    if (hours <= 6) return 28;
    if (hours <= 24) return 20;
    if (hours <= 72) return 12;
    if (hours <= 168) return 6;
    return 2;
  }

  // Like toggle — lokal state günceller (optimistic update)
  Future<void> toggleLike(VideoModel video) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _videoService.toggleLike(video.id, uid);
  }

  // Video yükle
  Future<bool> uploadVideo({
    required File videoFile,
    required String description,
    required String username,
    required String profilePicUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    _isUploading = true;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      // Storage'a yükle
      final videoUrl = await _storageService.uploadVideo(videoFile, uid);
      _uploadProgress = 0.8;
      notifyListeners();

      // Firestore'a kaydet
      await _videoService.addVideo(
        userId: uid,
        username: username,
        profilePicUrl: profilePicUrl,
        videoUrl: videoUrl,
        description: description,
      );
      _uploadProgress = 1.0;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}
