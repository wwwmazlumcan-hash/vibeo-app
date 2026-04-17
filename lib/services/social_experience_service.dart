import 'dart:math';

enum SocialIdentityMode { anonymous, verified, fluid }

class CompanionHint {
  final String title;
  final String message;
  final String rewrite;

  const CompanionHint({
    required this.title,
    required this.message,
    required this.rewrite,
  });
}

class WellnessReport {
  final int totalMinutes;
  final int meaningfulMinutes;
  final bool detoxSuggested;
  final String summary;
  final String advice;

  const WellnessReport({
    required this.totalMinutes,
    required this.meaningfulMinutes,
    required this.detoxSuggested,
    required this.summary,
    required this.advice,
  });
}

class KnowledgeTokenSnapshot {
  final int knowledgeTokens;
  final int orbitTokens;
  final int creatorCredits;
  final String accessLabel;

  const KnowledgeTokenSnapshot({
    required this.knowledgeTokens,
    required this.orbitTokens,
    required this.creatorCredits,
    required this.accessLabel,
  });
}

class ParallelUniverseVariant {
  final String orbitName;
  final String summary;
  final String angle;

  const ParallelUniverseVariant({
    required this.orbitName,
    required this.summary,
    required this.angle,
  });
}

class FeedToneLens {
  final String title;
  final String summary;

  const FeedToneLens({required this.title, required this.summary});
}

class SocialExperienceService {
  static double deepFeedScore(
    Map<String, dynamic> post, {
    required Map<String, int> preferredHashtags,
    required Map<String, int> preferredCreators,
  }) {
    final prompt = (post['prompt'] ?? '').toString();
    final hashtags = List<String>.from(post['hashtags'] ?? const <String>[]);
    final authorId = (post['userId'] ?? '') as String;
    final likes = (post['likesCount'] ?? 0) as int;
    final comments = (post['commentsCount'] ?? 0) as int;

    double score = prompt.length * 0.45 + comments * 8 + likes * 1.2;
    score += hashtags.length * 3;
    score += (preferredCreators[authorId] ?? 0) * 6;
    for (final tag in hashtags) {
      score += (preferredHashtags[tag] ?? 0) * 7;
    }
    if ((post['remixOf'] ?? '').toString().isNotEmpty) score += 10;
    if ((post['creationMode'] ?? '') == 'impossible_remix') score += 8;
    return score;
  }

  static double funFeedScore(
    Map<String, dynamic> post, {
    required Map<String, int> preferredHashtags,
    required Map<String, int> preferredCreators,
  }) {
    final prompt = (post['prompt'] ?? '').toString().toLowerCase();
    final hashtags = List<String>.from(post['hashtags'] ?? const <String>[]);
    final authorId = (post['userId'] ?? '') as String;
    final likes = (post['likesCount'] ?? 0) as int;

    const funWords = ['meme', 'fun', 'lol', 'komik', 'roast', 'wild'];
    double score = likes * 2.4 + max(0, 120 - prompt.length) * 0.12;
    score += (preferredCreators[authorId] ?? 0) * 4;
    for (final word in funWords) {
      if (prompt.contains(word)) score += 10;
    }
    for (final tag in hashtags) {
      score += min((preferredHashtags[tag] ?? 0) * 2, 6);
    }
    return score;
  }

  static int conversationQualityScore(Map<String, dynamic> post) {
    final prompt = (post['prompt'] ?? '').toString();
    final comments = (post['commentsCount'] ?? 0) as int;
    final hashtags = List<String>.from(post['hashtags'] ?? const <String>[]);
    final raw = 18 + prompt.length ~/ 6 + comments * 9 + hashtags.length * 4;
    return raw.clamp(0, 100);
  }

