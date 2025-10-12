import 'byte_converter_base.dart';
import 'byte_enums.dart';
import 'parse_result.dart';
import 'unified_parse.dart';

/// Adapters to parse sizes from common external libraries/outputs.
class OSParsingModes {
  /// Parse Linux `ls -lh` style sizes (e.g., 1.1K, 15M, 2.0G)
  static ParseResult<ByteConverter> parseLinuxHuman(String input) {
    final m = RegExp(r'^\s*([0-9]+(?:\.[0-9]+)?)\s*([KMGTP]?)\s*$',
            caseSensitive: false)
        .firstMatch(input.trim());
    if (m == null) {
      return ParseResult.failure(
        originalInput: input,
        error: const ParseError(message: 'Invalid linux human size'),
      );
    }
    final numStr = m.group(1)!;
    final unit = (m.group(2) ?? '').toUpperCase();
    final factor = switch (unit) {
      '' => 1.0,
      'K' => 1024.0,
      'M' => 1024.0 * 1024,
      'G' => 1024.0 * 1024 * 1024,
      'T' => 1024.0 * 1024 * 1024 * 1024,
      'P' => 1024.0 * 1024 * 1024 * 1024 * 1024,
      _ => 1.0,
    };
    final value = double.parse(numStr) * factor;
    return ParseResult.success(
      originalInput: input,
      value: ByteConverter(value),
      normalizedInput: '$value B',
      detectedUnit: 'B',
      isBitInput: false,
      parsedNumber: value,
    );
  }

  /// Parse Windows Get-ChildItem short forms (e.g., 1.5KB, 20MB)
  static ParseResult<ByteConverter> parseWindowsShort(String input) {
    final m = RegExp(r'^\s*([0-9]+(?:\.[0-9]+)?)\s*([KMGT]B)\s*$',
            caseSensitive: true)
        .firstMatch(input.trim());
    if (m == null) {
      return ParseResult.failure(
        originalInput: input,
        error: const ParseError(message: 'Invalid Windows short size'),
      );
    }
    final numStr = m.group(1)!;
    final unit = m.group(2)!;
    final value = '$numStr $unit';
    return parseLocalized(value, standard: ByteStandard.si);
  }
}
