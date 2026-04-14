import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
  final _messages = <_Msg>[];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;

  static const _quickPrompts = [
    '7 günlük antrenman planı yap',
    'Ev egzersizi için program',
    'Karın kası için egzersiz',
    'Sağlıklı beslenme önerileri',
    'Kilo vermek için tavsiye',
    'Sabah rutini öner',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_Msg(
      text: 'Merhaba! Ben Vibeo AI Fitness Koçun 💪\n'
          'Antrenman planı, beslenme önerileri veya fitness hedeflerin için buradayım. Ne öğrenmek istersin?',
      isAi: true,
    ));
  }

  Future<void> _ask(String question) async {
    if (question.trim().isEmpty) return;
    _ctrl.clear();
    setState(() {
      _messages.add(_Msg(text: question, isAi: false));
      _loading = true;
    });
    _scrollDown();

    try {
      final prompt = Uri.encodeComponent(
        'Sen bir profesyonel fitness koçusun. '
        'Türkçe olarak kısa, net ve motive edici cevap ver. '
        'Soru: $question',
      );

      final response = await http
          .get(Uri.parse('https://text.pollinations.ai/$prompt'))
          .timeout(const Duration(seconds: 20));

      final answer = response.statusCode == 200
          ? response.body.trim()
          : 'Şu an cevaplayamıyorum, biraz sonra dene.';

      setState(() => _messages.add(_Msg(text: answer, isAi: true)));
    } catch (e) {
      setState(() => _messages.add(_Msg(
            text: 'Bağlantı hatası. Lütfen tekrar dene.',
            isAi: true,
          )));
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💪', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('AI FITNESS KOÇ',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Quick prompts
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _ask(_quickPrompts[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_quickPrompts[i],
                      style: const TextStyle(
                          color: Colors.greenAccent, fontSize: 12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12),

          // Chat area
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) {
                  return const _TypingIndicator();
                }
                return _ChatBubble(msg: _messages[i]);
              },
            ),
          ),

          // Input
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _ask,
                    decoration: InputDecoration(
                      hintText: 'Fitness sorun...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _ask(_ctrl.text),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isAi;
  _Msg({required this.text, required this.isAi});
}

class _ChatBubble extends StatelessWidget {
  final _Msg msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.80),
        decoration: BoxDecoration(
          color: msg.isAi
              ? Colors.green.shade900.withValues(alpha: 0.7)
              : Colors.white12,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: msg.isAi ? const Radius.circular(4) : null,
            bottomRight: !msg.isAi ? const Radius.circular(4) : null,
          ),
          border: msg.isAi
              ? Border.all(color: Colors.greenAccent.withValues(alpha: 0.3))
              : null,
        ),
        child: Text(
          msg.text,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.greenAccent,
              child: Text('💪', style: TextStyle(fontSize: 14)),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                color: Colors.greenAccent,
                backgroundColor: Colors.white12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
