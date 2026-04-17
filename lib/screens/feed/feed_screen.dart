import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../providers/video_provider.dart';
import '../../services/social_experience_service.dart';
import '../../services/surprise_engine_service.dart';
import '../../widgets/video_item.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/stories_bar.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? _lastPrimedPostId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().refreshFeedPreferences();
    });
  }

  void _primeFirstVisiblePost(
    VideoProvider provider,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) return;

    final postId = docs.first.id;
    if (_lastPrimedPostId == postId) return;
    _lastPrimedPostId = postId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final data = docs.first.data();
      provider.registerPostView(
        postId: postId,
        hashtags: List<String>.from(data['hashtags'] ?? const []),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'vibeo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Bir hata oluştu!',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const FeedShimmer();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 60, color: Colors.white12),
                  SizedBox(height: 16),
                  Text(
                    "Henüz hiç Vibeo yok.\nİlkini sen üret!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final docs = provider.rankPostDocs(snapshot.data!.docs);
          _primeFirstVisiblePost(provider, docs);
          final parallelLens = provider.feedMode == FeedMode.parallel
              ? SurpriseEngineService.buildParallelFeedLens(
                  docs.map((doc) => doc.data()).toList(),
                )
              : null;
          final toneLens = provider.feedMode == FeedMode.deep
              ? SocialExperienceService.buildFeedToneLens('deep')
              : provider.feedMode == FeedMode.fun
                  ? SocialExperienceService.buildFeedToneLens('fun')
                  : null;

          if (provider.feedMode == FeedMode.following && docs.isEmpty) {
            return const _FeedEmptyState(
              title: 'Takip akışın boş',
              subtitle:
                  'Takip ettiğin hesapların gönderileri burada görünecek.',
            );
          }

          return Stack(
            children: [
              // Main vertical feed
              PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: docs.length,
                onPageChanged: (index) {
                  final data = docs[index].data();
                  provider.registerPostView(
                    postId: docs[index].id,
                    hashtags: List<String>.from(data['hashtags'] ?? const []),
                  );
                },
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  return VideoItem(
                    imageUrl: data['imageUrl'] ?? '',
                    prompt: data['prompt'] ?? 'AI Vibeo',
                    userId: data['userId'] ?? 'Unknown',
                    postId: docs[index].id,
                    contentOriginLabel:
                        (data['contentOriginLabel'] ?? '') as String,
                    proofHumanScore: (data['proofHumanScore'] ?? 0) as int,
                    proofAiScore: (data['proofAiScore'] ?? 0) as int,
                    recommendationReasons: provider.buildRecommendationReasons({
                      ...data,
                      'id': docs[index].id,
                    }),
                  );
                },
              ),

              // Stories bar overlay at top
              Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    _FeedModeBar(
                      selected: provider.feedMode,
                      onChanged: provider.setFeedMode,
                      loading: provider.isFeedLoading,
                    ),
                    if (parallelLens != null) ...[
                      const SizedBox(height: 8),
                      _ParallelModePanel(lens: parallelLens),
                    ],
                    if (toneLens != null) ...[
                      const SizedBox(height: 8),
                      _FeedTonePanel(lens: toneLens),
                    ],
                    const SizedBox(height: 8),
                    const StoriesBar(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeedModeBar extends StatelessWidget {
  final FeedMode selected;
  final ValueChanged<FeedMode> onChanged;
  final bool loading;

  const _FeedModeBar({
    required this.selected,
    required this.onChanged,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    const items = <FeedMode, String>{
      FeedMode.forYou: 'Sana Ozel',
      FeedMode.following: 'Takip',
      FeedMode.trending: 'Trend',
      FeedMode.parallel: 'Parallel',
      FeedMode.deep: 'Deep',
      FeedMode.fun: 'Fun',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: items.entries.map((entry) {
            final isSelected = entry.key == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.cyanAccent.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: loading && isSelected
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.cyanAccent,
                            ),
                          )
                        : Text(
                            entry.value,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.cyanAccent
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FeedTonePanel extends StatelessWidget {
  final FeedToneLens lens;

  const _FeedTonePanel({required this.lens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lens.title,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lens.summary,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParallelModePanel extends StatelessWidget {
  final ParallelFeedLens lens;

  const _ParallelModePanel({required this.lens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alt_route_rounded,
                    color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Text(
                  lens.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              lens.summary,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.public_rounded,
                      color: Colors.cyanAccent, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lens.realityName,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lens.realitySummary,
                          style: const TextStyle(
                            color: Colors.white60,
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lens.anchors.map((anchor) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    anchor,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FeedEmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 60, color: Colors.white12),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
