import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';
import '../models/comment_model.dart';

class VideoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Ana feed: tüm videolar, en yeni önce
  Stream<List<VideoModel>> getVideos() {
    return _db
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(VideoModel.fromDoc).toList());
  }

  // Bir kullanıcının videoları
  Stream<List<VideoModel>> getUserVideos(String userId) {
    return _db
        .collection('videos')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(VideoModel.fromDoc).toList());
  }

  // Açıklamaya göre arama
  Future<List<VideoModel>> searchVideos(String query) async {
    if (query.isEmpty) return [];
    final snap = await _db
        .collection('videos')
        .orderBy('description')
        .startAt([query]).endAt(['$query\uf8ff']).get();
    return snap.docs.map(VideoModel.fromDoc).toList();
  }

  // Beğen / beğeniyi geri al
  Future<void> toggleLike(String videoId, String userId) async {
    final ref = _db.collection('videos').doc(videoId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final likedBy = List<String>.from(doc['likedBy'] ?? []);
    if (likedBy.contains(userId)) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  // Video yükle (URL ve metadata Firestore'a)
  Future<void> addVideo({
    required String userId,
    required String username,
    required String profilePicUrl,
    required String videoUrl,
    required String description,
  }) async {
    await _db.collection('videos').add({
      'userId': userId,
      'username': username,
      'profilePicUrl': profilePicUrl,
      'videoUrl': videoUrl,
      'description': description,
      'likesCount': 0,
      'commentsCount': 0,
      'likedBy': [],
      'createdAt': Timestamp.now(),
    });

    // Kullanıcının video sayısını artır
    await _db.collection('users').doc(userId).update({
      'videosCount': FieldValue.increment(1),
    });
  }

  // Videoyu sil
  Future<void> deleteVideo(String videoId, String userId) async {
    await _db.collection('videos').doc(videoId).delete();
    await _db.collection('users').doc(userId).update({
      'videosCount': FieldValue.increment(-1),
    });
  }

  // Yorumları getir
  Stream<List<CommentModel>> getComments(String videoId) {
    return _db
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(CommentModel.fromDoc).toList());
  }

  // Yorum ekle
  Future<void> addComment({
    required String videoId,
    required String userId,
    required String username,
    required String profilePicUrl,
    required String text,
  }) async {
    await _db
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .add({
      'userId': userId,
      'username': username,
      'profilePicUrl': profilePicUrl,
      'text': text,
      'createdAt': Timestamp.now(),
    });

    await _db.collection('videos').doc(videoId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }
}
