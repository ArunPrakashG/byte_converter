import '_parsing.dart';
import 'big_byte_converter.dart';
import 'byte_converter_base.dart';
import 'byte_enums.dart';
import 'localized_unit_names.dart';
import 'parse_result.dart';

/// Sealed-like result for auto parsing a byte size.
abstract class ParsedByteSize {
  const ParsedByteSize();
  bool get isBig;
  double get bytes;
}

class ParsedNormal extends ParsedByteSize {
  const ParsedNormal(this.value);
  final ByteConverter value;
  @override
  bool get isBig => false;
  @override
  double get bytes => value.asBytes().toDouble();
}

class ParsedBig extends ParsedByteSize {
  const ParsedBig(this.value);
  final BigByteConverter value;
  @override
  bool get isBig => true;
  @override
  double get bytes => value.asBytes.toDouble();
}

/// Parse a size string and return either ByteConverter or BigByteConverter depending on threshold.
/// thresholdBytes: if parsed absolute bytes >= threshold, BigByteConverter is returned.
ParsedByteSize parseByteSizeAuto(
  String input, {
  ByteStandard standard = ByteStandard.si,
  RoundingMode rounding = RoundingMode.round,
  double thresholdBytes = 9.22e18, // ~2^63 for practical split
}) {
  // Use big-aware parsing for accurate detection across all units
  final preview = parseSizeBig(input: input, standard: standard);
  final bytes = preview.valueInBytes.abs();
  if (bytes >= thresholdBytes) {
    // reparse via Big path for better precision then round
    final big = BigByteConverter.parse(
      input,
      standard: standard,
      rounding: rounding,
    );
    return ParsedBig(big);
  }
  return ParsedNormal(ByteConverter(preview.valueInBytes));
}

/// Parse a size string using locale-aware unit words and number formats when available.
ParseResult<ByteConverter> parseLocalized(
  String input, {
  String? locale,
  ByteStandard standard = ByteStandard.si,
}) {
  final text = input.trim();
  if (text.isEmpty) {
    return ParseResult.failure(
      originalInput: input,
      error: const ParseError(message: 'Empty input'),
    );
  }
  // Split numeric and unit parts heuristically
  final m = RegExp(r'^\s*([+-]?[0-9\.,\u00A0_\s]+)\s*([\p{L}A-Za-z]+)?\s*$',
          unicode: true)
      .firstMatch(text);
  if (m == null) {
    return ParseResult.failure(
      originalInput: input,
      error: ParseError(message: 'Invalid format: $input'),
      normalizedInput: text,
    );
  }
  final numPart = (m.group(1) ?? '').trim();
  final unitPartRaw = (m.group(2) ?? '').trim();

  // Normalize number by inferring decimal separator (last of [.,]) and stripping grouping
  String normalizedNumber = _normalizeLocalizedNumber(numPart);

  String? resolvedSymbol;
  if (unitPartRaw.isNotEmpty) {
    resolvedSymbol = resolveLocalizedUnitSymbol(unitPartRaw, locale: locale);
  }

  final reconstructed = resolvedSymbol == null
      ? normalizedNumber
      : '$normalizedNumber $resolvedSymbol';

  try {
    final r = parseSize<SizeUnit>(input: reconstructed, standard: standard);
    final value = ByteConverter(r.valueInBytes);
    return ParseResult.success(
      originalInput: input,
      value: value,
      normalizedInput: r.normalizedInput,
      detectedUnit: r.unitSymbol,
      isBitInput: r.isBitInput,
      parsedNumber: r.rawValue,
    );
  } on FormatException catch (e) {
    return ParseResult.failure(
      originalInput: input,
      error: ParseError(
        message: e.message,
        position: e.offset,
        exception: e,
      ),
      normalizedInput: reconstructed,
    );
  }
}

String _normalizeLocalizedNumber(String input) {
  var t = input.trim();
  // Replace NBSP with space
  t = t.replaceAll('\u00A0', ' ');
  // Identify last separator
  final lastDot = t.lastIndexOf('.');
  final lastComma = t.lastIndexOf(',');
  int decimalIndex = -1;
  if (lastDot > lastComma) {
    decimalIndex = lastDot;
  } else {
    decimalIndex = lastComma;
  }
  final sign = t.startsWith('-') ? '-' : (t.startsWith('+') ? '+' : '');
  t = t.replaceFirst(RegExp(r'^[+-]'), '');
  final digits = StringBuffer();
  for (var i = 0; i < t.length; i++) {
    final ch = t[i];
    if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
      digits.write(ch);
    } else if (i == decimalIndex && (ch == '.' || ch == ',')) {
      digits.write('.');
    }
    // ignore grouping and other letters/spaces
  }
  final s = digits.toString();
  if (s.isEmpty) return '0';
  // Ensure leading zero when starts with decimal
  if (s.startsWith('.')) return '${sign}0$s';
  return '$sign$s';
}
