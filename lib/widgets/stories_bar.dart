import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// TikTok/Instagram style stories bar at the top of feed.
class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .limit(20)
            .snapshots(),
        builder: (context, snap) {
          final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
          final docs = snap.data?.docs ?? [];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: docs.length + 1,
            itemBuilder: (context, i) {
              // First item: "My Story" (add story button)
              if (i == 0) {
                return const _StoryAvatar(
                  label: 'Senin',
                  isMe: true,
                  isOnline: true,
                );
              }

              final doc = docs[i - 1];
              final data = doc.data() as Map<String, dynamic>;
              if (doc.id == myUid) return const SizedBox.shrink();

              return _StoryAvatar(
                label: data['username'] ?? '...',
                isOnline: i % 3 == 0, // simulated online status
              );
            },
          );
        },
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String label;
  final bool isMe;
  final bool isOnline;

  const _StoryAvatar({
    required this.label,
    this.isMe = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isMe
                      ? null
                      : const LinearGradient(
                          colors: [Colors.cyanAccent, Colors.purpleAccent],
                        ),
                  border:
                      isMe ? Border.all(color: Colors.white24, width: 2) : null,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade900,
                  child: isMe
                      ? const Icon(Icons.add,
                          color: Colors.cyanAccent, size: 26)
                      : const Icon(Icons.person,
                          color: Colors.white54, size: 26),
                ),
              ),
              if (isOnline && !isMe)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isMe ? 'Ekle' : label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
