import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/bookmark_service.dart';
import '../../services/hashtag_service.dart';
import '../../services/reality_layer_service.dart';
import '../../services/social_experience_service.dart';
import '../../services/spark_service.dart';
import '../../services/surprise_engine_service.dart';
import '../../services/time_capsule_service.dart';
import '../remix/remix_duel_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String imageUrl;
  final String prompt;
  final String username;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.imageUrl,
    required this.prompt,
    required this.username,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _aiEnhanced = true;
  bool _remixing = false;
  bool _saved = false;
  bool _saving = false;
  bool _sparked = false;
  bool _sparking = false;
  String? _remixedUrl;
  String _remixedPrompt = '';
  RealityLayerMode _realityMode = RealityLayerMode.balanced;

  static const _bg = Color(0xFF03070D);

  @override
  void initState() {
    super.initState();
    _loadSavedStatus();
    _loadSparkState();
  }

  Future<void> _loadSavedStatus() async {
    if (widget.postId.isEmpty) return;
    final saved = await BookmarkService.isSaved(widget.postId);
    if (!mounted) return;
    setState(() => _saved = saved);
  }

  Future<void> _loadSparkState() async {
    if (widget.postId.isEmpty) return;
    final sparked = await SparkService.hasSparked(widget.postId);
    if (!mounted) return;
    setState(() => _sparked = sparked);
  }

  Future<void> _toggleSave() async {
    if (widget.postId.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await BookmarkService.toggleSaved(widget.postId, isSaved: _saved);
      if (!mounted) return;
      setState(() => _saved = !_saved);
    } catch (e) {
      _showError('Kaydetme hatası: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remix(String styleHint) async {
    setState(() {
      _remixing = true;
      _remixedUrl = null;
    });

    final newPrompt = '${widget.prompt}, $styleHint';
    _remixedPrompt = newPrompt;
    final encoded = Uri.encodeComponent(newPrompt);
    final url =
        'https://image.pollinations.ai/prompt/$encoded?width=1024&height=1024&nologo=true&enhance=$_aiEnhanced';

    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 45));
      if (res.statusCode == 200 && mounted) {
        setState(() => _remixedUrl = url);
      } else if (mounted) {
        _showError('Remix başarısız: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Ağ hatası: $e');
      }
    }
    if (mounted) setState(() => _remixing = false);
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _toggleSpark() async {
    if (_sparking || widget.postId.isEmpty) return;
    setState(() => _sparking = true);
    try {
      await SparkService.toggleSpark(postId: widget.postId);
      if (!mounted) return;
      setState(() => _sparked = !_sparked);
      final starter = SparkService.buildConversationStarter(widget.prompt);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _sparked ? 'Spark gönderildi. $starter' : 'Spark geri çekildi.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _sparking = false);
    }
  }

  Future<void> _scheduleCapsule() async {
    final noteCtrl = TextEditingController();
    int years = 1;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text('Zaman Kapsülü'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<int>(
                        value: years,
                        isExpanded: true,
                        items: const [1, 5, 10]
                            .map((year) => DropdownMenuItem(
                                  value: year,
                                  child: Text('$year yıl sonra aç'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => years = value);
                          }
                        },
                      ),
                      TextField(
                        controller: noteCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Gelecekteki kendine not bırak...',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Vazgeç'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Planla'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await TimeCapsuleService.scheduleCapsule(
      postId: widget.postId,
      prompt: widget.prompt,
      revealAt: DateTime.now().add(Duration(days: years * 365)),
      note: noteCtrl.text.trim(),
    );
    noteCtrl.dispose();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zaman kapsülü planlandı.'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  Future<void> _share() async {
    if (_remixedUrl == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final hashtags = HashtagService.extractHashtags(_remixedPrompt);

    await FirebaseFirestore.instance.collection('posts').add({
      'userId': uid,
      'imageUrl': _remixedUrl,
      'prompt': _remixedPrompt,
      'hashtags': hashtags,
      'contentOriginLabel':
          _aiEnhanced ? 'AI optimize remix' : 'İnsan + AI remix',
      'creationMode': 'remix',
      'proofHumanScore': _aiEnhanced ? 34 : 48,
      'proofAiScore': _aiEnhanced ? 91 : 72,
      'likesCount': 0,
      'likedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
      'remixOf': widget.postId,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remix paylaşıldı ✨'),
          backgroundColor: Colors.cyanAccent,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = _remixedUrl ?? widget.imageUrl;
    final companionHint = SocialExperienceService.buildCompanionHint(
      prompt: widget.prompt,
      username: widget.username,
    );
    final parallelVariants =
        SocialExperienceService.buildParallelUniverseVariants(
      prompt: widget.prompt,
      hashtags: HashtagService.extractHashtags(widget.prompt),
    );

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('@${widget.username}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('posts')
                  .where('remixOf', isEqualTo: widget.postId)
                  .limit(12)
                  .get(),
              builder: (context, remixSnapshot) {
                final remixDocs = remixSnapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final lineage = SurpriseEngineService.buildRemixLineageInsight(
                  isRemix: _remixedPrompt.isNotEmpty,
                  descendantCount: remixDocs.length,
                );
                final accent = switch (lineage.colorSeed) {
                  ColorSeed.amber => Colors.amber,
                  ColorSeed.pink => Colors.pinkAccent,
                  ColorSeed.green => Colors.greenAccent,
                  ColorSeed.purple => Colors.purpleAccent,
                  ColorSeed.cyan => Colors.cyanAccent,
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lineage.title,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lineage.summary,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),
                        if (remixDocs.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 84,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: remixDocs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final data = remixDocs[index].data();
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PostDetailScreen(
                                        postId: remixDocs[index].id,
                                        imageUrl:
                                            (data['imageUrl'] ?? '') as String,
                                        prompt:
                                            (data['prompt'] ?? '') as String,
                                        username:
                                            ((data['userId'] ?? '') as String)
                                                .substring(
                                          0,
                                          ((data['userId'] ?? '') as String)
                                              .length
                                              .clamp(0, 6),
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      (data['imageUrl'] ?? '') as String,
                                      width: 84,
                                      height: 84,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const ColoredBox(
                                        color: Colors.black,
                                        child: SizedBox(
                                          width: 84,
                                          height: 84,
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.white24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .get(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? const <String, dynamic>{};
                final label = (data['contentOriginLabel'] ?? '') as String;
                final proofHuman = (data['proofHumanScore'] ?? 0) as int;
                final proofAi = (data['proofAiScore'] ?? 0) as int;

                if (label.isEmpty && proofHuman == 0 && proofAi == 0) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (label.isNotEmpty)
                        _MetaChip(label: label, accent: Colors.purpleAccent),
                      if (proofHuman > 0)
                        _MetaChip(
                            label: 'Yaratıcılık $proofHuman',
                            accent: Colors.orangeAccent),
                      if (proofAi > 0)
                        _MetaChip(
                            label: 'Verimlilik $proofAi',
                            accent: Colors.cyanAccent),
                    ],
                  ),
                );
              },
            ),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .get(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? const <String, dynamic>{};
                if (data.isEmpty) return const SizedBox.shrink();
                final afterimage =
                    SurpriseEngineService.buildPostAfterimage(data);
                final accent = switch (afterimage.colorSeed) {
                  ColorSeed.amber => Colors.amber,
                  ColorSeed.pink => Colors.pinkAccent,
                  ColorSeed.green => Colors.greenAccent,
                  ColorSeed.purple => Colors.purpleAccent,
                  ColorSeed.cyan => Colors.cyanAccent,
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          afterimage.title,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          afterimage.summary,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (HashtagService.extractHashtags(widget.prompt).isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HashtagService.extractHashtags(widget.prompt)
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            // Image card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    blurRadius: 28,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      Image.network(
                        displayUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (_, child, l) {
                          if (l == null) return child;
                          return const ColoredBox(
                            color: Colors.black,
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: Colors.cyanAccent)),
                          );
                        },
                      ),
                      if (_remixing)
                        Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: Colors.cyanAccent),
                                SizedBox(height: 14),
                                Text('Remixleniyor...',
                                    style: TextStyle(color: Colors.cyanAccent)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.prompt,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.purpleAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companionHint.title,
                    style: const TextStyle(
                      color: Colors.purpleAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    companionHint.message,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    companionHint.rewrite,
                    style: const TextStyle(color: Colors.white54, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.orangeAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spark',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    SparkService.buildConversationStarter(widget.prompt),
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _sparking ? null : _toggleSpark,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.black,
                        ),
                        icon: Icon(_sparked ? Icons.bolt : Icons.bolt_outlined),
                        label: Text(_sparked ? 'Spark aktif' : 'Spark at'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .get(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? const <String, dynamic>{};
                final label = (data['contentOriginLabel'] ?? '') as String;
                final proofHuman = (data['proofHumanScore'] ?? 0) as int;
                final proofAi = (data['proofAiScore'] ?? 0) as int;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dinamik Gerçeklik Katmanları',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: RealityLayerMode.values.map((mode) {
                          final selected = mode == _realityMode;
                          return ChoiceChip(
                            label: Text(_labelForRealityMode(mode)),
                            selected: selected,
                            selectedColor: Colors.cyanAccent,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.05),
                            labelStyle: TextStyle(
                              color: selected ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) =>
                                setState(() => _realityMode = mode),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      FutureBuilder<RealityLayerResult>(
                        future: RealityLayerService.adapt(
                          prompt: widget.prompt,
                          contentOriginLabel: label,
                          proofHumanScore: proofHuman,
                          proofAiScore: proofAi,
                          mode: _realityMode,
                        ),
                        builder: (context, layerSnap) {
                          if (layerSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: CircularProgressIndicator(
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            );
                          }

                          final result = layerSnap.data;
                          if (result == null) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.title,
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                result.summary,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                result.accessibilityHint,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _MetaChip(
                                label: result.signature,
                                accent: Colors.greenAccent,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    _saved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.cyanAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _saved ? 'Gönderi kaydedildi' : 'Gönderiyi kaydet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _toggleSave,
                    child: Text(
                      _saving ? '...' : (_saved ? 'Kaldır' : 'Kaydet'),
                      style: const TextStyle(color: Colors.cyanAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parallel Universe',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...parallelVariants.map((variant) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${variant.orbitName} • ${variant.angle}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            variant.summary,
                            style: const TextStyle(
                              color: Colors.white60,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RemixDuelScreen(
                      seedPostId: widget.postId,
                      seedImageUrl: widget.imageUrl,
                      seedPrompt: widget.prompt,
                      seedUsername: widget.username,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.orangeAccent.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.sports_martial_arts,
                    color: Colors.orangeAccent),
                label: const Text(
                  'Remix Duel Başlat',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _scheduleCapsule,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.lock_clock, color: Colors.amber),
                label: const Text(
                  'Zaman Kapsülü Planla',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // AI Enhanced toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI Enhanced',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: _aiEnhanced,
                    activeThumbColor: Colors.cyanAccent,
                    onChanged: (v) => setState(() => _aiEnhanced = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Remix stilleri',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _RemixChip(
                    label: 'Daha Ciddi',
                    onTap: () => _remix('serious, cinematic')),
                _RemixChip(
                    label: 'Daha Viral',
                    onTap: () => _remix('viral, eye-catching')),
                _RemixChip(
                    label: 'Daha Duygu',
                    onTap: () => _remix('emotional, heartfelt')),
                _RemixChip(
                    label: 'Daha Retro',
                    onTap: () => _remix('retro 80s aesthetic')),
                _RemixChip(
                    label: 'Daha Neon', onTap: () => _remix('cyberpunk neon')),
                _RemixChip(
                    label: 'Daha Rüya', onTap: () => _remix('dreamy surreal')),
              ],
            ),

            const SizedBox(height: 28),

            // Share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _remixedUrl == null ? null : _share,
                icon: const Icon(Icons.send_rounded, color: Colors.black),
                label: const Text('Paylaş',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  disabledBackgroundColor:
                      Colors.cyanAccent.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForRealityMode(RealityLayerMode mode) {
    switch (mode) {
      case RealityLayerMode.balanced:
        return 'Dengeli';
      case RealityLayerMode.child:
        return 'Çocuk';
      case RealityLayerMode.expert:
        return 'Uzman';
      case RealityLayerMode.audio:
        return 'Sesli';
      case RealityLayerMode.haptic:
        return 'Haptic';
    }
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _MetaChip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RemixChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RemixChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
