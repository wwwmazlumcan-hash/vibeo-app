import 'package:cloud_firestore/cloud_firestore.dart';

import 'openai_text_service.dart';

class MorningAction {
  final String title;
  final String detail;

  const MorningAction({
    required this.title,
    required this.detail,
  });
}

class MorningPulseReport {
  final String dreamTitle;
  final String dreamNarrative;
  final String collectiveMood;
  final int overnightHelps;
  final int collectiveWisdomPoints;
  final String recommendation;
  final List<MorningAction> actions;
  final bool canClaimReward;
  final String rewardDate;

  const MorningPulseReport({
    required this.dreamTitle,
    required this.dreamNarrative,
    required this.collectiveMood,
    required this.overnightHelps,
    required this.collectiveWisdomPoints,
    required this.recommendation,
    required this.actions,
    required this.canClaimReward,
    required this.rewardDate,
  });
}

class PassiveContributionService {
  static final _db = FirebaseFirestore.instance;

  static Future<MorningPulseReport> buildMorningPulse(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final user = userDoc.data() ?? <String, dynamic>{};
    final twin = user['aiTwin'] as Map<String, dynamic>?;
    final passiveMode = (twin?['passiveMode'] ?? false) as bool;
    final points = (user['points'] ?? 0) as int;
    final archetype = (user['archetype'] ?? 'Creative & Analytical') as String;

    final posts = await _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(18)
        .get();

    final prompts = posts.docs
        .map((doc) => (doc.data()['prompt'] ?? '') as String)
        .where((text) => text.trim().isNotEmpty)
        .take(10)
        .toList();

    final collectiveMood = _collectiveMood(prompts);
    final overnightHelps = passiveMode ? 2 + (points % 3) : 0;
    final wisdomPoints = passiveMode ? 24 + (points % 41) : 8 + (points % 12);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final canClaimReward = (user['lastDreamNetClaimDate'] ?? '') != today;

    final dreamNarrative = await _buildDreamNarrative(prompts, collectiveMood);

    return MorningPulseReport(
      dreamTitle:
          passiveMode ? 'Dream Net Sabah Özeti' : 'Potansiyel Dream Net Özeti',
      dreamNarrative: dreamNarrative,
      collectiveMood: collectiveMood,
      overnightHelps: overnightHelps,
      collectiveWisdomPoints: wisdomPoints,
      recommendation: passiveMode
          ? 'AI ikizin gece modunda topluluk akışına katkı sundu. Sabah kontrolünde sadece onay veya red bekleniyor.'
          : 'Pasif katkı modu kapalı. Açarsan AI ikizin uyurken düşük riskli yardım akışlarında seni temsil edebilir.',
      actions: [
        MorningAction(
          title: 'Topluluk Projesi',
          detail:
              '$archetype perspektifinle bir Synapse odasında çözüm önerisi taslağı çıkarıldı.',
        ),
        MorningAction(
          title: 'Uyurken Yardım',
          detail: passiveMode
              ? 'Bilgi alanına yakın 3 kullanıcıya taslak yanıt hattı hazırlandı.'
              : 'Pasif mod açılırsa sistem senin uzmanlığına yakın yardım isteklerini filtreler.',
        ),
        MorningAction(
          title: 'Kolektif Rüya',
          detail:
              'Bu sabah ağın duygusu "$collectiveMood" ekseninde sanatlaştırılmış bir özet olarak üretildi.',
        ),
      ],
      canClaimReward: canClaimReward,
      rewardDate: today,
    );
  }

  static Future<void> claimMorningReward(String uid) async {
    final report = await buildMorningPulse(uid);
    if (!report.canClaimReward) return;

    final userRef = _db.collection('users').doc(uid);
    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final data = userSnap.data() ?? <String, dynamic>{};
      final alreadyClaimed =
          (data['lastDreamNetClaimDate'] ?? '') == report.rewardDate;
      if (alreadyClaimed) return;

      final proofAi = (data['proofAiDreamNet'] ?? 0) as int;
      final wisdomTotal = (data['collectiveWisdomPoints'] ?? 0) as int;

      transaction.set(
          userRef,
          {
            'points': FieldValue.increment(report.collectiveWisdomPoints),
            'collectiveWisdomPoints':
                wisdomTotal + report.collectiveWisdomPoints,
            'proofAiDreamNet': proofAi + report.collectiveWisdomPoints,
            'dreamNetHelpCount': FieldValue.increment(report.overnightHelps),
            'lastDreamNetClaimDate': report.rewardDate,
            'pointsHistory': FieldValue.arrayUnion([
              {
                'amount': report.collectiveWisdomPoints,
                'reason': 'Dream Net sabah katkisi',
                'at': DateTime.now().toIso8601String(),
              }
            ]),
          },
          SetOptions(merge: true));
    });
  }

  static String _collectiveMood(List<String> prompts) {
    final combined = prompts.join(' ').toLowerCase();
    if (combined.contains('sağlık') || combined.contains('wellbeing')) {
      return 'iyileşme ve denge';
    }
    if (combined.contains('ai') || combined.contains('zeka')) {
      return 'merak ve hız';
    }
    if (combined.contains('tasarım') || combined.contains('dream')) {
      return 'yaratıcılık ve akış';
    }
    return 'temkinli umut';
  }

  static Future<String> _buildDreamNarrative(
    List<String> prompts,
    String mood,
  ) async {
    if (prompts.isEmpty) {
      return 'Gece ağı sakin geçti. Düşük gürültülü veri akışı, sabaha yumuşak bir başlangıç duygusu taşıdı.';
    }

    final aiPrompt = '''
Son 10 içerik sinyalini kullanarak insanlığın sabah ruh halini anlatan kısa, şiirsel ama anlaşılır bir Türkçe paragraf üret.
Mood: $mood
Sinyaller:
${prompts.map((prompt) => '- $prompt').join('\n')}
''';

    try {
      final result = await OpenAiTextService.generate(
        prompt: aiPrompt,
        temperature: 0.9,
        maxTokens: 180,
        fallback: '',
      );
      if (result.trim().isNotEmpty) {
        return result.trim();
      }
    } catch (_) {}

    return 'Bu sabah ağ, $mood hissiyle uyandı. Gece boyunca biriken kısa fikir parçaları, ortak ritmi bozmadan tek bir yumuşak frekansta birleşti.';
  }
}
