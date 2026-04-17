// Notification Settings — bildirim tercihleri
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _likes = true;
  bool _comments = true;
  bool _follows = true;
  bool _messages = true;
  bool _challenges = true;
  bool _battles = true;
  bool _dnd = false;
  int _dndStart = 23;
  int _dndEnd = 7;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _likes = p.getBool('n_likes') ?? true;
      _comments = p.getBool('n_comments') ?? true;
      _follows = p.getBool('n_follows') ?? true;
      _messages = p.getBool('n_messages') ?? true;
      _challenges = p.getBool('n_challenges') ?? true;
      _battles = p.getBool('n_battles') ?? true;
      _dnd = p.getBool('n_dnd') ?? false;
      _dndStart = p.getInt('n_dnd_start') ?? 23;
      _dndEnd = p.getInt('n_dnd_end') ?? 7;
    });
  }

  Future<void> _save(String key, dynamic value) async {
    final p = await SharedPreferences.getInstance();
    if (value is bool) await p.setBool(key, value);
    if (value is int) await p.setInt(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(title: const Text('🔔 Bildirim Ayarları')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Group('Etkileşim'),
          _Tile('❤️ Beğeniler', _likes, (v) {
            setState(() => _likes = v);
            _save('n_likes', v);
          }),
          _Tile('💬 Yorumlar', _comments, (v) {
            setState(() => _comments = v);
            _save('n_comments', v);
          }),
          _Tile('👤 Yeni Takipçiler', _follows, (v) {
            setState(() => _follows = v);
            _save('n_follows', v);
          }),
          _Tile('✉️ Mesajlar', _messages, (v) {
            setState(() => _messages = v);
            _save('n_messages', v);
          }),
          const SizedBox(height: 16),
          _Group('Özellikler'),
          _Tile('🏆 Haftalık Challenge', _challenges, (v) {
            setState(() => _challenges = v);
            _save('n_challenges', v);
          }),
          _Tile('⚔️ Prompt Battle', _battles, (v) {
            setState(() => _battles = v);
            _save('n_battles', v);
          }),
          const SizedBox(height: 16),
          _Group('Sessiz Saatler'),
          SwitchListTile(
            value: _dnd,
            onChanged: (v) {
              setState(() => _dnd = v);
              _save('n_dnd', v);
            },
            title: const Text('Rahatsız Etme',
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
              _dnd
                  ? '$_dndStart:00 - $_dndEnd:00 arası sessiz'
                  : 'Belirli saatlerde bildirim gelmez',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            secondary:
                const Icon(Icons.bedtime, color: Colors.purpleAccent),
            activeTrackColor: Colors.purpleAccent.withValues(alpha: 0.4),
            thumbColor:
                WidgetStateProperty.all(Colors.purpleAccent),
          ),
          if (_dnd)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0B141D),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TimePicker(
                      label: 'Başlangıç',
                      hour: _dndStart,
                      onChanged: (v) {
                        setState(() => _dndStart = v);
                        _save('n_dnd_start', v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePicker(
                      label: 'Bitiş',
                      hour: _dndEnd,
                      onChanged: (v) {
                        setState(() => _dndEnd = v);
                        _save('n_dnd_end', v);
                      },
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  const _Group(this.title);

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
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Tile(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B141D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title:
            Text(label, style: const TextStyle(color: Colors.white)),
        activeTrackColor: Colors.cyanAccent.withValues(alpha: 0.4),
        thumbColor: WidgetStateProperty.all(Colors.cyanAccent),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final int hour;
  final ValueChanged<int> onChanged;
  const _TimePicker({
    required this.label,
    required this.hour,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 6),
        DropdownButton<int>(
          value: hour,
          isExpanded: true,
          dropdownColor: const Color(0xFF0B141D),
          style: const TextStyle(color: Colors.white),
          items: List.generate(
              24,
              (i) => DropdownMenuItem(
                    value: i,
                    child: Text('${i.toString().padLeft(2, '0')}:00'),
                  )),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
