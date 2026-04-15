import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'presence_service.dart';

/// AI Digital Twin (İkiz) service.
/// Builds a persona from user data and generates replies when user is offline.
class TwinService {
  /// Fetches a user's twin persona. Returns null if twin is disabled.
  static Future<_Persona?> _loadPersona(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? {};
    final twin = data['aiTwin'] as Map<String, dynamic>?;
    if (twin == null || twin['enabled'] != true) return null;

    return _Persona(
      username: (data['username'] ?? 'kullanıcı') as String,
      bio: (twin['bio'] ?? '') as String,
      interests: List<String>.from(twin['interests'] ?? []),
      tone: (twin['tone'] ?? 'samimi') as String,
    );
  }

  /// Checks recent message history to give context to the twin.
  static Future<List<String>> _recentContext(String chatId,
      {int limit = 5}) async {
    final msgs = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return msgs.docs.reversed
        .map((d) => (d.data()['text'] ?? '') as String)
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Generates a reply if the recipient has twin enabled and is offline.
  /// Returns null if twin is not triggered or fails.
  static Future<String?> maybeReply({
    required String chatId,
    required String recipientUid,
    required String incomingMessage,
  }) async {
    // 1. Check recipient's online status
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(recipientUid)
        .get();
    if (!userDoc.exists) return null;

    final lastActive =
        (userDoc.data()?['lastActive'] as Timestamp?)?.toDate();
    if (!PresenceService.isOffline(lastActive)) return null;

    // 2. Load persona
    final persona = await _loadPersona(recipientUid);
    if (persona == null) return null;

    // 3. Get conversation context
    final context = await _recentContext(chatId);

    // 4. Build prompt
    final prompt = _buildPrompt(persona, incomingMessage, context);

    // 5. Generate reply via Pollinations
    try {
      final encoded = Uri.encodeComponent(prompt);
      final res = await http
          .get(Uri.parse('https://text.pollinations.ai/$encoded'))
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) return null;
      final reply = res.body.trim();
      if (reply.isEmpty) return null;

      // 6. Post reply as the recipient (marked as twin)
      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      await chatRef.collection('messages').add({
        'senderId': recipientUid,
        'text': reply,
        'isAiTwin': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await chatRef.update({
        'lastMessage': '🤖 $reply',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      return reply;
    } catch (_) {
      return null;
    }
  }

  static String _buildPrompt(
      _Persona p, String incoming, List<String> context) {
    final interestsStr =
        p.interests.isEmpty ? 'genel konular' : p.interests.join(', ');

    final contextStr = context.isEmpty
        ? ''
        : '\nSon konuşmalar:\n${context.map((m) => '- $m').join('\n')}\n';

    return '''Sen @${p.username} adlı bir sosyal medya kullanıcısısın.
Şu an çevrimdışısın ama AI İkiz'in senin yerine yanıt veriyor.

KİMLİĞİN:
- Biyografi: ${p.bio.isEmpty ? 'henüz yazmamış' : p.bio}
- İlgi alanları: $interestsStr
- Konuşma tarzı: ${p.tone}
$contextStr
Sana gelen mesaj: "$incoming"

Bu kişi gibi, onun tarzında, Türkçe, KISA (maks. 2 cümle) ve doğal bir yanıt ver.
Cevabın başında "Merhaba" veya "Selam" gibi klişe kullanma, direkt konuşma tarzında yanıt ver.
Sadece yanıtı yaz, başka bir şey ekleme.''';
  }
}

class _Persona {
  final String username;
  final String bio;
  final List<String> interests;
  final String tone;
  _Persona({
    required this.username,
    required this.bio,
    required this.interests,
    required this.tone,
  });
}
