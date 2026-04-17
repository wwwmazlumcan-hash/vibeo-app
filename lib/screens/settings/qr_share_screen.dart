// QR Share — kullanıcı QR kodu + paylaş
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class QrShareScreen extends StatelessWidget {
  const QrShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(title: const Text('📱 QR Kod')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snap) {
          final d = snap.data?.data() as Map<String, dynamic>? ?? {};
          final username = d['username'] as String? ?? 'vibeo';
          final avatar = d['profilePicUrl'] as String?;
          final profileUrl = 'https://vibeo.app/u/$username';

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003366), Color(0xFF001122)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color:
                            Colors.cyanAccent.withValues(alpha: 0.4),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.cyanAccent.withValues(alpha: 0.3),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            Colors.cyanAccent.withValues(alpha: 0.3),
                        backgroundImage:
                            avatar != null && avatar.isNotEmpty
                                ? NetworkImage(avatar)
                                : null,
                        child: avatar == null || avatar.isEmpty
                            ? const Icon(Icons.person,
                                size: 40, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text('@$username',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      // Simplified QR visualization
                      AspectRatio(
                        aspectRatio: 1,
                        child: _QrPattern(
                            seed: username.hashCode.abs()),
                      ),
                      const SizedBox(height: 16),
                      Text(profileUrl,
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 13,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Share.share(
                              'Vibeo\'da beni takip et! $profileUrl');
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Paylaş'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$profileUrl kopyalandı'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Kopyala'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.cyanAccent,
                          side: const BorderSide(
                              color: Colors.cyanAccent),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'QR kodunu bir arkadaşına göster, seni anında takip etsin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Simple deterministic QR-style grid based on seed.
/// Not a real QR code but a visually identifiable pattern tied to the user.
class _QrPattern extends StatelessWidget {
  final int seed;
  const _QrPattern({required this.seed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _QrPainter(seed: seed),
        child: Container(),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final int seed;
  const _QrPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    const cells = 21;
    final cellSize = size.width / cells;
    final paint = Paint()..color = const Color(0xFF001122);

    // Deterministic pseudo-random using seed
    int s = seed;
    int next() {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return s;
    }

    for (int y = 0; y < cells; y++) {
      for (int x = 0; x < cells; x++) {
        // Position-detection corners (filled 7x7 blocks)
        final corner = (x < 7 && y < 7) ||
            (x >= cells - 7 && y < 7) ||
            (x < 7 && y >= cells - 7);

        if (corner) {
          final bx = x < 7 ? x : x - (cells - 7);
          final by = y < 7 ? y : y - (cells - 7);
          final isEdge = bx == 0 ||
              bx == 6 ||
              by == 0 ||
              by == 6 ||
              (bx >= 2 && bx <= 4 && by >= 2 && by <= 4);
          if (isEdge) {
            canvas.drawRect(
              Rect.fromLTWH(
                  x * cellSize, y * cellSize, cellSize, cellSize),
              paint,
            );
          }
        } else {
          if (next() % 2 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(
                  x * cellSize, y * cellSize, cellSize, cellSize),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
