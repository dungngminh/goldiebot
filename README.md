# Vibe GoldieBot [@VangKimKhanh_bot](https://t.me/VangKimKhanh_bot)

## Latest Snapshot (Vàng 9999) 🪙

<!--SNAPSHOT_DETAILS_START-->
Last checked (UTC): Thứ Tư, 22/04/2026 15:31:53 UTC ⏰
- **Buy:** 15.660.000đ 🟢
- **Sell:** 15.850.000đ 🟠
- **Source:** https://kimkhanhviethung.vn/tra-cuu-gia-vang.html 🔗
<!--SNAPSHOT_DETAILS_END-->

## Configuration

- `config/goldbot.json`
  - `sourceUrl`: gold price page to crawl
  - `intervalHours`: minimum interval between checks (the script may skip if it runs too soon)
  - `notifyOnFirstRun`: if `true`, send Telegram on the very first run as well

## Telegram secrets (GitHub Actions)

- `TELEGRAM_BOT_TOKEN`

## Subscribe via Telegram

The bot processes commands on each scheduled cron run and stores the subscriber list in `data/subscribers.json`.

Commands:

- `/subscribe`: add your chat to the notification list
- `/unsubscribe`: remove your chat from the notification list
- `/start` or `/help`: show help

## Entry point

- `bin/check_gold_prices.dart`
