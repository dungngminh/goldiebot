import 'dart:convert';
import 'dart:io';

class TelegramUpdate {
  final int updateId;
  final int chatId;
  final String? text;

  const TelegramUpdate({
    required this.updateId,
    required this.chatId,
    required this.text,
  });
}

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
      final raw = await response.transform(utf8.decoder).join();
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

  Future<List<TelegramUpdate>> getUpdates({
    required String botToken,
    required int offset,
    int limit = 100,
  }) async {
    final uri = Uri.https(
      'api.telegram.org',
      '/bot$botToken/getUpdates',
      {
        'offset': offset.toString(),
        'limit': limit.toString(),
      },
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'goldiebot/1.0');
      final response = await request.close();

      final raw = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Telegram getUpdates failed: ${response.statusCode} ${response.reasonPhrase}. Body=$raw',
        );
      }

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final ok = json['ok'] == true;
      if (!ok) {
        throw StateError('Telegram API error: $raw');
      }

      final result = json['result'];
      if (result is! List) return const [];

      return result
          .whereType<Map<String, dynamic>>()
          .map((e) {
            final updateId = (e['update_id'] as num).toInt();
            final message = e['message'];
            final chat = message is Map<String, dynamic>
                ? message['chat']
                : null;
            final chatId = (chat is Map<String, dynamic> ? chat['id'] : 0)
                as num?;

            return TelegramUpdate(
              updateId: updateId,
              chatId: (chatId ?? 0).toInt(),
              text: message is Map<String, dynamic> ? message['text'] : null,
            );
          })
          // Bỏ các update không có chatId
          .where((u) => u.chatId != 0)
          .toList();
    } finally {
      client.close(force: true);
    }
  }
}

