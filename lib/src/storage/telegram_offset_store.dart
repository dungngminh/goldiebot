import 'dart:convert';
import 'dart:io';

class TelegramOffsetStore {
  final String path;

  const TelegramOffsetStore(this.path);

  Future<int> read() async {
    final file = File(path);
    if (!await file.exists()) return 0;
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return 0;

    final json = jsonDecode(raw);
    if (json is num) return json.toInt();
    if (json is Map<String, dynamic>) {
      final offset = json['offset'];
      if (offset is num) return offset.toInt();
      if (offset is String) return int.parse(offset);
    }
    throw FormatException('Invalid telegram_offset.json format');
  }

  Future<void> write(int offset) async {
    final file = File(path);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    // Lưu dạng số để dễ đọc/debug.
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(offset),
      flush: true,
    );
  }
}

