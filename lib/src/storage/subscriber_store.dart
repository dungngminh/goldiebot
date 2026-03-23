import 'dart:convert';
import 'dart:io';

class SubscriberStore {
  final String path;

  const SubscriberStore(this.path);

  Future<Set<int>> read() async {
    final file = File(path);
    if (!await file.exists()) return <int>{};
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return <int>{};

    final json = jsonDecode(raw);
    if (json is List) {
      return json
          .map((e) => (e is num ? e.toInt() : int.parse(e.toString())))
          .toSet();
    }

    if (json is Map<String, dynamic>) {
      final list = json['chatIds'];
      if (list is List) {
        return list
            .map((e) => (e is num ? e.toInt() : int.parse(e.toString())))
            .toSet();
      }
    }

    throw FormatException('Invalid subscribers.json format');
  }

  Future<void> write(Set<int> chatIds) async {
    final file = File(path);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    final sorted = chatIds.toList()..sort();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(sorted),
      flush: true,
    );
  }
}

