import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _sending = true);
    try {
      // Kullanıcı adını çek
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final username = (userDoc.exists && userDoc['username'] != null)
          ? userDoc['username'] as String
          : uid.substring(0, 6);

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'userId': uid,
        'username': username,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _ctrl.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Yorumlar',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const Divider(color: Colors.white12),

            // Yorum listesi
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.cyanAccent));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Henüz yorum yok. İlk yorumu yaz!',
                          style: TextStyle(color: Colors.white38)),
                    );
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    itemCount: docs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      return _CommentTile(
                        username: d['username'] ?? 'kullanıcı',
                        text: d['text'] ?? '',
                        createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
                      );
                    },
                  );
                },
              ),
            ),

            // Yorum yaz
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 12,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Yorum yaz...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.cyanAccent),
                        )
                      : IconButton(
                          onPressed: _send,
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.cyanAccent),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final String username;
  final String text;
  final DateTime? createdAt;
  const _CommentTile({
    required this.username,
    required this.text,
    this.createdAt,
  });

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}d';
    if (diff.inHours < 24) return '${diff.inHours}sa';
    return '${diff.inDays}g';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.cyanAccent,
            child: Icon(Icons.person, size: 18, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '@$username',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(createdAt),
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(text,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
