import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/comments/comments_screen.dart';
import '../services/bookmark_service.dart';
import '../services/moderation_service.dart';
import '../services/notification_service.dart';
import '../services/points_service.dart';
import '../services/reality_layer_service.dart';
import 'user_avatar.dart';

class VideoItem extends StatefulWidget {
  final String imageUrl;
  final String prompt;
  final String userId;
  final String postId;
  final String contentOriginLabel;
  final int proofHumanScore;
  final int proofAiScore;
  final List<String> recommendationReasons;

  const VideoItem({
    super.key,
    required this.imageUrl,
    required this.prompt,
    required this.userId,
    this.postId = '',
    this.contentOriginLabel = '',
    this.proofHumanScore = 0,
    this.proofAiScore = 0,
    this.recommendationReasons = const [],
  });

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  String _username = '';
  String _profilePicUrl = '';
  List<String> _likedBy = [];
  bool _liking = false;
  bool _saved = false;
  bool _saving = false;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isLiked => _likedBy.contains(_myUid);

  @override
  void initState() {
    super.initState();
    if (widget.postId.isNotEmpty) _loadSavedStatus();
    _loadUsername();
    if (widget.postId.isNotEmpty) _listenLikes();
  }

  Future<void> _loadSavedStatus() async {
    if (widget.postId.isEmpty || _myUid.isEmpty) return;
    final saved = await BookmarkService.isSaved(widget.postId);
    if (!mounted) return;
    setState(() => _saved = saved);
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
      _profilePicUrl = (doc.data()?['profilePicUrl'] ?? '') as String;
    });
  }

  void _showTransparencySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Neden bunu görüyorsun?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.recommendationReasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.fiber_manual_record,
                          size: 8, color: Colors.cyanAccent),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(
                            color: Colors.white70, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRealityLayerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      builder: (_) {
        var mode = RealityLayerMode.balanced;
        var future = RealityLayerService.adapt(
          prompt: widget.prompt,
          contentOriginLabel: widget.contentOriginLabel,
          proofHumanScore: widget.proofHumanScore,
          proofAiScore: widget.proofAiScore,
          mode: mode,
        );

        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dinamik Gerçeklik Katmanı',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RealityLayerMode.values.map((item) {
                    final selected = item == mode;
                    return ChoiceChip(
                      label: Text(_realityModeLabel(item)),
                      selected: selected,
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: Colors.cyanAccent,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      onSelected: (_) {
                        setModalState(() {
                          mode = item;
                          future = RealityLayerService.adapt(
                            prompt: widget.prompt,
                            contentOriginLabel: widget.contentOriginLabel,
                            proofHumanScore: widget.proofHumanScore,
                            proofAiScore: widget.proofAiScore,
                            mode: mode,
                          );
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                FutureBuilder<RealityLayerResult>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.cyanAccent,
                          ),
                        ),
                      );
                    }

                    final result = snapshot.data;
                    if (result == null) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.title,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.summary,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoChip(
                          label: result.signature,
                          accent: Colors.greenAccent,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          result.accessibilityHint,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _realityModeLabel(RealityLayerMode mode) {
    switch (mode) {
      case RealityLayerMode.balanced:
        return 'Dengeli';
      case RealityLayerMode.child:
        return 'Çocuk';
      case RealityLayerMode.expert:
        return 'Uzman';
      case RealityLayerMode.audio:
        return 'Sesli';
      case RealityLayerMode.haptic:
        return 'Haptic';
    }
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
      await NotificationService.sendLikeNotification(
        toUid: widget.userId,
        postId: widget.postId,
      );
    }

    if (mounted) setState(() => _liking = false);
  }

  Future<void> _toggleSave() async {
    if (widget.postId.isEmpty || _saving || _myUid.isEmpty) return;
    setState(() => _saving = true);
    try {
      if (_saved) {
        await BookmarkService.unsavePost(widget.postId);
      } else {
        await BookmarkService.savePost(widget.postId);
      }
      if (mounted) setState(() => _saved = !_saved);
    } catch (e) {
      debugPrint('Error toggling save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                child:
                    Icon(Icons.broken_image, color: Colors.white24, size: 60)),
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
                  UserAvatar(imageUrl: _profilePicUrl, size: 32),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.contentOriginLabel.isNotEmpty)
                    _InfoChip(
                        label: widget.contentOriginLabel,
                        accent: Colors.purpleAccent),
                  if (widget.proofHumanScore > 0)
                    _InfoChip(
                        label: 'H ${widget.proofHumanScore}',
                        accent: Colors.orangeAccent),
                  if (widget.proofAiScore > 0)
                    _InfoChip(
                        label: 'AI ${widget.proofAiScore}',
                        accent: Colors.cyanAccent),
                ],
              ),
              if (widget.contentOriginLabel.isNotEmpty ||
                  widget.proofHumanScore > 0 ||
                  widget.proofAiScore > 0)
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
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showTransparencySheet,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 12, color: Colors.white70),
                      SizedBox(width: 6),
                      Text(
                        'Neden bunu görüyorum?',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showRealityLayerSheet,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.layers_outlined,
                          size: 12, color: Colors.cyanAccent),
                      SizedBox(width: 6),
                      Text(
                        'Reality Layer',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
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
                          builder: (_) => CommentsScreen(postId: widget.postId),
                        ),
                child: const _ActionBtn(
                    icon: Icons.comment_rounded, label: 'Yorum'),
              ),
              const SizedBox(height: 22),

              // Paylaş
              const _ActionBtn(icon: Icons.share_rounded, label: 'Paylaş'),
              const SizedBox(height: 22),

              // Kaydet
              GestureDetector(
                onTap: _toggleSave,
                child: Column(
                  children: [
                    Icon(
                      _saved ? Icons.bookmark : Icons.bookmark_border,
                      color: _saved ? Colors.cyanAccent : Colors.white,
                      size: 30,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _saving ? '...' : (_saved ? 'Kaydedildi' : 'Kaydet'),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
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

class _InfoChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _InfoChip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
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
                leading:
                    const Icon(Icons.flag_outlined, color: Colors.redAccent),
                title: Text(r, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  await ModerationService.reportPost(postId: postId, reason: r);
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