  static CompanionHint buildCompanionHint({
    required String prompt,
    required String username,
  }) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return const CompanionHint(
        title: 'AI Companion sessiz',
        message:
            'Bir sey yazdigin anda daha akilli, daha komik veya daha keskin bir versiyon onerebilirim.',
        rewrite: 'Tek cümlede iddiani, ikinci cümlede nedenini söyle.',
      );
    }

    final concise = trimmed.length < 70;
    return CompanionHint(
      title: concise ? 'Biraz daha derinlestirelim' : 'Yapi guclu gorunuyor',
      message: concise
          ? '@$username, bu paylasim hizli ama yuzeyde kaliyor. Bir fikir, bir karsi gorus veya tek bir gozlem eklersen sohbet kalitesi yukselir.'
          : '@$username, paylasimin bir eksen tasiyor. Sonuna net bir soru eklersen yorumlar daha anlamli dallanir.',
      rewrite: concise
          ? '$trimmed\n\nAsil merak ettigim sey su: bu durum gelecekte nasil degisecek?'
          : '$trimmed\n\nSence bu fikir gercek hayatta hangi noktada kirilmaya baslar?',
    );
  }

  static WellnessReport buildWellnessReport({
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> viewedPosts,
  }) {
    final totalViews = viewedPosts.length;
    final meaningfulViews = viewedPosts.where((post) {
      return conversationQualityScore(post) >= 55;
    }).length;
    final totalMinutes = max(6, totalViews * 3);
    final meaningfulMinutes = min(totalMinutes, meaningfulViews * 4);
    final detoxSuggested = totalMinutes - meaningfulMinutes >= 35;

    return WellnessReport(
      totalMinutes: totalMinutes,
      meaningfulMinutes: meaningfulMinutes,
      detoxSuggested: detoxSuggested,
      summary:
          'Bugun $totalMinutes dakika gecirdin, bunun $meaningfulMinutes dakikasi gercekten deger ureten iceriklerle gecti.',
      advice: detoxSuggested
          ? 'Dopamin Detoks Modu acilirsa bir sure sadece metin ve uzun form icerik gosterebiliriz.'
          : 'Su an akisin dengeli. Deep Feed agirligini korursan verimli sure artar.',
    );
  }

  static KnowledgeTokenSnapshot buildKnowledgeTokenSnapshot({
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> posts,
  }) {
    final points = (userData['points'] ?? 0) as int;
    final deepPosts =
        posts.where((post) => conversationQualityScore(post) >= 60).length;
    final remixPosts = posts.where((post) {
      final mode = (post['creationMode'] ?? '') as String;
      return mode == 'remix' || mode == 'impossible_remix';
    }).length;
    final knowledgeTokens = (points ~/ 25) + deepPosts * 3;
    final orbitTokens = deepPosts + remixPosts * 2;
    final creatorCredits = (points ~/ 40) + max(0, remixPosts - 1) * 5;

    final label = knowledgeTokens >= 60
        ? 'Prime Orbit erişimi açık'
        : knowledgeTokens >= 25
            ? 'Uzman orbit erişimi yakında'
            : 'Temel orbit erişimi';

    return KnowledgeTokenSnapshot(
      knowledgeTokens: knowledgeTokens,
      orbitTokens: orbitTokens,
      creatorCredits: creatorCredits,
      accessLabel: label,
    );
  }

  static List<ParallelUniverseVariant> buildParallelUniverseVariants({
    required String prompt,
    required List<String> hashtags,
  }) {
    final leadTag = hashtags.isEmpty ? 'genel' : hashtags.first;
    return [
      ParallelUniverseVariant(
        orbitName: 'Felsefe Orbiti',
        angle: 'Derin yorum',
        summary:
            'Bu evrende paylasim, #$leadTag yerine fikir sorumlulugu uzerinden okunuyor: insanlar ne dusunuyor degil, neden dusundukleri tartisiliyor.',
      ),
      const ParallelUniverseVariant(
        orbitName: 'Mizah Orbiti',
        angle: 'Eglenceli yorum',
        summary:
            'Ayni icerik burada ironik bir enerji tasiyor. Ciddiyet korunuyor ama ilk cikis kapisi espri oluyor.',
      ),
      const ParallelUniverseVariant(
        orbitName: 'Gelecek Orbiti',
        angle: 'Uzun vade',
        summary:
            'Bu versiyon, paylasimin 5 yil sonraki etkisini soruyor: bugun masum gorunen sey gelecekte hangi davranisi normallestirir?',
      ),
    ];
  }

  static FeedToneLens buildFeedToneLens(String mode) {
    switch (mode) {
      case 'deep':
        return const FeedToneLens(
          title: 'Deep Feed',
          summary:
              'Uzun omurlu, dusunmeye degen ve sohbet kalitesi yuksek icerikler one cikiyor.',
        );
      case 'fun':
        return const FeedToneLens(
          title: 'Fun Feed',
          summary:
              'Hizli, komik, enerjik ve hafif icerikler akisi yumusatmak icin one cikiyor.',
        );
      default:
        return const FeedToneLens(title: 'Feed', summary: '');
    }
  }

  static List<String> buildValueMatchSignals({
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> posts,
  }) {
    final signals = <String>{};
    final deepCount =
        posts.where((post) => conversationQualityScore(post) >= 60).length;
    final points = (userData['points'] ?? 0) as int;

    if (deepCount >= 3) signals.add('uzun vadeli dusunen');
    if (points >= 120) signals.add('istikrarli ureten');
    if (posts
        .any((post) => (post['creationMode'] ?? '') == 'impossible_remix')) {
      signals.add('yaratici risk alan');
    }
    if (signals.isEmpty) signals.add('kesfetmeye acik');
    return signals.toList();
  }
}
