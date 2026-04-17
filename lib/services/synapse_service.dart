import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'liquid_identity_service.dart';
import 'openai_text_service.dart';

class SynapseService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String roomIdForTopic(String topic) {
    return topic
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static DocumentReference<Map<String, dynamic>> roomRef(String topic) {
    return _db.collection('synapse_rooms').doc(roomIdForTopic(topic));
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamRoom(
    String topic,
  ) {
    return roomRef(topic).snapshots();
  }

  static CollectionReference<Map<String, dynamic>> roomMessagesRef(
      String topic) {
    return roomRef(topic).collection('messages');
  }

  static Future<void> ensureRoom(String topic) async {
    await roomRef(topic).set({
      'topic': topic,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamRoomMessages(
    String topic, {
    int limit = 60,
  }) {
    return roomMessagesRef(topic)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots();
  }

  static Future<Map<String, dynamic>> _currentUserMeta() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const {
        'uid': '',
        'username': 'anonim',
        'profilePicUrl': '',
      };
    }

    final userDoc = await _db.collection('users').doc(uid).get();
    final data = userDoc.data() ?? <String, dynamic>{};
    return {
      'uid': uid,
      'username': (data['username'] ?? 'anonim') as String,
      'profilePicUrl': (data['profilePicUrl'] ?? '') as String,
    };
  }

  static Future<void> _touchRoomMetadata({
    required String topic,
    required String memberKey,
    required String senderUsername,
    required String lastMessage,
    String? pinnedSummary,
    String? pinnedSummaryRole,
  }) async {
    final ref = roomRef(topic);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data() ?? <String, dynamic>{};
      final memberKeys = List<String>.from(data['memberKeys'] ?? const []);

      if (memberKey.isNotEmpty && !memberKeys.contains(memberKey)) {
        memberKeys.add(memberKey);
      }

      final update = <String, dynamic>{
        'topic': topic,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivityAt': FieldValue.serverTimestamp(),
        'lastMessage': lastMessage,
        'lastSenderUsername': senderUsername,
        'messageCount': ((data['messageCount'] ?? 0) as int) + 1,
        'memberKeys': memberKeys,
        'participantCount': memberKeys.length,
      };

      if (pinnedSummary != null && pinnedSummary.trim().isNotEmpty) {
        update['pinnedSummary'] = pinnedSummary.trim();
        update['pinnedSummaryRole'] = pinnedSummaryRole ?? 'synthesizer';
        update['pinnedSummaryAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(ref, update, SetOptions(merge: true));
    });
  }

  static Future<void> sendRoomMessage({
    required String topic,
    required String text,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final meta = await _currentUserMeta();
    if ((meta['uid'] as String).isEmpty) return;
    final role = await LiquidIdentityService.buildSynapseRole(
      uid: meta['uid'] as String,
      topic: topic,
    );

    await ensureRoom(topic);
    await roomMessagesRef(topic).add({
      'senderId': meta['uid'],
      'memberKey': meta['uid'],
      'senderUsername': meta['username'],
      'senderProfilePicUrl': meta['profilePicUrl'],
      'memberType': 'human',
      'liquidRoleTitle': role.title,
      'liquidRoleHint': role.collaborationHint,
      'text': clean,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _touchRoomMetadata(
      topic: topic,
      memberKey: meta['uid'] as String,
      senderUsername: meta['username'] as String,
      lastMessage: clean,
    );
  }

  static Future<SynapseRoleProfile?> currentUserRoleForTopic(
      String topic) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return LiquidIdentityService.buildSynapseRole(uid: uid, topic: topic);
  }

  static Future<void> postAiRoomMessage({
    required String topic,
    required String senderLabel,
    required String text,
    required String aiRole,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await ensureRoom(topic);
    await roomMessagesRef(topic).add({
      'senderId': uid,
      'memberKey': 'ai:$aiRole',
      'senderUsername': senderLabel,
      'senderProfilePicUrl': '',
      'memberType': 'ai',
      'aiRole': aiRole,
      'text': clean,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _touchRoomMetadata(
      topic: topic,
      memberKey: 'ai:$aiRole',
      senderUsername: senderLabel,
      lastMessage: clean,
      pinnedSummary: aiRole == 'synthesizer' ? clean : null,
      pinnedSummaryRole: aiRole == 'synthesizer' ? aiRole : null,
    );
  }

  static Future<List<Map<String, dynamic>>> recentTopicPosts(String topic,
      {int limit = 20}) async {
    final snapshot = await _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(60)
        .get();

    final normalized = topic.toLowerCase();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .where((data) {
          final prompt = (data['prompt'] ?? '').toString().toLowerCase();
          final hashtags = List<String>.from(data['hashtags'] ?? const [])
              .map((tag) => tag.toLowerCase())
              .toList();
          return prompt.contains(normalized) || hashtags.contains(normalized);
        })
        .take(limit)
        .toList();
  }

  static Future<List<String>> recentMessages(String chatId,
      {int limit = 16}) async {
    final snapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.reversed
        .map((doc) => (doc.data()['text'] ?? '') as String)
        .where((text) => text.trim().isNotEmpty)
        .toList();
  }

  static Future<List<String>> recentRoomMessages(String topic,
      {int limit = 24}) async {
    final snapshot = await roomMessagesRef(topic)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.reversed
        .map((doc) => (doc.data()['text'] ?? '') as String)
        .where((text) => text.trim().isNotEmpty)
        .toList();
  }

  static Future<String> summarize(String chatId) async {
    final messages = await recentMessages(chatId);
    if (messages.isEmpty) {
      return 'Özet çıkaracak konuşma bulunamadı.';
    }

    final prompt = '''
Aşağıdaki konuşmayı Türkçe ve kısa biçimde özetle.
Çıktı formatı:
1) Kısa özet
2) Üzerinde uzlaşılan 3 ana madde

Konuşma:
${messages.map((m) => '- $m').join('\n')}
''';

    return OpenAiTextService.generate(
      prompt: prompt,
      temperature: 0.5,
      maxTokens: 220,
      fallback: 'Synapse özeti şu anda üretilemedi.',
    );
  }

  static Future<String> moderate(String chatId) async {
    final messages = await recentMessages(chatId);
    if (messages.isEmpty) {
      return 'Moderatör AI için yeterli konuşma yok.';
    }

    final prompt = '''
Tarafsız Moderatör AI rolündesin.
Aşağıdaki konuşmada tansiyon veya mantık hatası varsa nazikçe belirt.
Çıktı formatı:
- Gözlenen genel ton
- Varsa mantık hataları veya yanlış anlaşılma riski
- Ortamı sakinleştirecek 2 somut öneri

Konuşma:
${messages.map((m) => '- $m').join('\n')}
''';

    return OpenAiTextService.generate(
      prompt: prompt,
      temperature: 0.5,
      maxTokens: 220,
      fallback: 'Moderatör AI şu anda öneri üretemedi.',
    );
  }

  static Future<Map<String, dynamic>> buildTopicDashboard(String topic) async {
    await ensureRoom(topic);
    final posts = await recentTopicPosts(topic);
    final roomMessages = await recentRoomMessages(topic);

    if (posts.isEmpty && roomMessages.isEmpty) {
      return {
        'summary':
            '$topic odasında henüz yeterli içerik yok. İlk katkıyı sen yap.',
        'moderation': 'Tartışma sinyali oluşmadı; oda sakin görünüyor.',
        'synthesis': 'Topluluk büyüdükçe uzlaşı başlıkları burada belirecek.',
        'highlights': const <String>[],
      };
    }

    final postLines = posts.map((post) {
      final prompt = (post['prompt'] ?? '') as String;
      return '- $prompt';
    }).toList();
    final roomLines = roomMessages.map((message) => '- $message').toList();
    final lines = [...roomLines, ...postLines].take(16).toList();

    final summary = await _topicPrompt(
      lines: lines,
      instruction:
          'Konuşulan ana fikri ve üzerinde uzlaşılan 3 başlığı Türkçe, kısa ve net üret.',
      fallback: 'Oda özeti şu anda üretilemedi.',
    );

    final moderation = await _topicPrompt(
      lines: lines,
      instruction:
          'Tarafsız moderatör gibi bak. Tansiyon, mantık hatası veya yanlış anlaşılma riskini nazikçe belirt ve 2 öneri ver.',
      fallback: 'Moderatör AI şu anda öneri üretemedi.',
    );

    final synthesis = await _topicPrompt(
      lines: lines,
      instruction:
          'Fikir sentezleyici gibi davran. Bu içeriklerden ortaya çıkan ortak stratejiyi ve sonraki en mantıklı adımı yaz.',
      fallback: 'Sentez çıktısı şu anda üretilemedi.',
    );

    final highlights = posts.take(4).map((post) {
      final label = (post['contentOriginLabel'] ?? 'Karışık üretim') as String;
      final proofHuman = (post['proofHumanScore'] ?? 0) as int;
      final proofAi = (post['proofAiScore'] ?? 0) as int;
      final prompt = (post['prompt'] ?? '') as String;
      return '$label · H:$proofHuman AI:$proofAi · $prompt';
    }).toList();

    if (highlights.length < 4) {
      final roomHighlights = roomMessages.take(4 - highlights.length).map(
            (message) => 'Oda konuşması · $message',
          );
      highlights.addAll(roomHighlights);
    }

    return {
      'summary': summary,
      'moderation': moderation,
      'synthesis': synthesis,
      'highlights': highlights,
    };
  }

  static Future<Map<String, String>> buildMindMeldPlan(String topic) async {
    await ensureRoom(topic);
    final posts = await recentTopicPosts(topic, limit: 12);
    final roomMessages = await recentRoomMessages(topic, limit: 12);

    final lines = <String>[
      ...roomMessages.map((message) => '- $message'),
      ...posts.map((post) => '- ${(post['prompt'] ?? '') as String}'),
    ];

    if (lines.isEmpty) {
      return {
        'problemSolving':
            '$topic için henüz veri yok. Önce problemi netleştir, sonra etik sınırları yaz.',
        'coCreation':
            'İlk katkı olarak fikir, taslak ya da referans bırak. AI üyeler bunu üretim akışına çevirecek.',
        'echoBreaker':
            'Zıt görüşü önce risk diliyle değil, çözmek istediği problem diliyle ifade et.',
      };
    }

    final problemSolving = await _topicPrompt(
      lines: lines,
      instruction:
          'Bu oda için sorun çözme planı üret. Problem tanımı, veri ihtiyacı, etik sınırlar ve ilk 2 deney önerisini Türkçe yaz.',
      fallback:
          'Problem çerçevesi: hedefi küçük parçalara böl, veriyi topla, etik sınırları baştan sabitle.',
    );

    final coCreation = await _topicPrompt(
      lines: lines,
      instruction:
          'İnsan + AI ortak yaratıcılık akışı üret. Kim fikir başlatır, AI neyi hızlandırır, insan neyi onaylar açıkla.',
      fallback:
          'Ortak üretim akışı: insan niyeti başlatır, AI varyasyon üretir, topluluk etik ve kalite filtresi uygular.',
    );

    final echoBreaker = await _topicPrompt(
      lines: lines,
      instruction:
          'Yankı odasını kıracak ama savunmaya itmeyecek karşı görüş özeti yaz. Aynı mantık dilini kullanan nazik bir karşı argüman üret.',
      fallback:
          'Karşı görüş: aynı hedefe farklı araçla gidilebilir; önce ortak zemini adlandırmak gerilimi düşürür.',
    );

    return {
      'problemSolving': problemSolving,
      'coCreation': coCreation,
      'echoBreaker': echoBreaker,
    };
  }

  static Future<String> _topicPrompt({
    required List<String> lines,
    required String instruction,
    required String fallback,
  }) async {
    final prompt = '''
$instruction

İçerikler:
${lines.join('\n')}
''';

    return OpenAiTextService.generate(
      prompt: prompt,
      temperature: 0.6,
      maxTokens: 260,
      fallback: fallback,
    );
  }
}
