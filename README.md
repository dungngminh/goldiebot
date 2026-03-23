# Vibe GoldieBot

## Configuration

- `config/goldbot.json`
  - `sourceUrl`: gold price page to crawl
  - `intervalHours`: minimum interval between checks (the script may skip if it runs too soon)
  - `notifyOnFirstRun`: if `true`, send Telegram on the very first run as well

## Telegram secrets (GitHub Actions)

- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`

## Subscribe via Telegram

The bot processes commands on each scheduled cron run and stores the subscriber list in `data/subscribers.json`.

Commands:

- `/subscribe`: add your chat to the notification list
- `/unsubscribe`: remove your chat from the notification list
- `/start` or `/help`: show help

## Entry point

- `bin/check_gold_prices.dart`
