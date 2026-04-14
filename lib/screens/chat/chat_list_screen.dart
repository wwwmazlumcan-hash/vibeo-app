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
    // Chat ID = sorted UIDs joined
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('MESAJLAR',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // User Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Kullanıcı ara...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),

          // User search results
          if (_query.isNotEmpty)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snap) {
                final docs = (snap.data?.docs ?? [])
                    .where((d) =>
                        d.id != _myUid &&
                        (d['username'] as String? ?? '')
                            .toLowerCase()
                            .contains(_query))
                    .toList();

                return Column(
                  children: docs.map((d) {
                    final username = d['username'] ?? 'kullanıcı';
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.cyanAccent,
                        child: Icon(Icons.person, color: Colors.black),
                      ),
                      title: Text('@$username',
                          style: const TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chat_bubble_outline,
                          color: Colors.cyanAccent, size: 20),
                      onTap: () => _startChat(d.id, username),
                    );
                  }).toList(),
                );
              },
            ),

          const Divider(color: Colors.white12),

          // Existing chats
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
                      child: CircularProgressIndicator(color: Colors.cyanAccent));
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: Colors.white12, size: 60),
                        SizedBox(height: 12),
                        Text('Henüz konuşma yok.\nYukarıdan birini ara!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final participants =
                        List<String>.from(data['participants'] ?? []);
                    final otherUid =
                        participants.firstWhere((id) => id != _myUid, orElse: () => '');

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(otherUid)
                          .get(),
                      builder: (_, userSnap) {
                        final uData =
                            userSnap.data?.data() as Map<String, dynamic>? ?? {};
                        final username = uData['username'] ?? '...';

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.cyanAccent,
                            child: Icon(Icons.person, color: Colors.black),
                          ),
                          title: Text('@$username',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            data['lastMessage'] ?? '',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _startChat(otherUid, username),
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
    );
  }
}
