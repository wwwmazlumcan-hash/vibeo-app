import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification_model.dart';

class SerendipityJumpPlan {
  final String title;
  final String summary;
  final String categoryLabel;
  final List<String> signalWords;
  final List<String> hashtags;

  const SerendipityJumpPlan({
    required this.title,
    required this.summary,
    required this.categoryLabel,
    required this.signalWords,
    required this.hashtags,
  });

  double scorePost(Map<String, dynamic> post) {
    final prompt = (post['prompt'] ?? '').toString().toLowerCase();
    final tags = List<String>.from(post['hashtags'] ?? const <String>[]);
    final likes = (post['likesCount'] ?? 0) as int;

    double score = 0;

    for (final word in signalWords) {
      if (prompt.contains(word)) {
        score += 22;
      }
    }

    for (final tag in hashtags) {
      if (tags.contains(tag)) {
        score += 26;
      }
    }

    final createdAt = post['createdAt'];
    if (createdAt is Timestamp) {
      final ageHours = DateTime.now().difference(createdAt.toDate()).inHours;
      if (ageHours <= 24) score += 10;
      if (ageHours <= 6) score += 8;
    }

    score += min(likes * 1.4, 28);
    score += tags.length * 1.5;
    return score;
  }
}

class VibeDnaReport {
  final String codename;
  final String mirrorLine;
  final String anomalyLabel;
  final int rarityScore;
  final int contrastScore;
  final List<String> dominantSignals;
  final List<String> paletteLabels;
  final int sampleCount;

  const VibeDnaReport({
    required this.codename,
    required this.mirrorLine,
    required this.anomalyLabel,
    required this.rarityScore,
    required this.contrastScore,
    required this.dominantSignals,
    required this.paletteLabels,
    required this.sampleCount,
  });
}

class ParallelFeedLens {
  final String title;
  final String summary;
  final List<String> anchors;
  final String realityName;
  final String realitySummary;

  const ParallelFeedLens({
    required this.title,
    required this.summary,
    required this.anchors,
    required this.realityName,
    required this.realitySummary,
  });
}

class NotificationAfterimage {
  final String title;
  final String summary;
  final ColorSeed colorSeed;

  const NotificationAfterimage({
    required this.title,
    required this.summary,
    required this.colorSeed,
  });
}

enum ColorSeed { cyan, amber, pink, green, purple }

class ImpossibleRemixPlan {
  final String title;
  final String remixPrompt;
  final String bridgeLine;
  final List<String> tags;

  const ImpossibleRemixPlan({
    required this.title,
    required this.remixPrompt,
    required this.bridgeLine,
    required this.tags,
  });
}

class PostAfterimage {
  final String title;
  final String summary;
  final ColorSeed colorSeed;

  const PostAfterimage({
    required this.title,
    required this.summary,
    required this.colorSeed,
  });
}

class RemixShelfLens {
  final String title;
  final String summary;

  const RemixShelfLens({
    required this.title,
    required this.summary,
  });
}

class RemixLeaderboardLens {
  final String title;
  final String summary;

  const RemixLeaderboardLens({
    required this.title,
    required this.summary,
  });
}

class RemixLineageInsight {
  final String title;
  final String summary;
  final ColorSeed colorSeed;

  const RemixLineageInsight({
    required this.title,
    required this.summary,
    required this.colorSeed,
  });
}

class RemixDuelLens {
  final String title;
  final String summary;

  const RemixDuelLens({required this.title, required this.summary});
}

class SurpriseEngineService {
  static const Map<String, List<String>> _signalLexicon = {
    'neon': ['neon', 'cyber', 'glow', 'laser', 'electric', 'teal'],
    'dream': ['dream', 'moon', 'soft', 'mist', 'surreal', 'sleep'],
    'chaos': ['chaos', 'wild', 'glitch', 'fracture', 'storm', 'noise'],
    'ritual': ['ritual', 'ancient', 'sacred', 'totem', 'oracle', 'temple'],
    'architect': ['city', 'architecture', 'grid', 'structure', 'tower'],
    'organic': ['forest', 'flower', 'petal', 'ocean', 'nature', 'bloom'],
    'cinematic': ['cinematic', 'dramatic', 'epic', 'film', 'lens', 'frame'],
    'playful': ['fun', 'cute', 'joy', 'smile', 'toy', 'happy'],
    'cosmic': ['space', 'cosmic', 'star', 'galaxy', 'orbital', 'planet'],
  };

