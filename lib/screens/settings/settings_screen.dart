// Settings — Hesap, gizlilik, bildirim, tema, dil ayarları
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../legal/privacy_policy_screen.dart';
import 'edit_profile_screen.dart';
import 'blocked_users_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'language_settings_screen.dart';
import 'qr_share_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'Türkçe';
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('lang') == 'en' ? 'English' : 'Türkçe';
      _darkMode = prefs.getBool('darkMode') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(title: const Text('⚙️ Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section('Hesap'),
          _Tile(
            icon: Icons.person_outline,
            title: 'Profili Düzenle',
            subtitle: 'Kullanıcı adı, bio, avatar',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          _Tile(
            icon: Icons.qr_code_2,
            title: 'QR Kodumu Paylaş',
            subtitle: 'Arkadaşlarını hızlıca ekle',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const QrShareScreen())),
          ),
          _Tile(
            icon: Icons.lock_outline,
            title: 'Gizlilik',
            subtitle: 'Gizli hesap, kim yazabilir, kim görebilir',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PrivacySettingsScreen())),
          ),
          _Tile(
            icon: Icons.block,
            title: 'Engellenen Kullanıcılar',
            subtitle: 'Listeyi yönet',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BlockedUsersScreen())),
          ),
          const SizedBox(height: 20),
          _Section('Bildirimler'),
          _Tile(
            icon: Icons.notifications_none,
            title: 'Bildirim Tercihleri',
            subtitle: 'Beğeni, yorum, mesaj, takip',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen())),
          ),
          const SizedBox(height: 20),
          _Section('Görünüm'),
          SwitchListTile(
            value: _darkMode,
            onChanged: (v) async {
              setState(() => _darkMode = v);
              final p = await SharedPreferences.getInstance();
              await p.setBool('darkMode', v);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Tema seçimi kaydedildi. Uygulamayı yeniden başlat.'),
              ));
            },
            title: const Text('Karanlık Mod',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Tüm ekranlar için',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            secondary:
                const Icon(Icons.dark_mode, color: Colors.cyanAccent),
            activeTrackColor: Colors.cyanAccent.withValues(alpha: 0.4),
            thumbColor: WidgetStateProperty.all(Colors.cyanAccent),
          ),
          _Tile(
            icon: Icons.language,
            title: 'Dil',
            subtitle: _language,
            onTap: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LanguageSettingsScreen()));
              _loadPrefs();
            },
          ),
          const SizedBox(height: 20),
          _Section('Veri & Güvenlik'),
          _Tile(
            icon: Icons.download_outlined,
            title: 'Verilerimi İndir',
            subtitle: 'Profil + paylaşımlar (.json)',
            onTap: () => _exportData(uid),
          ),
          _Tile(
            icon: Icons.policy_outlined,
            title: 'Gizlilik Politikası',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen())),
          ),
          _Tile(
            icon: Icons.description_outlined,
            title: 'Kullanım Şartları',
            onTap: () => launchUrl(
                Uri.parse('https://vibeo.app/terms'),
                mode: LaunchMode.externalApplication),
          ),
          _Tile(
            icon: Icons.mail_outline,
            title: 'İletişim / Destek',
            subtitle: 'support@vibeo.app',
            onTap: () => launchUrl(
                Uri.parse('mailto:support@vibeo.app?subject=Vibeo Destek')),
          ),
          const SizedBox(height: 20),
          _Section('Hesap İşlemleri'),
          _Tile(
            icon: Icons.logout,
            title: 'Çıkış Yap',
            color: Colors.orangeAccent,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context)
                  .popUntil((r) => r.isFirst);
            },
          ),
          const SizedBox(height: 40),
          const Center(
            child: Text('Vibeo v1.1.0',
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Future<void> _exportData(String? uid) async {
    if (uid == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final posts = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: uid)
          .get();

      final data = {
        'profile': userDoc.data(),
        'posts': posts.docs.map((d) => d.data()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };

      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Veri Özeti'),
          content: SingleChildScrollView(
            child: Text(
              '📊 Profil: ${data['profile'] != null ? "Yüklendi" : "Yok"}\n'
              '📝 Paylaşım sayısı: ${posts.docs.length}\n\n'
              'Verilerinin kopyası e-posta ile de gönderilebilir.\n'
              'support@vibeo.app adresine yazın.',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam',
                  style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
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

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
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
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        leading: Icon(icon, color: c, size: 22),
        title: Text(title,
            style: TextStyle(
                color: color == Colors.orangeAccent ? c : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right,
            color: Colors.white24, size: 20),
        onTap: onTap,
      ),
    );
  }
}
