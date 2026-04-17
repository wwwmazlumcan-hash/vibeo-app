import 'openai_text_service.dart';

enum RealityLayerMode {
  balanced,
  child,
  expert,
  audio,
  haptic,
}

class RealityLayerResult {
  final String title;
  final String summary;
  final String accessibilityHint;
  final String signature;

  const RealityLayerResult({
    required this.title,
    required this.summary,
    required this.accessibilityHint,
    required this.signature,
  });
}

class RealityLayerService {
  static Future<RealityLayerResult> adapt({
    required String prompt,
    required String contentOriginLabel,
    required int proofHumanScore,
    required int proofAiScore,
    required RealityLayerMode mode,
  }) async {
    final fallback = _fallbackResult(
      prompt: prompt,
      contentOriginLabel: contentOriginLabel,
      proofHumanScore: proofHumanScore,
      proofAiScore: proofAiScore,
      mode: mode,
    );

    final instruction = switch (mode) {
      RealityLayerMode.balanced =>
        'İçeriği kısa, net ve dengeli bir şekilde yeniden anlat. 2 cümlelik özet ve 1 erişilebilirlik ipucu ver.',
      RealityLayerMode.child =>
        'İçeriği 10 yaşındaki bir çocuğa anlatır gibi sadeleştir. Karmaşık kavramları günlük örnekle açıkla. 2 kısa paragraf üret.',
      RealityLayerMode.expert =>
        'İçeriği alan uzmanına yönelik yeniden yapılandır. Teknik terim, olası tradeoff ve uygulanabilir 2 çıkarım ver.',
      RealityLayerMode.audio =>
        'İçeriği sesli anlatıma uygun dönüştür. Yavaş tempolu anlatıcı tonunda 3 cümlelik sesli özet ve görüntü betimi üret.',
      RealityLayerMode.haptic =>
        'İçeriği görme engelli kullanıcı için dokunsal veri akışı gibi tarif et. Yoğunluk, vurgu ve ritim üzerinden anlaşılır bir haptic rehber ver.',
    };

    final aiPrompt = '''
$instruction

İçerik: $prompt
Kaynak etiketi: ${contentOriginLabel.isEmpty ? 'belirsiz' : contentOriginLabel}
İnsan katkı skoru: $proofHumanScore
AI katkı skoru: $proofAiScore

Sadece şu formatta dön:
Başlık: ...
Özet: ...
Erişilebilirlik: ...
''';

    try {
      final body = await OpenAiTextService.generate(
        prompt: aiPrompt,
        temperature: 0.6,
        maxTokens: 220,
        fallback: '',
      );

      if (body.trim().isEmpty) {
        return fallback;
      }
      final title = _extract(body, 'Başlık:') ?? fallback.title;
      final summary = _extract(body, 'Özet:') ?? fallback.summary;
      final accessibility =
          _extract(body, 'Erişilebilirlik:') ?? fallback.accessibilityHint;

      return RealityLayerResult(
        title: title,
        summary: summary,
        accessibilityHint: accessibility,
        signature: fallback.signature,
      );
    } catch (_) {
      return fallback;
    }
  }

  static RealityLayerResult _fallbackResult({
    required String prompt,
    required String contentOriginLabel,
    required int proofHumanScore,
    required int proofAiScore,
    required RealityLayerMode mode,
  }) {
    final clean = prompt.trim();
    final short = clean.length > 170 ? '${clean.substring(0, 170)}...' : clean;

    final summary = switch (mode) {
      RealityLayerMode.balanced => short,
      RealityLayerMode.child =>
        'Bu içerik şunu anlatıyor: $short. Büyük fikri küçük ve günlük bir örnekle düşün.',
      RealityLayerMode.expert =>
        'Temel sinyal: $short. Teknik açıdan insan katkısı $proofHumanScore, AI katkısı $proofAiScore seviyesinde okunuyor.',
      RealityLayerMode.audio =>
        'Sesli özet: önce ana fikri dinle, sonra görseldeki vurgu noktalarını takip et. İçerik özü: $short',
      RealityLayerMode.haptic =>
        'Dokunsal akış: girişte düşük yoğunluk, ana fikirde çift vurgu, kapanışta uzun titreşim. İçerik özü: $short',
    };

    final accessibility = switch (mode) {
      RealityLayerMode.audio =>
        'Sesli mod açıkken önce bağlam, sonra görsel betim ve en sonda eylem önerisi okunmalı.',
      RealityLayerMode.haptic =>
        'Haptic modda kısa titreşim detay, uzun titreşim ana mesaj anlamına gelir.',
      _ => 'İstersen bu katmanı sesli veya haptic moda çevirebilirsin.',
    };

    return RealityLayerResult(
      title: _modeTitle(mode),
      summary: summary,
      accessibilityHint: accessibility,
      signature: _buildSignature(
        contentOriginLabel: contentOriginLabel,
        proofHumanScore: proofHumanScore,
        proofAiScore: proofAiScore,
      ),
    );
  }

  static String _modeTitle(RealityLayerMode mode) {
    return switch (mode) {
      RealityLayerMode.balanced => 'Dengeli Katman',
      RealityLayerMode.child => 'Çocuk Anlatımı',
      RealityLayerMode.expert => 'Uzman Katmanı',
      RealityLayerMode.audio => 'Sesli Özet',
      RealityLayerMode.haptic => 'Haptic Akış',
    };
  }

  static String _buildSignature({
    required String contentOriginLabel,
    required int proofHumanScore,
    required int proofAiScore,
  }) {
    final total = proofHumanScore + proofAiScore;
    final humanPct = total == 0 ? 0 : ((proofHumanScore / total) * 100).round();
    final aiPct = total == 0 ? 0 : 100 - humanPct;
    final source =
        contentOriginLabel.isEmpty ? 'İmza verisi sınırlı' : contentOriginLabel;
    return '$source · İnsan %$humanPct · AI %$aiPct';
  }

  static String? _extract(String body, String prefix) {
    final lines = body.split('\n');
    for (final line in lines) {
      if (line.trimLeft().startsWith(prefix)) {
        return line.split(prefix).last.trim();
      }
    }
    return null;
  }
}