  static const Map<String, String> _paletteBySignal = {
    'neon': 'Cyan Flux',
    'dream': 'Moon Lilac',
    'chaos': 'Solar Red',
    'ritual': 'Obsidian Gold',
    'architect': 'Chrome Blue',
    'organic': 'Bio Green',
    'cinematic': 'Amber Smoke',
    'playful': 'Candy Pulse',
    'cosmic': 'Deep Void',
  };

  static double parallelScore(
    Map<String, dynamic> post, {
    required Map<String, int> preferredHashtags,
    required Map<String, int> preferredCreators,
  }) {
    final prompt = (post['prompt'] ?? '').toString().toLowerCase();
    final tags = List<String>.from(post['hashtags'] ?? const <String>[]);
    final likes = (post['likesCount'] ?? 0) as int;
    final authorId = (post['userId'] ?? '') as String;

    final signalCounts = _buildSignalCounts([post]);
    final rankedSignals = signalCounts.keys.toList()
      ..sort((a, b) => (signalCounts[b] ?? 0).compareTo(signalCounts[a] ?? 0));
    final primary = rankedSignals.isNotEmpty ? rankedSignals.first : 'dream';

    double score = 14 + min(likes * 2.2, 34);
    score += (preferredCreators[authorId] ?? 0) * 5;

    for (final tag in tags) {
      final preference = preferredHashtags[tag] ?? 0;
      score += preference == 0 ? 8 : max(10 - preference * 2, 1);
    }

    if (prompt.contains(primary)) {
      score += 12;
    }

    final createdAt = post['createdAt'];
    if (createdAt is Timestamp) {
      final hours = DateTime.now().difference(createdAt.toDate()).inHours;
      if (hours <= 12) score += 12;
      if (hours > 96) score -= 8;
    }

    return score;
  }

  static ParallelFeedLens buildParallelFeedLens(
    List<Map<String, dynamic>> posts,
  ) {
    final counts = _buildSignalCounts(posts);
    final rankedSignals = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
    final primary = rankedSignals.isNotEmpty ? rankedSignals.first : 'dream';
    final secondary = rankedSignals.length > 1 ? rankedSignals[1] : 'neon';
    final reality = _buildDailyReality(primary, secondary);

    return ParallelFeedLens(
      title: '${_capitalize(primary)} Parallel',
      summary:
          'Bu akıs, beklenen yerine sapma, gerilim ve estetik carpismalari one cikarir. ${_capitalize(primary)} ile ${_capitalize(secondary)} arasindaki ince kirilma taraniyor.',
      anchors: [primary, secondary],
      realityName: reality.$1,
      realitySummary: reality.$2,
    );
  }

  static PostAfterimage buildPostAfterimage(Map<String, dynamic> post) {
    final likes = (post['likesCount'] ?? 0) as int;
    final creationMode = (post['creationMode'] ?? '') as String;
    final remixOf = (post['remixOf'] ?? '') as String;
    final hashtags = List<String>.from(post['hashtags'] ?? const <String>[]);

    if (creationMode == 'impossible_remix') {
      return const PostAfterimage(
        title: 'Paradox izi',
        summary:
            'Bu eser iki uyumsuz evreni tek kadraja kitliyor; yorum ve remix akisi normal postlardan daha garip dallanabilir.',
        colorSeed: ColorSeed.purple,
      );
    }

    if (remixOf.isNotEmpty || creationMode == 'remix') {
      return const PostAfterimage(
        title: 'Remix yankisi',
        summary:
            'Bu icerik tekil degil; baska bir postun etkisi burada ikinci bir soy olusturuyor.',
        colorSeed: ColorSeed.amber,
      );
    }

    if (likes >= 12) {
      return const PostAfterimage(
        title: 'Topluluk momentumu',
        summary:
            'Etkilesim yogunlugu bu postu sadece gorunen degil, baskalarinin davranisini da kaydiran bir merkeze donusturuyor.',
        colorSeed: ColorSeed.green,
      );
    }

    final topTag = hashtags.isEmpty ? null : hashtags.first;
    return PostAfterimage(
      title: 'Sessiz etki izi',
      summary: topTag == null
          ? 'Bu post yavas buyuyen bir merak izi birakiyor; gecikmeli etkisi anlik sayilardan daha yuksek olabilir.'
          : '#$topTag ekseninde yeni bir mikro topluluk kapisi acabilir.',
      colorSeed: ColorSeed.cyan,
    );
  }

