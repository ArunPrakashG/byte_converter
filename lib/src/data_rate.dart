import '_parsing.dart';
import 'byte_enums.dart';
import 'compound_format.dart';
import 'format_options.dart';
import 'localized_unit_names.dart' show localizedUnitName;
import 'parse_result.dart';
// ignore_for_file: prefer_constructors_over_static_methods

/// Represents a network/data rate. Internally stored as bits per second.
///
/// Provides human-readable formatting (including time base selection),
/// parsing from common strings, and convenience constructors for SI/IEC units.
class DataRate implements Comparable<DataRate> {
  /// Constructs a rate in bits per second.
  const DataRate.bitsPerSecond(this._bitsPerSecond)
      : assert(_bitsPerSecond >= 0, 'Rate cannot be negative');

  /// Constructs a rate given [bytesPerSecond].
  factory DataRate.bytesPerSecond(double bytesPerSecond) =>
      DataRate.bitsPerSecond(bytesPerSecond * 8.0);

  // Named constructors (SI)
  /// SI: kilobits per second.
  factory DataRate.kiloBitsPerSecond(double value) =>
      DataRate.bitsPerSecond(value * 1000);

  /// SI: megabits per second.
  factory DataRate.megaBitsPerSecond(double value) =>
      DataRate.bitsPerSecond(value * 1000 * 1000);

  /// SI: gigabits per second.
  factory DataRate.gigaBitsPerSecond(double value) =>
      DataRate.bitsPerSecond(value * 1000 * 1000 * 1000);

  /// SI: kilobytes per second.
  factory DataRate.kiloBytesPerSecond(double value) =>
      DataRate.bytesPerSecond(value * 1000);

  /// SI: megabytes per second.
  factory DataRate.megaBytesPerSecond(double value) =>
      DataRate.bytesPerSecond(value * 1000 * 1000);

  /// SI: gigabytes per second.
  factory DataRate.gigaBytesPerSecond(double value) =>
      DataRate.bytesPerSecond(value * 1000 * 1000 * 1000);

  // Named constructors (IEC)
  /// IEC: kibibits per second.
  factory DataRate.kibiBitsPerSecond(double value) =>
      DataRate.bitsPerSecond(value * 1024);

  /// IEC: mebibits per second.
  factory DataRate.mebiBitsPerSecond(double value) =>
      DataRate.bitsPerSecond(value * 1024 * 1024);

  /// IEC: gibibits per second.
  factory DataRate.gibiBitsPerSecond(double value) =>
      DataRate.bitsPerSecond(value * 1024 * 1024 * 1024);

  /// IEC: kibibytes per second.
  factory DataRate.kibiBytesPerSecond(double value) =>
      DataRate.bytesPerSecond(value * 1024);

  /// IEC: mebibytes per second.
  factory DataRate.mebiBytesPerSecond(double value) =>
      DataRate.bytesPerSecond(value * 1024 * 1024);

  /// IEC: gibibytes per second.
  factory DataRate.gibiBytesPerSecond(double value) =>
      DataRate.bytesPerSecond(value * 1024 * 1024 * 1024);
  final double _bitsPerSecond;

  /// Bits per second.
  double get bitsPerSecond => _bitsPerSecond;

  /// Bytes per second.
  double get bytesPerSecond => _bitsPerSecond / 8.0;

  // Time base for formatting
  static const _sec = 1.0;
  static const _ms = 1e-3;
  static const _min = 60.0;
  static const _hour = 3600.0;

  String _perSuffix(double perSeconds) {
    if (perSeconds == _sec) return '/s';
    if (perSeconds == _ms) return '/ms';
    if (perSeconds == _min) return '/min';
    if (perSeconds == _hour) return '/h';
    return '/s';
  }

  /// Duration to transfer [bytes] at this data rate.
  Duration transferTimeForBytes(double bytes) {
    if (_bitsPerSecond == 0) return Duration.zero;
    final seconds = (bytes * 8.0) / _bitsPerSecond;
    return Duration(microseconds: (seconds * 1e6).ceil());
  }

