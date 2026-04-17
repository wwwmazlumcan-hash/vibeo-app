// Vibes — TikTok tarzı dikey kaydırmalı AI içerik akışı
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/points_service.dart';
import '../comments/comments_screen.dart';
import '../post/post_detail_screen.dart';

class VibesScreen extends StatefulWidget {
  const VibesScreen({super.key});

  @override
  State<VibesScreen> createState() => _VibesScreenState();
}

class _VibesScreenState extends State<VibesScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {},
              child: const Text('Takip',
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
            const SizedBox(width: 16),
            const Text('Vibes',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {},
              child: const Text('Keşfet',
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome,
                      color: Colors.cyanAccent, size: 48),
                  SizedBox(height: 16),
                  Text('Henüz vibe yok',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }
          return PageView.builder(
            controller: _pageCtrl,
            scrollDirection: Axis.vertical,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              return _VibePage(doc: docs[i], isActive: i == _currentPage);
            },
          );
        },
      ),
    );
  }
}

class _VibePage extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final bool isActive;

  const _VibePage({required this.doc, required this.isActive});

  @override
  State<_VibePage> createState() => _VibePageState();
}

class _VibePageState extends State<_VibePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _liked = false;
  bool _saved = false;

  Future<void> _toggleLike() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final newLiked = !_liked;
    setState(() => _liked = newLiked);

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.doc.id)
        .update({
      'likes': FieldValue.increment(newLiked ? 1 : -1),
    });

    if (newLiked) {
      await PointsService.award(2, reason: 'like_given');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final d = widget.doc.data() as Map<String, dynamic>;
    final imageUrl = d['imageUrl'] as String? ?? '';
    final prompt = d['prompt'] as String? ?? '';
    final username = d['username'] as String? ?? 'anonim';
    final likes = d['likes'] as int? ?? 0;
    final commentCount = d['commentCount'] as int? ?? 0;
    final avatarUrl = d['avatarUrl'] as String?;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen image
        imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: Colors.cyanAccent),
                    ),
                  );
                },
              )
            : Container(color: Colors.black12),

        // Bottom gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 280,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),

        // Right action bar
        Positioned(
          right: 12,
          bottom: 120,
          child: Column(
            children: [
              _VibeAction(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                color: _liked ? Colors.redAccent : Colors.white,
                label: '${likes + (_liked ? 1 : 0)}',
                onTap: _toggleLike,
                glowing: _liked,
              ),
              const SizedBox(height: 20),
              _VibeAction(
                icon: Icons.comment_outlined,
                label: '$commentCount',
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CommentsScreen(postId: widget.doc.id),
                ),
              ),
              const SizedBox(height: 20),
              _VibeAction(
                icon: _saved ? Icons.bookmark : Icons.bookmark_border,
                color: _saved ? Colors.cyanAccent : Colors.white,
                label: 'Kaydet',
                glowing: _saved,
                onTap: () => setState(() => _saved = !_saved),
              ),
              const SizedBox(height: 20),
              _VibeAction(
                icon: Icons.auto_awesome,
                label: 'Remix',
                color: Colors.cyanAccent,
                glowing: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PostDetailScreen(
                            postId: widget.doc.id,
                            imageUrl: imageUrl,
                            prompt: prompt,
                            username: username,
                          )),
                ),
              ),
              const SizedBox(height: 20),
              _VibeAction(
                icon: Icons.share_outlined,
                label: 'Paylaş',
                onTap: () {},
              ),
            ],
          ),
        ),

        // Bottom info
        Positioned(
          left: 16,
          right: 80,
          bottom: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User row
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        Colors.cyanAccent.withValues(alpha: 0.3),
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text('@$username',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white70),
                    ),
                    child: const Text('Takip Et',
                        style:
                            TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Prompt
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Colors.cyanAccent, size: 12),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        prompt,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // AI badge top-right
        const Positioned(
          top: 100,
          right: 12,
          child: _AiBadge(),
        ),

        // Swipe hint
        if (widget.isActive)
          const Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.keyboard_arrow_up,
                  color: Colors.white24, size: 20),
            ),
          ),
      ],
    );
  }
}

class _VibeAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool glowing;
  final VoidCallback? onTap;

  const _VibeAction({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    this.glowing = false,
    this.onTap,
  });

  @override
  State<_VibeAction> createState() => _VibeActionState();
}

class _VibeActionState extends State<_VibeAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 1.3)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _ctrl.forward();
        await _ctrl.reverse();
        widget.onTap?.call();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          children: [
            Icon(
              widget.icon,
              color: widget.color,
              size: 28,
              shadows: widget.glowing
                  ? [Shadow(color: widget.color, blurRadius: 12)]
                  : null,
            ),
            const SizedBox(height: 3),
            Text(widget.label,
                style: TextStyle(color: widget.color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 11),
          SizedBox(width: 4),
          Text('AI',
              style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
