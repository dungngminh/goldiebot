import 'dart:io';

import 'package:goldiebot/src/config/app_config.dart';
import 'package:goldiebot/src/model/gold_snapshot.dart';
import 'package:goldiebot/src/parse/price_parser.dart';
import 'package:goldiebot/src/scraper/kimkhanhviethung_scraper.dart';
import 'package:goldiebot/src/storage/snapshot_store.dart';
import 'package:goldiebot/src/storage/subscriber_store.dart';
import 'package:goldiebot/src/storage/telegram_offset_store.dart';
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

  final botToken = Platform.environment['TELEGRAM_BOT_TOKEN'] ?? '';
  final telegramClient = TelegramClient();

  final subscriberStore = SubscriberStore('data/subscribers.json');
  final offsetStore = TelegramOffsetStore('data/telegram_offset.json');

  var subscribers = <int>{};
  if (botToken.isNotEmpty) {
    subscribers = await subscriberStore.read();

    // Nếu danh sách rỗng thì seed bằng `TELEGRAM_CHAT_ID` (tuỳ chọn).
    final envChatIdRaw = Platform.environment['TELEGRAM_CHAT_ID'];
    if (subscribers.isEmpty &&
        envChatIdRaw != null &&
        envChatIdRaw.trim().isNotEmpty) {
      subscribers = {int.parse(envChatIdRaw.trim())};
    }

    // Xử lý lệnh subscribe/unsubscribe mỗi lần job chạy.
    final offset = await offsetStore.read();
    final updates = await telegramClient.getUpdates(
      botToken: botToken,
      offset: offset,
      limit: 50,
    );

    if (updates.isNotEmpty) {
      var maxUpdateId = updates
          .map((u) => u.updateId)
          .reduce((a, b) => a > b ? a : b);
      var subscribersChanged = false;

      for (final update in updates) {
        final text = update.text?.trim() ?? '';
        if (text.isEmpty) continue;

        // Cho phép command dạng: /subscribe@TenBot
        final normalized = text.split('@').first.toLowerCase();
        final chatIdStr = update.chatId.toString();

        if (normalized == '/subscribe') {
          if (subscribers.add(update.chatId)) {
            subscribersChanged = true;
          }
          await telegramClient.sendMessage(
            botToken: botToken,
            chatId: chatIdStr,
            text:
                '✅ Đã subscribe giá vàng 9999. Khi có thay đổi, bot sẽ thông báo bạn.',
          );
        } else if (normalized == '/unsubscribe') {
          if (subscribers.remove(update.chatId)) {
            subscribersChanged = true;
          }
          await telegramClient.sendMessage(
            botToken: botToken,
            chatId: chatIdStr,
            text: '🛑 Đã unsubscribe. Bạn sẽ không nhận thông báo giá nữa.',
          );
        } else if (normalized == '/start' || normalized == '/help') {
          await telegramClient.sendMessage(
            botToken: botToken,
            chatId: chatIdStr,
            text: [
              '🪙 Bot báo giá vàng 9999',
              'Các lệnh:',
              '• /subscribe',
              '• /unsubscribe',
            ].join('\n'),
          );
        }

        // Dù là lệnh gì, ta vẫn tiến offset qua updateId ở cuối vòng.
        // (Không cần xử lý thêm logic phức tạp ở đây.)
        if (update.updateId > maxUpdateId) {
          maxUpdateId = update.updateId;
        }
      }

      if (subscribersChanged) {
        await subscriberStore.write(subscribers);
      }
      // Telegram yêu cầu offset = update_id + 1.
      await offsetStore.write(maxUpdateId + 1);
    }
  }

  // Crawl giá và so sánh thay đổi “Vàng 9999”.
  final scraper = KimKhanhVietHungScraper(config.sourceUrl);
  final rates = await scraper.fetchGoldRates();

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
      botToken.isNotEmpty &&
      subscribers.isNotEmpty &&
      changedGold9999 &&
      (oldSnapshot != null || config.notifyOnFirstRun == true);

  if (!shouldNotify) {
    stdout.writeln(
      changedGold9999
          ? 'First run baseline/notify not enabled or no subscribers; Telegram not sent.'
          : 'No price change; Telegram not sent.',
    );
    return;
  }

  final text = _buildMessage(
    newSnapshot: newSnapshot,
    oldSnapshot: oldSnapshot,
    changed: changedGold9999,
  );

  final targets = subscribers.toList()..sort();
  for (final chatId in targets) {
    await telegramClient.sendMessage(
      botToken: botToken,
      chatId: chatId.toString(),
      text: text,
    );
  }
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
