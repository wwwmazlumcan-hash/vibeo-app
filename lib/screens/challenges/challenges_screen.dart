import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/points_service.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
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
        title: const Text('Meydan Okumalar'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Leaderboard'),
            Tab(text: 'Geçmiş'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ActiveChallenges(),
          _Leaderboard(),
          _PastChallenges(),
        ],
      ),
    );
  }
}

class _ActiveChallenges extends StatelessWidget {
  const _ActiveChallenges();

  static const _challenges = [
    _ChallengeData(
      id: 'neon_city_2026',
      title: '🌆 Neon Şehir',
      description:
          'En etkileyici neon şehir manzarasını AI ile yarat! Kazanan 500 XP alır.',
      deadline: '2 gün kaldı',
      prize: '500 XP',
      participants: 1247,
      accent: Colors.cyanAccent,
      prompt: 'cyberpunk neon city night, futuristic, glowing signs',
    ),
    _ChallengeData(
      id: 'dream_creatures',
      title: '🐉 Rüya Yaratıkları',
      description:
          'Hiç görülmemiş fantastik bir yaratık hayal et ve AI ile canlandır.',
      deadline: '5 gün kaldı',
      prize: '300 XP + Rozet',
      participants: 892,
      accent: Colors.purpleAccent,
      prompt: 'fantasy creature, ethereal, magical, detailed',
    ),
    _ChallengeData(
      id: 'emotion_abstract',
      title: '🎭 Duygu Soyutlaması',
      description:
          'Bir duyguyu soyut AI sanatı olarak ifade et. Jüri en özgün eseri seçer.',
      deadline: '7 gün kaldı',
      prize: '400 XP',
      participants: 634,
      accent: Colors.orangeAccent,
      prompt: 'abstract emotion art, flowing colors, expressive',
    ),
    _ChallengeData(
      id: 'future_earth',
      title: '🌍 Gelecek Dünya',
      description:
          '100 yıl sonra Dünya nasıl görünüyor? Hayal gücünü konuştur.',
      deadline: '10 gün kaldı',
      prize: '250 XP',
      participants: 421,
      accent: Colors.greenAccent,
      prompt: 'future earth 2124, utopia or dystopia, realistic',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Weekly featured
        _WeeklyBanner(),
        const SizedBox(height: 20),
        const Text('Tüm Yarışmalar',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._challenges.map((c) => _ChallengeCard(data: c)),
      ],
    );
  }
}

