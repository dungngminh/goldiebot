import 'dart:convert';

class GoldRate {
  final int buy;
  final int sell;

  const GoldRate({required this.buy, required this.sell});

  bool equals(GoldRate other) => buy == other.buy && sell == other.sell;

  Map<String, dynamic> toJson() => {'buy': buy, 'sell': sell};

  static GoldRate fromJson(Map<String, dynamic> json) {
    return GoldRate(
      buy: (json['buy'] as num).toInt(),
      sell: (json['sell'] as num).toInt(),
    );
  }
}

class GoldRates {
  final GoldRate gold9999;

  const GoldRates({required this.gold9999});

  Map<String, dynamic> toJson() => {'gold9999': gold9999.toJson()};

  static GoldRates fromJson(Map<String, dynamic> json) {
    return GoldRates(
      gold9999: GoldRate.fromJson(json['gold9999'] as Map<String, dynamic>),
    );
  }
}

class GoldSnapshot {
  final DateTime checkedAtUtc;
  final String sourceUrl;
  final GoldRates rates;

  const GoldSnapshot({
    required this.checkedAtUtc,
    required this.sourceUrl,
    required this.rates,
  });

  Map<String, dynamic> toJson() => {
    'checkedAtUtc': checkedAtUtc.toUtc().toIso8601String(),
    'sourceUrl': sourceUrl,
    'rates': rates.toJson(),
  };

  static GoldSnapshot fromJson(Map<String, dynamic> json) {
    return GoldSnapshot(
      checkedAtUtc: DateTime.parse(json['checkedAtUtc'] as String).toUtc(),
      sourceUrl: json['sourceUrl'] as String,
      rates: GoldRates.fromJson(json['rates'] as Map<String, dynamic>),
    );
  }

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
