import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/vibeo_button.dart';
import '../../widgets/vibeo_input.dart';

class AiStudioScreen extends StatefulWidget {
  const AiStudioScreen({super.key});

  @override
  State<AiStudioScreen> createState() => _AiStudioScreenState();
}

class _AiStudioScreenState extends State<AiStudioScreen> {
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
    _promptController.addListener(() {
      setState(() => _charCount = _promptController.text.length);
    });
  }

  // 🎨 AI Görselini Üreten Fonksiyon
  void _generateImage() {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir hayal kurup yazın!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      // Pollinations AI kullanarak ücretsiz görsel üretiyoruz
      _generatedImageUrl =
          "https://image.pollinations.ai/prompt/${Uri.encodeFull(_promptController.text.trim())}?width=1080&height=1920&nologo=true&seed=${DateTime.now().millisecondsSinceEpoch}";
    });

    // Görselin yüklenmesi için kısa bir bekleme simülasyonu
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // 📤 Görseli Paylaşan (Firestore'a kaydeden) Fonksiyon
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
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vibeo Paylaşıldı!"),
          backgroundColor: Colors.cyanAccent,
        ),
      );
      _promptController.clear();
      setState(() => _generatedImageUrl = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("AI STUDIO",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prompt ipuçları
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
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

            // Giriş Alanı + karakter sayacı
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
                      color: _charCount > 400
                          ? Colors.redAccent
                          : Colors.white24,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Üret Butonu
            VibeoButton(
              text: "GÖRSELİ OLUŞTUR",
              onPressed: _generateImage,
              isLoading: _isLoading && _generatedImageUrl == null,
            ),

            const SizedBox(height: 30),

            // Görsel Alanı
            if (_generatedImageUrl != null) ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
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

              // Paylaş Butonu
              VibeoButton(
                text: "DÜNYA İLE PAYLAŞ",
                onPressed: _shareVibeo,
                isLoading: _isLoading && _generatedImageUrl != null,
                color: Colors.white,
              ),
            ] else ...[
              const SizedBox(height: 100),
              Icon(Icons.auto_awesome,
                  size: 80, color: Colors.white.withValues(alpha: 0.1)),
              const Text("Henüz bir şey üretilmedi",
                  style: TextStyle(color: Colors.white24)),
            ],
          ],
        ),
      ),
    );
  }
}