class _WeeklyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.cyanAccent.withValues(alpha: 0.2),
            Colors.purpleAccent.withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('⭐ HAFTANIN YARIŞMASI',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              const Text('⏰ 2 gün',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '🌆 Neon Şehir Challenge',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            '1.247 katılımcı  •  Ödül: 500 XP',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChallengeDetailScreen(
                          challengeId: 'neon_city_2026',
                          title: '🌆 Neon Şehir',
                        )),
              ),
              child: const Text('Katıl & Yarat'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeData {
  final String id;
  final String title;
  final String description;
  final String deadline;
  final String prize;
  final int participants;
  final Color accent;
  final String prompt;

  const _ChallengeData({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.prize,
    required this.participants,
    required this.accent,
    required this.prompt,
  });
}

class _ChallengeCard extends StatelessWidget {
  final _ChallengeData data;
  const _ChallengeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChallengeDetailScreen(
                challengeId: data.id, title: data.title)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0B141D),
          border: Border.all(color: data.accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(data.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: data.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: data.accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(data.deadline,
                      style: TextStyle(
                          color: data.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(data.description,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.people_outline, color: data.accent, size: 14),
                const SizedBox(width: 4),
                Text('${data.participants} katılımcı',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
                const Spacer(),
                Icon(Icons.emoji_events, color: data.accent, size: 14),
                const SizedBox(width: 4),
                Text(data.prize,
                    style: TextStyle(
                        color: data.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('challenge_entries')
          .where('challengeId', isEqualTo: 'neon_city_2026')
          .orderBy('votes', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.isEmpty ? 5 : docs.length,
          itemBuilder: (context, i) {
            if (docs.isEmpty) {
              return _LeaderRow(
                rank: i + 1,
                username: 'user_${i + 1}',
                votes: (100 - i * 15),
                imageUrl: null,
              );
            }
            final d = docs[i].data() as Map<String, dynamic>;
            return _LeaderRow(
              rank: i + 1,
              username: d['username'] as String? ?? 'anonim',
              votes: d['votes'] as int? ?? 0,
              imageUrl: d['imageUrl'] as String?,
            );
          },
        );
      },
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final String username;
  final int votes;
  final String? imageUrl;

  const _LeaderRow({
    required this.rank,
    required this.username,
    required this.votes,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: rank <= 3
            ? Colors.cyanAccent.withValues(alpha: 0.08)
            : const Color(0xFF0B141D),
        border: Border.all(
          color: rank <= 3
              ? Colors.cyanAccent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Text(
            rank <= 3 ? medals[rank - 1] : '#$rank',
            style: TextStyle(
                fontSize: rank <= 3 ? 22 : 14,
                color: Colors.white54,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
            backgroundImage:
                imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? Text(username[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(username,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          Row(
            children: [
              const Icon(Icons.thumb_up, color: Colors.cyanAccent, size: 14),
              const SizedBox(width: 4),
              Text('$votes',
                  style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PastChallenges extends StatelessWidget {
  const _PastChallenges();

  static const _past = [
    ('🌅 Gün Batımı Düşleri', 'Geçen Hafta', '🥇 neon_painter_42'),
    ('🤖 Robot Romantizmi', '2 Hafta Önce', '🥇 ai_dreamer_x'),
    ('🌺 Çiçek Fütürizmi', '3 Hafta Önce', '🥇 vibeo_artist'),
    ('🏔️ Dağ Mistisizmi', '4 Hafta Önce', '🥇 cosmos_girl'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _past
          .map((p) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF0B141D),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.$1,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${p.$2}  •  ${p.$3}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white24),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// Challenge Detail Screen
class ChallengeDetailScreen extends StatefulWidget {
  final String challengeId;
  final String title;

  const ChallengeDetailScreen({
    super.key,
    required this.challengeId,
    required this.title,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final _promptCtrl = TextEditingController();
  bool _loading = false;
  String? _previewUrl;
  bool _submitted = false;

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final encoded = Uri.encodeComponent(
          '${_promptCtrl.text.trim()}, cyberpunk neon city night, ultra detailed, cinematic');
      setState(() {
        _previewUrl =
            'https://image.pollinations.ai/prompt/$encoded?width=720&height=720&nologo=true&seed=${DateTime.now().millisecondsSinceEpoch}';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_previewUrl == null) return;
    setState(() => _loading = true);
    try {
      final me = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(me.uid)
          .get();
      final username =
          (userDoc.data() as Map<String, dynamic>?)?['username'] ?? 'anonim';

      await FirebaseFirestore.instance.collection('challenge_entries').add({
        'challengeId': widget.challengeId,
        'userId': me.uid,
        'username': username,
        'imageUrl': _previewUrl,
        'prompt': _promptCtrl.text.trim(),
        'votes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await PointsService.award(50, reason: 'challenge_entry');

      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(title: Text(widget.title)),
      body: _submitted
          ? _SuccessView(onClose: () => Navigator.pop(context))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entries grid
                  const Text('Katılımcı Eserleri',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _EntriesGrid(challengeId: widget.challengeId),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),
                  const Text('Katıl',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_previewUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        _previewUrl!,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, p) {
                          if (p == null) return child;
                          return Container(
                            height: 240,
                            color: const Color(0xFF0B141D),
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.cyanAccent)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _promptCtrl,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Prompt\'unu yaz (İngilizce daha iyi sonuç verir)',
                      prefixIcon: Icon(Icons.edit_outlined,
                          color: Colors.cyanAccent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _generate,
                          icon: _loading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Oluştur'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.cyanAccent,
                            side: const BorderSide(color: Colors.cyanAccent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (_previewUrl == null || _loading) ? null : _submit,
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text('Yarışmaya Gönder'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('+50 XP kazanırsın!',
                        style: TextStyle(
                            color: Colors.cyanAccent, fontSize: 12)),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EntriesGrid extends StatelessWidget {
  final String challengeId;
  const _EntriesGrid({required this.challengeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('challenge_entries')
          .where('challengeId', isEqualTo: challengeId)
          .orderBy('votes', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Henüz katılım yok. İlk sen ol!',
                  style: TextStyle(color: Colors.white38)),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final url = d['imageUrl'] as String? ?? '';
            final votes = d['votes'] as int? ?? 0;
            return GestureDetector(
              onTap: () => _vote(context, docs[i].id, votes),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.thumb_up,
                              color: Colors.cyanAccent, size: 10),
                          const SizedBox(width: 3),
                          Text('$votes',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _vote(BuildContext context, String docId, int currentVotes) {
    FirebaseFirestore.instance
        .collection('challenge_entries')
        .doc(docId)
        .update({'votes': currentVotes + 1});
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onClose;
  const _SuccessView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text('Yarışmaya Katıldın!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('+50 XP kazandın',
                style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Topluluk oy versin, leaderboard\'da yüksel!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: onClose, child: const Text('Tamam')),
            ),
          ],
        ),
      ),
    );
  }
}
