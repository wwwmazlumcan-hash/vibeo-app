import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/hashtag_service.dart';
import '../../services/surprise_engine_service.dart';
import '../post/post_detail_screen.dart';
import '../remix/remix_duel_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'Tümü';
  String? _selectedHashtag;
  bool _serendipityMode = false;
  int _jumpSeed = 0;

  static const _bg = Color(0xFF03070D);
  static const _categories = {
    'Tümü': Icons.grid_view_rounded,
    'Creative': Icons.palette_outlined,
    'Deep': Icons.psychology_outlined,
    'Funny': Icons.emoji_emotions_outlined,
    'Tech': Icons.memory_outlined,
  };

  bool _matchesFilters(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final prompt = (data['prompt'] ?? '').toString().toLowerCase();
    final hashtags = List<String>.from(data['hashtags'] ?? []);
    final hashtagQuery = _query.startsWith('#') ? _query.substring(1) : _query;

    final matchesQuery = _query.isEmpty ||
        prompt.contains(_query) ||
        hashtags.any((tag) => tag.toLowerCase().contains(hashtagQuery));
    if (!matchesQuery) {
      return false;
    }
    if (_selectedHashtag != null && !hashtags.contains(_selectedHashtag)) {
      return false;
    }
    return true;
  }

  void _jump() {
    setState(() {
      _serendipityMode = true;
      _jumpSeed += 1;
      _query = '';
      _selectedHashtag = null;
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  const Text('Keşfet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyanAccent.withValues(alpha: 0.08),
                      border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.cyanAccent, size: 16),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _jump,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shuffle_rounded,
                              color: Colors.amber, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Jump',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.2)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Vibe ara...',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.cyanAccent, size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _categories.entries.map((e) {
                  final selected = _category == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _category = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.cyanAccent.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected
                                ? Colors.cyanAccent
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                      color: Colors.cyanAccent
                                          .withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      spreadRadius: -4)
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(e.value,
                                size: 16,
                                color: selected
                                    ? Colors.cyanAccent
                                    : Colors.white70),
                            const SizedBox(width: 6),
                            Text(e.key,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.cyanAccent
                                      : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: StreamBuilder<List<String>>(
                stream: HashtagService.trendingHashtags(),
                builder: (context, snapshot) {
                  final tags = snapshot.data ?? const <String>[];
                  if (tags.isEmpty) return const SizedBox.shrink();

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedHashtag = null),
                          child: _HashtagChip(
                            label: 'Trend',
                            selected: _selectedHashtag == null,
                          ),
                        ),
                      ),
                      ...tags.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedHashtag = tag),
                            child: _HashtagChip(
                              label: '#$tag',
                              selected: _selectedHashtag == tag,
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.cyanAccent));
                  }
                  final sourceDocs = snap.data?.docs ??
                      const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                  final filteredDocs =
                      sourceDocs.where(_matchesFilters).toList();
                  final remixDocs = sourceDocs
                      .where((doc) {
                        final data = doc.data();
                        final creationMode =
                            (data['creationMode'] ?? '') as String;
                        return creationMode == 'impossible_remix' ||
                            creationMode == 'remix' ||
                            (data['remixBridgeLine'] ?? '')
                                .toString()
                                .isNotEmpty;
                      })
                      .take(8)
                      .toList();
                  final remixLens = remixDocs.isEmpty
                      ? null
                      : SurpriseEngineService.buildRemixShelfLens(
                          remixDocs.map((doc) => doc.data()).toList(),
                        );
                  final remixLeaderboardDocs =
                      List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                    remixDocs,
                  )..sort((a, b) => ((b.data()['likesCount'] ?? 0) as int)
                          .compareTo((a.data()['likesCount'] ?? 0) as int));
                  final remixLeaderboardLens = remixLeaderboardDocs.isEmpty
                      ? null
                      : SurpriseEngineService.buildRemixLeaderboardLens(
                          remixLeaderboardDocs
                              .map((doc) => doc.data())
                              .toList(),
                        );
                  final plan = _serendipityMode && sourceDocs.isNotEmpty
                      ? SurpriseEngineService.buildSerendipityJump(
                          sourceDocs.map((doc) => doc.data()).toList(),
                          seed: _jumpSeed,
                          query: _query,
                          category: _category,
                          selectedHashtag: _selectedHashtag,
                        )
                      : null;
                  final docs = plan == null
                      ? filteredDocs
                      : (List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                          sourceDocs,
                        )..sort((a, b) => plan
                              .scorePost(b.data())
                              .compareTo(plan.scorePost(a.data()))))
                          .where((doc) => plan.scorePost(doc.data()) > 12)
                          .take(12)
                          .toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Sonuç yok',
                          style: TextStyle(color: Colors.white38)),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _DuelArenaEntry(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RemixDuelScreen(),
                            ),
                          ),
                        ),
                      ),
                      if (remixLeaderboardLens != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _RemixLeaderboard(
                            lens: remixLeaderboardLens,
                            docs: remixLeaderboardDocs.take(3).toList(),
                          ),
                        ),
                      if (remixLens != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _RemixShelf(
                            lens: remixLens,
                            docs: remixDocs,
                          ),
                        ),
                      if (plan != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _SerendipityPanel(
                            plan: plan,
                            onReroll: _jump,
                            onDisable: () => setState(
                              () => _serendipityMode = false,
                            ),
                          ),
                        ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final data = docs[i].data();
                            return _ExploreCard(
                              postId: docs[i].id,
                              imageUrl: data['imageUrl'] ?? '',
                              prompt: data['prompt'] ?? '',
                              hashtags:
                                  List<String>.from(data['hashtags'] ?? []),
                              userId: data['userId'] ?? '',
                            );
                          },
                        ),
                      ),
                    ],
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