  static RemixShelfLens buildRemixShelfLens(List<Map<String, dynamic>> posts) {
    final counts = _buildSignalCounts(posts);
    final rankedSignals = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
    final primary = rankedSignals.isNotEmpty ? rankedSignals.first : 'chaos';

    return RemixShelfLens(
      title: '${_capitalize(primary)} Remix Koridoru',
      summary:
          'Imkansiz birlesimler burada toplanir. Ayrik estetikler tek akista carpistigi icin kaydirma davranisi daha uzun surer.',
    );
  }

  static RemixLeaderboardLens buildRemixLeaderboardLens(
    List<Map<String, dynamic>> posts,
  ) {
    final counts = _buildSignalCounts(posts);
    final rankedSignals = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
    final primary = rankedSignals.isNotEmpty ? rankedSignals.first : 'neon';

    return RemixLeaderboardLens(
      title: '${_capitalize(primary)} Remix Liderleri',
      summary:
          'Bu raf, son remix dalgasinda en cok topluluk ivmesi alan deneyleri gosterir.',
    );
  }

  static RemixLineageInsight buildRemixLineageInsight({
    required bool isRemix,
    required int descendantCount,
  }) {
    if (isRemix && descendantCount > 0) {
      return RemixLineageInsight(
        title: 'Soy dallanmasi',
        summary:
            'Bu remix artik tekil degil; kendi alt kolunu olusturmus ve $descendantCount yeni varyasyon dogurmus.',
        colorSeed: ColorSeed.amber,
      );
    }

    if (isRemix) {
      return const RemixLineageInsight(
        title: 'Birinci nesil remix',
        summary:
            'Bu eser baska bir posttan dogdu. Henuz sessiz olsa da ikinci dalga icin uygun bir cekirdek tasiyor.',
        colorSeed: ColorSeed.purple,
      );
    }

    if (descendantCount > 0) {
      return RemixLineageInsight(
        title: 'Kaynak cekirdek',
        summary:
            'Bu orijinal post su ana kadar $descendantCount farkli remix varyasyonu tetikledi.',
        colorSeed: ColorSeed.green,
      );
    }

    return const RemixLineageInsight(
      title: 'Remix potansiyeli',
      summary:
          'Bu post henuz dallanmadi ama yapisi remix zinciri baslatmaya uygun gorunuyor.',
      colorSeed: ColorSeed.cyan,
    );
  }

  static RemixDuelLens buildRemixDuelLens({
    required String leftPrompt,
    required String rightPrompt,
    required int votesLeft,
    required int votesRight,
  }) {
    final total = votesLeft + votesRight;
    final state = total == 0
        ? 'Ilk oyu bekliyor'
        : votesLeft == votesRight
            ? 'Denge kirilmadi'
            : votesLeft > votesRight
                ? 'Sol varyasyon onde'
                : 'Sag varyasyon onde';
    return RemixDuelLens(
      title: 'Remix Duel • $state',
      summary:
          '"${_trimForLabel(leftPrompt)}" ile "${_trimForLabel(rightPrompt)}" toplulukta ayni dikkat alanini paylasiyor.',
    );
  }

  static NotificationAfterimage buildAfterimage(
    AppNotificationModel item, {
    Map<String, dynamic>? postData,
  }) {
    switch (item.type) {
      case 'follow':
        return NotificationAfterimage(
          title: 'Sosyal cekim alani',
          summary:
              '@${item.fromUsername} profilinin etrafinda yeni bir merak halkasi olustu.',
          colorSeed: ColorSeed.cyan,
        );
      case 'message':
        return const NotificationAfterimage(
          title: 'Konusma izi',
          summary:
              'Bu mesaj, anlik sohbetten uzun sureli bir bag eksenine kayabilir.',
          colorSeed: ColorSeed.purple,
        );
      case 'comment':
        final prompt = (postData?['prompt'] ?? '').toString();
        return NotificationAfterimage(
          title: 'Yankili yorum',
          summary: prompt.isEmpty
              ? 'Yorum, icerigin etrafinda ikinci bir anlam katmani aciyor.'
              : 'Yorum, "$prompt" fikrini yeni bir yonde yankiliyor.',
          colorSeed: ColorSeed.amber,
        );
      case 'like':
        final likes = (postData?['likesCount'] ?? 0) as int;
        return NotificationAfterimage(
          title: 'Mikro momentum',
          summary: likes > 3
              ? 'Bu begeni tekil degil, icerigin etrafinda hizlanan bir alanin parcasi.'
              : 'Kucuk gorunen bu temas, algoritmik gorunurlukte zincir etkisi yaratabilir.',
          colorSeed: ColorSeed.green,
        );
      default:
        return const NotificationAfterimage(
          title: 'Etki izi',
          summary: 'Bu olay, profilinde kucuk ama kalici bir iz birakti.',
          colorSeed: ColorSeed.pink,
        );
    }
  }

