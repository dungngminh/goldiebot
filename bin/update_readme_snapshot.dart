import 'dart:convert';
import 'dart:io';

import 'package:goldiebot/src/model/gold_snapshot.dart';
import 'package:goldiebot/src/parse/price_parser.dart';

String _formatUtcVi(DateTime dtUtc) {
  const weekdays = [
    'Chủ nhật',
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
  ];

  String two(int n) => n.toString().padLeft(2, '0');
  final weekday = weekdays[dtUtc.weekday % 7]; // Dart: 1(Mon)..7(Sun)

  final dd = two(dtUtc.day);
  final mm = two(dtUtc.month);
  final yyyy = dtUtc.year.toString();
  final HH = two(dtUtc.hour);
  final MM = two(dtUtc.minute);
  final ss = two(dtUtc.second);

  return '$weekday, $dd/$mm/$yyyy $HH:$MM:$ss';
}

Future<void> main(List<String> arguments) async {
  final snapshotPath = arguments.contains('--snapshot-path')
      ? (arguments[arguments.indexOf('--snapshot-path') + 1])
      : 'data/last_snapshot.json';

  final readmePath = arguments.contains('--readme-path')
      ? (arguments[arguments.indexOf('--readme-path') + 1])
      : 'README.md';

  final snapshotFile = File(snapshotPath);
  if (!await snapshotFile.exists()) {
    stderr.writeln('Snapshot not found: $snapshotPath');
    return;
  }

  final rawSnapshot = await snapshotFile.readAsString();
  final json = jsonDecode(rawSnapshot) as Map<String, dynamic>;
  final snapshot = GoldSnapshot.fromJson(json);

  final details = [
    'Last checked (UTC): ${_formatUtcVi(snapshot.checkedAtUtc.toUtc())} UTC ⏰',
    'Buy: ${formatVnd(snapshot.rates.gold9999.buy)}đ 🟢',
    'Sell: ${formatVnd(snapshot.rates.gold9999.sell)}đ 🟠',
    'Source: ${snapshot.sourceUrl} 🔗',
  ].join('\n');

  const startMarker = '<!--SNAPSHOT_DETAILS_START-->';
  const endMarker = '<!--SNAPSHOT_DETAILS_END-->';

  final readmeFile = File(readmePath);
  if (!await readmeFile.exists()) {
    stderr.writeln('README not found: $readmePath');
    return;
  }

  final readme = await readmeFile.readAsString();
  final start = readme.indexOf(startMarker);
  final end = readme.indexOf(endMarker);

  if (start == -1 || end == -1 || end <= start) {
    stderr.writeln('Markers not found in README. Skip update.');
    return;
  }

  final updated = readme.replaceRange(
    start + startMarker.length,
    end,
    '\n$details\n',
  );

  if (updated != readme) {
    await readmeFile.writeAsString(updated, flush: true);
    stdout.writeln('README snapshot updated.');
  } else {
    stdout.writeln('README snapshot unchanged.');
  }
}

