// Prompt Battle — iki kullanıcı prompt girer, AI üretir, topluluk oy verir
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/points_service.dart';

class PromptBattleScreen extends StatefulWidget {
  const PromptBattleScreen({super.key});

  @override
  State<PromptBattleScreen> createState() => _PromptBattleScreenState();
}

class _PromptBattleScreenState extends State<PromptBattleScreen>
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚡ Prompt Battle'),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: const Text('BETA',
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.orangeAccent,
          labelColor: Colors.orangeAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Oy Ver'),
            Tab(text: 'Battle Kur'),
            Tab(text: 'Sonuçlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _VotingTab(),
          _CreateBattleTab(),
          _ResultsTab(),
        ],
      ),
    );
  }
}

// ─── Voting Tab ────────────────────────────────────────────────
class _VotingTab extends StatelessWidget {
  const _VotingTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('battles')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyBattles();
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) =>
              _BattleCard(doc: docs[i]),
        );
      },
    );
  }
}

class _BattleCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const _BattleCard({required this.doc});

  @override
  State<_BattleCard> createState() => _BattleCardState();
}

class _BattleCardState extends State<_BattleCard> {
  bool _voted = false;
  int? _votedSide; // 0 = left, 1 = right

  Future<void> _vote(int side) async {
    if (_voted) return;
    setState(() {
      _voted = true;
      _votedSide = side;
    });

    final field = side == 0 ? 'votesA' : 'votesB';
    await FirebaseFirestore.instance
        .collection('battles')
        .doc(widget.doc.id)
        .update({field: FieldValue.increment(1)});

    final me = FirebaseAuth.instance.currentUser;
    if (me != null) {
      await PointsService.award(5, reason: 'battle_vote');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doc.data() as Map<String, dynamic>;
    final promptA = d['promptA'] as String? ?? '?';
    final promptB = d['promptB'] as String? ?? '?';
    final imageA = d['imageA'] as String? ?? '';
    final imageB = d['imageB'] as String? ?? '';
    final votesA = d['votesA'] as int? ?? 0;
    final votesB = d['votesB'] as int? ?? 0;
    final total = votesA + votesB;
    final pctA = total == 0 ? 0.5 : votesA / total;
    final user1 = d['user1name'] as String? ?? 'User A';
    final user2 = d['user2name'] as String? ?? 'User B';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0B141D),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withValues(alpha: 0.08), blurRadius: 20)
        ],
      ),
      child: Column(
        children: [
          // VS header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Text('@$user1',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Colors.orangeAccent, Colors.deepOrange]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('⚡ VS',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                ),
                Expanded(
                  child: Text('@$user2',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          ),

          // Images
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _vote(0),
                  child: _BattleImage(
                    imageUrl: imageA,
                    prompt: promptA,
                    selected: _votedSide == 0,
                    losing: _voted && _votedSide != 0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => _vote(1),
                  child: _BattleImage(
                    imageUrl: imageB,
                    prompt: promptB,
                    selected: _votedSide == 1,
                    losing: _voted && _votedSide != 1,
                  ),
                ),
              ),
            ],
          ),

          // Vote bar
          if (_voted)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('${(pctA * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${((1 - pctA) * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pctA,
                      backgroundColor:
                          Colors.orangeAccent.withValues(alpha: 0.3),
                      color: Colors.cyanAccent,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Toplam $total oy  •  +5 XP kazandın!',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('👆 Daha iyisine oy ver!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _BattleImage extends StatelessWidget {
  final String imageUrl;
  final String prompt;
  final bool selected;
  final bool losing;

  const _BattleImage({
    required this.imageUrl,
    required this.prompt,
    required this.selected,
    required this.losing,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: losing ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF0B141D),
                      child: const Icon(Icons.image_outlined,
                          color: Colors.white24, size: 40),
                    ),
            ),
          ),
          if (selected)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.cyanAccent, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle,
                        color: Colors.cyanAccent, size: 36),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                padding: const EdgeInsets.all(6),
                child: Text(
                  prompt,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBattles extends StatelessWidget {
  const _EmptyBattles();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Henüz aktif battle yok',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('İlk battle\'ı sen başlat!',
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

// ─── Create Battle Tab ─────────────────────────────────────────
class _CreateBattleTab extends StatefulWidget {
  const _CreateBattleTab();

  @override
  State<_CreateBattleTab> createState() => _CreateBattleTabState();
}

class _CreateBattleTabState extends State<_CreateBattleTab> {
  final _promptCtrl = TextEditingController();
  bool _loading = false;
  String? _myImageUrl;
  bool _created = false;

  Future<void> _generateAndCreate() async {
    if (_promptCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final me = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(me.uid)
          .get();
      final username =
          (userDoc.data() as Map<String, dynamic>?)?['username'] ?? 'anonim';

      final encoded = Uri.encodeComponent(
          '${_promptCtrl.text.trim()}, ultra detailed, cinematic');
      final imgUrl =
          'https://image.pollinations.ai/prompt/$encoded?width=512&height=512&nologo=true&seed=${Random().nextInt(99999)}';

      setState(() => _myImageUrl = imgUrl);

      // Create battle waiting for opponent
      await FirebaseFirestore.instance.collection('battles').add({
        'user1': me.uid,
        'user1name': username,
        'promptA': _promptCtrl.text.trim(),
        'imageA': imgUrl,
        'user2': null,
        'user2name': null,
        'promptB': null,
        'imageB': null,
        'votesA': 0,
        'votesB': 0,
        'status': 'waiting', // waiting → active → closed
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _created = true);
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
    if (_created) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_myImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(_myImageUrl!,
                      width: 200, height: 200, fit: BoxFit.cover),
                ),
              const SizedBox(height: 20),
              const Text('⚔️ Battle Hazır!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                  'Rakip geldiğinde battle başlayacak.\nTopluluğun oy vermesini bekle!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _created = false;
                    _myImageUrl = null;
                    _promptCtrl.clear();
                  }),
                  child: const Text('Yeni Battle'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [
                Colors.orange.withValues(alpha: 0.15),
                Colors.deepOrange.withValues(alpha: 0.08),
              ]),
              border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Text('⚡', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Prompt gir → AI görsel üretilir → Rakip gelir → Topluluk oy verir → Kazanan XP alır!',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Prompt\'unu gir',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _promptCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'En yaratıcı prompt\'unu yaz...',
              prefixIcon:
                  Icon(Icons.flash_on, color: Colors.orangeAccent),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _generateAndCreate,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.flash_on, size: 18),
              label: Text(_loading ? 'Hazırlanıyor...' : '⚔️ Battle Başlat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Results Tab ───────────────────────────────────────────────
class _ResultsTab extends StatelessWidget {
  const _ResultsTab();

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('battles')
          .where('status', isEqualTo: 'closed')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('Henüz tamamlanan battle yok',
                style: TextStyle(color: Colors.white54)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final votesA = d['votesA'] as int? ?? 0;
            final votesB = d['votesB'] as int? ?? 0;
            final winnerSide = votesA >= votesB ? 'A' : 'B';
            final winnerName =
                winnerSide == 'A' ? d['user1name'] : d['user2name'];
            return ListTile(
              leading: Text(winnerSide == 'A' ? '🏆' : '🏆',
                  style: const TextStyle(fontSize: 24)),
              title: Text('@$winnerName kazandı!',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('$votesA vs $votesB oy',
                  style: const TextStyle(color: Colors.white54)),
            );
          },
        );
      },
    );
  }
}
