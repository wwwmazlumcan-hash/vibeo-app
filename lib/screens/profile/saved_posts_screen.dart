import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/bookmark_service.dart';
import '../post/post_detail_screen.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF03070D),
        title: const Text('Kaydedilenler'),
      ),
      body: StreamBuilder<List<String>>(
        stream: BookmarkService.streamSavedPostIds(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          final ids = snap.data ?? [];
          if (ids.isEmpty) {
            return const Center(
              child: Text('Henüz kaydedilmiş içerik yok.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
            );
          }

          final batch = ids.length > 10 ? ids.take(10).toList() : ids;
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('posts')
                .where(FieldPath.documentId, whereIn: batch)
                .get(),
            builder: (context, postsSnap) {
              if (postsSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent));
              }

              final docs = postsSnap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text('Kaydedilen gönderiler yüklenemedi.',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  itemCount: docs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(
                              postId: docs[index].id,
                              imageUrl: data['imageUrl'] ?? '',
                              prompt: data['prompt'] ?? '',
                              username: data['username'] ?? '',
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          data['imageUrl'] ?? '',
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, loading) {
                            if (loading == null) return child;
                            return const ColoredBox(
                              color: Colors.black,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.cyanAccent)),
                            );
                          },
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Colors.white10,
                            child: Icon(Icons.broken_image,
                                color: Colors.white24, size: 26),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
