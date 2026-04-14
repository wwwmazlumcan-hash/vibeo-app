import 'package:flutter/material.dart';
// Sayfalarımızı import ediyoruz (Bu dosyaların screens klasöründe olduğundan emin ol)

import 'ai/ai_studio_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Menüdeki butonlara tıklandığında açılacak sayfalar listesi
  final List<Widget> _pages = [
    const Center(
        child: Text("Keşfet Sayfası",
            style: TextStyle(color: Colors.white))), // Index 1: Placeholder
    const AiStudioScreen(), // Index 2: AI Üretim Merkezi (Artı butonu)
    const Center(
        child: Text("Mesajlar Sayfası",
            style: TextStyle(color: Colors.white))), // Index 3: Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _pages[_selectedIndex], // Seçili sayfayı ekranda göster
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Akış'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Keşfet'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_box, size: 35, color: Colors.purpleAccent),
              label: 'AI Studio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Mesajlar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
