import 'package:cloud_firestore/cloud_firestore.dart';

class IdentityLens {
  final String title;
  final String subtitle;
  final String contributionValue;
  final String interfaceHint;
  final String biasShield;

  const IdentityLens({
    required this.title,
    required this.subtitle,
    required this.contributionValue,
    required this.interfaceHint,
    required this.biasShield,
  });
}

class LiquidIdentitySnapshot {
  final String headline;
  final String description;
  final String zeroBiasMode;
  final List<IdentityLens> lenses;

  const LiquidIdentitySnapshot({
    required this.headline,
    required this.description,
    required this.zeroBiasMode,
    required this.lenses,
  });
}

class SynapseRoleProfile {
  final String title;
  final String contributionLabel;
  final String collaborationHint;

  const SynapseRoleProfile({
    required this.title,
    required this.contributionLabel,
    required this.collaborationHint,
  });
}

class LiquidIdentityService {
  static final _db = FirebaseFirestore.instance;

  static Future<LiquidIdentitySnapshot> buildSnapshot(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    final posts = await _db
        .collection('posts')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(18)
        .get();

    final points = (userData['points'] ?? 0) as int;
    final archetype =
        (userData['archetype'] ?? 'Creative & Analytical') as String;
    final followingCount = (userData['followingCount'] ?? 0) as int;
    final twin = userData['aiTwin'] as Map<String, dynamic>?;
    final passiveMode = (twin?['passiveMode'] ?? false) as bool;

    final prompts = posts.docs
        .map((doc) => (doc.data()['prompt'] ?? '') as String)
        .where((text) => text.trim().isNotEmpty)
        .toList();

    final combined = prompts.join(' ').toLowerCase();
    final lenses = <IdentityLens>[
      IdentityLens(
        title: _buildAcademicTitle(combined, points),
        subtitle:
            'Bilgi yoğun alanlarda katkın öne çıkıyor. Sistem seni uzmanlık sinyalinle gösteriyor.',
        contributionValue: 'Katkı Değeri ${_score(points, 28)}',
        interfaceHint:
            'İsim ve statü geri plana alınır; argüman kalitesi ve kaynak disiplini öne çıkar.',
        biasShield:
            'Sıfır Önyargı: sosyal statü gizli, bağlamsal yetkinlik görünür.',
      ),
      IdentityLens(
        title: _buildCreativeTitle(combined),
        subtitle:
            'Yaratıcı ve duygusal alanlarda tonun daha görünür hale gelir; mizah ve estetik izi korunur.',
        contributionValue:
            'Kolektif Etki ${_score(prompts.length * 9 + followingCount, 18)}',
        interfaceHint:
            'Görsel ritim, kelime sıcaklığı ve ortak üretime açıklık üzerinden eşleşme yapılır.',
        biasShield:
            'Bağlam odaklı görünüm: görünüş değil, üretim biçimi okunur.',
      ),
      IdentityLens(
        title:
            passiveMode ? 'Otonom Katkı Temsilcisi' : 'Canlı Diyalog Operatörü',
        subtitle: passiveMode
            ? 'AI ikizin düşük sürtünmeli yardım akışlarında seni temsil etmeye hazır.'
            : 'Sistem seni anlık diyalog ve ortak çözüm odalarında aktif yüz olarak konumlandırıyor.',
        contributionValue:
            'Synapse Uyum ${_score(followingCount * 7 + points, 24)}',
        interfaceHint:
            'Topluluk odalarında rol kartın probleme göre dinamik biçimde yeniden yazılır.',
        biasShield: 'Sosyal etiketler yerine rol-temelli görünürlük aktif.',
      ),
    ];

    return LiquidIdentitySnapshot(
      headline:
          '${archetype.split('&').first.trim()} kimliği şu an akışta baskın',
      description:
          'Kimliğin sabit değil; girdiğin bağlama göre uzman, yaratıcı veya köprü kurucu rolüne evriliyor.',
      zeroBiasMode:
          'Zero Bias modu, fiziksel/sosyal statü sinyallerini bastırıp sadece katkı değerini vurgular.',
      lenses: lenses,
    );
  }

  static String _buildAcademicTitle(String combined, int points) {
    if (combined.contains('ai') ||
        combined.contains('zeka') ||
        combined.contains('bilim')) {
      return points > 500 ? 'Akademik Stratejist' : 'Araştırma Meraklısı';
    }
    return points > 500 ? 'Alan Uzmanı' : 'Bağlamsal Öğrenen';
  }

  static String _buildCreativeTitle(String combined) {
    if (combined.contains('tasarım') ||
        combined.contains('esthetic') ||
        combined.contains('retro')) {
      return 'Mizahşör Tasarımcı';
    }
    if (combined.contains('duygu') || combined.contains('dream')) {
      return 'Duygu Küratörü';
    }
    return 'Hibrit Anlatıcı';
  }

  static int _score(int seed, int base) {
    return (base + (seed % 73)).clamp(1, 100);
  }

  static Future<SynapseRoleProfile> buildSynapseRole({
    required String uid,
    required String topic,
  }) async {
    final snapshot = await buildSnapshot(uid);
    final combined =
        '${snapshot.headline} ${snapshot.description}'.toLowerCase();
    final normalizedTopic = topic.toLowerCase();

    String title;
    String hint;

    if (normalizedTopic.contains('zeka') || normalizedTopic.contains('ai')) {
      title = combined.contains('stratejist')
          ? 'Araştırma Stratejisti'
          : 'Model Çevirmeni';
      hint =
          'Teknik karmaşıklığı insan diline çevir ve kararın etik sınırını belirt.';
    } else if (normalizedTopic.contains('tasarım')) {
      title = combined.contains('yaratıcı')
          ? 'Estetik Küratör'
          : 'Görsel Sistem Kurucu';
      hint =
          'Önce hissi tanımla, sonra biçim ve kullanılabilirlik dengesi kur.';
    } else if (normalizedTopic.contains('girişim')) {
      title = 'Uzlaşı Mimarı';
      hint =
          'Büyüme ve etik riskleri aynı kartta düşün; ilk deneyin maliyetini kısalt.';
    } else {
      title = 'İyileşme Operatörü';
      hint = 'İnsan ritmini ve sürdürülebilirliği ilk sinyal olarak öne çıkar.';
    }

    final roleScore =
        _score(topic.length * 11 + snapshot.lenses.length * 13, 31);
    return SynapseRoleProfile(
      title: title,
      contributionLabel: 'Katkı Değeri $roleScore',
      collaborationHint: hint,
    );
  }
}
