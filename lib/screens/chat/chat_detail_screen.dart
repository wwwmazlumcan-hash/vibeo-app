import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/twin_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUsername;
  final String otherUid;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUsername,
    required this.otherUid,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    // Add message
    await chatRef.collection('messages').add({
      'senderId': _myUid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update last message
    await chatRef.update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    // AI İkiz: alıcı offline ve twin aktifse otomatik yanıt üret
    // Arka planda çalışsın, UI beklemesin
    TwinService.maybeReply(
      chatId: widget.chatId,
      recipientUid: widget.otherUid,
      incomingMessage: text,
    );

    // Scroll to bottom
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackButton(color: Colors.white),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.cyanAccent,
              child: Icon(Icons.person, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            Text('@${widget.otherUsername}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.cyanAccent));
                }

                final docs = snap.data?.docs ?? [];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) {
                    _scroll.jumpTo(_scroll.position.maxScrollExtent);
                  }
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Konuşmayı başlat!',
                        style: TextStyle(color: Colors.white38)),
                  );
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final isMe = d['senderId'] == _myUid;
                    return _MessageBubble(
                      text: d['text'] ?? '',
                      isMe: isMe,
                      time: (d['createdAt'] as Timestamp?)?.toDate(),
                      isAiTwin: (d['isAiTwin'] ?? false) as bool,
                    );
                  },
                );
              },
            ),
          ),

          // Input
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Mesaj yaz...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.cyanAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime? time;
  final bool isAiTwin;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    this.time,
    this.isAiTwin = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isAiTwin
        ? Colors.purple.shade900.withValues(alpha: 0.6)
        : (isMe ? Colors.cyanAccent : Colors.white12);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: !isMe ? const Radius.circular(4) : null,
          ),
          border: isAiTwin
              ? Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isAiTwin) ...[
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🤖', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 4),
                  Text('AI İkiz',
                      style: TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              text,
              style: TextStyle(
                color: isAiTwin
                    ? Colors.white
                    : (isMe ? Colors.black : Colors.white),
                fontSize: 14,
              ),
            ),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(
                '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                    color: isAiTwin
                        ? Colors.white38
                        : (isMe ? Colors.black54 : Colors.white38),
                    fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
