// Mood Vibe — Ruh haline göre AI görsel + müzik önerisi
import 'package:flutter/material.dart';
import 'dart:math';

class MoodVibeScreen extends StatefulWidget {
  const MoodVibeScreen({super.key});

  @override
  State<MoodVibeScreen> createState() => _MoodVibeScreenState();
}

class _MoodVibeScreenState extends State<MoodVibeScreen>
    with TickerProviderStateMixin {
  int? _selectedMood;
  bool _generating = false;
  String? _imageUrl;
  String? _musicSuggestion;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  static const _moods = [
    _Mood('😄', 'Mutlu', 'joyful colorful vibrant celebration, sunshine', Colors.amber, 'Happy Pop / Dance'),
    _Mood('😔', 'Hüzünlü', 'melancholic rainy window reflection, blue tones', Colors.blueAccent, 'Lo-fi / Sad Piano'),
    _Mood('😤', 'Öfkeli', 'dramatic stormy dark red energy, lightning', Colors.redAccent, 'Metal / Aggressive'),
    _Mood('😌', 'Sakin', 'peaceful zen nature, soft pastel, minimalist', Colors.greenAccent, 'Ambient / Nature Sounds'),
    _Mood('🤩', 'Heyecanlı', 'electric neon cityscape, futuristic energy', Colors.cyanAccent, 'EDM / Energetic'),
    _Mood('😍', 'Aşık', 'romantic rose gold dreamy soft bokeh', Colors.pinkAccent, 'Romantic / R&B'),
    _Mood('🤔', 'Düşünceli', 'philosophical cosmic space stars thinking', Colors.purpleAccent, 'Classical / Jazz'),
    _Mood('😴', 'Yorgun', 'dreamy surreal floating clouds, soft purple', Color(0xFF9C88FF), 'Sleep / Relaxing'),
    _Mood('🔥', 'Motive', 'powerful mountain sunrise warrior energy', Colors.orangeAccent, 'Hip-Hop / Motivational'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate(int moodIdx) async {
    setState(() {
      _selectedMood = moodIdx;
      _generating = true;
      _imageUrl = null;
    });

    final mood = _moods[moodIdx];
    final encoded = Uri.encodeComponent(
        '${mood.prompt}, ultra detailed, artistic, 4k, mood art, no text');
    final seed = Random().nextInt(99999);

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _imageUrl =
          'https://image.pollinations.ai/prompt/$encoded?width=720&height=720&nologo=true&seed=$seed';
      _musicSuggestion = mood.music;
      _generating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(title: const Text('🎨 Mood Vibe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.cyanAccent.withValues(alpha: 0.1),
                    Colors.purpleAccent.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Text('🎨', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ruh haline göre AI görsel üret ve müzik keşfet!',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mood grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: List.generate(_moods.length, (i) {
                final mood = _moods[i];
                final selected = _selectedMood == i;
                return GestureDetector(
                  onTap: () => _generate(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: selected
                          ? mood.color.withValues(alpha: 0.2)
                          : const Color(0xFF0B141D),
                      border: Border.all(
                        color: selected
                            ? mood.color
                            : Colors.white.withValues(alpha: 0.08),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: mood.color.withValues(alpha: 0.3),
                                  blurRadius: 12)
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(mood.emoji,
                            style: TextStyle(
                                fontSize: selected ? 30 : 26)),
                        const SizedBox(height: 4),
                        Text(mood.label,
                            style: TextStyle(
                                color: selected ? mood.color : Colors.white60,
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),

            // Generated image
            if (_generating)
              Column(
                children: [
                  ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _selectedMood != null
                                ? _moods[_selectedMood!].color
                                : Colors.cyanAccent,
                            width: 2),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: _selectedMood != null
                            ? _moods[_selectedMood!].color
                            : Colors.cyanAccent,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Ruh halin AI\'ya aktarılıyor...',
                      style: TextStyle(color: Colors.white54)),
                ],
              )
            else if (_imageUrl != null) ...[
              // Image result
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      _imageUrl!,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) {
                        if (p == null) return child;
                        return Container(
                          height: 300,
                          color: const Color(0xFF0B141D),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _moods[_selectedMood!].color,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _moods[_selectedMood!].color.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '${_moods[_selectedMood!].emoji} ${_moods[_selectedMood!].label}',
                        style: TextStyle(
                            color: _moods[_selectedMood!].color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Music suggestion
              if (_musicSuggestion != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _moods[_selectedMood!].color.withValues(alpha: 0.1),
                    border: Border.all(
                        color: _moods[_selectedMood!].color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.music_note,
                          color: _moods[_selectedMood!].color, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🎵 Müzik Önerisi',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              _musicSuggestion!,
                              style: TextStyle(
                                  color: _moods[_selectedMood!].color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _generate(_selectedMood!),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Yenile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _moods[_selectedMood!].color,
                        side: BorderSide(color: _moods[_selectedMood!].color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share_outlined, size: 16),
                      label: const Text('Paylaş'),
                    ),
                  ),
                ],
              ),
            ] else
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF0B141D),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: const Center(
                  child: Text('👆 Ruh halini seç',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _Mood {
  final String emoji;
  final String label;
  final String prompt;
  final Color color;
  final String music;

  const _Mood(this.emoji, this.label, this.prompt, this.color, this.music);
}
