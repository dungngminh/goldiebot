import 'package:goldiebot/src/scraper/kimkhanhviethung_scraper.dart';
import 'package:test/test.dart';

void main() {
  test('parse VND price with thousands separators', () {
    final scraper = KimKhanhVietHungScraper(Uri.parse('https://example.com'));
    final price = scraper.parseGold9999FromHtml(
      '<table><tr><td>Vàng 999.9</td><td>15.850.000đ</td><td>16.180.000đ</td><td>0đ</td></tr></table>',
    );

    expect(price.buy, 15850000);
    expect(price.sell, 16180000);
  });

  test('parse VND price with <sup>đ</sup>', () {
    final scraper = KimKhanhVietHungScraper(Uri.parse('https://example.com'));
    final price = scraper.parseGold9999FromHtml(
      '<table><tr><td>Vàng 999.9</td><td>15.900.000<sup>đ</sup></td><td>16.230.000<sup>đ</sup></td><td>0<sup>đ</sup></td></tr></table>',
    );

    expect(price.buy, 15900000);
    expect(price.sell, 16230000);
  });
}