  static ImpossibleRemixPlan buildImpossibleRemix({
    required String sourceA,
    required String sourceB,
  }) {
    final cleanA = sourceA.trim();
    final cleanB = sourceB.trim();
    final merged = [cleanA, cleanB].where((item) => item.isNotEmpty).join(', ');
    final counts = _buildSignalCounts([
      {
        'prompt': merged,
        'hashtags': <String>[],
      }
    ]);
    final rankedSignals = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
    final primary = rankedSignals.isNotEmpty ? rankedSignals.first : 'dream';
    final secondary = rankedSignals.length > 1 ? rankedSignals[1] : 'chaos';

    return ImpossibleRemixPlan(
      title: '${_capitalize(primary)} x ${_capitalize(secondary)} Remix',
      bridgeLine:
          'Birbirine ait olmayan iki evren zorla ayni kadraja cekildi: ${cleanA.isEmpty ? 'Kaynak A' : cleanA} ile ${cleanB.isEmpty ? 'Kaynak B' : cleanB}.',
      remixPrompt:
          '$merged, impossible fusion, paradox aesthetic, hybrid universe, cinematic collision, impossible remix, detailed, dramatic lighting, surreal coherence, social media breaking concept',
      tags: [primary, secondary, 'impossible', 'remix'],
    );
  }

  static SerendipityJumpPlan buildSerendipityJump(
    List<Map<String, dynamic>> posts, {
    required int seed,
    String query = '',
    String category = 'Tumu',
    String? selectedHashtag,
  }) {
    final random = Random(seed);
    final counts = _buildSignalCounts(posts);
    final rankedSignals = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    final first = rankedSignals.isNotEmpty
        ? rankedSignals[random.nextInt(min(3, rankedSignals.length))]
        : 'dream';
    final secondPool = rankedSignals.where((item) => item != first).toList();
    final second = secondPool.isNotEmpty
        ? secondPool[random.nextInt(min(4, secondPool.length))]
        : 'chaos';

    final hashtagCounts = <String, int>{};
    for (final post in posts) {
      for (final tag
          in List<String>.from(post['hashtags'] ?? const <String>[])) {
        hashtagCounts[tag] = (hashtagCounts[tag] ?? 0) + 1;
      }
    }

    final rankedTags = hashtagCounts.keys.toList()
      ..sort(
          (a, b) => (hashtagCounts[b] ?? 0).compareTo(hashtagCounts[a] ?? 0));

    final chosenTags = <String>{
      if (selectedHashtag != null && selectedHashtag.isNotEmpty)
        selectedHashtag,
      if (rankedTags.isNotEmpty)
        rankedTags[random.nextInt(min(4, rankedTags.length))],
      if (rankedTags.length > 1)
        rankedTags[random.nextInt(min(6, rankedTags.length))],
    }.toList();

    final titleTemplates = [
      'Serendipity Jump',
      'Kuantum Kesisim',
      'Beklenmedik Vibe',
      'Paralel Kesif',
    ];

    final cleanCategory = category == 'Tümü' ? 'Acik Evren' : category;
    final cleanQuery = query.trim().isEmpty ? null : query.trim();

    return SerendipityJumpPlan(
      title: titleTemplates[random.nextInt(titleTemplates.length)],
      summary:
          '${_capitalize(first)} ile ${_capitalize(second)} ayni akista carpistirildi. ${cleanQuery == null ? 'Beklenmedik bir kesif koridoru acildi.' : 'Araman "$cleanQuery" etrafinda yeni bir kesisim acildi.'}',
      categoryLabel: cleanCategory,
      signalWords: [first, second],
      hashtags: chosenTags,
    );
  }

