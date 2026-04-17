import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/orbit_service.dart';
import '../../services/social_experience_service.dart';
import '../../services/time_capsule_service.dart';

class SocialOsScreen extends StatefulWidget {
  const SocialOsScreen({super.key});

  @override
  State<SocialOsScreen> createState() => _SocialOsScreenState();
}

class _SocialOsScreenState extends State<SocialOsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
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
        backgroundColor: const Color(0xFF03070D),
        title: const Text('Social OS'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: Colors.cyanAccent,
          tabs: const [
            Tab(text: 'Felsefe'),
            Tab(text: 'Orbitler'),
            Tab(text: 'Kapsül'),
            Tab(text: 'Wellness'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _PhilosophyTab(),
          _OrbitTab(),
          _CapsuleTab(),
          _WellnessTab(),
        ],
      ),
    );
  }
}

class _PhilosophyTab extends StatelessWidget {
  const _PhilosophyTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? const <String, dynamic>{};
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .limit(12)
              .snapshots(),
          builder: (context, postSnapshot) {
            final posts =
                postSnapshot.data?.docs.map((doc) => doc.data()).toList() ??
                    const <Map<String, dynamic>>[];
            final latestPrompt =
                posts.isEmpty ? '' : (posts.first['prompt'] ?? '') as String;
            final hint = SocialExperienceService.buildCompanionHint(
              prompt: latestPrompt,
              username: (userData['username'] ?? 'vibeo') as String,
            );
            final tokens = SocialExperienceService.buildKnowledgeTokenSnapshot(
              userData: userData,
              posts: posts,
            );
            final values = SocialExperienceService.buildValueMatchSignals(
              userData: userData,
              posts: posts,
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SurfaceCard(
                  title: 'Gerçek Sohbet Modu',
                  subtitle:
                      'Beğeni yerine sohbet kalitesi merkezi. Kısa gürültü yerine cevap üretme ihtimali olan içerikler öne çıkar.',
                  accent: Colors.cyanAccent,
                  child: Text(
                    posts.isEmpty
                        ? 'İlk paylaşımını yaptıktan sonra kalite skorun burada görünecek.'
                        : 'Son paylaşım kalite skoru: ${SocialExperienceService.conversationQualityScore(posts.first)}/100',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 14),
                _SurfaceCard(
                  title: 'AI Companion',
                  subtitle: hint.message,
                  accent: Colors.purpleAccent,
                  child: Text(
                    hint.rewrite,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ),
                const SizedBox(height: 14),
                _IdentityModeCard(userData: userData),
                const SizedBox(height: 14),
                _SurfaceCard(
                  title: 'Knowledge Token',
                  subtitle: tokens.accessLabel,
                  accent: Colors.amber,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetricChip(label: 'Knowledge ${tokens.knowledgeTokens}'),
                      _MetricChip(label: 'Orbit ${tokens.orbitTokens}'),
                      _MetricChip(label: 'Creator ${tokens.creatorCredits}'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SurfaceCard(
                  title: 'Value Match',
                  subtitle:
                      'İnsanlar sadece ortak ilgiyle değil, uzun vadeli düşünme ve üretim tarzına göre de eşleşsin.',
                  accent: Colors.greenAccent,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: values
                        .map((value) => _MetricChip(label: value))
                        .toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OrbitTab extends StatefulWidget {
  const _OrbitTab();

  @override
  State<_OrbitTab> createState() => _OrbitTabState();
}

class _OrbitTabState extends State<_OrbitTab> {
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _createOrbit() async {
    final name = _nameCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    if (name.isEmpty || description.isEmpty) return;
    await OrbitService.createOrbit(
      name: name,
      description: description,
      themes: name.toLowerCase().split(' '),
    );
    if (!mounted) return;
    _nameCtrl.clear();
    _descriptionCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SurfaceCard(
          title: 'Orbit Oluştur',
          subtitle:
              'Circle yerine Orbit. Bir post sadece ilgili çekim alanlarında görünür.',
          accent: Colors.cyanAccent,
          child: Column(
            children: [
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Örn. Felsefe Orbiti',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Bu orbit neyi savunur?',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _createOrbit,
                  child: const Text('Orbit Aç'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OrbitService.suggestedOrbits().map((orbit) {
            return _MetricChip(label: orbit['name'] as String);
          }).toList(),
        ),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: OrbitService.streamOrbits(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final members =
                    List<String>.from(data['members'] ?? const <String>[]);
                final joined = members.contains(uid);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SurfaceCard(
                    title: (data['name'] ?? 'Orbit') as String,
                    subtitle: (data['description'] ?? '') as String,
                    accent: Colors.blueAccent,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${(data['memberCount'] ?? 0) as int} üye',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => OrbitService.toggleMembership(
                            orbitId: doc.id,
                            joined: joined,
                          ),
                          child: Text(joined ? 'Ayrıl' : 'Katıl'),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CapsuleTab extends StatelessWidget {
  const _CapsuleTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TimeCapsuleService.streamMine(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SurfaceCard(
              title: 'Zaman Kapsülü',
              subtitle:
                  'Bir postu 1 yıl, 5 yıl veya 10 yıl sonra açılacak şekilde saklayabilirsin. Kapsüller post detayından planlanır.',
              accent: Colors.amber,
              child: SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            if (docs.isEmpty)
              const _SurfaceCard(
                title: 'Henüz kapsül yok',
                subtitle: 'Bir post detayından ilk zaman kapsülünü oluştur.',
                accent: Colors.white54,
                child: SizedBox.shrink(),
              ),
            ...docs.map((doc) {
              final data = doc.data();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SurfaceCard(
                  title: (data['prompt'] ?? 'Kapsül') as String,
                  subtitle: (data['note'] ?? '') as String,
                  accent: Colors.amber,
                  child: Text(
                    'Açılış: ${TimeCapsuleService.formatReveal(data['revealAt'] as Timestamp?)}',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _WellnessTab extends StatelessWidget {
  const _WellnessTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? const <String, dynamic>{};
        final viewedIds =
            List<String>.from(userData['viewedPostIds'] ?? const <String>[]);
        return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future:
              FirebaseFirestore.instance.collection('posts').limit(40).get(),
          builder: (context, postsSnapshot) {
            final allPosts =
                postsSnapshot.data?.docs.map((doc) => doc.data()).toList() ??
                    const <Map<String, dynamic>>[];
            final viewedPosts = allPosts
                .where((post) {
                  return viewedIds.isEmpty ||
                      viewedIds.contains((post['id'] ?? '').toString());
                })
                .take(max(viewedIds.length, 1))
                .toList();
            final report = SocialExperienceService.buildWellnessReport(
              userData: userData,
              viewedPosts: viewedPosts,
            );
            final detoxMode = (userData['dopamineDetoxMode'] ?? false) as bool;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SurfaceCard(
                  title: 'Ekran Süresi Gerçeği',
                  subtitle: report.summary,
                  accent: Colors.greenAccent,
                  child: Text(
                    report.advice,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ),
                const SizedBox(height: 14),
                _SurfaceCard(
                  title: 'Dopamin Detoks Modu',
                  subtitle:
                      'Açıldığında akışta metin ve derin içerik ağırlığı artar, görsel/video yoğunluğu düşer.',
                  accent: Colors.greenAccent,
                  child: SwitchListTile(
                    value: detoxMode,
                    activeThumbColor: Colors.greenAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .set({
                        'dopamineDetoxMode': value,
                      }, SetOptions(merge: true));
                    },
                    title: Text(
                      detoxMode ? 'Detoks aktif' : 'Detoks pasif',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _SurfaceCard(
                  title: 'Gerçek Hayata Taşı',
                  subtitle:
                      'Yakındaki insanlarla değil, değer ve ilgi çakışmalarına göre güvenli buluşma önerisi katmanı tasarlandı.',
                  accent: Colors.cyanAccent,
                  child: Text(
                    'Şimdilik eşleşme sinyalleri hesaplanıyor. Sonraki aşamada güvenlik katmanlı buluşma önerileri açılabilir.',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _IdentityModeCard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const _IdentityModeCard({required this.userData});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final currentMode = (userData['identityMode'] ?? 'fluid') as String;

    Future<void> setMode(String mode) async {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'identityMode': mode,
      }, SetOptions(merge: true));
    }

    return _SurfaceCard(
      title: 'Anonimlik + Gerçek Kimlik Dengesi',
      subtitle:
          'İstersen anonim, istersen doğrulanmış, istersen iki mod arasında akışkan kal.',
      accent: Colors.purpleAccent,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final mode in const ['anonymous', 'verified', 'fluid'])
            ChoiceChip(
              selected: currentMode == mode,
              label: Text(mode),
              selectedColor: Colors.purpleAccent,
              onSelected: (_) => setMode(mode),
              labelStyle: TextStyle(
                color: currentMode == mode ? Colors.black : Colors.white70,
              ),
            ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  const _SurfaceCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;

  const _MetricChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
