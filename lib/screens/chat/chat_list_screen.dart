import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _startChat(String otherUid, String otherUsername) async {
    final ids = [_myUid, otherUid]..sort();
    final chatId = ids.join('_');

    final ref = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [_myUid, otherUid],
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          chatId: chatId,
          otherUsername: otherUsername,
          otherUid: otherUid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  const Text('Sohbet',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyanAccent.withValues(alpha: 0.08),
                      border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Colors.cyanAccent, size: 16),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Kullanıcı ara...',
                  prefixIcon:
                      Icon(Icons.search, color: Colors.cyanAccent, size: 20),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Text('Hata: ${snap.error}',
                          style: const TextStyle(color: Colors.redAccent)),
                    );
                  }

                  final docs = (snap.data?.docs ?? [])
                      .where((d) =>
                          d.id != _myUid &&
                          (d['username'] as String? ?? '')
                              .toLowerCase()
                              .contains(_query))
                      .toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Kullanıcı bulunamadı',
                          style: TextStyle(color: Colors.white38)),
                    );
                  }

                  return Column(
                    children: docs.map((d) {
                      final username = d['username'] ?? 'kullanıcı';
                      return ListTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Colors.cyanAccent, Color(0xFF006666)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      Colors.cyanAccent.withValues(alpha: 0.4),
                                  blurRadius: 10),
                            ],
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.black, size: 20),
                        ),
                        title: Text('@$username',
                            style: const TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.chat_bubble_outline,
                            color: Colors.cyanAccent, size: 18),
                        onTap: () => _startChat(d.id, username),
                      );
                    }).toList(),
                  );
                },
              ),
            Divider(color: Colors.white.withValues(alpha: 0.06)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('participants', arrayContains: _myUid)
                    .orderBy('lastMessageAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.cyanAccent));
                  }

                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              color: Colors.cyanAccent.withValues(alpha: 0.15),
                              size: 60),
                          const SizedBox(height: 12),
                          const Text(
                              'Henüz konuşma yok.\nYukarıdan birini ara!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final participants =
                          List<String>.from(data['participants'] ?? []);
                      final otherUid = participants
                          .firstWhere((id) => id != _myUid, orElse: () => '');

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUid)
                            .get(),
                        builder: (_, userSnap) {
                          final uData =
                              userSnap.data?.data() as Map<String, dynamic>? ??
                                  {};
                          final username = uData['username'] ?? '...';

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.cyanAccent
                                      .withValues(alpha: 0.12)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [
                                      Colors.cyanAccent,
                                      Color(0xFF006666)
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.cyanAccent
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8),
                                  ],
                                ),
                                child: const Icon(Icons.person,
                                    color: Colors.black, size: 22),
                              ),
                              title: Text('@$username',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              subtitle: Text(
                                data['lastMessage'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: Colors.white24, size: 20),
                              onTap: () => _startChat(otherUid, username),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