  /// Formats this data rate using humanized units.
  ///
  /// Supports SI/IEC/JEDEC [standard], bits/bytes via [useBytes], locale and
  /// grouping options, min/max fraction digits with optional [truncate], and
  /// [per] time-base selection: 's' (default), 'ms', 'min', or 'h'.
  String toHumanReadableAuto({
    ByteStandard standard = ByteStandard.si,
    bool useBytes = false,
    int precision = 2,
    bool showSpace = true,
    bool nonBreakingSpace = false,
    bool fullForm = false,
    Map<String, String>? fullForms,
    String? separator,
    String? spacer,
    int? minimumFractionDigits,
    int? maximumFractionDigits,
    bool truncate = false,
    bool signed = false,
    String? forceUnit,
    String? locale,
    bool useGrouping = true,
    SiKSymbolCase siKSymbolCase = SiKSymbolCase.upperK,
    int? fixedWidth,
    bool includeSignInWidth = false,
    String per = 's', // 's','ms','min','h'
  }) {
    final perSeconds = switch (per) {
      's' => _sec,
      'ms' => _ms,
      'min' => _min,
      'h' => _hour,
      _ => _sec,
    };
    final scale = 1.0 / perSeconds; // multiply base per-second to get per-unit
    final baseBytesPerUnit =
        (useBytes ? bytesPerSecond : bitsPerSecond / 8.0) / scale;
    // Reuse humanize on bytes per second and then append '/s'
    final res = humanize(
      baseBytesPerUnit,
      HumanizeOptions(
        standard: standard,
        useBits: !useBytes, // if not bytes, use bits
        precision: precision,
        showSpace: showSpace,
        nonBreakingSpace: nonBreakingSpace,
        fullForm: fullForm,
        fullForms: fullForms,
        separator: separator,
        spacer: spacer,
        minimumFractionDigits: minimumFractionDigits,
        maximumFractionDigits: maximumFractionDigits,
        truncate: truncate,
        signed: signed,
        forceUnit: forceUnit,
        locale: locale,
        useGrouping: useGrouping,
        siKSymbolCase: siKSymbolCase,
        fixedWidth: fixedWidth,
        includeSignInWidth: includeSignInWidth,
      ),
    );
    // Use existing formatted text from humanize (includes sign/spacing/locale), then append '/s'
    final formatted = res.text;
    return '$formatted${_perSuffix(perSeconds)}';
  }

  /// Convenience overload using [ByteFormatOptions].
  String toHumanReadableAutoWith(ByteFormatOptions options) =>
      toHumanReadableAuto(
        standard: options.standard,
        useBytes: options.useBytes,
        precision: options.precision,
        showSpace: options.showSpace,
        nonBreakingSpace: options.nonBreakingSpace,
        fullForm: options.fullForm,
        fullForms: options.fullForms,
        separator: options.separator,
        spacer: options.spacer,
        minimumFractionDigits: options.minimumFractionDigits,
        maximumFractionDigits: options.maximumFractionDigits,
        truncate: options.truncate,
        signed: options.signed,
        forceUnit: options.forceUnit,
        locale: options.locale,
        useGrouping: options.useGrouping,
        siKSymbolCase: options.siKSymbolCase,
        fixedWidth: options.fixedWidth,
        includeSignInWidth: options.includeSignInWidth,
        per: options.per,
      );

  /// Compound mixed-unit formatting for data rates. Appends '/s'.
  String toHumanReadableCompound(
      {CompoundFormatOptions options = const CompoundFormatOptions(),
      String per = 's'}) {
    final perSeconds = switch (per) {
      's' => _sec,
      'ms' => _ms,
      'min' => _min,
      'h' => _hour,
      _ => _sec,
    };
    final baseBytesPerUnit =
        (options.useBits ? bitsPerSecond / 8.0 : bytesPerSecond) * perSeconds;
    final text = formatCompound(baseBytesPerUnit, options);
    return '$text${_perSuffix(perSeconds)}';
  }

  /// Parses a string like "100 Mb/s", "12.5 MB/s", or "2 kibps" to a DataRate.
  static DataRate parse(
    String input, {
    ByteStandard standard = ByteStandard.si,
  }) {
    final r = parseRate(input: input, standard: standard);
    return DataRate.bitsPerSecond(r.bitsPerSecond);
  }

