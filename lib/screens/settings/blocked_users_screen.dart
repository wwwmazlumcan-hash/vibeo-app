// Blocked Users — engellenen kullanıcılar listesi
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/block_service.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(title: const Text('🚫 Engellenen Kullanıcılar')),
      body: StreamBuilder<List<String>>(
        stream: BlockService.streamBlockedIds(),
        builder: (context, snap) {
          final ids = snap.data ?? [];
          if (ids.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block, size: 48, color: Colors.white24),
                  SizedBox(height: 12),
                  Text('Engellediğin kullanıcı yok',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ids.length,
            itemBuilder: (context, i) {
              final uid = ids[i];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get(),
                builder: (context, userSnap) {
                  final d = userSnap.data?.data() as Map<String, dynamic>?;
                  final username = d?['username'] as String? ?? 'Bilinmiyor';
                  final avatar = d?['profilePicUrl'] as String?;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B141D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              Colors.redAccent.withValues(alpha: 0.2),
                          backgroundImage: avatar != null && avatar.isNotEmpty
                              ? NetworkImage(avatar)
                              : null,
                          child: avatar == null || avatar.isEmpty
                              ? Text(
                                  username.isEmpty
                                      ? '?'
                                      : username[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('@$username',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: () async {
                            await BlockService.unblockUser(uid);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('$username engeli kaldırıldı')),
                            );
                          },
                          child: const Text('Engeli Kaldır',
                              style: TextStyle(color: Colors.cyanAccent)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
