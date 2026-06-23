/// Formats an integer with thousands separators, e.g. 12345 -> "12,345".
String commas(int n) {
  final negative = n < 0;
  final digits = n.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
}