  /// Safe parsing variant that returns diagnostics instead of throwing.
  static ParseResult<DataRate> tryParse(
    String input, {
    ByteStandard standard = ByteStandard.si,
  }) {
    try {
      final r = parseRate(input: input, standard: standard);
      if (r.bitsPerSecond.isNaN || r.bitsPerSecond.isInfinite) {
        throw FormatException('Invalid numeric value in input: $input');
      }
      if (r.bitsPerSecond < 0) {
        return ParseResult.failure(
          originalInput: input,
          error: const ParseError(message: 'Rate cannot be negative'),
          normalizedInput: r.normalizedInput,
        );
      }
      final rate = DataRate.bitsPerSecond(r.bitsPerSecond);
      return ParseResult.success(
        originalInput: input,
        value: rate,
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
        normalizedInput: input.trim().isEmpty ? null : input.trim(),
      );
    }
  }

  @override
  int compareTo(DataRate other) =>
      _bitsPerSecond.compareTo(other._bitsPerSecond);

  @override
  String toString() => toHumanReadableAuto();

  /// Formats the rate using a custom [pattern].
  ///
  /// Placeholders:
  /// - 'U' = localized full unit name (e.g., megabytes)
  /// - 'u' = unit symbol (e.g., MB)
  /// - a numeric mask like 0.## replaced by the value
  ///
  /// [per] controls the time unit denominator ('s', 'ms', 'min', 'h').
  String formatWith(String pattern,
      {ByteFormatOptions options = const ByteFormatOptions(),
      String per = 's'}) {
    final perSeconds = switch (per) {
      's' => _sec,
      'ms' => _ms,
      'min' => _min,
      'h' => _hour,
      _ => _sec,
    };
    final scale = 1.0 / perSeconds;
    final baseBytesPerUnit =
        (options.useBytes ? bytesPerSecond : bitsPerSecond / 8.0) / scale;
    final res = humanize(
      baseBytesPerUnit,
      HumanizeOptions(
        standard: options.standard,
        useBits: !options.useBytes,
        precision: options.precision,
        showSpace: true,
        nonBreakingSpace: options.nonBreakingSpace,
        fullForm: false,
        separator: options.separator,
        spacer: '',
        minimumFractionDigits: options.minimumFractionDigits,
        maximumFractionDigits: options.maximumFractionDigits,
        truncate: options.truncate,
        signed: options.signed,
        forceUnit: options.forceUnit,
        locale: options.locale,
        useGrouping: options.useGrouping,
        siKSymbolCase: options.siKSymbolCase,
      ),
    );
    final symbol = res.symbol;
    final text = res.text;
    final parts = text.split(RegExp(r'\u00A0|\s'));
    final valuePart = parts.first;
    final unitSymbol = () {
      if (symbol == 'KB' && options.siKSymbolCase == SiKSymbolCase.lowerK) {
        return 'kB';
      }
      return symbol;
    }();
    String fullWord() {
      final bits = !options.useBytes;
      final sym = bits ? unitSymbol.toLowerCase() : unitSymbol;
      final loc = options.locale ?? 'en';
      return localizedUnitName(sym, locale: loc) ?? unitSymbol;
    }

    final core = pattern
        .replaceAll('U', fullWord())
        .replaceAll('u', unitSymbol)
        .replaceAll(RegExp(r'0[#0\.,]*'), valuePart);
    return '$core${_perSuffix(perSeconds)}';
  }

  /// Formats the rate as full words (e.g., "12 megabytes per second").
  /// [per] controls the time unit denominator ('s', 'ms', 'min', 'h').
  String toFullWords(
      {ByteFormatOptions options = const ByteFormatOptions(),
      String per = 's'}) {
    return toHumanReadableAuto(
      standard: options.standard,
      useBytes: options.useBytes,
      precision: options.precision,
      showSpace: options.showSpace,
      nonBreakingSpace: options.nonBreakingSpace,
      fullForm: true,
      fullForms: options.fullForms,
      separator: options.separator,
      spacer: options.spacer,
      minimumFractionDigits: options.minimumFractionDigits,
      maximumFractionDigits: options.maximumFractionDigits,
      truncate: options.truncate,
      signed: options.signed,
      forceUnit: options.forceUnit,
      locale: options.locale,
      useGrouping: options.useGrouping,
      siKSymbolCase: options.siKSymbolCase,
      per: per,
    );
  }
}
