class CommunicationInsight {
  final String tone;
  final String perception;
  final String suggestion;
  final String empathyBridge;
  final bool needsAttention;

  const CommunicationInsight({
    required this.tone,
    required this.perception,
    required this.suggestion,
    required this.empathyBridge,
    required this.needsAttention,
  });
}

class MessageScenario {
  final String title;
  final String outcome;
  final String probability;

  const MessageScenario({
    required this.title,
    required this.outcome,
    required this.probability,
  });
}

class MessageSimulation {
  final String intentQuestion;
  final String constructiveRewrite;
  final String echoBreaker;
  final List<MessageScenario> scenarios;

  const MessageSimulation({
    required this.intentQuestion,
    required this.constructiveRewrite,
    required this.echoBreaker,
    required this.scenarios,
  });
}

class CommunicationInsightService {
  static CommunicationInsight analyze(String text) {
    final value = text.trim().toLowerCase();
    if (value.isEmpty) {
      return const CommunicationInsight(
        tone: 'nötr',
        perception: 'Mesajın dengeli görünüyor.',
        suggestion: 'Göndermeden önce amaç ve netlik kontrolü yap.',
        empathyBridge: 'Kısa ve açık ifade, yanlış anlaşılmayı azaltır.',
        needsAttention: false,
      );
    }

    final aggressiveHits = [
      'saçma',
      'anlamıyorsun',
      'aptal',
      'sus',
      'hemen',
      '!!!',
    ].where(value.contains).length;
    final sadHits = ['üzgün', 'kırıldım', 'yalnız', 'moralim bozuk']
        .where(value.contains)
        .length;
    final sarcasticHits = ['tabii ya', 'aynen', 'şaka gibi', 'ne kadar da']
        .where(value.contains)
        .length;

    if (aggressiveHits > 0) {
      return const CommunicationInsight(
        tone: 'sert',
        perception: 'Karşı tarafta agresif veya savunmacı algı yaratabilir.',
        suggestion:
            'Fiilleri yumuşat, suçlayıcı dili gözlem odaklı cümleye çevir.',
        empathyBridge:
            'Kültürel bağlamda doğrudan eleştiri bazı kişilerce kişisel saldırı gibi algılanabilir.',
        needsAttention: true,
      );
    }

    if (sarcasticHits > 0) {
      return const CommunicationInsight(
        tone: 'alaycı',
        perception: 'Mesajın alaycı veya küçümseyici okunabilir.',
        suggestion:
            'İroni yerine ne istediğini doğrudan yazman daha güvenli olur.',
        empathyBridge:
            'Yazılı iletişimde mimik kaybolduğu için mizah kolayca yanlış anlaşılır.',
        needsAttention: true,
      );
    }

    if (sadHits > 0) {
      return const CommunicationInsight(
        tone: 'hassas',
        perception: 'Mesajın kırgın veya üzgün bir ruh hali yansıtıyor.',
        suggestion: 'İhtiyacını net ekle: “Şu konuda desteğe ihtiyacım var.”',
        empathyBridge:
            'Duygunu adlandırman, kültürel farklılıklarda niyetinin daha doğru anlaşılmasını sağlar.',
        needsAttention: true,
      );
    }

    return const CommunicationInsight(
      tone: 'dengeli',
      perception: 'Mesajın açık ve yapıcı görünüyor.',
      suggestion:
          'İstersen bir soru ekleyerek karşı tarafın katılımını artırabilirsin.',
      empathyBridge:
          'Net dil ve kısa bağlam cümlesi, farklı kültürel arka planlarda anlaşılmayı artırır.',
      needsAttention: false,
    );
  }

  static MessageSimulation simulate(String text) {
    final insight = analyze(text);
    final rewrite = rewriteConstructively(text);

    if (insight.needsAttention) {
      return MessageSimulation(
        intentQuestion:
            'Gerçekten kırmak mı istiyorsun, yoksa yorgunluk veya gerilim bunu daha sert gösteriyor olabilir mi?',
        constructiveRewrite: rewrite,
        echoBreaker:
            'Zıt görüşü savunma değil, aynı problemi farklı yerden çözmeye çalışma olarak çerçevele.',
        scenarios: const [
          MessageScenario(
            title: 'Ham Gönderim',
            outcome:
                'Karşı taraf savunmaya geçebilir ve konuşma hızla gerilebilir.',
            probability: '%80 gerilim',
          ),
          MessageScenario(
            title: 'Yumuşatılmış Versiyon',
            outcome:
                'Eleştiri korunur ama niyet daha net görünür; yanıt alma ihtimali artar.',
            probability: '%60 uzlaşı',
          ),
          MessageScenario(
            title: 'Soru ile Açılış',
            outcome:
                'Karşı taraf önce kendini açıklama alanı bulur, tartışma daha sakin başlar.',
            probability: '%72 yapıcı diyalog',
          ),
        ],
      );
    }

    return MessageSimulation(
      intentQuestion:
          'Mesajın net görünüyor. Daha fazla açıklık mı, daha fazla sıcaklık mı istiyorsun?',
      constructiveRewrite: rewrite,
      echoBreaker:
          'Karşı argümana bir cümle yer açmak, yankı odasını kırmadan etkini artırır.',
      scenarios: const [
        MessageScenario(
          title: 'Olduğu Gibi Gönder',
          outcome: 'Mesaj muhtemelen net ve sakin algılanır.',
          probability: '%76 olumlu karşılanma',
        ),
        MessageScenario(
          title: 'Kısa Bağlam Ekle',
          outcome: 'Niyetin daha hızlı anlaşılır, yanlış okuma riski düşer.',
          probability: '%84 net anlaşılma',
        ),
        MessageScenario(
          title: 'Soru ile Bitir',
          outcome: 'Karşı tarafı pasif okuyucu yerine katılımcı yapar.',
          probability: '%69 etkileşim artışı',
        ),
      ],
    );
  }

  static String rewriteConstructively(String text) {
    var value = text.trim();
    if (value.isEmpty) return value;

    const replacements = {
      'saçma': 'bana ikna edici gelmiyor',
      'anlamıyorsun': 'aynı noktaya bakmıyor olabiliriz',
      'aptal': 'çok zayıf',
      'sus': 'bir dakika durup tekrar bakalım',
      'hemen': 'mümkünse kısa sürede',
      '!!!': '!',
    };

    replacements.forEach((source, target) {
      value = value.replaceAll(source, target);
      value = value.replaceAll(source.toUpperCase(), target);
    });

    if (!value.contains('?') && !value.toLowerCase().contains('bence')) {
      value = 'Bence $value';
    }

    return value;
  }
}
