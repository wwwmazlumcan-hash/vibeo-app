import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_secret.dart';

class OpenAiTextService {
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4.1-mini';

  static Future<String> generate({
    required String prompt,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 300,
    String fallback = 'Şu an yanıt üretilemedi.',
  }) async {
    if (openAiApiKey.trim().isEmpty) {
      return fallback;
    }

    try {
      final messages = <Map<String, String>>[];
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt.trim(),
        });
      }
      messages.add({
        'role': 'user',
        'content': prompt.trim(),
      });

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $openAiApiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'temperature': temperature,
              'max_tokens': maxTokens,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return fallback;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = (data['choices'] as List<dynamic>? ?? const []);
      if (choices.isEmpty) return fallback;

      final choice = choices.first as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>?;
      final content = (message?['content'] ?? '') as String;
      final text = content.trim();
      return text.isEmpty ? fallback : text;
    } catch (_) {
      return fallback;
    }
  }
}
