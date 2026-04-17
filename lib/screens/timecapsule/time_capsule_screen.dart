// Time Capsule — Gelecek bir tarihe kilitli AI görseller
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class TimeCapsuleScreen extends StatefulWidget {
  const TimeCapsuleScreen({super.key});

  @override
  State<TimeCapsuleScreen> createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends State<TimeCapsuleScreen>
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
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(
        title: const Text('⏳ Time Capsule'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MyCapsules(),
          const _CreateCapsule(),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabs,
        indicatorColor: Colors.purpleAccent,
        labelColor: Colors.purpleAccent,
        unselectedLabelColor: Colors.white38,
        tabs: const [
          Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Kapsüllerim'),
          Tab(icon: Icon(Icons.add_circle_outline), text: 'Yeni Kapsül'),
        ],
      ),
    );
  }
}

class _MyCapsules extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('time_capsules')
          .where('userId', isEqualTo: me.uid)
          .orderBy('revealAt', descending: false)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⏳', style: TextStyle(fontSize: 64)),
                SizedBox(height: 16),
                Text('Henüz kapsülün yok',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                    'Gelecekte açılacak bir AI görseli oluştur',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final revealAt =
                (d['revealAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final isUnlocked = DateTime.now().isAfter(revealAt);
            final imageUrl = d['imageUrl'] as String? ?? '';
            final message = d['message'] as String? ?? '';
            final remaining = revealAt.difference(DateTime.now());

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF0B141D),
                border: Border.all(
                  color: isUnlocked
                      ? Colors.greenAccent.withValues(alpha: 0.4)
                      : Colors.purpleAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image or lock
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: isUnlocked && imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.purpleAccent
                                      .withValues(alpha: 0.1),
                                  child: const Center(
                                    child: Icon(Icons.lock,
                                        color: Colors.purpleAccent, size: 48),
                                  ),
                                ),
                        ),
                        if (!isUnlocked)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock,
                                      color: Colors.purpleAccent, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatRemaining(remaining),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    _dateStr(revealAt),
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (isUnlocked)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('🔓 AÇILDI',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.message_outlined,
                                  color: Colors.purpleAccent, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isUnlocked
                                      ? message
                                      : '🔒 ${message.length} karakterlik mesaj',
                                  style: TextStyle(
                                    color: isUnlocked
                                        ? Colors.white70
                                        : Colors.white38,
                                    fontSize: 13,
                                    fontStyle: isUnlocked
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inDays > 0) return '${d.inDays} gün kaldı';
    if (d.inHours > 0) return '${d.inHours} saat kaldı';
    return '${d.inMinutes} dakika kaldı';
  }

  String _dateStr(DateTime dt) =>
      '${dt.day}.${dt.month}.${dt.year} açılacak';
}

class _CreateCapsule extends StatefulWidget {
  const _CreateCapsule();

  @override
  State<_CreateCapsule> createState() => _CreateCapsuleState();
}

class _CreateCapsuleState extends State<_CreateCapsule> {
  final _promptCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  DateTime _revealDate = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;
  String? _previewUrl;
  bool _created = false;

  static const _presets = [
    ('1 hafta', Duration(days: 7)),
    ('1 ay', Duration(days: 30)),
    ('3 ay', Duration(days: 90)),
    ('6 ay', Duration(days: 180)),
    ('1 yıl', Duration(days: 365)),
  ];

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final encoded = Uri.encodeComponent(
          '${_promptCtrl.text.trim()}, time capsule, nostalgic, dreamlike, soft light');
      setState(() {
        _previewUrl =
            'https://image.pollinations.ai/prompt/$encoded?width=720&height=720&nologo=true&seed=${Random().nextInt(99999)}';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createCapsule() async {
    if (_previewUrl == null) return;
    setState(() => _loading = true);
    try {
      final me = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('time_capsules').add({
        'userId': me.uid,
        'prompt': _promptCtrl.text.trim(),
        'imageUrl': _previewUrl,
        'message': _messageCtrl.text.trim(),
        'revealAt': Timestamp.fromDate(_revealDate),
        'createdAt': FieldValue.serverTimestamp(),
        'isPublic': false,
      });
      setState(() => _created = true);
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
    if (_created) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏳', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Kapsül Kilitlendi!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '${_revealDate.day}.${_revealDate.month}.${_revealDate.year} tarihinde açılacak',
              style: const TextStyle(color: Colors.purpleAccent, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {
                _created = false;
                _previewUrl = null;
                _promptCtrl.clear();
                _messageCtrl.clear();
              }),
              child: const Text('Yeni Kapsül'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.purpleAccent.withValues(alpha: 0.1),
              border: Border.all(
                  color: Colors.purpleAccent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Text('⏳', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI görselini seçtiğin tarihe kilitle. O güne kadar sadece sen kilit ikonunu görürsün!',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reveal date presets
          const Text('Ne Zaman Açılsın?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _presets.map((p) {
              final date = DateTime.now().add(p.$2);
              final selected = _revealDate.difference(DateTime.now()).inDays ==
                  p.$2.inDays;
              return GestureDetector(
                onTap: () => setState(() => _revealDate = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: selected
                        ? Colors.purpleAccent.withValues(alpha: 0.2)
                        : const Color(0xFF0B141D),
                    border: Border.all(
                        color: selected
                            ? Colors.purpleAccent
                            : Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Text(p.$1,
                      style: TextStyle(
                          color: selected
                              ? Colors.purpleAccent
                              : Colors.white60,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          if (_previewUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                _previewUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, p) {
                  if (p == null) return child;
                  return Container(
                    height: 200,
                    color: const Color(0xFF0B141D),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: Colors.purpleAccent),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          TextField(
            controller: _promptCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Kapsüldeki AI görselini tanımla...',
              prefixIcon:
                  Icon(Icons.auto_awesome, color: Colors.purpleAccent),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Gelecekteki kendine mesaj (isteğe bağlı)...',
              prefixIcon:
                  Icon(Icons.message_outlined, color: Colors.purpleAccent),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Görsel Oluştur'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purpleAccent,
                    side: const BorderSide(color: Colors.purpleAccent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_previewUrl == null || _loading)
                      ? null
                      : _createCapsule,
                  icon: const Icon(Icons.lock, size: 16),
                  label: const Text('Kilitle'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
