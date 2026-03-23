A tool để tự động crawl giá vàng (mỗi giờ theo GitHub Actions), lưu snapshot và
gửi thông báo Telegram khi có thay đổi.

## Config
- `config/goldbot.json`
  - `sourceUrl`: trang crawl
  - `intervalHours`: khoảng thời gian tối thiểu giữa các lần chạy (script có thể skip nếu chưa đủ thời gian)
  - `notifyOnFirstRun`: nếu `true` thì lần chạy đầu cũng gửi Telegram

## Telegram secrets (GitHub Actions)
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`

## Entry point
- `bin/check_gold_prices.dart`

