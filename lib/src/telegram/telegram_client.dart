import 'dart:convert';
import 'dart:io';

class TelegramClient {
  Future<void> sendMessage({
    required String botToken,
    required String chatId,
    required String text,
  }) async {
    final uri = Uri.https(
      'api.telegram.org',
      '/bot$botToken/sendMessage',
      {
        'chat_id': chatId,
        'text': text,
      },
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'goldiebot/1.0');
      final response = await request.close();
      final raw = await response.transform(const Utf8Decoder()).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Telegram request failed: ${response.statusCode} ${response.reasonPhrase}. Body=$raw',
        );
      }

      // Telegram trả về JSON {ok: bool, result: ...}
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final ok = json['ok'] == true;
      if (!ok) {
        throw StateError('Telegram API error: $raw');
      }
    } finally {
      client.close(force: true);
    }
  }
}

