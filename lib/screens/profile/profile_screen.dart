import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../post/post_detail_screen.dart';
import '../../services/user_service.dart';
import '../../services/liquid_identity_service.dart';
import '../../widgets/user_avatar.dart';
import '../hub/liquid_identity_screen.dart';
import 'follow_list_screen.dart';
import 'saved_posts_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = '';
  String _email = '';
  int _points = 0;
  String _archetype = 'Creative & Analytical';
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;
  bool _followLoading = false;
  String _profilePicUrl = '';
  bool _twinEnabled = false;
  String _twinStatusLabel = '';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  final _userService = UserService();

  static const _bg = Color(0xFF03070D);

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;
  String? get _profileUid => widget.userId ?? _currentUid;
  bool get _isOwnProfile =>
      widget.userId == null || widget.userId == _currentUid;

  @override
  void initState() {
    super.initState();
    _subscribeProfile();
    _loadUser();
  }

  void _subscribeProfile() {
    final uid = _profileUid;
    if (uid == null) return;

    _profileSub?.cancel();
    _profileSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (!mounted || !doc.exists) return;
      final data = doc.data() ?? <String, dynamic>{};
      final twin = data['aiTwin'] as Map<String, dynamic>?;
      final twinEnabled = (twin?['enabled'] ?? false) as bool;
      final passiveMode = (twin?['passiveMode'] ?? false) as bool;
      final transparency = (twin?['identityLabel'] ?? '') as String;

      setState(() {
        _username = (data['username'] ?? '') as String;
        _email = _isOwnProfile ? (data['email'] ?? '') as String : '';
        _points = (data['points'] ?? 0) as int;
        _archetype = (data['archetype'] ?? 'Creative & Analytical') as String;
        _followersCount = (data['followersCount'] ?? 0) as int;
        _followingCount = (data['followingCount'] ?? 0) as int;
        _profilePicUrl = (data['profilePicUrl'] ?? '') as String;
        _twinEnabled = twinEnabled;
        _twinStatusLabel = twinEnabled
            ? (transparency.isNotEmpty
                ? transparency
                : (passiveMode ? 'İnsan AI asistanı' : 'AI desteği açık'))
            : '';
      });
    });
  }

  Future<void> _loadUser() async {
    final uid = _profileUid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted || !doc.exists) return;
    final data = doc.data() ?? {};
    final isFollowing =
        _isOwnProfile ? false : await _userService.isFollowing(uid);
    setState(() {
      _username = (data['username'] ?? '') as String;
      _email = _isOwnProfile ? (data['email'] ?? '') as String : '';
      _points = (data['points'] ?? 0) as int;
      _archetype = (data['archetype'] ?? 'Creative & Analytical') as String;
      _followersCount = (data['followersCount'] ?? 0) as int;
      _followingCount = (data['followingCount'] ?? 0) as int;
      _profilePicUrl = (data['profilePicUrl'] ?? '') as String;
      _isFollowing = isFollowing;
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  Future<void> _toggleFollow(String targetUid) async {
    setState(() => _followLoading = true);
    try {
      if (_isFollowing) {
        await _userService.unfollowUser(targetUid);
        _followersCount = (_followersCount - 1).clamp(0, 1 << 31);
      } else {
        await _userService.followUser(targetUid);
        _followersCount += 1;
      }
      // Check follow status again
      final isFollowing = await _userService.isFollowing(targetUid);
      if (mounted) {
        setState(() => _isFollowing = isFollowing);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  void _openFollowList({required bool showFollowers}) {
    final profileUid = _profileUid;
    if (profileUid == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListScreen(
          userId: profileUid,
          username: _username,
          showFollowers: showFollowers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profileUid = _profileUid;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Text('Profil',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (_isOwnProfile)
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white54),
                        onPressed: () => FirebaseAuth.instance.signOut(),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  children: [
                    // Avatar with glow
                    UserAvatar(
                      imageUrl: _profilePicUrl,
                      size: 96,
                      glow: true,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _username.isEmpty ? 'Vibeo' : '@$_username',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email.isEmpty
                          ? (_isOwnProfile ? (user?.email ?? '') : '')
                          : _email,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    if (_twinEnabled) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.purpleAccent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smart_toy,
                                size: 14, color: Colors.purpleAccent),
                            const SizedBox(width: 6),
                            Text(
                              _twinStatusLabel,
                              style: const TextStyle(
                                color: Colors.purpleAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Follow button (only for other users)
                    if (!_isOwnProfile)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          onPressed: _followLoading
                              ? null
                              : (profileUid == null
                                  ? null
                                  : () => _toggleFollow(profileUid)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing
                                ? Colors.transparent
                                : Colors.cyanAccent,
                            side: const BorderSide(
                              color: Colors.cyanAccent,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            _followLoading
                                ? '...'
                                : (_isFollowing ? 'Takibi Bırak' : 'Takip Et'),
                            style: TextStyle(
                              color: _isFollowing
                                  ? Colors.cyanAccent
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Live Score card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.cyanAccent.withValues(alpha: 0.18),
                        Colors.cyan.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.25),
                        blurRadius: 28,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bolt,
                                    color: Colors.cyanAccent, size: 14),
                                const SizedBox(width: 4),
                                Text('LIVE SCORE',
                                    style: TextStyle(
                                      color: Colors.cyanAccent
                                          .withValues(alpha: 0.9),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_points',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                height: 1,
                                shadows: [
                                  Shadow(
                                      color: Colors.cyanAccent, blurRadius: 16),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _archetype,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Colors.cyanAccent, Color(0xFF003333)],
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.6),
                                blurRadius: 20),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: Colors.black, size: 32),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('userId', isEqualTo: profileUid)
                    .snapshots(),
                builder: (context, snap) {
                  final count = snap.data?.docs.length ?? 0;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Row(
                      children: [
                        _StatBox(label: 'Vibeo', value: '$count'),
                        const SizedBox(width: 10),
                        _StatBox(
                          label: 'Takipçi',
                          value: '$_followersCount',
                          onTap: () => _openFollowList(showFollowers: true),
                        ),
                        const SizedBox(width: 10),
                        _StatBox(
                          label: 'Takip',
                          value: '$_followingCount',
                          onTap: () => _openFollowList(showFollowers: false),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: FutureBuilder<LiquidIdentitySnapshot>(
                  future: profileUid == null
                      ? null
                      : LiquidIdentityService.buildSnapshot(profileUid),
                  builder: (context, snapshot) {
                    final identity = snapshot.data;
                    if (identity == null) {
                      return const SizedBox.shrink();
                    }

                    final topLens =
                        identity.lenses.isEmpty ? null : identity.lenses.first;
                    if (topLens == null) return const SizedBox.shrink();

                    return GestureDetector(
                      onTap: _isOwnProfile
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LiquidIdentityScreen(),
                                ),
                              )
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.masks_outlined,
                                  color: Colors.cyanAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Liquid Identity',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (_isOwnProfile)
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.white38,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              topLens.title,
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              topLens.subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _IdentityBadge(
                                  label: topLens.contributionValue,
                                  accent: Colors.cyanAccent,
                                ),
                                _IdentityBadge(
                                  label: identity.zeroBiasMode,
                                  accent: Colors.greenAccent,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            if (_isOwnProfile)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedPostsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bookmark, color: Colors.cyanAccent),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Kaydedilen gönderilere git',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.grid_view_rounded,
                        color: Colors.cyanAccent, size: 16),
                    const SizedBox(width: 8),
                    Text('Eserlerin',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('userId', isEqualTo: profileUid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child:
                            CircularProgressIndicator(color: Colors.cyanAccent),
                      ),
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text('Henüz eserin yok',
                            style: TextStyle(color: Colors.white38)),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(
                                postId: docs[i].id,
                                imageUrl: data['imageUrl'] ?? '',
                                prompt: data['prompt'] ?? '',
                                username: _username,
                              ),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      Colors.cyanAccent.withValues(alpha: 0.2)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                data['imageUrl'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                  color: Colors.white10,
                                  child: Icon(Icons.broken_image,
                                      color: Colors.white24, size: 24),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatBox({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _IdentityBadge({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
