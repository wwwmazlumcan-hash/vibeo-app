import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/hashtag_service.dart';
import '../../services/moderation_service.dart';
import '../../services/openai_text_service.dart';
import '../../services/points_service.dart';

class AiStudioScreen extends StatefulWidget {
  const AiStudioScreen({super.key});

  @override
  State<AiStudioScreen> createState() => _AiStudioScreenState();
}

class _AiStudioScreenState extends State<AiStudioScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Colors.cyanAccent, Color(0xFF006666)],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.5),
                            blurRadius: 12),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.black, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('AI Studio',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
              ),
              child: TabBar(
                controller: _tabs,
                indicatorColor: Colors.cyanAccent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.cyanAccent,
                unselectedLabelColor: Colors.white38,
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'Görsel Üret'),
                  Tab(text: 'AI Yazar'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _ImageTab(),
                  _TextTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTab extends StatefulWidget {
  const _ImageTab();

  @override
  State<_ImageTab> createState() => _ImageTabState();
}

class _ImageTabState extends State<_ImageTab> {
  final _promptCtrl = TextEditingController();
  String? _generatedImageUrl;
  bool _loading = false;
  int _charCount = 0;

  static const _suggestions = [
    'Siberpunk İstanbul, neon ışıklar',
    'Japon bahçesi, kiraz çiçekleri',
    'Uzayda yüzen astronot, galaksi',
    'Sihirli orman, parıldayan mantarlar',
    'Fütüristik şehir, 2077',
    'Antik Mısır, piramitler',
  ];

  @override
  void initState() {
    super.initState();
    _promptCtrl.addListener(
        () => setState(() => _charCount = _promptCtrl.text.length));
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    final text = _promptCtrl.text.trim();
    if (text.isEmpty) return;

    final violation = ModerationService.checkText(text);
    if (violation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(violation), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _loading = true;
      _generatedImageUrl =
          "https://image.pollinations.ai/prompt/${Uri.encodeFull(text)}?width=1080&height=1920&nologo=true&seed=${DateTime.now().millisecondsSinceEpoch}";
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _share() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _generatedImageUrl == null) return;

    setState(() => _loading = true);
    try {
      final hashtags = HashtagService.extractHashtags(_promptCtrl.text.trim());
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'imageUrl': _generatedImageUrl,
        'prompt': _promptCtrl.text.trim(),
        'hashtags': hashtags,
        'contentOriginLabel': 'İnsan + AI',
        'creationMode': 'ai_assisted',
        'proofHumanScore': 38,
        'proofAiScore': 87,
        'createdAt': FieldValue.serverTimestamp(),
        'likedBy': [],
        'likesCount': 0,
        'reportCount': 0,
      });

      await PointsService.award(PointsService.pointsPerPost,
          reason: 'Vibeo paylaşıldı');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vibeo Paylaşıldı! +10 XP'),
          backgroundColor: Colors.cyanAccent,
        ),
      );
      _promptCtrl.clear();
      setState(() => _generatedImageUrl = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Fikir al:',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _promptCtrl.text = _suggestions[i],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.35)),
                  ),
                  child: Text(_suggestions[i],
                      style: const TextStyle(
                          color: Colors.cyanAccent, fontSize: 12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<String>>(
            stream: HashtagService.trendingHashtags(tagLimit: 8),
            builder: (context, snapshot) {
              final tags = snapshot.data ?? const <String>[];
              if (tags.isEmpty) {
                return Text(
                  'Ipucu: keşifte görünmek için açıklamaya #etiket ekle',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trend etiketler',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return GestureDetector(
                        onTap: () {
                          final value = _promptCtrl.text.trim();
                          final insert = '#$tag';
                          _promptCtrl.text =
                              value.isEmpty ? insert : '$value $insert';
                          _promptCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: _promptCtrl.text.length),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.cyanAccent.withValues(alpha: 0.3),
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
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.25)),
                ),
                child: TextField(
                  controller: _promptCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Hayal et ve yaz... örn. #neon #istanbul',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 10,
                child: Text('$_charCount/500',
                    style: TextStyle(
                        color: _charCount > 400
                            ? Colors.redAccent
                            : Colors.white24,
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _loading && _generatedImageUrl == null ? null : _generate,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('GÖRSELİ OLUŞTUR'),
            ),
          ),
          const SizedBox(height: 24),
          if (_generatedImageUrl != null) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border:
                    Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                      blurRadius: 24),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  _generatedImageUrl!,
                  height: 400,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, l) {
                    if (l == null) return child;
                    return const SizedBox(
                      height: 400,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.cyanAccent)),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _loading && _generatedImageUrl != null ? null : _share,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('PAYLAŞ  +10 XP'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 80,
                      color: Colors.cyanAccent.withValues(alpha: 0.1)),
                  const SizedBox(height: 12),
                  const Text('Henüz bir şey üretilmedi',
                      style: TextStyle(color: Colors.white24)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TextTab extends StatefulWidget {
  const _TextTab();

  @override
  State<_TextTab> createState() => _TextTabState();
}

class _TextTabState extends State<_TextTab> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];
  bool _loading = false;

  static const _quickPrompts = [
    'İlham verici bir söz',
    'Kısa bir şiir',
    'Vibeo caption',
    'Motivasyon metni',
    'Komik etiket',
    'Türkçe slogan',
  ];

  @override
  void initState() {
    super.initState();
    _msgs.add(_Msg(
      text:
          'AI Yazarın burada!\nSana özgün içerik, caption, şiir veya slogan üretebilirim.',
      isAi: true,
    ));
  }

  Future<void> _ask(String q) async {
    if (q.trim().isEmpty) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(text: q, isAi: false));
      _loading = true;
    });

    try {
      final reply = await OpenAiTextService.generate(
        prompt: 'Kısa, yaratıcı ve Türkçe cevap ver: $q',
        temperature: 0.9,
        maxTokens: 180,
        fallback: 'Şu an yanıt veremiyorum.',
      );

      setState(() => _msgs.add(_Msg(
            text: reply,
            isAi: true,
          )));
    } catch (e) {
      debugPrint('AI response error: $e');
      setState(() => _msgs.add(_Msg(
          text: 'Bağlantı hatası. Lütfen bağlantınızı kontrol edin.',
          isAi: true)));
    } finally {
      if (mounted) setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _quickPrompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _ask(_quickPrompts[i]),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.35)),
                ),
                child: Text(_quickPrompts[i],
                    style: const TextStyle(
                        color: Colors.cyanAccent, fontSize: 12)),
              ),
            ),
          ),
        ),
        Divider(color: Colors.cyanAccent.withValues(alpha: 0.1), height: 16),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _msgs.length) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: LinearProgressIndicator(
                    color: Colors.cyanAccent,
                    backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
                  ),
                );
              }
              final m = _msgs[i];
              return Align(
                alignment:
                    m.isAi ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8),
                  decoration: BoxDecoration(
                    color: m.isAi
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.cyanAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: m.isAi
                          ? Colors.cyanAccent.withValues(alpha: 0.2)
                          : Colors.cyanAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(m.text,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.4)),
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 10,
          ),
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
                    color: Colors.cyanAccent.withValues(alpha: 0.15))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.2)),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _ask,
                    decoration: const InputDecoration(
                      hintText: 'Ne üreteyim?',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _ask(_ctrl.text),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Colors.cyanAccent, Color(0xFF006666)],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.5),
                          blurRadius: 12),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.black, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Msg {
  final String text;
  final bool isAi;
  _Msg({required this.text, required this.isAi});
}
