import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/stories_bar.dart';
import '../../services/points_service.dart';
import '../comments/comments_screen.dart';
import '../post/post_detail_screen.dart';
import '../challenges/challenges_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — logo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    child: const Icon(Icons.person_outline,
                        color: Colors.white70, size: 18),
                  ),
                  const Spacer(),
                  _GlowLogo(),
                  const Spacer(),
                  Icon(Icons.chat_bubble_outline,
                      color: Colors.white.withValues(alpha: 0.7), size: 20),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stories bar
            const StoriesBar(),
            const SizedBox(height: 4),

            // Challenge banner
            _ChallengeBanner(),
            const SizedBox(height: 8),

            // Headline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Bugün senin vibe'ına uygun\niçerikler",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                  _GlowButton(icon: Icons.tune),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Feed list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const FeedShimmer();
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Bir hata oluştu',
                          style: TextStyle(color: Colors.white54)),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 60,
                              color: Colors.cyanAccent.withValues(alpha: 0.15)),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz hiç Vibeo yok.\nİlkini sen üret!',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white54, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return _VibeCard(
                        postId: docs[i].id,
                        imageUrl: data['imageUrl'] ?? '',
                        prompt: data['prompt'] ?? '',
                        userId: data['userId'] ?? '',
                        likesCount: (data['likesCount'] ?? 0) as int,
                        likedBy: List<String>.from(data['likedBy'] ?? []),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── LOGO ────────────────────────────────────────────────────────────────────

class _GlowLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Colors.cyanAccent, Color(0xFF006666)],
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.6),
                  blurRadius: 10),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'vibeo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}

class _GlowButton extends StatelessWidget {
  final IconData icon;
  const _GlowButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.cyanAccent.withValues(alpha: 0.08),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 12)
        ],
      ),
      child: Icon(icon, color: Colors.cyanAccent, size: 16),
    );
  }
}

// ─── CHALLENGE BANNER ─────────────────────────────────────────────────────────
class _ChallengeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChallengesScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: [
            Colors.cyanAccent.withValues(alpha: 0.15),
            Colors.purpleAccent.withValues(alpha: 0.1),
          ]),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Haftanın Challenge',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text('Neon Şehir  •  ⏰ 2 gün kaldı  •  500 XP',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.cyanAccent, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── VIBE CARD ───────────────────────────────────────────────────────────────

class _VibeCard extends StatefulWidget {
  final String postId;
  final String imageUrl;
  final String prompt;
  final String userId;
  final int likesCount;
  final List<String> likedBy;

  const _VibeCard({
    required this.postId,
    required this.imageUrl,
    required this.prompt,
    required this.userId,
    required this.likesCount,
    required this.likedBy,
  });

  @override
  State<_VibeCard> createState() => _VibeCardState();
}

class _VibeCardState extends State<_VibeCard> {
  String _username = '...';
  late List<String> _likedBy;
  late int _likesCount;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isLiked => _likedBy.contains(_myUid);

  @override
  void initState() {
    super.initState();
    _likedBy = List.from(widget.likedBy);
    _likesCount = widget.likesCount;
    _loadUsername();
  }

  Future<void> _loadUsername() async {
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

  Future<void> _toggleLike() async {
    if (_myUid.isEmpty) return;
    final wasLiked = _isLiked;
    setState(() {
      if (wasLiked) {
        _likedBy.remove(_myUid);
        _likesCount--;
      } else {
        _likedBy.add(_myUid);
        _likesCount++;
      }
    });

    final ref =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    await ref.update({
      'likedBy': wasLiked
          ? FieldValue.arrayRemove([_myUid])
          : FieldValue.arrayUnion([_myUid]),
      'likesCount': FieldValue.increment(wasLiked ? -1 : 1),
    });

    if (!wasLiked && widget.userId != _myUid) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'points':
            FieldValue.increment(PointsService.pointsPerLikeReceived),
      });
    }
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _openDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          postId: widget.postId,
          imageUrl: widget.imageUrl,
          prompt: widget.prompt,
          username: _username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF0B141D),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Image
          GestureDetector(
            onTap: _openDetail,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                  child: AspectRatio(
                    aspectRatio: 16 / 11,
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, l) {
                        if (l == null) return child;
                        return const ColoredBox(
                          color: Colors.black,
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: Colors.cyanAccent)),
                        );
                      },
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Colors.black,
                        child: Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.white24, size: 50)),
                      ),
                    ),
                  ),
                ),

                // AI Enhanced badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Colors.cyanAccent, size: 12),
                        SizedBox(width: 4),
                        Text('AI Enhanced',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.prompt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Stats row
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.favorite,
                      value: _fmt(_likesCount),
                      active: _isLiked,
                      onTap: _toggleLike,
                    ),
                    const SizedBox(width: 16),
                    _MiniStat(
                      icon: Icons.comment_rounded,
                      value: _fmt(_likesCount ~/ 3 + 1),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            CommentsScreen(postId: widget.postId),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // User row
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.cyanAccent,
                        child: Icon(Icons.person,
                            color: Colors.black, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _username.isEmpty ? '...' : _username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'AI festival 4 gönderini',
                              style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.more_horiz,
                          color: Colors.white38, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool active;
  final VoidCallback? onTap;

  const _MiniStat({
    required this.icon,
    required this.value,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon,
              color: active ? Colors.redAccent : Colors.cyanAccent, size: 15),
          const SizedBox(width: 5),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
