import '_parsing.dart';
import 'big_byte_converter.dart';
import 'byte_enums.dart';
import 'data_rate.dart';
import 'parse_result.dart';

class BigDataRate implements Comparable<BigDataRate> {
  BigDataRate.bitsPerSecond(BigInt bitsPerSecond)
      : assert(!bitsPerSecond.isNegative, 'Rate cannot be negative'),
        _bitsPerSecond = bitsPerSecond;

  factory BigDataRate.bytesPerSecond(BigInt bytesPerSecond) =>
      BigDataRate.bitsPerSecond(bytesPerSecond * BigInt.from(8));

  factory BigDataRate.kiloBitsPerSecond(BigInt value) =>
      BigDataRate.bitsPerSecond(value * BigInt.from(1000));
  factory BigDataRate.megaBitsPerSecond(BigInt value) =>
      BigDataRate.bitsPerSecond(value * BigInt.from(1000 * 1000));
  factory BigDataRate.gigaBitsPerSecond(BigInt value) =>
      BigDataRate.bitsPerSecond(value * BigInt.from(1000 * 1000 * 1000));

  factory BigDataRate.kibiBitsPerSecond(BigInt value) =>
      BigDataRate.bitsPerSecond(value * BigInt.from(1024));
  factory BigDataRate.mebiBitsPerSecond(BigInt value) =>
      BigDataRate.bitsPerSecond(value * BigInt.from(1024 * 1024));
  factory BigDataRate.gibiBitsPerSecond(BigInt value) =>
      BigDataRate.bitsPerSecond(value * BigInt.from(1024 * 1024 * 1024));

  factory BigDataRate.fromDataRate(DataRate rate) =>
      BigDataRate.bitsPerSecond(BigInt.from(rate.bitsPerSecond.round()));

  BigInt get bitsPerSecond => _bitsPerSecond;
  final BigInt _bitsPerSecond;

  double get bytesPerSecond => _bitsPerSecond.toDouble() / 8.0;
  BigInt get bytesPerSecondExact => _bitsPerSecond ~/ BigInt.from(8);

  Duration transferTimeForBytes(BigInt bytes) {
    if (_bitsPerSecond == BigInt.zero) return Duration.zero;
    final seconds = bytes * BigInt.from(8) ~/ _bitsPerSecond;
    return Duration(seconds: seconds.toInt());
  }

  String toHumanReadableAuto({
    ByteStandard standard = ByteStandard.si,
    bool useBytes = false,
    int precision = 2,
    bool showSpace = true,
    bool fullForm = false,
    Map<String, String>? fullForms,
    String? separator,
    String? spacer,
    int? minimumFractionDigits,
    int? maximumFractionDigits,
    bool signed = false,
    String? forceUnit,
    String? locale,
    bool useGrouping = true,
  }) {
    final baseBytesPerSec =
        useBytes ? bytesPerSecond : _bitsPerSecond.toDouble() / 8.0;
    final result = humanize(
      baseBytesPerSec,
      HumanizeOptions(
        standard: standard,
        useBits: useBytes ? false : true,
        precision: precision,
        showSpace: showSpace,
        fullForm: fullForm,
        fullForms: fullForms,
        separator: separator,
        spacer: spacer,
        minimumFractionDigits: minimumFractionDigits,
        maximumFractionDigits: maximumFractionDigits,
        signed: signed,
        forceUnit: forceUnit,
        locale: locale,
        useGrouping: useGrouping,
      ),
    );
    return '${result.text}/s';
  }

  DataRate toDataRate() => DataRate.bitsPerSecond(bytesPerSecond);

  static BigDataRate parse(
    String input, {
    ByteStandard standard = ByteStandard.si,
    RoundingMode rounding = RoundingMode.round,
  }) {
    final parsed = parseRate(input: input, standard: standard);
    final bits = _applyRounding(parsed.bitsPerSecond, rounding);
    if (bits.isNegative) {
      throw FormatException('Rate cannot be negative: $input');
    }
    return BigDataRate.bitsPerSecond(bits);
  }

  static ParseResult<BigDataRate> tryParse(
    String input, {
    ByteStandard standard = ByteStandard.si,
    RoundingMode rounding = RoundingMode.round,
  }) {
    try {
      final parsed = parseRate(input: input, standard: standard);
      final bits = _applyRounding(parsed.bitsPerSecond, rounding);
      if (bits.isNegative) {
        return ParseResult.failure(
          originalInput: input,
          error: const ParseError(message: 'Rate cannot be negative'),
          normalizedInput: parsed.normalizedInput,
        );
      }
      final rate = BigDataRate.bitsPerSecond(bits);
      return ParseResult.success(
        originalInput: input,
        value: rate,
        normalizedInput: parsed.normalizedInput,
        detectedUnit: parsed.unitSymbol,
        isBitInput: parsed.isBitInput,
        parsedNumber: parsed.rawValue,
      );
    } on FormatException catch (e) {
      return ParseResult.failure(
        originalInput: input,
        error: ParseError(
          message: e.message,
          position: e.offset,
          exception: e,
        ),
        normalizedInput: input.trim().isEmpty ? null : input.trim(),
      );
    }
  }

  @override
  int compareTo(BigDataRate other) =>
      _bitsPerSecond.compareTo(other._bitsPerSecond);

  @override
  String toString() => toHumanReadableAuto();

  static BigInt _applyRounding(double bitsPerSecond, RoundingMode mode) {
    if (bitsPerSecond.isNaN || bitsPerSecond.isInfinite) {
      throw const FormatException('Invalid numeric value for rate');
    }
    switch (mode) {
      case RoundingMode.floor:
        return BigInt.from(bitsPerSecond.floor());
      case RoundingMode.ceil:
        return BigInt.from(bitsPerSecond.ceil());
      case RoundingMode.round:
        return BigInt.from(bitsPerSecond.round());
    }
  }
}

extension BigDataRatePlanning on BigDataRate {
  BigByteConverter transferableBytes(Duration window) {
    final seconds = BigInt.from(window.inSeconds);
    final totalMicros = window.inMicroseconds;
    final remainderMicros = totalMicros - window.inSeconds * 1000000;
    final bitsFromSeconds = bitsPerSecond * seconds;
    final bytesFromSeconds = bitsFromSeconds ~/ BigInt.from(8);
    final bitsFromMicros = bitsPerSecond * BigInt.from(remainderMicros);
    final bytesFromMicros = bitsFromMicros ~/ BigInt.from(8 * 1000000);
    return BigByteConverter(bytesFromSeconds + bytesFromMicros);
  }
}
