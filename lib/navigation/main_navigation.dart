import 'package:flutter/material.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/ai/ai_studio_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/profile/profile_screen.dart';

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
    ProfileScreen(),
  ];

  final List<_NavItem> _items = const [
    _NavItem(Icons.home_rounded, 'Akış'),
    _NavItem(Icons.explore_outlined, 'Keşfet'),
    _NavItem(Icons.auto_awesome, 'Üret'),
    _NavItem(Icons.chat_bubble_outline, 'Sohbet'),
    _NavItem(Icons.person_outline, 'Profil'),
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
                  color: Colors.cyanAccent.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (i) {
                final selected = i == _selectedIndex;
                final item = _items[i];
                final isCenter = i == 2;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedIndex = i),
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
                                    Color(0xFF006666)
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
                              child: const Icon(Icons.auto_awesome,
                                  color: Colors.black, size: 22),
                            )
                          : AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: EdgeInsets.symmetric(
                                horizontal: selected ? 14 : 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.cyanAccent
                                        .withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                item.icon,
                                color: selected
                                    ? Colors.cyanAccent
                                    : Colors.white54,
                                size: selected ? 24 : 22,
                                shadows: selected
                                    ? const [
                                        Shadow(
                                            color: Colors.cyanAccent,
                                            blurRadius: 10)
                                      ]
                                    : null,
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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
