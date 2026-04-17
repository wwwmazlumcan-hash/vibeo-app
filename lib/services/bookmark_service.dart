import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing bookmarks (saved posts)
class BookmarkService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> toggleSaved(String postId, {required bool isSaved}) {
    return isSaved ? unsavePost(postId) : savePost(postId);
  }

  /// Save a post to bookmarks
  static Future<void> savePost(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db.collection('users').doc(uid).set({
        'saved': FieldValue.arrayUnion([postId]),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error saving post: $e');
    }
  }

  /// Remove a post from bookmarks
  static Future<void> unsavePost(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db.collection('users').doc(uid).set({
        'saved': FieldValue.arrayRemove([postId]),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error unsaving post: $e');
    }
  }

  /// Check if a post is saved by current user
  static Future<bool> isSaved(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      final saved = List<String>.from(doc.data()?['saved'] ?? []);
      return saved.contains(postId);
    } catch (e) {
      return false;
    }
  }

  /// Get all saved posts for current user
  static Future<List<String>> getSavedPostIds() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      final doc = await _db.collection('users').doc(uid).get();
      return List<String>.from(doc.data()?['saved'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Stream saved posts real-time
  static Stream<List<String>> streamSavedPostIds() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _db.collection('users').doc(uid).snapshots().map((doc) {
      return List<String>.from(doc.data()?['saved'] ?? []);
    });
  }
}
