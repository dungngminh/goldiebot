int parseVndPriceToInt(String raw) {
  final cleaned = raw
      .replaceAll('đ', '')
      .replaceAll('₫', '')
      .replaceAll('VND', '')
      .trim();

  final digitsOnly = cleaned.replaceAll('.', '').replaceAll(RegExp(r'\s+'), '');
  final justNumbers = digitsOnly.replaceAll(RegExp(r'[^0-9]'), '');
  if (justNumbers.isEmpty) {
    throw FormatException('Could not parse VND price from: "$raw"');
  }
  return int.parse(justNumbers);
}

String formatVnd(int value) {
  final isNegative = value < 0;
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final remaining = s.length - i;
    buf.write(s[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buf.write('.');
    }
  }
  return (isNegative ? '-' : '') + buf.toString();
}

String signedDelta(int delta) {
  if (delta > 0) return '+${formatVnd(delta)}đ';
  if (delta < 0) return '${formatVnd(delta)}đ';
  return '0đ';
}

