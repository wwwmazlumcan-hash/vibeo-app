import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/comment_model.dart';
import '../../providers/user_provider.dart';
import '../../services/video_service.dart';

class CommentsScreen extends StatefulWidget {
  final String videoId;
  const CommentsScreen({super.key, required this.videoId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentCtrl = TextEditingController();
  final _videoService = VideoService();
  bool _isSending = false;

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userProv = context.read<UserProvider>();
    final user = userProv.user;

    setState(() => _isSending = true);
    try {
      await _videoService.addComment(
        videoId: widget.videoId,
        userId: uid,
        username: user?.username ?? 'anonymous',
        profilePicUrl: user?.profilePicUrl ?? '',
        text: text,
      );
      _commentCtrl.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
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
            // Başlık
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
              child: StreamBuilder<List<CommentModel>>(
                stream: _videoService.getComments(widget.videoId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.cyanAccent),
                    );
                  }
                  final comments = snap.data ?? [];
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text('Henüz yorum yok. İlk yorumu yaz!',
                          style: TextStyle(color: Colors.white38)),
                    );
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    itemCount: comments.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (_, i) => _CommentTile(comment: comments[i]),
                  );
                },
              ),
            ),

            // Yorum yazma alanı
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
                      controller: _commentCtrl,
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
                  _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.cyanAccent),
                        )
                      : IconButton(
                          onPressed: _sendComment,
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
  final CommentModel comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.cyanAccent,
            backgroundImage: comment.profilePicUrl.isNotEmpty
                ? CachedNetworkImageProvider(comment.profilePicUrl)
                : null,
            child: comment.profilePicUrl.isEmpty
                ? const Icon(Icons.person, size: 18, color: Colors.black)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '@${comment.username}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt, locale: 'tr'),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(comment.text,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
