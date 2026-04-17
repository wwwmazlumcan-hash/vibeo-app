// Language Settings — dil seçimi
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selected = 'tr';

  static const _langs = [
    _Lang('tr', 'Türkçe', '🇹🇷'),
    _Lang('en', 'English', '🇬🇧'),
    _Lang('de', 'Deutsch', '🇩🇪'),
    _Lang('fr', 'Français', '🇫🇷'),
    _Lang('es', 'Español', '🇪🇸'),
    _Lang('ar', 'العربية', '🇸🇦'),
    _Lang('ru', 'Русский', '🇷🇺'),
    _Lang('ja', '日本語', '🇯🇵'),
    _Lang('ko', '한국어', '🇰🇷'),
    _Lang('zh', '中文', '🇨🇳'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _selected = p.getString('lang') ?? 'tr');
  }

  Future<void> _save(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', code);
    setState(() => _selected = code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Dil değiştirildi. Uygulamayı yeniden başlat.'),
      backgroundColor: Colors.cyanAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(title: const Text('🌐 Dil')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _langs.length,
        itemBuilder: (context, i) {
          final l = _langs[i];
          final selected = l.code == _selected;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.cyanAccent.withValues(alpha: 0.1)
                  : const Color(0xFF0B141D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? Colors.cyanAccent
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: ListTile(
              leading: Text(l.flag, style: const TextStyle(fontSize: 28)),
              title: Text(l.name,
                  style: TextStyle(
                      color: selected ? Colors.cyanAccent : Colors.white,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal)),
              trailing: selected
                  ? const Icon(Icons.check_circle,
                      color: Colors.cyanAccent)
                  : null,
              onTap: () => _save(l.code),
            ),
          );
        },
      ),
    );
  }
}

class _Lang {
  final String code;
  final String name;
  final String flag;
  const _Lang(this.code, this.name, this.flag);
}
