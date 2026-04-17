// Dream Chain — Kullanıcılar birbirinin AI görselini devam ettirir
// Bir zincir oluşturur: A başlatır → B devam ettirir → C devam ettirir → ...
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/points_service.dart';
import '../../services/user_service.dart';

class DreamChainScreen extends StatefulWidget {
  const DreamChainScreen({super.key});

  @override
  State<DreamChainScreen> createState() => _DreamChainScreenState();
}

class _DreamChainScreenState extends State<DreamChainScreen>
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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔗 Dream Chain'),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.purpleAccent,
          labelColor: Colors.purpleAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [Tab(text: 'Aktif Zincirler'), Tab(text: 'Başlat')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_ActiveChains(), _StartChain()],
      ),
    );
  }
}

class _ActiveChains extends StatelessWidget {
  const _ActiveChains();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dream_chains')
          .where('isOpen', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔗', style: TextStyle(fontSize: 56)),
                SizedBox(height: 16),
                Text('Henüz aktif zincir yok',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(height: 8),
                Text('İlk zinciri sen başlat!',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) => _ChainCard(doc: docs[i]),
        );
      },
    );
  }
}

class _ChainCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _ChainCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final theme = d['theme'] as String? ?? '';
    final steps = (d['steps'] as List<dynamic>?) ?? [];
    final stepCount = steps.length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0B141D),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.purpleAccent.withValues(alpha: 0.08),
              blurRadius: 20)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(theme,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('$stepCount halka  •  Devam edebilirsin',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Text('🔗 Açık',
                      style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Chain images
          if (steps.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: steps.length,
                itemBuilder: (_, i) {
                  final step = steps[i] as Map<String, dynamic>;
                  final imgUrl = step['imageUrl'] as String? ?? '';
                  return Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(imgUrl,
                            width: 90, height: 90, fit: BoxFit.cover),
                      ),
                      if (i < steps.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward,
                              color: Colors.purpleAccent, size: 18),
                        ),
                    ],
                  );
                },
              ),
            ),

          // Add button
          Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ContinueChainScreen(
                      chainId: doc.id,
                      theme: theme,
                      steps: steps,
                    ),
                  ),
                ),
                icon: const Icon(Icons.add_link, size: 16),
                label: const Text('Zinciri Devam Ettir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purpleAccent,
                  side: const BorderSide(color: Colors.purpleAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Start Chain Tab
class _StartChain extends StatefulWidget {
  const _StartChain();

  @override
  State<_StartChain> createState() => _StartChainState();
}

class _StartChainState extends State<_StartChain> {
  final _themeCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  bool _loading = false;
  String? _previewUrl;
  bool _started = false;

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final encoded = Uri.encodeComponent(
          '${_promptCtrl.text.trim()}, dreamlike, surreal, ultra detailed');
      setState(() {
        _previewUrl =
            'https://image.pollinations.ai/prompt/$encoded?width=512&height=512&nologo=true&seed=${Random().nextInt(99999)}';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createChain() async {
    if (_previewUrl == null || _themeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final me = FirebaseAuth.instance.currentUser!;
      final username = await UserService().getUsername(me.uid);

      await FirebaseFirestore.instance.collection('dream_chains').add({
        'theme': _themeCtrl.text.trim(),
        'createdBy': me.uid,
        'isOpen': true,
        'steps': [
          {
            'userId': me.uid,
            'username': username,
            'prompt': _promptCtrl.text.trim(),
            'imageUrl': _previewUrl,
            'addedAt': DateTime.now().millisecondsSinceEpoch,
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await PointsService.award(75, reason: 'dream_chain_created');
      setState(() => _started = true);
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
    if (_started) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔗', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Zincir Başladı!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('+75 XP kazandın',
                style: TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Başkaları halka eklediğinde bildirim alırsın',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => setState(() {
                _started = false;
                _previewUrl = null;
                _themeCtrl.clear();
                _promptCtrl.clear();
              }),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent),
              child: const Text('Yeni Zincir'),
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
              border:
                  Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Text('🔗', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sen bir sahne yarat → Başkaları devam ettirir → Epik bir hikaye zinciri oluşur!',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _themeCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Zincir teması (ör: "Geleceğin Şehri")',
              prefixIcon: Icon(Icons.link, color: Colors.purpleAccent),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'İlk sahneyi yaz...',
              prefixIcon: Icon(Icons.edit_outlined, color: Colors.purpleAccent),
            ),
          ),
          const SizedBox(height: 12),
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
                            color: Colors.purpleAccent)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Oluştur'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purpleAccent,
                    side: const BorderSide(color: Colors.purpleAccent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      (_previewUrl == null || _loading) ? null : _createChain,
                  icon: const Icon(Icons.add_link, size: 16),
                  label: const Text('Zincir Başlat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Continue Chain Screen
class _ContinueChainScreen extends StatefulWidget {
  final String chainId;
  final String theme;
  final List<dynamic> steps;

  const _ContinueChainScreen({
    required this.chainId,
    required this.theme,
    required this.steps,
  });

  @override
  State<_ContinueChainScreen> createState() => _ContinueChainScreenState();
}

class _ContinueChainScreenState extends State<_ContinueChainScreen> {
  final _promptCtrl = TextEditingController();
  bool _loading = false;
  String? _previewUrl;

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final encoded = Uri.encodeComponent(
          '${_promptCtrl.text.trim()}, continuation, dreamlike, surreal');
      setState(() {
        _previewUrl =
            'https://image.pollinations.ai/prompt/$encoded?width=512&height=512&nologo=true&seed=${Random().nextInt(99999)}';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addStep() async {
    if (_previewUrl == null) return;
    setState(() => _loading = true);
    try {
      final me = FirebaseAuth.instance.currentUser!;
      final username = await UserService().getUsername(me.uid);

      final newStep = {
        'userId': me.uid,
        'username': username,
        'prompt': _promptCtrl.text.trim(),
        'imageUrl': _previewUrl,
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await FirebaseFirestore.instance
          .collection('dream_chains')
          .doc(widget.chainId)
          .update({
        'steps': FieldValue.arrayUnion([newStep]),
      });

      await PointsService.award(40, reason: 'dream_chain_continued');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔗 Halka eklendi! +40 XP'),
            backgroundColor: Colors.purpleAccent,
          ),
        );
      }
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
      appBar: AppBar(title: Text('🔗 ${widget.theme}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Previous steps
            const Text('Zincir',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.steps.length,
                itemBuilder: (_, i) {
                  final step = widget.steps[i] as Map<String, dynamic>;
                  final url = step['imageUrl'] as String? ?? '';
                  return Row(
                    children: [
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(url,
                                width: 90, height: 90, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 4),
                          Text('@${step['username'] ?? '?'}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 9)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward,
                            color: Colors.purpleAccent, size: 18),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text('Sonraki Halka — Senin Sahnen',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_previewUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(_previewUrl!,
                    width: double.infinity, height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _promptCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Sahneyi devam ettir...',
                prefixIcon:
                    Icon(Icons.edit_outlined, color: Colors.purpleAccent),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _generate,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Oluştur'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purpleAccent,
                      side: const BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (_previewUrl == null || _loading) ? null : _addStep,
                    icon: const Icon(Icons.add_link, size: 16),
                    label: const Text('Halka Ekle (+40 XP)'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
