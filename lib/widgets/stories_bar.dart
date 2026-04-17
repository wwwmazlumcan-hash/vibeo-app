import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../screens/stories/story_viewer_screen.dart';
import '../screens/stories/story_create_screen.dart';

class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;

    return SizedBox(
      height: 96,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .where('expiresAt',
                isGreaterThan: Timestamp.fromDate(DateTime.now()))
            .orderBy('expiresAt', descending: false)
            .limit(30)
            .snapshots(),
        builder: (context, snap) {
          final stories = snap.data?.docs ?? [];

          // Group stories by userId
          final Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (final doc in stories) {
            final uid = doc['userId'] as String? ?? '';
            grouped.putIfAbsent(uid, () => []).add(doc);
          }
          final userIds = grouped.keys.toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: userIds.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return _MyStoryButton(uid: me?.uid ?? '');
              final uid = userIds[i - 1];
              return _StoryRing(
                userId: uid,
                stories: grouped[uid]!,
              );
            },
          );
        },
      ),
    );
  }
}

class _MyStoryButton extends StatelessWidget {
  final String uid;
  const _MyStoryButton({required this.uid});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const StoryCreateScreen())),
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF003333), Color(0xFF01111A)],
                    ),
                    border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.3),
                        width: 2),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: Colors.white54, size: 28),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyanAccent,
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Hikaye',
                style: TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _StoryRing extends StatefulWidget {
  final String userId;
  final List<QueryDocumentSnapshot> stories;

  const _StoryRing({required this.userId, required this.stories});

  @override
  State<_StoryRing> createState() => _StoryRingState();
}

class _StoryRingState extends State<_StoryRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserPreview>(
      future: UserService().getUserPreview(
        widget.userId,
        fallbackUsername: '...',
      ),
      builder: (context, snap) {
        final preview = snap.data;
        final username = preview?.username ?? '...';
        final avatar = preview?.profileImageUrl;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoryViewerScreen(
                userId: widget.userId,
                username: username,
                stories: widget.stories,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _RingPainter(_ctrl.value),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF0B141D),
                          backgroundImage:
                              avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? Text(
                                  username.isNotEmpty
                                      ? username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 62,
                  child: Text(
                    username,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 2.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    final shader = SweepGradient(
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
      colors: const [Colors.cyanAccent, Color(0xFF00FFAA), Colors.cyanAccent],
      stops: [progress - 0.001, progress, 1.0],
    ).createShader(rect);

    final fgPaint = Paint()
      ..shader = shader
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
