import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class TwinSetupScreen extends StatefulWidget {
  const TwinSetupScreen({super.key});

  @override
  State<TwinSetupScreen> createState() => _TwinSetupScreenState();
}

class _TwinSetupScreenState extends State<TwinSetupScreen> {
  final _bioCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();
  final _testCtrl = TextEditingController();

  bool _enabled = false;
  String _tone = 'samimi';
  List<String> _interests = [];
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  String? _testReply;

  static const _tones = ['samimi', 'resmi', 'esprili', 'romantik', 'ciddi'];

  static const _suggestedInterests = [
    'müzik', 'film', 'spor', 'kitap', 'oyun', 'yemek',
    'seyahat', 'fotoğraf', 'teknoloji', 'moda', 'sanat', 'doğa',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final twin = doc.data()?['aiTwin'] as Map<String, dynamic>?;
    if (twin != null) {
      setState(() {
        _enabled = (twin['enabled'] ?? false) as bool;
        _bioCtrl.text = (twin['bio'] ?? '') as String;
        _interests = List<String>.from(twin['interests'] ?? []);
        _tone = (twin['tone'] ?? 'samimi') as String;
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'aiTwin': {
        'enabled': _enabled,
        'bio': _bioCtrl.text.trim(),
        'interests': _interests,
        'tone': _tone,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI İkiz ayarların kaydedildi 🤖'),
          backgroundColor: Colors.purpleAccent,
        ),
      );
    }
  }

  void _addInterest(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty || _interests.contains(t)) return;
    setState(() => _interests.add(t));
    _interestCtrl.clear();
  }

  /// Test the twin locally (without posting to any chat).
  Future<void> _testTwin() async {
    final msg = _testCtrl.text.trim();
    if (msg.isEmpty) return;
    setState(() {
      _testing = true;
      _testReply = null;
    });

    try {
      final username =
          FirebaseAuth.instance.currentUser?.displayName ?? 'sen';
      final interestsStr =
          _interests.isEmpty ? 'genel konular' : _interests.join(', ');

      final prompt = Uri.encodeComponent(
        '''Sen @$username adlı bir kişisin.
Biyografi: ${_bioCtrl.text.trim().isEmpty ? 'yok' : _bioCtrl.text.trim()}
İlgi alanları: $interestsStr
Konuşma tarzı: $_tone

Sana gelen mesaj: "$msg"

Bu kişi gibi, onun tarzında, Türkçe, KISA (maks. 2 cümle) ve doğal bir yanıt ver. Sadece yanıtı yaz.''',
      );

      final res = await http
          .get(Uri.parse('https://text.pollinations.ai/$prompt'))
          .timeout(const Duration(seconds: 20));

      setState(() {
        _testReply = res.statusCode == 200
            ? res.body.trim()
            : 'Yanıt alınamadı';
      });
    } catch (_) {
      setState(() => _testReply = 'Bağlantı hatası.');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _interestCtrl.dispose();
    _testCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🤖', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('AI İKİZ',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.purpleAccent),
                  )
                : const Text('KAYDET',
                    style: TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.2),
                    Colors.deepPurple.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Text('🤖', style: TextStyle(fontSize: 36)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dijital İkizin',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                          'Sen çevrimdışıyken gelen mesaplara AI senin tarzında yanıt verir.',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Enable toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('AI İkizi etkinleştir',
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  _enabled
                      ? '✓ Aktif — mesajlara otomatik yanıt veriyor'
                      : '✗ Pasif — sadece sen yanıtlayabilirsin',
                  style: TextStyle(
                      color:
                          _enabled ? Colors.greenAccent : Colors.white38,
                      fontSize: 12),
                ),
                value: _enabled,
                activeColor: Colors.purpleAccent,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ),

            const SizedBox(height: 20),

            // Bio
            _SectionLabel('Biyografi', 'Kendini kısaca tanıt'),
            TextField(
              controller: _bioCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Örn: İstanbul\'da yaşayan bir yazılımcıyım, kahve ve film seviyorum',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white10,
                counterStyle: const TextStyle(color: Colors.white24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Interests
            _SectionLabel('İlgi Alanları', 'Konuşmak sevdiğin konular'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._interests.map((i) => Chip(
                      label: Text(i),
                      backgroundColor:
                          Colors.purpleAccent.withValues(alpha: 0.2),
                      labelStyle: const TextStyle(color: Colors.purpleAccent),
                      deleteIconColor: Colors.purpleAccent,
                      side: BorderSide(
                          color: Colors.purpleAccent.withValues(alpha: 0.5)),
                      onDeleted: () =>
                          setState(() => _interests.remove(i)),
                    )),
              ],
            ),
            const SizedBox(height: 8),
            // Quick-add suggestions
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _suggestedInterests
                  .where((s) => !_interests.contains(s))
                  .map((s) => GestureDetector(
                        onTap: () => setState(() => _interests.add(s)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('+ $s',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _interestCtrl,
              style: const TextStyle(color: Colors.white),
              onSubmitted: _addInterest,
              decoration: InputDecoration(
                hintText: 'Özel ilgi alanı ekle...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white10,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: Colors.purpleAccent),
                  onPressed: () => _addInterest(_interestCtrl.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tone
            _SectionLabel('Konuşma Tarzı', 'İkizin nasıl konuşsun?'),
            Wrap(
              spacing: 8,
              children: _tones.map((t) {
                final selected = _tone == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (_) => setState(() => _tone = t),
                  backgroundColor: Colors.white10,
                  selectedColor: Colors.purpleAccent.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: selected ? Colors.purpleAccent : Colors.white70,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected
                        ? Colors.purpleAccent
                        : Colors.white24,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // Test area
            _SectionLabel('🧪 Test Et', 'İkizin nasıl yanıtlıyor gör'),
            TextField(
              controller: _testCtrl,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => _testTwin(),
              decoration: InputDecoration(
                hintText: 'Test mesajı yaz...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white10,
                suffixIcon: IconButton(
                  icon: _testing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.purpleAccent),
                        )
                      : const Icon(Icons.send, color: Colors.purpleAccent),
                  onPressed: _testing ? null : _testTwin,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_testReply != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.purpleAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('🤖', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 6),
                        Text('AI İkizin:',
                            style: TextStyle(
                                color: Colors.purpleAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(_testReply!,
                        style:
                            const TextStyle(color: Colors.white, height: 1.4)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionLabel(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
