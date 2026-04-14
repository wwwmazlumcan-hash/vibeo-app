import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/comments/comments_screen.dart';
import '../services/moderation_service.dart';
import '../services/points_service.dart';

class VideoItem extends StatefulWidget {
  final String imageUrl;
  final String prompt;
  final String userId;
  final String postId;

  const VideoItem({
    super.key,
    required this.imageUrl,
    required this.prompt,
    required this.userId,
    this.postId = '',
  });

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  String _username = '';
  List<String> _likedBy = [];
  bool _liking = false;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isLiked => _likedBy.contains(_myUid);

  @override
  void initState() {
    super.initState();
    _loadUsername();
    if (widget.postId.isNotEmpty) _listenLikes();
  }

  void _loadUsername() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    if (!mounted) return;
    setState(() {
      _username = (doc.exists && doc['username'] != null)
          ? doc['username']
          : widget.userId.substring(0, widget.userId.length.clamp(0, 6));
    });
  }

  void _listenLikes() {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .snapshots()
        .listen((snap) {
      if (mounted && snap.exists) {
        setState(() {
          _likedBy = List<String>.from(
              (snap.data() as Map<String, dynamic>)['likedBy'] ?? []);
        });
      }
    });
  }

  Future<void> _toggleLike() async {
    if (_liking || widget.postId.isEmpty || _myUid.isEmpty) return;
    final wasLiked = _isLiked;
    setState(() {
      _liking = true;
      wasLiked ? _likedBy.remove(_myUid) : _likedBy.add(_myUid);
    });

    final ref =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    await ref.update({
      'likedBy': wasLiked
          ? FieldValue.arrayRemove([_myUid])
          : FieldValue.arrayUnion([_myUid]),
      'likesCount': FieldValue.increment(wasLiked ? -1 : 1),
    });

    // Award XP to post owner when liked
    if (!wasLiked && widget.userId != _myUid) {
      final ownerRef =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);
      await ownerRef.update({
        'points': FieldValue.increment(PointsService.pointsPerLikeReceived),
      });
    }

    if (mounted) setState(() => _liking = false);
  }

  void _showReport() {
    if (widget.postId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReportSheet(postId: widget.postId),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Görsel
        Image.network(
          widget.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, loading) {
            if (loading == null) return child;
            return const ColoredBox(
              color: Colors.black,
              child: Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent)),
            );
          },
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Colors.black,
            child: Center(
                child: Icon(Icons.broken_image, color: Colors.white24, size: 60)),
          ),
        ),

        // Alt gradient
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
              stops: [0.4, 1.0],
            ),
          ),
        ),

        // Sol alt — kullanıcı ve prompt
        Positioned(
          left: 15,
          right: 85,
          bottom: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.cyanAccent,
                    child: Icon(Icons.person, size: 18, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _username.isEmpty ? '...' : '@$_username',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.prompt,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Sağ — butonlar
        Positioned(
          right: 12,
          bottom: 30,
          child: Column(
            children: [
              // Like
              GestureDetector(
                onTap: _toggleLike,
                child: Column(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.redAccent : Colors.white,
                      size: 34,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _fmt(_likedBy.length),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Yorum
              GestureDetector(
                onTap: widget.postId.isEmpty
                    ? null
                    : () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              CommentsScreen(postId: widget.postId),
                        ),
                child: const _ActionBtn(
                    icon: Icons.comment_rounded, label: 'Yorum'),
              ),
              const SizedBox(height: 22),

              // Paylaş
              const _ActionBtn(icon: Icons.share_rounded, label: 'Paylaş'),
              const SizedBox(height: 22),

              // Şikayet
              GestureDetector(
                onTap: _showReport,
                child: const _ActionBtn(
                    icon: Icons.flag_outlined, label: 'Bildir'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionBtn({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}

class _ReportSheet extends StatelessWidget {
  final String postId;
  const _ReportSheet({required this.postId});

  static const _reasons = [
    'Spam veya yanıltıcı içerik',
    'Nefret söylemi',
    'Şiddet içeriği',
    'Uygunsuz içerik',
    'Telif hakkı ihlali',
    'Diğer',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('İçeriği Bildir',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Neden bildiriyorsunuz?',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 16),
          ..._reasons.map((r) => ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
                title: Text(r, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  await ModerationService.reportPost(
                      postId: postId, reason: r);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bildiriminiz alındı. Teşekkürler.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
