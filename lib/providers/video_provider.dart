import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import '../services/storage_service.dart';

class VideoProvider extends ChangeNotifier {
  final VideoService _videoService = VideoService();
  final StorageService _storageService = StorageService();

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;

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
