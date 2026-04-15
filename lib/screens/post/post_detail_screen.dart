import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String imageUrl;
  final String prompt;
  final String username;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.imageUrl,
    required this.prompt,
    required this.username,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _aiEnhanced = true;
  bool _remixing = false;
  String? _remixedUrl;
  String _remixedPrompt = '';

  static const _bg = Color(0xFF03070D);

  Future<void> _remix(String styleHint) async {
    setState(() {
      _remixing = true;
      _remixedUrl = null;
    });

    final newPrompt = '${widget.prompt}, $styleHint';
    _remixedPrompt = newPrompt;
    final encoded = Uri.encodeComponent(newPrompt);
    final url =
        'https://image.pollinations.ai/prompt/$encoded?width=1024&height=1024&nologo=true&enhance=$_aiEnhanced';

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 45));
      if (res.statusCode == 200 && mounted) {
        setState(() => _remixedUrl = url);
      }
    } catch (_) {}
    if (mounted) setState(() => _remixing = false);
  }

  Future<void> _share() async {
    if (_remixedUrl == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('posts').add({
      'userId': uid,
      'imageUrl': _remixedUrl,
      'prompt': _remixedPrompt,
      'likesCount': 0,
      'likedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
      'remixOf': widget.postId,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remix paylaşıldı ✨'),
          backgroundColor: Colors.cyanAccent,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = _remixedUrl ?? widget.imageUrl;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('@${widget.username}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    blurRadius: 28,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      Image.network(
                        displayUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (_, child, l) {
                          if (l == null) return child;
                          return const ColoredBox(
                            color: Colors.black,
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: Colors.cyanAccent)),
                          );
                        },
                      ),
                      if (_remixing)
                        Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: Colors.cyanAccent),
                                SizedBox(height: 14),
                                Text('Remixleniyor...',
                                    style:
                                        TextStyle(color: Colors.cyanAccent)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.prompt,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            // AI Enhanced toggle
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI Enhanced',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: _aiEnhanced,
                    activeColor: Colors.cyanAccent,
                    onChanged: (v) => setState(() => _aiEnhanced = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Remix stilleri',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _RemixChip(label: 'Daha Ciddi', onTap: () => _remix('serious, cinematic')),
                _RemixChip(label: 'Daha Viral', onTap: () => _remix('viral, eye-catching')),
                _RemixChip(label: 'Daha Duygu', onTap: () => _remix('emotional, heartfelt')),
                _RemixChip(label: 'Daha Retro', onTap: () => _remix('retro 80s aesthetic')),
                _RemixChip(label: 'Daha Neon', onTap: () => _remix('cyberpunk neon')),
                _RemixChip(label: 'Daha Rüya', onTap: () => _remix('dreamy surreal')),
              ],
            ),

            const SizedBox(height: 28),

            // Share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _remixedUrl == null ? null : _share,
                icon: const Icon(Icons.send_rounded, color: Colors.black),
                label: const Text('Paylaş',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  disabledBackgroundColor:
                      Colors.cyanAccent.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemixChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RemixChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
