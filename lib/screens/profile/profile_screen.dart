import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(user?.email?.split('@')[0].toUpperCase() ?? "PROFİL"),
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
          const SizedBox(height: 20),
          // Profil Bilgisi
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.cyanAccent,
              child: Icon(Icons.person, size: 50, color: Colors.black),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            user?.email ?? "Misafir Kullanıcı",
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white24),
          // Kullanıcının AI Galerisi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('userId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Colors.cyanAccent));
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                      child: Text("Henüz bir AI eserin yok.",
                          style: TextStyle(color: Colors.grey)));
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
                    return Image.network(data['imageUrl'], fit: BoxFit.cover);
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