  static VibeDnaReport buildVibeDna(
    List<Map<String, dynamic>> posts, {
    String username = '',
  }) {
    final signalCounts = _buildSignalCounts(posts);
    final rankedSignals = signalCounts.keys.toList()
      ..sort((a, b) => (signalCounts[b] ?? 0).compareTo(signalCounts[a] ?? 0));

    final primary = rankedSignals.isNotEmpty ? rankedSignals.first : 'dream';
    final secondary = rankedSignals.length > 1 ? rankedSignals[1] : 'cinematic';
    final tertiary = rankedSignals.length > 2 ? rankedSignals[2] : 'neon';

    final uniqueTags = <String>{};
    for (final post in posts) {
      uniqueTags
          .addAll(List<String>.from(post['hashtags'] ?? const <String>[]));
    }

    final rarityScore =
        min(96, 35 + uniqueTags.length * 5 + rankedSignals.length * 6);
    final contrastScore = min(
      94,
      28 +
          (signalCounts[secondary] ?? 0) * 8 +
          _contrastBonus(primary, secondary),
    );

    final codename = '${_capitalize(primary)} ${_capitalize(secondary)} Weaver';
    final handle = username.isEmpty ? 'Bu profil' : '@$username';

    return VibeDnaReport(
      codename: codename,
      mirrorLine:
          '$handle, ${primary == secondary ? _capitalize(primary) : '${_capitalize(primary)} ile ${_capitalize(secondary)}'} ekseninde kendine ozgu bir icerik imzasi olusturuyor.',
      anomalyLabel:
          '${_capitalize(primary)} x ${_capitalize(secondary)} anomalisi',
      rarityScore: rarityScore,
      contrastScore: contrastScore,
      dominantSignals: [primary, secondary, tertiary],
      paletteLabels: [
        _paletteBySignal[primary] ?? 'Cyan Flux',
        _paletteBySignal[secondary] ?? 'Moon Lilac',
        _paletteBySignal[tertiary] ?? 'Deep Void',
      ],
      sampleCount: posts.length,
    );
  }

  static Map<String, int> _buildSignalCounts(List<Map<String, dynamic>> posts) {
    final counts = <String, int>{};
    for (final post in posts) {
      final tokens = _extractTokens(post);
      for (final entry in _signalLexicon.entries) {
        final hits = entry.value.where(tokens.contains).length;
        if (hits > 0) {
          counts[entry.key] = (counts[entry.key] ?? 0) + hits;
        }
      }
    }
    return counts;
  }

  static Set<String> _extractTokens(Map<String, dynamic> post) {
    final prompt = (post['prompt'] ?? '').toString().toLowerCase();
    final hashtags = List<String>.from(post['hashtags'] ?? const <String>[])
        .map((item) => item.toLowerCase());
    final words = prompt
        .split(RegExp(r'[^a-z0-9]+'))
        .where((item) => item.trim().length >= 3)
        .toSet();
    return {...words, ...hashtags};
  }

  static int _contrastBonus(String a, String b) {
    const opposites = {
      'dream:chaos',
      'organic:architect',
      'ritual:neon',
      'playful:cinematic',
      'cosmic:organic',
    };
    final pairA = '$a:$b';
    final pairB = '$b:$a';
    return opposites.contains(pairA) || opposites.contains(pairB) ? 24 : 12;
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static String _trimForLabel(String value) {
    if (value.length <= 28) return value;
    return '${value.substring(0, 28)}...';
  }

  static (String, String) _buildDailyReality(String primary, String secondary) {
    final now = DateTime.now().toUtc();
    final daySeed = now.difference(DateTime(now.year)).inDays;
    final modes = [
      'Alt Timeline',
      'Mirror Loop',
      'Future Echo',
      'Soft Rupture',
      'Orbit Shift',
    ];
    final mode = modes[daySeed % modes.length];
    return (
      mode,
      '$mode bugun ${_capitalize(primary)} ve ${_capitalize(secondary)} sinyallerini one cekiyor; ayni zevkin daha yabanci bir varyasyonunu gosteriyor.',
    );
  }
}
