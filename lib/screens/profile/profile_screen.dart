import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_metadata.dart';
import '../post/post_detail_screen.dart';
import '../../services/user_service.dart';
import '../../services/liquid_identity_service.dart';
import '../../services/surprise_engine_service.dart';
import '../../widgets/user_avatar.dart';
import '../hub/liquid_identity_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../social/social_os_screen.dart';
import 'follow_list_screen.dart';
import 'saved_posts_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/edit_profile_screen.dart';
import '../../services/block_service.dart';

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
  bool _accountDeletionLoading = false;
  String _profilePicUrl = '';
  bool _twinEnabled = false;
  String _twinStatusLabel = '';
  String _identityMode = 'fluid';
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
        _identityMode = (data['identityMode'] ?? 'fluid') as String;
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
      _identityMode = (data['identityMode'] ?? 'fluid') as String;
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

  Future<void> _requestStoreReview() async {
    final review = InAppReview.instance;
    final canRequest = await review.isAvailable();
    if (!canRequest || !mounted) return;
    await review.requestReview();
  }

  Future<void> _openSupportEmail({String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppMetadata.supportEmail,
      queryParameters: {
        if (subject != null) 'subject': subject,
      },
    );

    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destek e-postasi acilamadi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openWebsite() async {
    final uri = Uri.parse(AppMetadata.websiteUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Web sitesi acilamadi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hesabi Sil'),
            content: const Text(
              'Bu islem geri alinamaz. Profilin, paylasimlarin, hikayelerin ve temel hesap verilerin silinir.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgec'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Kalici Olarak Sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() => _accountDeletionLoading = true);
    try {
      await _userService.deleteCurrentUserAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesabin silindi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _accountDeletionLoading = false);
    }
  }

  void _showUserActions(String targetUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B141D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.volume_off,
                  color: Colors.orangeAccent),
              title: const Text('Sessize Al',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Paylaşımları feed\'inde görünmez',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await BlockService.muteUser(targetUid);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kullanıcı sessize alındı')),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.block, color: Colors.redAccent),
              title: const Text('Engelle',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Seni takip edemez, mesaj atamaz',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Engellemek istediğinden emin misin?'),
                    content: const Text(
                      'Bu kullanıcı seni takip edemeyecek, mesaj atamayacak ve paylaşımlarını göremeyecek.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Vazgeç'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text('Engelle'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                await BlockService.blockUser(targetUid);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kullanıcı engellendi')),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.flag_outlined, color: Colors.amber),
              title: const Text('Şikayet Et',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Spam, taciz veya uygunsuz içerik',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showReportDialog(targetUid);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(String targetUid) {
    const reasons = [
      'Spam',
      'Taciz veya zorbalık',
      'Uygunsuz içerik',
      'Sahte hesap',
      'Telif ihlali',
      'Diğer',
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şikayet nedeni'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons
              .map((r) => ListTile(
                    title: Text(r,
                        style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await BlockService.reportUser(targetUid, r);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Şikayetin alındı. İnceleyeceğiz.')),
                      );
                    },
                  ))
              .toList(),
        ),
      ),
    );
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
                    if (_isOwnProfile) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.white54),
                        tooltip: 'Profili Düzenle',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: Colors.white54),
                        tooltip: 'Ayarlar',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    ],
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
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        'Kimlik modu: $_identityMode',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Follow button (only for other users)
                    if (!_isOwnProfile)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                                    : (_isFollowing
                                        ? 'Takibi Bırak'
                                        : 'Takip Et'),
                                style: TextStyle(
                                  color: _isFollowing
                                      ? Colors.cyanAccent
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.more_horiz,
                                color: Colors.white70),
                            tooltip: 'Daha fazla',
                            onPressed: profileUid == null
                                ? null
                                : () => _showUserActions(profileUid),
                          ),
                        ],
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
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('userId', isEqualTo: profileUid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ??
                        const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                    if (docs.length < 2) {
                      return const SizedBox.shrink();
                    }

                    final report = SurpriseEngineService.buildVibeDna(
                      docs.map((doc) => doc.data()).toList(),
                      username: _username,
                    );

                    return _VibeDnaCard(report: report);
                  },
                ),
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
                  child: Column(
                    children: [
                      _ProfileActionCard(
                        icon: Icons.auto_awesome_motion,
                        label: 'Social OS merkezi',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SocialOsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileActionCard(
                        icon: Icons.bookmark,
                        label: 'Kaydedilen gönderilere git',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavedPostsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ProfileActionCard(
                        icon: Icons.star_outline,
                        label: 'Uygulamayi degerlendir',
                        onTap: _requestStoreReview,
                      ),
                      const SizedBox(height: 12),
                      _ProfileActionCard(
                        icon: Icons.mail_outline,
                        label: 'Destek iletisimi',
                        onTap: () => _openSupportEmail(
                          subject: AppMetadata.supportSubject,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileActionCard(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Gizlilik politikasi',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileActionCard(
                        icon: Icons.description_outlined,
                        label: 'Kullanim kosullari',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileActionCard(
                        icon: Icons.public,
                        label: 'Resmi web sitesi',
                        onTap: _openWebsite,
                      ),
                      const SizedBox(height: 12),
                      _ProfileActionCard(
                        icon: Icons.delete_forever_outlined,
                        label: _accountDeletionLoading
                            ? 'Hesap siliniyor...'
                            : 'Hesabi kalici olarak sil',
                        iconColor: Colors.redAccent,
                        onTap: _accountDeletionLoading
                            ? null
                            : _confirmDeleteAccount,
                      ),
                    ],
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

class _ProfileActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color iconColor;

  const _ProfileActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.white38),
          ],
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

class _VibeDnaCard extends StatelessWidget {
  final VibeDnaReport report;

  const _VibeDnaCard({required this.report});

  Color _paletteColor(String label) {
    switch (label) {
      case 'Cyan Flux':
        return Colors.cyanAccent;
      case 'Moon Lilac':
        return Colors.purpleAccent;
      case 'Solar Red':
        return Colors.redAccent;
      case 'Obsidian Gold':
        return Colors.amberAccent;
      case 'Chrome Blue':
        return Colors.lightBlueAccent;
      case 'Bio Green':
        return Colors.greenAccent;
      case 'Amber Smoke':
        return Colors.orangeAccent;
      case 'Candy Pulse':
        return Colors.pinkAccent;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.withValues(alpha: 0.22),
            Colors.cyanAccent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.biotech_outlined,
                  color: Colors.purpleAccent, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Vibe DNA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${report.sampleCount} sinyal',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.codename,
            style: const TextStyle(
              color: Colors.purpleAccent,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            report.mirrorLine,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final signal in report.dominantSignals)
                _IdentityBadge(
                  label: signal,
                  accent: Colors.purpleAccent,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DnaMetric(
                  label: 'Rarity',
                  value: '${report.rarityScore}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DnaMetric(
                  label: 'Contrast',
                  value: '${report.contrastScore}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.anomalyLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: report.paletteLabels.map((label) {
              final color = _paletteColor(label);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DnaMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DnaMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
