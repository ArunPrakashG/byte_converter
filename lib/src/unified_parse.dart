import '_parsing.dart';
import 'big_byte_converter.dart';
import 'byte_converter_base.dart';
import 'byte_enums.dart';
import 'localized_unit_names.dart';
import 'parse_result.dart';

/// Abstract view over an auto-parsed byte size, which may be backed by a
/// regular-precision or BigInt-precision implementation depending on size.
abstract class ParsedByteSize {
  /// Default const constructor for subclasses.
  ///
  /// Enables using `const` for lightweight wrapper instances when appropriate.
  const ParsedByteSize();

  /// True when the parsed value uses BigInt precision.
  bool get isBig;

  /// Byte count as a double for quick comparisons/thresholding.
  double get bytes;
}

/// Normal-sized parsed result backed by a [ByteConverter].
class ParsedNormal extends ParsedByteSize {
  /// Creates a [ParsedNormal] carrying a [ByteConverter] value.
  const ParsedNormal(this.value);

  /// The parsed value using double-based precision.
  final ByteConverter value;
  @override
  bool get isBig => false;
  @override
  double get bytes => value.asBytes().toDouble();
}

/// Parsed result carrying a [BigByteConverter] for very large magnitudes.
/// Large parsed result backed by a [BigByteConverter].
class ParsedBig extends ParsedByteSize {
  /// Creates a [ParsedBig] carrying a [BigByteConverter] value.
  const ParsedBig(this.value);

  /// The parsed value using BigInt precision for very large magnitudes.
  final BigByteConverter value;
  @override
  bool get isBig => true;
  @override
  double get bytes => value.asBytes.toDouble();
}

/// Parses [input] and returns either [ByteConverter] or [BigByteConverter]
/// depending on [thresholdBytes]. Useful when inputs may exceed 64-bit range.
/// Values >= [thresholdBytes] are parsed and returned as [ParsedBig].
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

/// Parses a size string using locale-aware unit words and number formats when
/// available. Uses [resolveLocalizedUnitSymbol] and number normalization to
/// reconstruct a canonical parse input before delegating to the core parser.
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
