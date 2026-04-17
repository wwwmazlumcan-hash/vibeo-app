import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/points_service.dart';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _awardDailyLogin();
  }

  Future<void> _awardDailyLogin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final lastLogin = doc.data()?['lastLoginDate'] as String?;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastLogin != today) {
      await PointsService.award(PointsService.pointsPerDailyLogin,
          reason: 'Günlük giriş bonusu');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'lastLoginDate': today});
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('KAZAN'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.2)),
            ),
            child: TabBar(
              controller: _tabs,
              indicatorColor: Colors.cyanAccent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.cyanAccent,
              unselectedLabelColor: Colors.white38,
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'Puanlarım'),
                Tab(text: 'Liderlik'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MyPointsTab(uid: uid),
          const _LeaderboardTab(),
        ],
      ),
    );
  }
}

class _MyPointsTab extends StatelessWidget {
  final String uid;
  const _MyPointsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final points = (data['points'] ?? 0) as int;
        final badge = PointsService.getBadge(points);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Colors.cyanAccent, Color(0xFF003333)],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.5),
                        blurRadius: 30),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$points',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 42,
                            fontWeight: FontWeight.bold)),
                    const Text('XP',
                        style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(badge, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Nasıl kazanırsın?',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              const _EarnRow(
                  icon: Icons.auto_awesome,
                  label: 'Vibeo paylaş',
                  xp: '+${PointsService.pointsPerPost} XP'),
              const _EarnRow(
                  icon: Icons.favorite,
                  label: 'Beğeni al',
                  xp: '+${PointsService.pointsPerLikeReceived} XP'),
              const _EarnRow(
                  icon: Icons.comment,
                  label: 'Yorum al',
                  xp: '+${PointsService.pointsPerComment} XP'),
              const _EarnRow(
                  icon: Icons.login,
                  label: 'Günlük giriş',
                  xp: '+${PointsService.pointsPerDailyLogin} XP'),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Rozetler',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _BadgeChip(label: 'Starter', unlocked: points >= 0),
                  _BadgeChip(label: 'Bronze', unlocked: points >= 100),
                  _BadgeChip(label: 'Silver', unlocked: points >= 500),
                  _BadgeChip(label: 'Gold', unlocked: points >= 1000),
                  _BadgeChip(label: 'Diamond', unlocked: points >= 2000),
                  _BadgeChip(label: 'Legend', unlocked: points >= 5000),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EarnRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String xp;
  const _EarnRow(
      {required this.icon, required this.label, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 14))),
          Text(xp,
              style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final bool unlocked;
  const _BadgeChip({required this.label, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: unlocked
            ? Colors.cyanAccent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: unlocked
                ? Colors.cyanAccent.withValues(alpha: 0.5)
                : Colors.white12),
        boxShadow: unlocked
            ? [
                BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                    blurRadius: 10)
              ]
            : null,
      ),
      child: Text(label,
          style: TextStyle(
              color: unlocked ? Colors.cyanAccent : Colors.white24,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: Colors.cyanAccent));
        }

        final docs = snap.data?.docs ?? [];
        final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final points = (d['points'] ?? 0) as int;
            final username = d['username'] ?? '...';
            final isMe = docs[i].id == myUid;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.cyanAccent.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isMe
                      ? Colors.cyanAccent.withValues(alpha: 0.5)
                      : Colors.cyanAccent.withValues(alpha: 0.1),
                ),
                boxShadow: isMe
                    ? [
                        BoxShadow(
                            color: Colors.cyanAccent
                                .withValues(alpha: 0.15),
                            blurRadius: 12)
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                        i < 3
                            ? ['1', '2', '3'][i]
                            : '${i + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: i < 3
                                ? Colors.cyanAccent
                                : Colors.white54)),
                  ),
                  const SizedBox(width: 12),
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
                            color: Colors.cyanAccent
                                .withValues(alpha: 0.3),
                            blurRadius: 6),
                      ],
                    ),
                    child: const Icon(Icons.person,
                        color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '@$username${isMe ? ' (Sen)' : ''}',
                      style: TextStyle(
                          color: isMe ? Colors.cyanAccent : Colors.white,
                          fontWeight:
                              isMe ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14),
                    ),
                  ),
                  Text('$points XP',
                      style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
