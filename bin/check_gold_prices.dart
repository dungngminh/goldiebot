import 'dart:io';

import 'package:goldiebot/src/config/app_config.dart';
import 'package:goldiebot/src/model/gold_snapshot.dart';
import 'package:goldiebot/src/parse/price_parser.dart';
import 'package:goldiebot/src/scraper/kimkhanhviethung_scraper.dart';
import 'package:goldiebot/src/storage/snapshot_store.dart';
import 'package:goldiebot/src/telegram/telegram_client.dart';

Future<void> main(List<String> arguments) async {
  final configPath =
      _getArgValue(arguments, '--config-path') ?? 'config/goldbot.json';
  final snapshotPath =
      _getArgValue(arguments, '--snapshot-path') ?? 'data/last_snapshot.json';

  final config = await AppConfig.load(configPath);
  final store = SnapshotStore(snapshotPath);
  final oldSnapshot = await store.read();
  final nowUtc = DateTime.now().toUtc();

  // if (oldSnapshot != null) {
  //   final interval = Duration(hours: config.intervalHours);
  //   // Cron thường lệch vài phút do thời gian khởi động runner.
  //   // Thêm slack nhỏ để tránh skip nhầm.
  //   final slack = const Duration(minutes: 1);
  //   if (nowUtc.difference(oldSnapshot.checkedAtUtc) + slack < interval) {
  //     stdout.writeln(
  //       'Skip: intervalHours=${config.intervalHours}, lastCheckedAtUtc=${oldSnapshot.checkedAtUtc.toIso8601String()}',
  //     );
  //     return;
  //   }
  // }

  final scraper = KimKhanhVietHungScraper(config.sourceUrl);
  final rates = await scraper.fetchGoldRates();

  // Chỉ quan tâm “Vàng 9999” (thực tế lấy từ dòng “Vàng 999.9”).
  final changedGold9999 = oldSnapshot == null
      ? true
      : (rates.gold9999.buy != oldSnapshot.rates.gold9999.buy ||
            rates.gold9999.sell != oldSnapshot.rates.gold9999.sell);

  final newSnapshot = GoldSnapshot(
    checkedAtUtc: nowUtc,
    sourceUrl: config.sourceUrl.toString(),
    rates: rates,
  );

  await store.write(newSnapshot);

  final shouldNotify =
      changedGold9999 &&
      (oldSnapshot != null || config.notifyOnFirstRun == true);

  if (!shouldNotify) {
    stdout.writeln(
      changedGold9999
          ? 'First run baseline created. notifyOnFirstRun=false so no Telegram.'
          : 'No price change; Telegram not sent.',
    );
    return;
  }

  final botToken = Platform.environment['TELEGRAM_BOT_TOKEN'] ?? '';
  final chatId = Platform.environment['TELEGRAM_CHAT_ID'] ?? '';
  if (botToken.isEmpty || chatId.isEmpty) {
    stdout.writeln('TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID not set. Skip send.');
    return;
  }

  final text = _buildMessage(
    newSnapshot: newSnapshot,
    oldSnapshot: oldSnapshot,
    changed: changedGold9999,
  );

  await TelegramClient().sendMessage(
    botToken: botToken,
    chatId: chatId,
    text: text,
  );
}

String? _getArgValue(List<String> args, String key) {
  final index = args.indexOf(key);
  if (index == -1) return null;
  if (index + 1 >= args.length) return null;
  return args[index + 1];
}

String _buildMessage({
  required GoldSnapshot newSnapshot,
  GoldSnapshot? oldSnapshot,
  required bool changed,
}) {
  final current = newSnapshot.rates.gold9999;
  final previous = oldSnapshot?.rates.gold9999;

  String arrowForDelta(int delta) {
    if (delta > 0) return '🔺';
    if (delta < 0) return '🔻';
    return '➖';
  }

  String prettyUtc(DateTime dt) {
    final utc = dt.toUtc();
    const weekdays = [
      'Chủ nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
    ];
    final weekday = weekdays[utc.weekday % 7]; // Dart: 1(Mon)..7(Sun)

    String two(int n) => n.toString().padLeft(2, '0');
    final dd = two(utc.day);
    final mm = two(utc.month);
    final yyyy = utc.year.toString();
    final hh = two(utc.hour);
    final minute = two(utc.minute);
    final ss = two(utc.second);

    return '$weekday, $dd/$mm/$yyyy $hh:$minute:$ss UTC';
  }

  final status = previous == null
      ? '🆕 Tạo mốc'
      : (changed ? '🚨 Thay đổi' : '✅ Không đổi');

  final lines = <String>[
    '🪙 Giá Vàng 9999',
    '📌 $status',
    '⏰ ${prettyUtc(newSnapshot.checkedAtUtc)}',
    '🔗 Nguồn: ${newSnapshot.sourceUrl}',
    '',
  ];

  if (previous == null) {
    lines.addAll([
      '🟢 Mua vào: ${formatVnd(current.buy)}đ',
      '🟠 Bán ra: ${formatVnd(current.sell)}đ',
    ]);
  } else {
    final deltaBuy = current.buy - previous.buy;
    final deltaSell = current.sell - previous.sell;

    lines.addAll([
      '🟢 Mua vào: ${formatVnd(previous.buy)}đ \n→ ${formatVnd(current.buy)}đ(${arrowForDelta(deltaBuy)} ${signedDelta(deltaBuy)})',
      '🟠 Bán ra: ${formatVnd(previous.sell)}đ \n→ ${formatVnd(current.sell)}đ(${arrowForDelta(deltaSell)} ${signedDelta(deltaSell)})',
    ]);
  }

  return lines.join('\n');
}
