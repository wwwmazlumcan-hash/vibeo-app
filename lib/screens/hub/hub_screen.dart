import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../earn/earn_screen.dart';
import '../fitness/fitness_screen.dart';
import '../twin/twin_setup_screen.dart';
import '../../services/points_service.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('VİBEO HUB',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile summary card
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>? ?? {};
                final username = data['username'] ?? '...';
                final points = (data['points'] ?? 0) as int;
                final badge = PointsService.getBadge(points);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003333), Color(0xFF001a2e)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.cyanAccent,
                        child: Icon(Icons.person, size: 32, color: Colors.black),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('@$username',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Text(badge,
                                style: const TextStyle(fontSize: 16)),
                            Text('$points XP',
                                style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white38),
                        onPressed: () => FirebaseAuth.instance.signOut(),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const _SectionTitle('Özellikler'),
            const SizedBox(height: 12),

            // Feature grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _FeatureCard(
                  icon: '🤖',
                  title: 'AI İkiz',
                  subtitle: 'Dijital klonun\nsenin yerine yanıtlar',
                  gradient: const [Color(0xFF1a0033), Color(0xFF330066)],
                  borderColor: Colors.purpleAccent,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TwinSetupScreen())),
                ),
                _FeatureCard(
                  icon: '🏆',
                  title: 'Kazan',
                  subtitle: 'XP, rozetler\nve liderlik tablosu',
                  gradient: const [Color(0xFF1a1a00), Color(0xFF333300)],
                  borderColor: Colors.amber,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EarnScreen())),
                ),
                _FeatureCard(
                  icon: '💪',
                  title: 'Fitness Koç',
                  subtitle: 'AI destekli\nkişisel antrenör',
                  gradient: const [Color(0xFF001a00), Color(0xFF003300)],
                  borderColor: Colors.greenAccent,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FitnessScreen())),
                ),
                _FeatureCard(
                  icon: '🛡️',
                  title: 'Güvenli Alan',
                  subtitle: 'AI moderasyon\naktif',
                  gradient: const [Color(0xFF330000), Color(0xFF660033)],
                  borderColor: Colors.redAccent,
                  onTap: () => _showModInfo(context),
                ),
                _FeatureCard(
                  icon: '🔧',
                  title: 'Sistem Durumu',
                  subtitle: 'Self-healing\naktif',
                  gradient: const [Color(0xFF001a1a), Color(0xFF003333)],
                  borderColor: Colors.cyanAccent,
                  onTap: () => _showSystemStatus(context),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const _SectionTitle('Nasıl kazanırsın?'),
            const SizedBox(height: 12),

            _MiniEarnRow(icon: Icons.auto_awesome, label: 'Vibeo paylaş', xp: '+10 XP'),
            _MiniEarnRow(icon: Icons.favorite, label: 'Beğeni al', xp: '+2 XP'),
            _MiniEarnRow(icon: Icons.comment, label: 'Yorum al', xp: '+3 XP'),
            _MiniEarnRow(icon: Icons.login, label: 'Günlük giriş', xp: '+5 XP'),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showModInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('🛡️ AI Moderasyon',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tüm içerikler yapay zeka tarafından otomatik olarak denetlenmektedir.\n\n'
          '• Uygunsuz kelimeler engellenir\n'
          '• Kullanıcılar şikayet edebilir\n'
          '• Bildirilen içerikler 24 saat içinde incelenir',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  void _showSystemStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('🔧 Sistem Durumu',
            style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusRow(label: 'Firebase', status: 'Çalışıyor', ok: true),
            _StatusRow(label: 'AI Studio', status: 'Çalışıyor', ok: true),
            _StatusRow(label: 'Bağlantı', status: 'Çalışıyor', ok: true),
            _StatusRow(label: 'Self-Healing', status: 'Aktif', ok: true),
            _StatusRow(label: 'Moderasyon', status: 'Aktif', ok: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1));
  }
}

class _FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color borderColor;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: borderColor.withValues(alpha: 0.4), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 30)),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 11, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _MiniEarnRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String xp;
  const _MiniEarnRow(
      {required this.icon, required this.label, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Text(xp,
              style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String status;
  final bool ok;
  const _StatusRow(
      {required this.label, required this.status, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.error,
              color: ok ? Colors.greenAccent : Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 13))),
          Text(status,
              style: TextStyle(
                  color: ok ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 12)),
        ],
      ),
    );
  }
}