class _DuelArenaEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _DuelArenaEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orangeAccent.withValues(alpha: 0.16),
              Colors.redAccent.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.orangeAccent.withValues(alpha: 0.32)),
        ),
        child: const Row(
          children: [
            Icon(Icons.sports_martial_arts, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duel Arena',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Aktif remix kapismalarina gir, oy ver veya kendi duelini baslat.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _RemixLeaderboard extends StatelessWidget {
  final RemixLeaderboardLens lens;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const _RemixLeaderboard({required this.lens, required this.docs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lens.title,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lens.summary,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(docs.length, (index) {
            final data = docs[index].data();
            final likes = (data['likesCount'] ?? 0) as int;
            final prompt = (data['prompt'] ?? '') as String;
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == docs.length - 1 ? 0 : 10),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(
                      postId: docs[index].id,
                      imageUrl: (data['imageUrl'] ?? '') as String,
                      prompt: prompt,
                      username: ((data['userId'] ?? '') as String).substring(
                        0,
                        ((data['userId'] ?? '') as String).length.clamp(0, 6),
                      ),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.greenAccent.withValues(alpha: 0.14),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        (data['imageUrl'] ?? '') as String,
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Colors.black,
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child:
                                Icon(Icons.broken_image, color: Colors.white24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.greenAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$likes',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RemixShelf extends StatelessWidget {
  final RemixShelfLens lens;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const _RemixShelf({required this.lens, required this.docs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lens.title,
          style: const TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          lens.summary,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final prompt = (data['prompt'] ?? '') as String;
              final bridge = (data['remixBridgeLine'] ?? '') as String;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(
                      postId: docs[index].id,
                      imageUrl: (data['imageUrl'] ?? '') as String,
                      prompt: prompt,
                      username: ((data['userId'] ?? '') as String).substring(
                          0,
                          ((data['userId'] ?? '') as String)
                              .length
                              .clamp(0, 6)),
                    ),
                  ),
                ),
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          (data['imageUrl'] ?? '') as String,
                          width: 76,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 76,
                            color: Colors.black,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Impossible Remix',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              bridge.isEmpty ? prompt : bridge,
                              maxLines: 4,
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SerendipityPanel extends StatelessWidget {
  final SerendipityJumpPlan plan;
  final VoidCallback onReroll;
  final VoidCallback onDisable;

  const _SerendipityPanel({
    required this.plan,
    required this.onReroll,
    required this.onDisable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.16),
            Colors.cyanAccent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_motion,
                  color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${plan.title} • ${plan.categoryLabel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.summary,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final signal in plan.signalWords)
                _HashtagChip(label: signal, selected: true),
              for (final tag in plan.hashtags)
                _HashtagChip(label: '#$tag', selected: false),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: onReroll,
                icon: const Icon(Icons.shuffle_rounded, size: 16),
                label: const Text('Tekrar Buk'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDisable,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Normal Mod'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final String postId;
  final String imageUrl;
  final String prompt;
  final List<String> hashtags;
  final String userId;

  const _ExploreCard({
    required this.postId,
    required this.imageUrl,
    required this.prompt,
    required this.hashtags,
    required this.userId,
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
            username: userId.substring(0, userId.length.clamp(0, 6)),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF0B141D),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Colors.black,
                        child: Icon(Icons.broken_image, color: Colors.white24),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.cyanAccent.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.cyanAccent, size: 9),
                            SizedBox(width: 3),
                            Text('AI',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    if (hashtags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: hashtags.take(2).map((tag) {
                          return Text(
                            '#$tag',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _HashtagChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected
            ? Colors.cyanAccent.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? Colors.cyanAccent
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.cyanAccent : Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
