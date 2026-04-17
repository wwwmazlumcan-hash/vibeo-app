import 'package:flutter/material.dart';

import '../../services/openai_text_service.dart';

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
    '7 günlük plan',
    'Ev egzersizi',
    'Karın kası',
    'Beslenme önerileri',
    'Kilo verme',
    'Sabah rutini',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_Msg(
      text: 'AI Fitness Koçun burada!\n'
          'Antrenman planı, beslenme veya fitness hedeflerin için sorun.',
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
      final answer = await OpenAiTextService.generate(
        prompt:
            'Sen bir profesyonel fitness koçusun. Türkçe olarak kısa, net ve motive edici cevap ver. Soru: $question',
        temperature: 0.7,
        maxTokens: 180,
        fallback: 'Şu an cevaplayamıyorum, biraz sonra dene.',
      );

      setState(() => _messages.add(_Msg(text: answer, isAi: true)));
    } catch (e) {
      setState(() => _messages
          .add(_Msg(text: 'Bağlantı hatası. Lütfen tekrar dene.', isAi: true)));
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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Colors.cyanAccent, Color(0xFF006666)],
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.5),
                      blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.fitness_center,
                  color: Colors.black, size: 14),
            ),
            const SizedBox(width: 8),
            const Text('AI FITNESS KOÇ'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _ask(_quickPrompts[i]),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.35)),
                  ),
                  child: Text(_quickPrompts[i],
                      style: const TextStyle(
                          color: Colors.cyanAccent, fontSize: 12)),
                ),
              ),
            ),
          ),
          Divider(color: Colors.cyanAccent.withValues(alpha: 0.1), height: 16),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Colors.cyanAccent, Color(0xFF006666)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      Colors.cyanAccent.withValues(alpha: 0.4),
                                  blurRadius: 8),
                            ],
                          ),
                          child: const Icon(Icons.fitness_center,
                              color: Colors.black, size: 14),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: LinearProgressIndicator(
                            color: Colors.cyanAccent,
                            backgroundColor:
                                Colors.cyanAccent.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final m = _messages[i];
                return Align(
                  alignment:
                      m.isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.80),
                    decoration: BoxDecoration(
                      color: m.isAi
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.cyanAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomLeft: m.isAi ? const Radius.circular(4) : null,
                        bottomRight: !m.isAi ? const Radius.circular(4) : null,
                      ),
                      border: Border.all(
                        color: m.isAi
                            ? Colors.cyanAccent.withValues(alpha: 0.2)
                            : Colors.cyanAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(m.text,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14, height: 1.4)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: Colors.cyanAccent.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.2)),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _ask,
                      decoration: const InputDecoration(
                        hintText: 'Fitness sorun...',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _ask(_ctrl.text),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Colors.cyanAccent, Color(0xFF006666)],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.5),
                            blurRadius: 12),
                      ],
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
