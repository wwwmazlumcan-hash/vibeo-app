import 'package:flutter/material.dart';

class VideoItem extends StatelessWidget {
  final String imageUrl;
  final String prompt;
  final String userId;

  const VideoItem({
    super.key,
    required this.imageUrl,
    required this.prompt,
    required this.userId,
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
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),

        // Alt Karartma
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
        ),

        // Prompt Yazısı
        Positioned(
          left: 10,
          bottom: 10,
          right: 10,
          child: Text(
            prompt,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
