import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/app_notification_model.dart';
import '../../widgets/user_avatar.dart';
import '../chat/chat_detail_screen.dart';
import '../post/post_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _openNotification(AppNotificationModel item) async {
    await NotificationService.markAsRead(item.id);
    if (!mounted) return;

    switch (item.type) {
      case 'follow':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: item.fromUid),
          ),
        );
        return;
      case 'message':
        if (item.chatId == null || item.chatId!.isEmpty) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: item.chatId!,
              otherUsername: item.fromUsername,
              otherUid: item.fromUid,
            ),
          ),
        );
        return;
      case 'like':
      case 'comment':
        if (item.postId == null || item.postId!.isEmpty) return;
        final postDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(item.postId!)
            .get();
        if (!postDoc.exists || !mounted) {
          _showMessage('Gönderi artık mevcut değil.');
          return;
        }

        final postData = postDoc.data() ?? <String, dynamic>{};
        final ownerUid = (postData['userId'] ?? '') as String;
        String username = item.fromUsername;

        if (ownerUid.isNotEmpty) {
          final ownerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(ownerUid)
              .get();
          username = (ownerDoc.data()?['username'] ?? username) as String;
        }

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              postId: item.postId!,
              imageUrl: (postData['imageUrl'] ?? '') as String,
              prompt: (postData['prompt'] ?? '') as String,
              username: username,
            ),
          ),
        );
        return;
      default:
        return;
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF03070D),
        elevation: 0,
        title: const Text('Bildirimler'),
        actions: const [
          TextButton(
            onPressed: NotificationService.markAllAsRead,
            child: Text(
              'Tümünü oku',
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotificationModel>>(
        stream: NotificationService.streamNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }

          final items = snapshot.data ?? const <AppNotificationModel>[];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Henüz bildirimin yok.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => _openNotification(item),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: item.isRead
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.cyanAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: item.isRead
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.cyanAccent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          UserAvatar(
                            imageUrl: item.fromProfilePicUrl,
                            size: 42,
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF03070D),
                                border: Border.all(
                                  color:
                                      Colors.cyanAccent.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Icon(
                                _iconForType(item.type),
                                color: Colors.cyanAccent,
                                size: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '@${item.fromUsername} ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: item.message,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _timeAgo(item.createdAt),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_hasPostPreview(item)) ...[
                        const SizedBox(width: 10),
                        _NotificationPostPreview(postId: item.postId!),
                      ],
                      if (!item.isRead)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.cyanAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add_alt_1_rounded;
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.mode_comment_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'az önce';
    if (diff.inHours < 1) return '${diff.inMinutes} dk';
    if (diff.inDays < 1) return '${diff.inHours} sa';
    return '${diff.inDays} g';
  }

  static bool _hasPostPreview(AppNotificationModel item) {
    return (item.type == 'like' || item.type == 'comment') &&
        item.postId != null &&
        item.postId!.isNotEmpty;
  }
}

class _NotificationPostPreview extends StatelessWidget {
  final String postId;

  const _NotificationPostPreview({required this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('posts').doc(postId).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final imageUrl = (data?['imageUrl'] ?? '') as String;

        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.18),
            ),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: imageUrl.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white24,
                      size: 18,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white24,
                        size: 18,
                      ),
                    ),
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
