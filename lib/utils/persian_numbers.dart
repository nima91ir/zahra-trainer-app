/// Converts Latin digits in a string or number to Persian (۰-۹).
/// Example: fa(12) → \'۱۲\'
///          fa(\'1405/06/21\') → \'۱۴۰۵/۰۶/۲۱\'
String fa(dynamic input) {
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  return input.toString().replaceAllMapped(
    RegExp(r'[0-9]'),
    (m) => persian[int.parse(m.group(0)!)],
  );
}

/// Converts Persian digits in a string to Latin (0-9).
/// Example: faToEn(\'۱۴۰۵\') → \'1405\'
String faToEn(String input) {
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final idx = persian.indexOf(ch);
    buffer.write(idx >= 0 ? idx.toString() : ch);
  }
  return buffer.toString();
}

/// True if the string contains any Persian digit.
bool hasPersianDigits(String input) {
  return RegExp(r'[۰-۹]').hasMatch(input);
}