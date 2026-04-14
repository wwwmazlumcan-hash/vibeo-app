import 'package:flutter/material.dart';
import '../feed/feed_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // HomeScreen genelde FeedScreen'i kapsayan ana yapıdır.
    return const Scaffold(
      backgroundColor: Colors.black,
      body: FeedScreen(),
    );
  }
}
