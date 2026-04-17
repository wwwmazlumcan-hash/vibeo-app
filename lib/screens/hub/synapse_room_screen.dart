import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/liquid_identity_service.dart';
import '../../services/synapse_service.dart';
import '../../widgets/user_avatar.dart';

class SynapseRoomScreen extends StatefulWidget {
  const SynapseRoomScreen({super.key});

  @override
  State<SynapseRoomScreen> createState() => _SynapseRoomScreenState();
}

class _SynapseRoomScreenState extends State<SynapseRoomScreen> {
  static const _rooms = <_SynapseRoom>[
    _SynapseRoom(
      topic: 'Yapay Zeka',
      accent: Colors.cyanAccent,
      description: 'AI ürünleri, otomasyon ve insan-AI işbirliği.',
    ),
    _SynapseRoom(
      topic: 'Tasarım',
      accent: Colors.orangeAccent,
      description: 'Görsel dil, marka tonu ve yaratıcı yönelimler.',
    ),
    _SynapseRoom(
      topic: 'Girişim',
      accent: Colors.greenAccent,
      description: 'Büyüme, ürün stratejisi ve pazar sinyalleri.',
    ),
    _SynapseRoom(
      topic: 'Sağlık',
      accent: Colors.pinkAccent,
      description: 'Rutinler, dayanıklılık ve wellbeing konuşmaları.',
    ),
  ];

