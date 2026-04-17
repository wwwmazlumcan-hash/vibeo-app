import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/communication_insight_service.dart';
import '../../services/notification_service.dart';
import '../../services/synapse_service.dart';
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
  CommunicationInsight _draftInsight = CommunicationInsightService.analyze('');
  MessageSimulation _draftSimulation = CommunicationInsightService.simulate('');
  bool _synapseBusy = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_handleDraftChanged);
  }

  void _handleDraftChanged() {
    if (!mounted) return;
    setState(() {
      _draftInsight = CommunicationInsightService.analyze(_ctrl.text);
      _draftSimulation = CommunicationInsightService.simulate(_ctrl.text);
    });
  }

  void _applyConstructiveRewrite() {
    final rewrite = _draftSimulation.constructiveRewrite.trim();
    if (rewrite.isEmpty) return;

    setState(() {
      _ctrl.text = rewrite;
      _ctrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _ctrl.text.length),
      );
    });
  }

  void _openSimulationSheet() {
    if (_ctrl.text.trim().isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gelecek Simülasyonu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _draftSimulation.intentQuestion,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 14),
            ..._draftSimulation.scenarios.map(
              (scenario) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            scenario.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          scenario.probability,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scenario.outcome,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yankı Odası Kırıcı',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _draftSimulation.echoBreaker,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSynapseTool({required bool summary}) async {
    setState(() => _synapseBusy = true);
    try {
      final result = summary
          ? await SynapseService.summarize(widget.chatId)
          : await SynapseService.moderate(widget.chatId);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF111111),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary ? 'Synapse Özeti' : 'Moderatör AI',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result,
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synapse hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _synapseBusy = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    try {
      await chatRef.collection('messages').add({
        'senderId': _myUid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await chatRef.update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.sendMessageNotification(
        toUid: widget.otherUid,
        chatId: widget.chatId,
        text: text,
      );

      // Handle AI twin reply asynchronously
      try {
        await TwinService.maybeReply(
          chatId: widget.chatId,
          recipientUid: widget.otherUid,
          incomingMessage: text,
        );
      } catch (e) {
        debugPrint('TwinService error: $e');
        // Don't fail the whole operation if twin reply fails
      }

      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gönderilemedi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_handleDraftChanged);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Colors.cyanAccent, Color(0xFF006666)],
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.4),
                      blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            Text('@${widget.otherUsername}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Synapse Özeti',
            onPressed:
                _synapseBusy ? null : () => _openSynapseTool(summary: true),
            icon: const Icon(Icons.hub_outlined, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Moderatör AI',
            onPressed:
                _synapseBusy ? null : () => _openSynapseTool(summary: false),
            icon: const Icon(Icons.balance_outlined, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
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
                      child:
                          CircularProgressIndicator(color: Colors.cyanAccent));
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
                      aiIdentityLabel: (d['aiIdentityLabel'] ?? '') as String,
                    );
                  },
                );
              },
            ),
          ),
          if (_ctrl.text.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _draftInsight.needsAttention
                    ? Colors.orangeAccent.withValues(alpha: 0.12)
                    : Colors.cyanAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _draftInsight.needsAttention
                      ? Colors.orangeAccent.withValues(alpha: 0.35)
                      : Colors.cyanAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Empati Katmanı · ${_draftInsight.tone.toUpperCase()}',
                    style: TextStyle(
                      color: _draftInsight.needsAttention
                          ? Colors.orangeAccent
                          : Colors.cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _draftInsight.perception,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _draftInsight.suggestion,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _draftInsight.empathyBridge,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _openSimulationSheet,
                        icon:
                            const Icon(Icons.psychology_alt_outlined, size: 16),
                        label: const Text('Simüle Et'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.cyanAccent,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_draftInsight.needsAttention)
                        TextButton.icon(
                          onPressed: _applyConstructiveRewrite,
                          icon: const Icon(Icons.auto_fix_high, size: 16),
                          label: const Text('Daha Yapıcı Yaz'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: Colors.cyanAccent.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.2)),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Mesaj yaz...',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Colors.cyanAccent, Color(0xFF006666)],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.5),
                            blurRadius: 12),
                      ],
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
  final String aiIdentityLabel;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    this.time,
    this.isAiTwin = false,
    this.aiIdentityLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isAiTwin
              ? Colors.purple.withValues(alpha: 0.25)
              : (isMe
                  ? Colors.cyanAccent.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: !isMe ? const Radius.circular(4) : null,
          ),
          border: Border.all(
            color: isAiTwin
                ? Colors.purpleAccent.withValues(alpha: 0.4)
                : (isMe
                    ? Colors.cyanAccent.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08)),
          ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                      blurRadius: 8)
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isAiTwin) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.smart_toy,
                      color: Colors.purpleAccent, size: 12),
                  const SizedBox(width: 4),
                  Text(aiIdentityLabel.isEmpty ? 'AI İkiz' : aiIdentityLabel,
                      style: TextStyle(
                        color: Colors.purpleAccent.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(
                '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
