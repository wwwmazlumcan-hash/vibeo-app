import 'package:flutter/material.dart';
// YOLLAR: Klasörlerin ayrı olduğunu bildiğim için yolları buna göre yazdım
import '../screens/feed/feed_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/ai/ai_studio_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const FeedScreen(),
    const SearchScreen(),
    const AiStudioScreen(), // Orta buton burayı açacak
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Akış'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Keşfet'),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              backgroundColor: Colors.cyanAccent,
              child: Icon(Icons.add, color: Colors.black),
            ),
            label: 'AI',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Mesajlar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
