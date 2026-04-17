import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/points_service.dart';
import '../../services/surprise_engine_service.dart';
import '../post/post_detail_screen.dart';

class RemixDuelScreen extends StatelessWidget {
  final String? seedPostId;
  final String? seedImageUrl;
  final String? seedPrompt;
  final String? seedUsername;

  const RemixDuelScreen({
    super.key,
    this.seedPostId,
    this.seedImageUrl,
    this.seedPrompt,
    this.seedUsername,
  });

  @override
  Widget build(BuildContext context) {
    final hasSeed = seedPostId != null && seedPostId!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF03070D),
        title: const Text('Remix Duel'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.22),
                  ),
                ),
                child: const Text(
                  'Remix Duel, iki varyasyonu ayni sahnede carpistirir. Topluluk hangisinin daha ileri bir estetik sapma olduguna oy verir.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ),
            ),
          ),
          if (hasSeed)
            SliverToBoxAdapter(
              child: _SeedComposer(
                seedPostId: seedPostId!,
                seedImageUrl: seedImageUrl ?? '',
                seedPrompt: seedPrompt ?? '',
                seedUsername: seedUsername ?? '',
              ),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Aktif Dueller',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('remix_duels')
                  .where('status', isEqualTo: 'active')
                  .orderBy('createdAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 40),
                    child: _EmptyDuelState(),
                  );
                }

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) =>
                      _RemixDuelCard(doc: docs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SeedComposer extends StatelessWidget {
  final String seedPostId;
  final String seedImageUrl;
  final String seedPrompt;
  final String seedUsername;

  const _SeedComposer({
    required this.seedPostId,
    required this.seedImageUrl,
    required this.seedPrompt,
    required this.seedUsername,
  });

  Future<void> _createDuel(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> challenger,
  ) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final challengerData = challenger.data();
    final challengerUser = (challengerData['userId'] ?? '') as String;
    final duelDoc = await FirebaseFirestore.instance
        .collection('remix_duels')
        .where('leftPostId', isEqualTo: seedPostId)
        .where('rightPostId', isEqualTo: challenger.id)
        .limit(1)
        .get();
    if (duelDoc.docs.isNotEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu duel zaten aktif.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('remix_duels').add({
      'leftPostId': seedPostId,
      'leftImageUrl': seedImageUrl,
      'leftPrompt': seedPrompt,
      'leftUsername': seedUsername,
      'leftUid': currentUid,
      'rightPostId': challenger.id,
      'rightImageUrl': (challengerData['imageUrl'] ?? '') as String,
      'rightPrompt': (challengerData['prompt'] ?? '') as String,
      'rightUsername':
          challengerUser.substring(0, challengerUser.length.clamp(0, 6)),
      'rightUid': challengerUser,
      'votesLeft': 0,
      'votesRight': 0,
      'votedBy': <String>[],
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUid,
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Remix Duel başlatıldı.'),
        backgroundColor: Colors.cyanAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bu Post ile Duel Başlat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    seedImageUrl,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Colors.black,
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: Icon(Icons.broken_image, color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seedPrompt,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '@$seedUsername',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Rakip seç',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('createdAt', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = (snapshot.data?.docs ??
                      const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                  .where((doc) {
                final data = doc.data();
                final creationMode = (data['creationMode'] ?? '') as String;
                return doc.id != seedPostId &&
                    (creationMode == 'remix' ||
                        creationMode == 'impossible_remix' ||
                        (data['remixOf'] ?? '').toString().isNotEmpty);
              }).toList();
              if (docs.isEmpty) {
                return const SizedBox.shrink();
              }

              return SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return GestureDetector(
                      onTap: () => _createDuel(context, docs[index]),
                      child: Container(
                        width: 170,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.orangeAccent.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  (data['imageUrl'] ?? '') as String,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const ColoredBox(
                                    color: Colors.black,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (data['prompt'] ?? '') as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RemixDuelCard extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _RemixDuelCard({required this.doc});

  @override
  State<_RemixDuelCard> createState() => _RemixDuelCardState();
}

class _RemixDuelCardState extends State<_RemixDuelCard> {
  bool _voting = false;

  Future<void> _vote(String side) async {
    if (_voting) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = widget.doc.data();
    final votedBy = List<String>.from(data['votedBy'] ?? const <String>[]);
    if (votedBy.contains(uid)) return;

    setState(() => _voting = true);
    final field = side == 'left' ? 'votesLeft' : 'votesRight';
    await FirebaseFirestore.instance
        .collection('remix_duels')
        .doc(widget.doc.id)
        .update({
      field: FieldValue.increment(1),
      'votedBy': FieldValue.arrayUnion([uid]),
    });
    await PointsService.award(4, reason: 'remix_duel_vote');
    if (mounted) setState(() => _voting = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final votesLeft = (data['votesLeft'] ?? 0) as int;
    final votesRight = (data['votesRight'] ?? 0) as int;
    final total = votesLeft + votesRight;
    final leftRatio = total == 0 ? 0.5 : votesLeft / total;
    final lens = SurpriseEngineService.buildRemixDuelLens(
      leftPrompt: (data['leftPrompt'] ?? '') as String,
      rightPrompt: (data['rightPrompt'] ?? '') as String,
      votesLeft: votesLeft,
      votesRight: votesRight,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lens.title,
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lens.summary,
            style: const TextStyle(color: Colors.white60, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DuelSide(
                  imageUrl: (data['leftImageUrl'] ?? '') as String,
                  prompt: (data['leftPrompt'] ?? '') as String,
                  username: (data['leftUsername'] ?? '') as String,
                  onVote: _voting ? null : () => _vote('left'),
                  postId: (data['leftPostId'] ?? '') as String,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DuelSide(
                  imageUrl: (data['rightImageUrl'] ?? '') as String,
                  prompt: (data['rightPrompt'] ?? '') as String,
                  username: (data['rightUsername'] ?? '') as String,
                  onVote: _voting ? null : () => _vote('right'),
                  postId: (data['rightPostId'] ?? '') as String,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: leftRatio,
              minHeight: 10,
              color: Colors.orangeAccent,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$votesLeft oy',
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              Text(
                '$votesRight oy',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DuelSide extends StatelessWidget {
  final String imageUrl;
  final String prompt;
  final String username;
  final String postId;
  final VoidCallback? onVote;

  const _DuelSide({
    required this.imageUrl,
    required this.prompt,
    required this.username,
    required this.postId,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            postId: postId,
            imageUrl: imageUrl,
            prompt: prompt,
            username: username,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Colors.black,
                child: SizedBox(
                  height: 170,
                  child: Icon(Icons.broken_image, color: Colors.white24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@$username',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prompt,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onVote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Oy Ver'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDuelState extends StatelessWidget {
  const _EmptyDuelState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Column(
        children: [
          Icon(Icons.sports_martial_arts, color: Colors.white24, size: 42),
          SizedBox(height: 12),
          Text(
            'Henüz aktif remix duel yok',
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Bir post detayından duel başlat ve topluluğun hangi varyasyonu daha cesur bulduğunu gör.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, height: 1.35),
          ),
        ],
      ),
    );
  }
}
