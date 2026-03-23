import 'dart:convert';
import 'dart:io';

import '../model/gold_snapshot.dart';

class SnapshotStore {
  final String snapshotPath;

  SnapshotStore(this.snapshotPath);

  Future<GoldSnapshot?> read() async {
    final file = File(snapshotPath);
    if (!await file.exists()) return null;

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return null;

    final json = jsonDecode(raw) as Map<String, dynamic>;
    return GoldSnapshot.fromJson(json);
  }

  Future<void> write(GoldSnapshot snapshot) async {
    final file = File(snapshotPath);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    await file.writeAsString(snapshot.toPrettyJson(), flush: true);
  }
}

