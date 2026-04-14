import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted && doc.exists) {
      setState(() => _username = doc['username'] ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _username.isNotEmpty ? '@$_username' : 'PROFİL',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          // Avatar
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.cyanAccent,
              child: Icon(Icons.person, size: 50, color: Colors.black),
            ),
          ),
          const SizedBox(height: 12),
          if (_username.isNotEmpty)
            Text(
              '@$_username',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // İstatistikler
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('userId', isEqualTo: user?.uid)
                .snapshots(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatBox(label: 'Vibeo', value: '$count'),
                  const SizedBox(width: 40),
                  const _StatBox(label: 'Takipçi', value: '0'),
                  const SizedBox(width: 40),
                  const _StatBox(label: 'Takip', value: '0'),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),

          // Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('userId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.cyanAccent));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white12, size: 60),
                        SizedBox(height: 12),
                        Text("Henüz bir AI eserin yok.",
                            style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Image.network(
                      data['imageUrl'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Colors.white10,
                        child: Icon(Icons.broken_image,
                            color: Colors.white24, size: 30),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
