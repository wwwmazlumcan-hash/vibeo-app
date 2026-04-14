import 'package:flutter/material.dart';

class VideoItem extends StatelessWidget {
  final String imageUrl;
  final String prompt;
  final String userId; // HATAYI ÇÖZEN SATIR: Tanımlama eklendi

  const VideoItem({
    super.key,
    required this.imageUrl,
    required this.prompt,
    required this.userId, // HATAYI ÇÖZEN SATIR: Constructor'a eklendi
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // AI Görseli
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent));
          },
          errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
        ),

        // Alt Karartma Gradyanı
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
        ),

        // Yazılar (Kullanıcı ve Prompt)
        Positioned(
          left: 15,
          bottom: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.cyanAccent,
                    child: Icon(Icons.person, size: 18, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "User: ${userId.substring(0, 5)}...", // userId'yi burada kullanıyoruz
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Text(
                  prompt,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Sağ Menü Butonları
        Positioned(
          right: 15,
          bottom: 100,
          child: Column(
            children: [
              _buildActionButton(Icons.favorite, "Like"),
              const SizedBox(height: 20),
              _buildActionButton(Icons.comment, "Reply"),
              const SizedBox(height: 20),
              _buildActionButton(Icons.share, "Share"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}