  _SynapseRoom _selectedRoom = _rooms.first;
  final _messageCtrl = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  bool _publishingAi = false;
  Map<String, dynamic> _dashboard = const <String, dynamic>{};
  Map<String, String> _mindMeld = const <String, String>{};

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  Future<void> _sendRoomMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await SynapseService.sendRoomMessage(
        topic: _selectedRoom.topic,
        text: text,
      );
      _messageCtrl.clear();
      await _loadRoom(_selectedRoom);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synapse mesajı gönderilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _publishAiNote({required bool summary}) async {
    if (_publishingAi) return;
    setState(() => _publishingAi = true);
    try {
      final text = summary
          ? (_dashboard['summary'] ?? '') as String
          : (_dashboard['moderation'] ?? '') as String;
      await SynapseService.postAiRoomMessage(
        topic: _selectedRoom.topic,
        senderLabel: summary ? 'Fikir Sentezleyici' : 'Moderatör AI',
        aiRole: summary ? 'synthesizer' : 'moderator',
        text: text,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI notu paylaşılamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _publishingAi = false);
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRoom([_SynapseRoom? room]) async {
    final target = room ?? _selectedRoom;
    setState(() {
      _selectedRoom = target;
      _loading = true;
    });

    try {
      final results = await Future.wait<dynamic>([
        SynapseService.buildTopicDashboard(target.topic),
        SynapseService.buildMindMeldPlan(target.topic),
      ]);
      final dashboard = results[0] as Map<String, dynamic>;
      final mindMeld = results[1] as Map<String, String>;
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _mindMeld = mindMeld;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dashboard = const <String, dynamic>{};
        _mindMeld = const <String, String>{};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlights = (_dashboard['highlights'] as List<String>?) ?? const [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'THE SYNAPSE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadRoom(_selectedRoom),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF101A2A), Color(0xFF19122D)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kolektif Zeka Odaları',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'İnsanlar ve uzman AI üyeler aynı odada düşünür. Synapse; tartışmayı özetler, tansiyonu dengeler ve ana sinyalleri yüzeye çıkarır.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _rooms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final room = _rooms[index];
                  final selected = room.topic == _selectedRoom.topic;
                  return GestureDetector(
                    onTap: () => _loadRoom(room),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 180,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected
                            ? room.accent.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? room.accent.withValues(alpha: 0.55)
                              : Colors.white12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.hub_rounded,
                                  color: room.accent, size: 20),
                              const Spacer(),
                              if (selected)
                                Icon(Icons.check_circle,
                                    color: room.accent, size: 18),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            room.topic,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            room.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<SynapseRoleProfile?>(
              future:
                  SynapseService.currentUserRoleForTopic(_selectedRoom.topic),
              builder: (context, snapshot) {
                final role = snapshot.data;
                if (role == null) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _selectedRoom.accent.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Liquid Role',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            role.title,
                            style: TextStyle(
                              color: _selectedRoom.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _RoleChip(
                                label: role.contributionLabel,
                                accent: _selectedRoom.accent,
                              ),
                              _RoleChip(
                                label: role.collaborationHint,
                                accent: Colors.greenAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: SynapseService.streamRoom(_selectedRoom.topic),
              builder: (context, snapshot) {
                final roomData =
                    snapshot.data?.data() ?? const <String, dynamic>{};
                final participantCount =
                    (roomData['participantCount'] ?? 0) as int;
                final messageCount = (roomData['messageCount'] ?? 0) as int;
                final lastSender =
                    (roomData['lastSenderUsername'] ?? '') as String;
                final pinnedSummary =
                    (roomData['pinnedSummary'] ?? '') as String;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Oda Durumu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _RoomMetricChip(
                                  icon: Icons.group_outlined,
                                  label: 'Katılımcı',
                                  value: '$participantCount',
                                  accent: _selectedRoom.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _RoomMetricChip(
                                  icon: Icons.forum_outlined,
                                  label: 'Mesaj',
                                  value: '$messageCount',
                                  accent: Colors.cyanAccent,
                                ),
                              ),
                            ],
                          ),
                          if (lastSender.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Son hareket: $lastSender odayı güncelledi.',
                              style: const TextStyle(
                                color: Colors.white54,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (pinnedSummary.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF132235), Color(0xFF1A1231)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _selectedRoom.accent.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.push_pin_outlined,
                                  color: _selectedRoom.accent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Sabit Synapse Özeti',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'AI',
                                    style: TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              pinnedSummary,
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            if (_mindMeld.isNotEmpty) ...[
              const Text(
                'Mind Meld',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _InsightCard(
                title: 'Sorun Çözme Odası',
                icon: Icons.account_tree_outlined,
                accent: Colors.amberAccent,
                body: _mindMeld['problemSolving'] ??
                    'Çözüm planı şu anda üretilemedi.',
              ),
              const SizedBox(height: 12),
              _InsightCard(
                title: 'Ortak Yaratıcılık',
                icon: Icons.music_note_outlined,
                accent: Colors.cyanAccent,
                body: _mindMeld['coCreation'] ??
                    'Ortak üretim akışı şu anda üretilemedi.',
              ),
              const SizedBox(height: 12),
              _InsightCard(
                title: 'Yankı Odası Kırıcı',
                icon: Icons.compare_arrows_outlined,
                accent: Colors.greenAccent,
                body: _mindMeld['echoBreaker'] ??
                    'Karşı görüş özeti şu anda üretilemedi.',
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                const Text(
                  'Canlı Oda',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _publishingAi
                      ? null
                      : () => _publishAiNote(summary: true),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Özeti Paylaş'),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.cyanAccent),
                ),
                TextButton.icon(
                  onPressed: _publishingAi
                      ? null
                      : () => _publishAiNote(summary: false),
                  icon: const Icon(Icons.balance, size: 16),
                  label: const Text('Mod Notu'),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 260,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: SynapseService.streamRoomMessages(
                          _selectedRoom.topic),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.cyanAccent),
                          );
                        }

                        final docs = snapshot.data?.docs ?? const [];
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'Bu odada henüz mesaj yok. İlk düşünceyi sen yaz.',
                              style: TextStyle(color: Colors.white54),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        final participants = <Map<String, dynamic>>[];
                        final seenMemberKeys = <String>{};
                        for (final doc in docs.reversed) {
                          final data = doc.data();
                          final memberKey = (data['memberKey'] ??
                                  '${data['memberType']}:${data['senderUsername']}')
                              as String;
                          if (!seenMemberKeys.add(memberKey)) {
                            continue;
                          }

                          participants.add({
                            'username':
                                (data['senderUsername'] ?? 'anonim') as String,
                            'imageUrl':
                                (data['senderProfilePicUrl'] ?? '') as String,
                            'isAi': (data['memberType'] ?? 'human') == 'ai',
                            'role': (data['liquidRoleTitle'] ?? '') as String,
                          });

                          if (participants.length == 5) {
                            break;
                          }
                        }

                        return Column(
                          children: [
                            if (participants.isNotEmpty) ...[
                              SizedBox(
                                height: 42,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: participants.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final participant = participants[index];
                                    return _ParticipantPill(
                                      username:
                                          participant['username'] as String,
                                      imageUrl:
                                          participant['imageUrl'] as String,
                                      isAi: participant['isAi'] as bool,
                                      role: participant['role'] as String,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Expanded(
                              child: ListView.separated(
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data();
                                  return _RoomMessageTile(
                                    text: (data['text'] ?? '') as String,
                                    senderUsername: (data['senderUsername'] ??
                                        'anonim') as String,
                                    senderProfilePicUrl:
                                        (data['senderProfilePicUrl'] ?? '')
                                            as String,
                                    isAi:
                                        (data['memberType'] ?? 'human') == 'ai',
                                    aiRole: (data['aiRole'] ?? '') as String,
                                    liquidRoleTitle: (data['liquidRoleTitle'] ??
                                        '') as String,
                                    isMe: (data['senderId'] ?? '') ==
                                        FirebaseAuth.instance.currentUser?.uid,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.cyanAccent.withValues(alpha: 0.18),
                            ),
                          ),
                          child: TextField(
                            controller: _messageCtrl,
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendRoomMessage(),
                            decoration: const InputDecoration(
                              hintText: 'Bu oda için bir fikir bırak...',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _sending ? null : _sendRoomMessage,
                        style: FilledButton.styleFrom(
                          backgroundColor: _selectedRoom.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'AI Üyeler',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const _AiMemberCard(
              icon: Icons.balance_rounded,
              title: 'Moderatör AI',
              subtitle:
                  'Mantık hatalarını ve yanlış anlaşılma riskini nazikçe işaretler.',
              accent: Colors.redAccent,
            ),
            const _AiMemberCard(
              icon: Icons.auto_awesome,
              title: 'Fikir Sentezleyici',
              subtitle:
                  'Uzlaşıları toplar ve çok sesli konuşmaları kısa özete dönüştürür.',
              accent: Colors.cyanAccent,
            ),
            const _AiMemberCard(
              icon: Icons.travel_explore_rounded,
              title: 'Research Twin',
              subtitle:
                  'Son içeriklerden sinyalleri tarar ve ön araştırma özeti çıkarır.',
              accent: Colors.greenAccent,
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                ),
              )
            else ...[
              _InsightCard(
                title: 'Oda Özeti',
                icon: Icons.notes_rounded,
                accent: _selectedRoom.accent,
                body: (_dashboard['summary'] ?? 'Özet üretilemedi.') as String,
              ),
              const SizedBox(height: 12),
              _InsightCard(
                title: 'Moderatör Notu',
                icon: Icons.shield_outlined,
                accent: Colors.redAccent,
                body: (_dashboard['moderation'] ??
                    'Moderatör notu üretilemedi.') as String,
              ),
              const SizedBox(height: 12),
              _InsightCard(
                title: 'Sentez Çıktısı',
                icon: Icons.bubble_chart_outlined,
                accent: Colors.greenAccent,
                body: (_dashboard['synthesis'] ?? 'Sentez üretilemedi.')
                    as String,
              ),
              const SizedBox(height: 16),
              if (highlights.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Canlı Sinyaller',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...highlights.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.fiber_manual_record,
                                  size: 9, color: _selectedRoom.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final String body;

  const _InsightCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body,
              style: const TextStyle(color: Colors.white70, height: 1.4)),
        ],
      ),
    );
  }
}

class _AiMemberCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const _AiMemberCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _RoomMetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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

class _SynapseRoom {
  final String topic;
  final Color accent;
  final String description;

  const _SynapseRoom({
    required this.topic,
    required this.accent,
    required this.description,
  });
}

class _RoleChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _RoleChip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ParticipantPill extends StatelessWidget {
  final String username;
  final String imageUrl;
  final bool isAi;
  final String role;

  const _ParticipantPill({
    required this.username,
    required this.imageUrl,
    required this.isAi,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isAi ? Colors.cyanAccent : Colors.white70;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(
            imageUrl: imageUrl,
            size: 24,
            fallbackIcon: isAi ? Icons.smart_toy : Icons.person,
          ),
          const SizedBox(width: 8),
          Text(
            username,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (role.isNotEmpty && !isAi) ...[
            const SizedBox(width: 6),
            Text(
              role,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoomMessageTile extends StatelessWidget {
  final String text;
  final String senderUsername;
  final String senderProfilePicUrl;
  final bool isAi;
  final bool isMe;
  final String aiRole;
  final String liquidRoleTitle;

  const _RoomMessageTile({
    required this.text,
    required this.senderUsername,
    required this.senderProfilePicUrl,
    required this.isAi,
    required this.isMe,
    required this.aiRole,
    required this.liquidRoleTitle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isAi
        ? (aiRole == 'moderator' ? Colors.redAccent : Colors.cyanAccent)
        : (isMe ? Colors.greenAccent : Colors.white70);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(
          imageUrl: senderProfilePicUrl,
          size: 34,
          fallbackIcon: isAi ? Icons.smart_toy : Icons.person,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        senderUsername,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (isAi)
                      const Text(
                        'AI',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (!isAi && liquidRoleTitle.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          liquidRoleTitle,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
