import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/video_item.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/stories_bar.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'vibeo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text("Bir hata oluştu!",
                    style: TextStyle(color: Colors.white)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const FeedShimmer();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 60, color: Colors.white12),
                  const SizedBox(height: 16),
                  const Text(
                    "Henüz hiç Vibeo yok.\nİlkini sen üret!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return Stack(
            children: [
              // Main vertical feed
              PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return VideoItem(
                    imageUrl: data['imageUrl'] ?? '',
                    prompt: data['prompt'] ?? 'AI Vibeo',
                    userId: data['userId'] ?? 'Unknown',
                    postId: docs[index].id,
                  );
                },
              ),

              // Stories bar overlay at top
              Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: const StoriesBar(),
              ),
            ],
          );
        },
      ),
    );
  }
}
