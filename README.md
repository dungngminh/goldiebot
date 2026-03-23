# Vibe GoldieBot

## Latest Snapshot (Vàng 9999) 🪙

<!--SNAPSHOT_DETAILS_START-->
Last checked (UTC): Thứ Hai, 23/03/2026 16:20:05 UTC ⏰
- **Buy:** 15.900.000đ 🟢
- **Sell:** 16.230.000đ 🟠
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
