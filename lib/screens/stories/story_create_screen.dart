import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryCreateScreen extends StatefulWidget {
  const StoryCreateScreen({super.key});

  @override
  State<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

class _StoryCreateScreenState extends State<StoryCreateScreen> {
  final _promptCtrl = TextEditingController();
  bool _loading = false;
  String? _generatedUrl;

  static const _styles = [
    ('🎨 Dijital Sanat', 'digital art, vibrant colors'),
    ('🌌 Uzay', 'space galaxy nebula, cosmic'),
    ('🌸 Anime', 'anime style, soft lighting'),
    ('💎 Kristal', 'crystal glass, iridescent'),
    ('🔥 Ateş', 'fire flames, dramatic'),
    ('🌊 Su', 'flowing water, serene'),
  ];

  String _selectedStyle = 'digital art, vibrant colors';

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final fullPrompt =
          '${_promptCtrl.text.trim()}, $_selectedStyle, 9:16 vertical';
      final encoded = Uri.encodeComponent(fullPrompt);
      final url =
          'https://image.pollinations.ai/prompt/$encoded?width=540&height=960&nologo=true&seed=${DateTime.now().millisecondsSinceEpoch}';
      // Warm up the URL
      setState(() => _generatedUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publish() async {
    if (_generatedUrl == null) return;
    setState(() => _loading = true);
    try {
      final me = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('stories').add({
        'userId': me.uid,
        'imageUrl': _generatedUrl,
        'prompt': _promptCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 24))),
        'views': 0,
      });
      if (mounted) Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text('AI Hikaye Oluştur'),
        actions: [
          if (_generatedUrl != null)
            TextButton(
              onPressed: _loading ? null : _publish,
              child: const Text('Paylaş',
                  style: TextStyle(
                      color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview
            if (_generatedUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Image.network(
                    _generatedUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFF0B141D),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Colors.cyanAccent),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.2)),
                  color: const Color(0xFF0B141D),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          color: Colors.cyanAccent, size: 40),
                      SizedBox(height: 12),
                      Text('AI hikayen burada görünecek',
                          style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Style chips
            const Text('Stil',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _styles.map((s) {
                final selected = s.$2 == _selectedStyle;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStyle = s.$2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: selected
                          ? Colors.cyanAccent.withValues(alpha: 0.15)
                          : const Color(0xFF0B141D),
                      border: Border.all(
                        color: selected
                            ? Colors.cyanAccent
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(s.$1,
                        style: TextStyle(
                          color: selected ? Colors.cyanAccent : Colors.white60,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Prompt input
            TextField(
              controller: _promptCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Hikayen için bir sahne yaz... (ör: "neon şehirde yürüyen astronot")',
                prefixIcon: Icon(Icons.edit_outlined, color: Colors.cyanAccent),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _generate,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_loading ? 'Oluşturuluyor...' : 'AI ile Oluştur'),
              ),
            ),

            const SizedBox(height: 10),
            const Center(
              child: Text('⏳ Hikayeler 24 saat sonra silinir',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
