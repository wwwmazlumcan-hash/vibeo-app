import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../widgets/vibeo_button.dart';
import '../../widgets/vibeo_input.dart';
import '../../services/moderation_service.dart';
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('AI STUDIO',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.image), text: 'Görsel Üret'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI Yazar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ImageTab(),
          _TextTab(),
        ],
      ),
    );
  }
}

// ─── IMAGE TAB ────────────────────────────────────────────────────────────────

class _ImageTab extends StatefulWidget {
  const _ImageTab();

  @override
  State<_ImageTab> createState() => _ImageTabState();
}

class _ImageTabState extends State<_ImageTab> {
  final _promptController = TextEditingController();
  String? _generatedImageUrl;
  bool _isLoading = false;
  int _charCount = 0;

  static const _suggestions = [
    'Siberpunk İstanbul, neon ışıklar, yağmur',
    'Japon bahçesi, kiraz çiçekleri, gün batımı',
    'Uzayda yüzen astronot, galaksi arka plan',
    'Sihirli orman, parıldayan mantarlar, gece',
    'Fütüristik şehir, uçan arabalar, 2077',
    'Antik Mısır, piramitler, altın çöl',
  ];

  @override
  void initState() {
    super.initState();
    _promptController.addListener(
        () => setState(() => _charCount = _promptController.text.length));
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _generateImage() {
    final text = _promptController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir hayal kurup yazın!")),
      );
      return;
    }

    // Moderasyon kontrolü
    final violation = ModerationService.checkText(text);
    if (violation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(violation), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedImageUrl =
          "https://image.pollinations.ai/prompt/${Uri.encodeFull(text)}?width=1080&height=1920&nologo=true&seed=${DateTime.now().millisecondsSinceEpoch}";
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _shareVibeo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _generatedImageUrl == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'imageUrl': _generatedImageUrl,
        'prompt': _promptController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'likedBy': [],
        'likesCount': 0,
        'reportCount': 0,
      });

      // XP ödülü
      await PointsService.award(PointsService.pointsPerPost,
          reason: 'Vibeo paylaşıldı');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vibeo Paylaşıldı! +10 XP kazandın 🎉"),
          backgroundColor: Colors.cyanAccent,
        ),
      );
      _promptController.clear();
      setState(() => _generatedImageUrl = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Hata oluştu: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fikir al:',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _promptController.text = _suggestions[i],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_suggestions[i],
                      style: const TextStyle(
                          color: Colors.cyanAccent, fontSize: 12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              VibeoInput(
                controller: _promptController,
                hintText: "Hayal et ve yaz...",
                maxLines: 3,
              ),
              Positioned(
                right: 12,
                bottom: 10,
                child: Text(
                  '$_charCount/500',
                  style: TextStyle(
                    color: _charCount > 400 ? Colors.redAccent : Colors.white24,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          VibeoButton(
            text: "GÖRSELİ OLUŞTUR",
            onPressed: _generateImage,
            isLoading: _isLoading && _generatedImageUrl == null,
          ),
          const SizedBox(height: 30),
          if (_generatedImageUrl != null) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                      blurRadius: 20)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  _generatedImageUrl!,
                  height: 400,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loading) {
                    if (loading == null) return child;
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
            const SizedBox(height: 25),
            VibeoButton(
              text: "DÜNYA İLE PAYLAŞ  +10 XP",
              onPressed: _shareVibeo,
              isLoading: _isLoading && _generatedImageUrl != null,
              color: Colors.white,
            ),
          ] else ...[
            const SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 80, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 12),
                  const Text("Henüz bir şey üretilmedi",
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

// ─── TEXT / AI WRITER TAB ─────────────────────────────────────────────────────

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
    'Bana ilham verici bir söz yaz',
    'Kısa bir şiir yaz',
    'Vibeo için caption yaz',
    'Motivasyon metni yaz',
    'Komik bir etiket yaz',
    'Türkçe slogan yaz',
  ];

  @override
  void initState() {
    super.initState();
    _msgs.add(_Msg(
      text: '✨ AI Yazarın burada!\nSana özgün içerik, caption, şiir veya slogan üretebilirim.',
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
      final prompt = Uri.encodeComponent(
          'Kısa, yaratıcı ve Türkçe cevap ver: $q');
      final res = await http
          .get(Uri.parse('https://text.pollinations.ai/$prompt'))
          .timeout(const Duration(seconds: 20));

      setState(() => _msgs.add(_Msg(
            text: res.statusCode == 200
                ? res.body.trim()
                : 'Şu an yanıt veremiyorum.',
            isAi: true,
          )));
    } catch (_) {
      setState(() => _msgs
          .add(_Msg(text: 'Bağlantı hatası. Tekrar dene.', isAi: true)));
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
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _quickPrompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _ask(_quickPrompts[i]),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_quickPrompts[i],
                    style: const TextStyle(
                        color: Colors.cyanAccent, fontSize: 12)),
              ),
            ),
          ),
        ),
        const Divider(color: Colors.white12, height: 16),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _msgs.length) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(color: Colors.cyanAccent),
                );
              }
              final m = _msgs[i];
              return Align(
                alignment:
                    m.isAi ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8),
                  decoration: BoxDecoration(
                    color: m.isAi
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: m.isAi
                        ? Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.2))
                        : null,
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
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _ask,
                  decoration: InputDecoration(
                    hintText: 'Ne üreteyim?',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _ask(_ctrl.text),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
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
