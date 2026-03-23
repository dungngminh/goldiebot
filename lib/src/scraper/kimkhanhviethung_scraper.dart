import 'dart:convert';
import 'dart:io';

import '../model/gold_snapshot.dart';
import '../parse/price_parser.dart';

class KimKhanhVietHungScraper {
  final Uri url;

  KimKhanhVietHungScraper(this.url);

  Future<String> fetchHtml() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.userAgentHeader, 'goldiebot/1.0');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Request failed: ${response.statusCode} ${response.reasonPhrase}',
        );
      }

      final contents = await response.transform(utf8.decoder).join();
      return contents;
    } finally {
      client.close(force: true);
    }
  }

  GoldRate parseGold9999FromHtml(String html) {
    // Trang thường có bảng “Vàng 24K” với dòng “Vàng 999.9”.
    final key = RegExp(r'Vàng\s*999\.9', caseSensitive: false);
    final match = key.firstMatch(html);
    if (match == null) {
      throw FormatException('Could not find "Vàng 999.9" in HTML');
    }

    // Chỉ parse trong đúng hàng `<tr>` chứa “Vàng 999.9” để tránh bắt nhầm số
    // của các dòng khác.
    final start = match.start;
    final trStart = html.lastIndexOf('<tr', start);
    final trEnd = html.indexOf('</tr>', start);
    if (trStart == -1 || trEnd == -1) {
      throw FormatException('Could not locate table row for "Vàng 999.9"');
    }

    final rowHtml = html.substring(trStart, trEnd + '</tr>'.length);

    // Trang thường render hậu tố đơn vị dưới dạng `<sup>đ</sup>`:
    //   15.900.000<sup>đ</sup>
    // hoặc đôi khi là text thuần:
    //   15.900.000đ
    final priceRegex = RegExp(
      r'(\d[\d\.\s]*)\s*(?:đ|₫|<sup>\s*(?:đ|₫)\s*</sup>)',
      caseSensitive: false,
    );

    final priceMatches = priceRegex
        .allMatches(rowHtml)
        .map((m) => m.group(1)!)
        .toList();

    if (priceMatches.length < 2) {
      throw FormatException(
        'Could not parse buy/sell for "Vàng 999.9" (matches=${priceMatches.length})',
      );
    }

    final buyRaw = priceMatches[0];
    final sellRaw = priceMatches[1];
    return GoldRate(
      buy: parseVndPriceToInt(buyRaw),
      sell: parseVndPriceToInt(sellRaw),
    );
  }

  Future<GoldRates> fetchGoldRates() async {
    final html = await fetchHtml();
    final gold9999 = parseGold9999FromHtml(html);

    return GoldRates(gold9999: gold9999);
  }
}
