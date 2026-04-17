import 'package:flutter/material.dart';

import '../screens/ai/ai_studio_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/search/search_screen.dart';
import '../services/notification_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const _bg = Color(0xFF03070D);

  final List<Widget> _pages = const [
    FeedScreen(),
    SearchScreen(),
    AiStudioScreen(),
    ChatListScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _items = const [
    _NavItem(Icons.home_rounded),
    _NavItem(Icons.explore_outlined),
    _NavItem(Icons.auto_awesome),
    _NavItem(Icons.chat_bubble_outline),
    _NavItem(Icons.notifications_none_rounded),
    _NavItem(Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0B141D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (index) {
                final selected = index == _selectedIndex;
                final item = _items[index];
                final isCenter = index == 2;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Center(
                      child: isCenter
                          ? Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Colors.cyanAccent,
                                    Color(0xFF006666),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent
                                        .withValues(alpha: 0.6),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.black,
                                size: 22,
                              ),
                            )
                          : AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: EdgeInsets.symmetric(
                                horizontal: selected ? 14 : 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.cyanAccent.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: _NavIcon(
                                icon: item.icon,
                                selected: selected,
                                showBadge: index == 4,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final bool showBadge;

  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.showBadge,
  });

  @override
  Widget build(BuildContext context) {
    final baseIcon = Icon(
      icon,
      color: selected ? Colors.cyanAccent : Colors.white54,
      size: selected ? 24 : 22,
      shadows: selected
          ? const [Shadow(color: Colors.cyanAccent, blurRadius: 10)]
          : null,
    );

    if (!showBadge) {
      return baseIcon;
    }

    return StreamBuilder<int>(
      stream: NotificationService.streamUnreadCount(),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            baseIcon,
            if (unread > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0B141D)),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;

  const _NavItem(this.icon);
}
