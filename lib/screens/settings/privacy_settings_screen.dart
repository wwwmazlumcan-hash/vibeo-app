// Privacy Settings — gizli hesap, kim mesaj atabilir
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _privateAccount = false;
  bool _hideActivity = false;
  bool _hideOnlineStatus = false;
  String _whoCanMessage = 'everyone';
  String _whoCanComment = 'everyone';
  bool _loading = true;

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
    final p = doc.data()?['privacy'] as Map<String, dynamic>? ?? {};
    setState(() {
      _privateAccount = p['privateAccount'] ?? false;
      _hideActivity = p['hideActivity'] ?? false;
      _hideOnlineStatus = p['hideOnlineStatus'] ?? false;
      _whoCanMessage = p['whoCanMessage'] ?? 'everyone';
      _whoCanComment = p['whoCanComment'] ?? 'everyone';
      _loading = false;
    });
  }

  Future<void> _update(String key, dynamic value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'privacy.$key': value});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(title: const Text('🔒 Gizlilik')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section('Hesap Gizliliği'),
                _Switch(
                  title: 'Gizli Hesap',
                  sub: 'Sadece onayladığın kişiler seni takip edebilir',
                  value: _privateAccount,
                  onChanged: (v) {
                    setState(() => _privateAccount = v);
                    _update('privateAccount', v);
                  },
                  color: Colors.orangeAccent,
                ),
                _Switch(
                  title: 'Aktiviteyi Gizle',
                  sub: 'Beğenilerin ve kaydettiklerin görünmez',
                  value: _hideActivity,
                  onChanged: (v) {
                    setState(() => _hideActivity = v);
                    _update('hideActivity', v);
                  },
                ),
                _Switch(
                  title: 'Çevrimiçi Durumumu Gizle',
                  sub: 'Son görülme bilgisi paylaşılmaz',
                  value: _hideOnlineStatus,
                  onChanged: (v) {
                    setState(() => _hideOnlineStatus = v);
                    _update('hideOnlineStatus', v);
                  },
                ),
                const SizedBox(height: 16),
                _Section('İzinler'),
                _Radio(
                  title: 'Kim mesaj atabilir?',
                  value: _whoCanMessage,
                  options: const {
                    'everyone': 'Herkes',
                    'followers': 'Sadece takipçilerim',
                    'nobody': 'Kimse',
                  },
                  onChanged: (v) {
                    setState(() => _whoCanMessage = v);
                    _update('whoCanMessage', v);
                  },
                ),
                _Radio(
                  title: 'Kim yorum yapabilir?',
                  value: _whoCanComment,
                  options: const {
                    'everyone': 'Herkes',
                    'followers': 'Sadece takipçilerim',
                    'nobody': 'Kimse',
                  },
                  onChanged: (v) {
                    setState(() => _whoCanComment = v);
                    _update('whoCanComment', v);
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? color;
  const _Switch({
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.cyanAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B141D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title:
            Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(sub,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        activeTrackColor: c.withValues(alpha: 0.4),
        thumbColor: WidgetStateProperty.all(c),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final String title;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  const _Radio({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B141D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...options.entries.map((e) => RadioListTile<String>(
                value: e.key,
                groupValue: value,
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
                title: Text(e.value,
                    style: const TextStyle(color: Colors.white70)),
                activeColor: Colors.cyanAccent,
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
        ],
      ),
    );
  }
}
