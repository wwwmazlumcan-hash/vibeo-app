import 'package:cloud_firestore/cloud_firestore.dart';

class HashtagService {
  static final _db = FirebaseFirestore.instance;
  static final _hashtagRegex = RegExp(r'(?:^|\s)#([a-zA-Z0-9_çğıöşüÇĞİÖŞÜ]+)');

  static List<String> extractHashtags(String text) {
    final tags = <String>{};
    for (final match in _hashtagRegex.allMatches(text)) {
      final raw = match.group(1);
      if (raw == null || raw.isEmpty) continue;
      tags.add(raw.toLowerCase());
    }
    return tags.toList()..sort();
  }

  static Stream<List<String>> trendingHashtags(
      {int postLimit = 50, int tagLimit = 12}) {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(postLimit)
        .snapshots()
        .map((snapshot) {
      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final hashtags = List<String>.from(data['hashtags'] ?? []);
        for (final tag in hashtags) {
          counts[tag] = (counts[tag] ?? 0) + 1;
        }
      }

      final ranked = counts.entries.toList()
        ..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          return byCount != 0 ? byCount : a.key.compareTo(b.key);
        });

      return ranked.take(tagLimit).map((entry) => entry.key).toList();
    });
  }
}
