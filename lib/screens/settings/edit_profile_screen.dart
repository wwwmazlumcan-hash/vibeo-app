// Edit Profile — kullanıcı adı, bio, avatar, link düzenleme
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _link = TextEditingController();
  final _location = TextEditingController();

  String? _avatarUrl;
  bool _loading = true;
  bool _saving = false;

  final _storage = StorageService();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final d = doc.data() ?? {};
    setState(() {
      _username.text = (d['username'] ?? '') as String;
      _bio.text = (d['bio'] ?? '') as String;
      _link.text = (d['link'] ?? '') as String;
      _location.text = (d['location'] ?? '') as String;
      _avatarUrl = d['profilePicUrl'] as String?;
      _loading = false;
    });
  }

  Future<void> _pickAvatar() async {
    final img = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024);
    if (img == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final url =
          await _storage.uploadProfilePic(File(img.path), uid);
      setState(() => _avatarUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar yüklenemedi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final newUsername = _username.text.trim();
    if (newUsername.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kullanıcı adı en az 3 karakter olmalı')));
      return;
    }

    setState(() => _saving = true);
    try {
      // username uniqueness check (skip if unchanged)
      final current = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final currentUsername = current.data()?['username'] as String?;

      if (newUsername != currentUsername) {
        final clash = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: newUsername)
            .limit(1)
            .get();
        if (clash.docs.isNotEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Bu kullanıcı adı alınmış')));
          setState(() => _saving = false);
          return;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'username': newUsername,
        'bio': _bio.text.trim(),
        'link': _link.text.trim(),
        'location': _location.text.trim(),
        if (_avatarUrl != null) 'profilePicUrl': _avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil güncellendi ✓'),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text('Kaydet',
                style: TextStyle(
                    color: _saving ? Colors.white24 : Colors.cyanAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            Colors.cyanAccent.withValues(alpha: 0.15),
                        backgroundImage: _avatarUrl != null
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: _avatarUrl == null
                            ? const Icon(Icons.person,
                                size: 48, color: Colors.cyanAccent)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.cyanAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _pickAvatar,
                    child: const Text('Avatarı değiştir',
                        style: TextStyle(color: Colors.cyanAccent)),
                  ),
                ),
                const SizedBox(height: 20),
                _Field(
                    controller: _username,
                    label: 'Kullanıcı Adı',
                    icon: Icons.alternate_email,
                    maxLength: 20),
                _Field(
                    controller: _bio,
                    label: 'Biyografi',
                    icon: Icons.edit_note,
                    maxLength: 150,
                    maxLines: 3),
                _Field(
                    controller: _link,
                    label: 'Bağlantı',
                    hint: 'https://...',
                    icon: Icons.link),
                _Field(
                    controller: _location,
                    label: 'Konum',
                    icon: Icons.location_on_outlined),
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final int? maxLength;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLength,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 20),
          labelStyle: const TextStyle(color: Colors.white54),
          hintStyle: const TextStyle(color: Colors.white24),
          filled: true,
          fillColor: const Color(0xFF0B141D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Colors.cyanAccent, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
      ),
    );
  }
}
