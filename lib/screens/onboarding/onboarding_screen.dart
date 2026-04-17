import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _bg = Color(0xFF03070D);

  static const _pages = [
    _Page(
      icon: Icons.auto_awesome,
      title: 'AI ile Yarat',
      body: 'Aklındaki her sahneyi tek cümleyle\nAI görseline dönüştür.',
      accent: Colors.cyanAccent,
    ),
    _Page(
      icon: Icons.explore_outlined,
      title: 'Keşfet & Bağlan',
      body: 'Milyonlarca AI eserini keşfet,\nyorum yap, beğen, takip et.',
      accent: Colors.cyanAccent,
    ),
    _Page(
      icon: Icons.bolt,
      title: 'XP Kazan',
      body: 'Her paylaşım, beğeni ve yorumda\npuan kazan, rozet topla.',
      accent: Colors.cyanAccent,
    ),
    _Page(
      icon: Icons.smart_toy_outlined,
      title: 'AI İkizin Seninle',
      body: 'Çevrimdışıyken bile dijital klonun\nmesajlarına yanıt verir.',
      accent: Colors.purpleAccent,
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _PageView(page: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? Colors.cyanAccent
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: i == _page
                              ? [
                                  BoxShadow(
                                      color: Colors.cyanAccent
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8)
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_page < _pages.length - 1)
                    Row(
                      children: [
                        TextButton(
                          onPressed: _finish,
                          child: const Text('Atla'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => _ctrl.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          ),
                          child: const Text('İleri'),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _finish,
                        child: const Text('Başlayalım!',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  const _Page(
      {required this.icon,
      required this.title,
      required this.body,
      required this.accent});
}

class _PageView extends StatelessWidget {
  final _Page page;
  const _PageView({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [page.accent, const Color(0xFF003333)],
              ),
              boxShadow: [
                BoxShadow(
                    color: page.accent.withValues(alpha: 0.5), blurRadius: 40),
              ],
            ),
            child: Icon(page.icon, color: Colors.black, size: 64),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: page.accent, blurRadius: 12)],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
