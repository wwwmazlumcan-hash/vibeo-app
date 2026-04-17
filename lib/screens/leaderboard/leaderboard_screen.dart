import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/points_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(
        title: const Text('🏆 Liderlik Tablosu'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Tüm Zamanlar'),
            Tab(text: 'Bu Hafta'),
            Tab(text: 'Bu Ay'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _Board(period: 'all'),
          _Board(period: 'week'),
          _Board(period: 'month'),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  final String period;
  const _Board({required this.period});

  /// Returns the Firestore field path and the display key for this period.
  static ({String field, String? subKey}) _periodField(String period) {
    final now = DateTime.now();
    if (period == 'week') {
      final weekNum = _isoWeek(now);
      final key = '${now.year}-W${weekNum.toString().padLeft(2, '0')}';
      return (field: 'weeklyPoints.$key', subKey: key);
    }
    if (period == 'month') {
      final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      return (field: 'monthlyPoints.$key', subKey: key);
    }
    return (field: 'points', subKey: null);
  }

  static int _isoWeek(DateTime date) {
    final thu =
        date.subtract(Duration(days: date.weekday - DateTime.thursday));
    final firstThu = DateTime(thu.year, 1, 1);
    final correction =
        (firstThu.weekday - DateTime.thursday + 7) % 7;
    return ((thu.difference(firstThu).inDays + correction) ~/ 7) + 1;
  }

  int _extractPoints(Map<String, dynamic> d, String? subKey) {
    if (period == 'all' || subKey == null) {
      return d['points'] as int? ?? 0;
    }
    final map = d[period == 'week' ? 'weeklyPoints' : 'monthlyPoints'];
    if (map is Map) return (map[subKey] as int?) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final pf = _periodField(period);

    // For weekly/monthly we query all users and sort client-side
    // because Firestore nested map ordering requires a composite index.
    Stream<QuerySnapshot> stream;
    if (period == 'all') {
      stream = FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .limit(50)
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('users')
          .limit(200)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          );
        }

        var docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text('Henüz veri yok',
                style: TextStyle(color: Colors.white38)),
          );
        }

        // Client-side sort for period tabs
        if (period != 'all') {
          docs = [...docs]..sort((a, b) {
              final ap =
                  _extractPoints(a.data() as Map<String, dynamic>, pf.subKey);
              final bp =
                  _extractPoints(b.data() as Map<String, dynamic>, pf.subKey);
              return bp.compareTo(ap);
            });
          docs = docs.take(50).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) return _TopThree(docs: docs.take(3).toList(), period: period, subKey: pf.subKey);

            final idx = i;
            if (idx - 1 >= 3 && idx - 1 < docs.length) {
              final doc = docs[idx - 1];
              final d = doc.data() as Map<String, dynamic>;
              final isMe = doc.id == me?.uid;
              return _RankRow(
                rank: idx,
                username: d['username'] as String? ?? 'anonim',
                points: _extractPoints(d, pf.subKey),
                avatar: d['profilePicUrl'] as String?,
                isMe: isMe,
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}

class _TopThree extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final String period;
  final String? subKey;
  const _TopThree({required this.docs, required this.period, this.subKey});

  int _pts(Map<String, dynamic> d) {
    if (period == 'all' || subKey == null) return d['points'] as int? ?? 0;
    final map = d[period == 'week' ? 'weeklyPoints' : 'monthlyPoints'];
    if (map is Map) return (map[subKey] as int?) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) return const SizedBox.shrink();

    final medals = ['🥇', '🥈', '🥉'];
    final heights = [110.0, 90.0, 80.0];
    final colors = [Colors.amber, Colors.grey, Colors.brown];
    // Reorder: 2nd, 1st, 3rd
    final order = docs.length >= 3 ? [1, 0, 2] : [0];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.08),
            Colors.cyanAccent.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text('Top 3',
              style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: order.map((origIdx) {
              if (origIdx >= docs.length) return const SizedBox(width: 80);
              final doc = docs[origIdx];
              final d = doc.data() as Map<String, dynamic>;
              final username = d['username'] as String? ?? 'anonim';
              final points = _pts(d);
              final avatar = d['profilePicUrl'] as String?;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(medals[origIdx], style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  CircleAvatar(
                    radius: origIdx == 0 ? 30 : 22,
                    backgroundColor:
                        colors[origIdx].withValues(alpha: 0.3),
                    backgroundImage:
                        avatar != null && avatar.isNotEmpty
                            ? NetworkImage(avatar)
                            : null,
                    child: avatar == null || avatar.isEmpty
                        ? Text(
                            username[0].toUpperCase(),
                            style: TextStyle(
                                color: colors[origIdx],
                                fontWeight: FontWeight.bold,
                                fontSize: origIdx == 0 ? 18 : 14),
                          )
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    username.length > 8
                        ? '${username.substring(0, 8)}…'
                        : username,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11),
                  ),
                  Text(
                    _fmt(points),
                    style: TextStyle(
                        color: colors[origIdx],
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: heights[origIdx],
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                      color: colors[origIdx].withValues(alpha: 0.2),
                      border: Border.all(
                          color: colors[origIdx].withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text('#${origIdx + 1}',
                          style: TextStyle(
                              color: colors[origIdx],
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String username;
  final int points;
  final String? avatar;
  final bool isMe;

  const _RankRow({
    required this.rank,
    required this.username,
    required this.points,
    required this.avatar,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final badge = PointsService.getBadge(points);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isMe
            ? Colors.cyanAccent.withValues(alpha: 0.1)
            : const Color(0xFF0B141D),
        border: Border.all(
          color: isMe
              ? Colors.cyanAccent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#$rank',
                style: TextStyle(
                    color: isMe ? Colors.cyanAccent : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
            backgroundImage:
                avatar != null && avatar!.isNotEmpty
                    ? NetworkImage(avatar!)
                    : null,
            child: avatar == null || avatar!.isEmpty
                ? Text(username[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                          color: isMe ? Colors.cyanAccent : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      const Text('(Sen)',
                          style: TextStyle(
                              color: Colors.cyanAccent, fontSize: 10)),
                    ],
                  ],
                ),
                Text(badge,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmt(points),
                  style: TextStyle(
                      color: isMe ? Colors.cyanAccent : Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const Text('XP',
                  style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
