// Collections — Pinterest-style AI görsel panoları
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen>
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
    final me = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(
        title: const Text('Koleksiyonlar'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [Tab(text: 'Benimkiler'), Tab(text: 'Keşfet')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.cyanAccent,
            onPressed: () => _showCreateDialog(context, me?.uid ?? ''),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MyCollections(uid: me?.uid ?? ''),
          const _DiscoverCollections(),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, String uid) {
    final ctrl = TextEditingController();
    bool isPublic = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: const Text('Yeni Koleksiyon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  hintText: 'Koleksiyon adı...',
                  prefixIcon:
                      Icon(Icons.collections_bookmark, color: Colors.cyanAccent),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Switch(
                    value: isPublic,
                    onChanged: (v) => setSt(() => isPublic = v),
                    activeTrackColor: Colors.cyanAccent,
                  ),
                  Text(isPublic ? '🌐 Herkese açık' : '🔒 Özel',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                await FirebaseFirestore.instance
                    .collection('collections')
                    .add({
                  'userId': uid,
                  'name': ctrl.text.trim(),
                  'isPublic': isPublic,
                  'postCount': 0,
                  'coverUrl': null,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyCollections extends StatelessWidget {
  final String uid;
  const _MyCollections({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return const Center(
          child: Text('Giriş yap', style: TextStyle(color: Colors.white54)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('collections')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _EmptyCollections();
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _CollectionCard(
              docId: docs[i].id,
              name: d['name'] as String? ?? 'Koleksiyon',
              postCount: d['postCount'] as int? ?? 0,
              coverUrl: d['coverUrl'] as String?,
              isPublic: d['isPublic'] as bool? ?? true,
            );
          },
        );
      },
    );
  }
}

class _EmptyCollections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.collections_bookmark_outlined,
                color: Colors.cyanAccent.withValues(alpha: 0.5), size: 64),
            const SizedBox(height: 16),
            const Text('Koleksiyonun yok',
                style:
                    TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('AI görsellerini pano şeklinde düzenle',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final String docId;
  final String name;
  final int postCount;
  final String? coverUrl;
  final bool isPublic;

  const _CollectionCard({
    required this.docId,
    required this.name,
    required this.postCount,
    required this.coverUrl,
    required this.isPublic,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                CollectionDetailScreen(docId: docId, name: name)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0B141D),
          border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: coverUrl != null
                    ? Image.network(coverUrl!,
                        width: double.infinity, fit: BoxFit.cover)
                    : Container(
                        color: Colors.cyanAccent.withValues(alpha: 0.08),
                        child: const Center(
                          child: Icon(
                              Icons.collections_bookmark_outlined,
                              color: Colors.cyanAccent,
                              size: 36),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('$postCount görsel',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                      const Spacer(),
                      Icon(isPublic ? Icons.public : Icons.lock,
                          color: Colors.white38, size: 12),
                    ],
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

class _DiscoverCollections extends StatelessWidget {
  const _DiscoverCollections();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('collections')
          .where('isPublic', isEqualTo: true)
          .orderBy('postCount', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('Henüz herkese açık koleksiyon yok',
                style: TextStyle(color: Colors.white54)),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _CollectionCard(
              docId: docs[i].id,
              name: d['name'] as String? ?? '',
              postCount: d['postCount'] as int? ?? 0,
              coverUrl: d['coverUrl'] as String?,
              isPublic: true,
            );
          },
        );
      },
    );
  }
}

// Collection Detail Screen
class CollectionDetailScreen extends StatelessWidget {
  final String docId;
  final String name;

  const CollectionDetailScreen({
    super.key,
    required this.docId,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(title: Text(name)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('collections')
            .doc(docId)
            .collection('posts')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('Koleksiyon boş',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return MasonryGrid(docs: docs);
        },
      ),
    );
  }
}

class MasonryGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  const MasonryGrid({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final d = docs[i].data() as Map<String, dynamic>;
        final url = d['imageUrl'] as String? ?? '';
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.cover),
        );
      },
    );
  }
}
