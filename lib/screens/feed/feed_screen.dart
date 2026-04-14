import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/video_item.dart'; // Bu yolun doğruluğundan emin ol

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        // Firestore'daki 'posts' koleksiyonuna bağlanıyoruz
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Hata kontrolü
          if (snapshot.hasError) {
            return const Center(
                child: Text("Bir hata oluştu!",
                    style: TextStyle(color: Colors.white)));
          }

          // Yükleniyor durumu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          // Veri boşsa
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Henüz hiç Vibeo yok.\nİlkini sen üret!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54)),
            );
          }

          final docs = snapshot.data!.docs;

          // TikTok stili dikey kaydırma için PageView
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // Her bir dokümanı (post) alıyoruz
              final data = docs[index].data() as Map<String, dynamic>;

              // HATALARI ÇÖZEN KRİTİK NOKTA: Burası mutlaka bir Widget RETURN etmeli!
              return VideoItem(
                imageUrl: data['imageUrl'] ?? '',
                prompt: data['prompt'] ?? 'AI Vibeo',
                userId: data['userId'] ?? 'Unknown',
              );
            },
          );
        },
      ),
    );
  }
}
