import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Video dosyasını Firebase Storage'a yükler, download URL döner.
  Future<String> uploadVideo(File file, String userId) async {
    final fileName = '${_uuid.v4()}.mp4';
    final ref = _storage.ref().child('videos/$userId/$fileName');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'video/mp4'),
    );
    return await task.ref.getDownloadURL();
  }

  /// Profil fotoğrafını Firebase Storage'a yükler, download URL döner.
  Future<String> uploadProfilePic(File file, String userId) async {
    final ref = _storage.ref().child('profiles/$userId/avatar.jpg');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }
}
