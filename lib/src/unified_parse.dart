import '_parsing.dart';
import 'big_byte_converter.dart';
import 'byte_converter_base.dart';
import 'byte_enums.dart';

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
