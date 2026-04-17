import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

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
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
        'reactions': {}, // Initialize empty reactions map
      });

      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();
      final postOwnerUid = (postDoc.data()?['userId'] ?? '') as String;
      if (postOwnerUid.isNotEmpty && postOwnerUid != uid) {
        await NotificationService.sendCommentNotification(
          toUid: postOwnerUid,
          postId: widget.postId,
          commentText: text,
        );
      }

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
        decoration: BoxDecoration(
          color: const Color(0xFF0B141D),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: -4),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Yorumlar',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Divider(color: Colors.cyanAccent.withValues(alpha: 0.15)),
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
                        child: CircularProgressIndicator(
                            color: Colors.cyanAccent));
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
                        postId: widget.postId,
                        commentId: docs[i].id,
                        userId: d['userId'] ?? '',
                        username: d['username'] ?? 'kullanıcı',
                        text: d['text'] ?? '',
                        createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
                        reactions:
                            Map<String, String>.from(d['reactions'] ?? {}),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 12,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: Colors.cyanAccent.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.2)),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Yorum yaz...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
                      : GestureDetector(
                          onTap: _send,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Colors.cyanAccent, Color(0xFF006666)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.cyanAccent
                                        .withValues(alpha: 0.5),
                                    blurRadius: 10),
                              ],
                            ),
                            child: const Icon(Icons.send_rounded,
                                color: Colors.black, size: 18),
                          ),
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

class _CommentTile extends StatefulWidget {
  final String postId;
  final String commentId;
  final String userId;
  final String username;
  final String text;
  final DateTime? createdAt;
  final Map<String, String> reactions;

  const _CommentTile({
    required this.postId,
    required this.commentId,
    required this.userId,
    required this.username,
    required this.text,
    this.createdAt,
    this.reactions = const {},
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  final _emojis = ['❤️', '😂', '😮', '😢', '🔥'];
  bool _showReactionPicker = false;

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}d';
    if (diff.inHours < 24) return '${diff.inHours}sa';
    return '${diff.inDays}g';
  }

  Future<void> _addReaction(String emoji) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(widget.commentId)
          .update({
        'reactions.$myUid': emoji,
      });
      setState(() => _showReactionPicker = false);
    } catch (e) {
      debugPrint('Error adding reaction: $e');
    }
  }

  Future<void> _removeReaction() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(widget.commentId)
          .update({
        'reactions.$myUid': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('Error removing reaction: $e');
    }
  }

  Map<String, int> _getReactionCounts() {
    final counts = <String, int>{};
    for (var emoji in widget.reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final myReaction = widget.reactions[myUid];
    final reactionCounts = _getReactionCounts();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Colors.cyanAccent, Color(0xFF006666)],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.3),
                        blurRadius: 6),
                  ],
                ),
                child: const Icon(Icons.person, size: 18, color: Colors.black),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('@${widget.username}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                                fontSize: 13)),
                        const SizedBox(width: 8),
                        Text(_timeAgo(widget.createdAt),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(widget.text,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              // Emoji picker button
              GestureDetector(
                onTap: () =>
                    setState(() => _showReactionPicker = !_showReactionPicker),
                child: Icon(Icons.emoji_emotions_outlined,
                    color: Colors.cyanAccent.withValues(alpha: 0.6), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Reaction picker (emoji buttons)
          if (_showReactionPicker)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              child: Wrap(
                spacing: 4,
                children: _emojis
                    .map(
                      (emoji) => GestureDetector(
                        onTap: () => _addReaction(emoji),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.cyanAccent.withValues(alpha: 0.2),
                            ),
                          ),
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          // Reaction display (emoji counts)
          if (reactionCounts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 4,
                children: reactionCounts.entries
                    .map(
                      (entry) => GestureDetector(
                        onTap: myReaction == entry.key
                            ? _removeReaction
                            : () => _addReaction(entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: myReaction == entry.key
                                ? Colors.cyanAccent.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: myReaction == entry.key
                                  ? Colors.cyanAccent
                                  : Colors.cyanAccent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(entry.key,
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 3),
                              Text(
                                '${entry.value}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
