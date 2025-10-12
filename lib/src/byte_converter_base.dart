import 'dart:math' as math;

import '_parsing.dart';
import 'byte_enums.dart';
import 'compound_format.dart';
import 'format_options.dart';
import 'localized_unit_names.dart' show localizedUnitName;
import 'parse_result.dart';
import 'storage_profile.dart';
// ignore_for_file: prefer_constructors_over_static_methods

/// High-performance byte unit converter with caching
class ByteConverter implements Comparable<ByteConverter> {
  ByteConverter(double bytes) : this._(bytes, (bytes * 8.0).ceil());

  // Constructors
  ByteConverter._(this._bytes, this._bits) {
    if (_bytes < 0) throw ArgumentError('Bytes cannot be negative');
  }

  factory ByteConverter.withBits(int bits) {
    if (bits < 0) throw ArgumentError('Bits cannot be negative');
    return ByteConverter._(bits / 8.0, bits);
  }

  // Named constructors for decimal units
  ByteConverter.fromKiloBytes(double value) : this(value * _KB);
  ByteConverter.fromMegaBytes(double value) : this(value * _MB);
  ByteConverter.fromGigaBytes(double value) : this(value * _GB);
  ByteConverter.fromTeraBytes(double value) : this(value * _TB);
  ByteConverter.fromPetaBytes(double value) : this(value * _PB);

  // Named constructors for binary units
  ByteConverter.fromKibiBytes(double value) : this(value * _KIB);
  ByteConverter.fromMebiBytes(double value) : this(value * _MIB);
  ByteConverter.fromGibiBytes(double value) : this(value * _GIB);
  ByteConverter.fromTebiBytes(double value) : this(value * _TIB);
  ByteConverter.fromPebiBytes(double value) : this(value * _PIB);

  factory ByteConverter.fromJson(Map<String, dynamic> json) {
    return ByteConverter(json['bytes'] as double);
  }

  // Unit conversion constants
  static const _KB = 1000.0;
  static const _MB = _KB * 1000;
  static const _GB = _MB * 1000;
  static const _TB = _GB * 1000;
  static const _PB = _TB * 1000;

  static const _KIB = 1024.0;
  static const _MIB = _KIB * 1024;
  static const _GIB = _MIB * 1024;
  static const _TIB = _GIB * 1024;
  static const _PIB = _TIB * 1024;

  // Storage constants
  static const _SECTOR_SIZE = 512.0; // Traditional sector size
  static const _BLOCK_SIZE = 4096.0; // Common filesystem block
  static const _PAGE_SIZE = 4096.0; // Memory page size
  static const _WORD_SIZE = 8.0; // 64-bit word

  // Storage units
  int get sectors => (_bytes / _SECTOR_SIZE).ceil();
  int get blocks => (_bytes / _BLOCK_SIZE).ceil();
  int get pages => (_bytes / _PAGE_SIZE).ceil();
  int get words => (_bytes / _WORD_SIZE).ceil();

  // Network rates
  int get bitsPerSecond => _bits;
  double get kiloBitsPerSecond => bitsPerSecond / 1000;
  double get megaBitsPerSecond => kiloBitsPerSecond / 1000;
  double get gigaBitsPerSecond => megaBitsPerSecond / 1000;

  // Time-based methods
  Duration transferTimeAt(double bitsPerSecond) =>
      Duration(microseconds: (_bits / bitsPerSecond * 1000000).ceil());

  Duration downloadTimeAt(double bytesPerSecond) =>
      Duration(microseconds: (_bytes / bytesPerSecond * 1000000).ceil());

  // Convenience getters
  bool get isWholeSector => _bytes % _SECTOR_SIZE == 0;
  bool get isWholeBlock => _bytes % _BLOCK_SIZE == 0;
  bool get isWholePage => _bytes % _PAGE_SIZE == 0;
  bool get isWholeWord => _bytes % _WORD_SIZE == 0;

  // Cached unit strings
  static const _units = {
    SizeUnit.PB: ' PB',
    SizeUnit.B: ' B',
    SizeUnit.KB: ' KB',
    SizeUnit.MB: ' MB',
    SizeUnit.GB: ' GB',
    SizeUnit.TB: ' TB',
  };

  // Core data
  final double _bytes;
  final int _bits;

  // Cached conversions
  late final double _kiloBytes = _bytes / _KB;
  late final double _megaBytes = _bytes / _MB;
  late final double _gigaBytes = _bytes / _GB;
  late final String _cachedString = _calculateString();

  // Optimized getters
  double get kiloBytes => _kiloBytes;
  double get megaBytes => _megaBytes;
  double get gigaBytes => _gigaBytes;
  double get teraBytes => _bytes / _TB;
  double get petaBytes => _bytes / _PB;

  double get kibiBytes => _bytes / _KIB;
  double get mebiBytes => _bytes / _MIB;
  double get gibiBytes => _bytes / _GIB;
  double get tebiBytes => _bytes / _TIB;
  double get pebiBytes => _bytes / _PIB;

  /// Exact byte representation of this value.
  double get bytes => _bytes;

  num asBytes({int precision = 2}) => _withPrecision(_bytes, precision);
  int get bits => _bits;

  // Math operations
  ByteConverter operator +(ByteConverter other) {
    return ByteConverter._(
      _bytes + other._bytes,
      _bits + other._bits,
    );
  }

  ByteConverter operator -(ByteConverter other) {
    return ByteConverter._(
      _bytes - other._bytes,
      _bits - other._bits,
    );
  }

  ByteConverter operator *(num factor) => ByteConverter(_bytes * factor);

  ByteConverter operator /(num divisor) => ByteConverter(_bytes / divisor);

  // Comparison operators
  bool operator >(ByteConverter other) => _bits > other._bits;
  bool operator <(ByteConverter other) => _bits < other._bits;
  bool operator <=(ByteConverter other) => _bits <= other._bits;
  bool operator >=(ByteConverter other) => _bits >= other._bits;

  // Rounding methods
  ByteConverter roundToSector() => ByteConverter(sectors * _SECTOR_SIZE);
  ByteConverter roundToBlock() => ByteConverter(blocks * _BLOCK_SIZE);
  ByteConverter roundToPage() => ByteConverter(pages * _PAGE_SIZE);
  ByteConverter roundToWord() => ByteConverter(words * _WORD_SIZE);

  /// Aligns this converter to a [StorageProfile] bucket using the configured rounding rules.
  ByteConverter roundToProfile(
    StorageProfile profile, {
    String? alignment,
    RoundingMode? rounding,
  }) {
    final resolved = profile.resolve(alignment);
    final blockSize = resolved.blockSizeBytes.toDouble();
    final mode = profile.roundingFor(
      alignment: alignment,
      override: rounding,
    );
    final quotient = _bytes / blockSize;
    final multiplier = switch (mode) {
      RoundingMode.floor => quotient.floor(),
      RoundingMode.ceil => quotient.ceil(),
      RoundingMode.round => quotient.round(),
    };
    return ByteConverter(multiplier * blockSize);
  }

  /// Calculates the slack (unused bytes) after aligning to the specified [StorageProfile].
  ByteConverter alignmentSlack(
    StorageProfile profile, {
    String? alignment,
    RoundingMode? rounding,
  }) {
    final aligned = roundToProfile(
      profile,
      alignment: alignment,
      rounding: rounding,
    );
    final slack = aligned._bytes - _bytes;
    return ByteConverter(slack <= 0 ? 0.0 : slack);
  }

  /// Returns true when this value already satisfies the requested profile alignment.
  bool isAligned(
    StorageProfile profile, {
    String? alignment,
  }) {
    final blockSize = profile.blockSizeBytes(alignment).toDouble();
    if (blockSize == 0) return false;
    final remainder = _bytes % blockSize;
    const epsilon = 1e-9;
    return remainder.abs() < epsilon || (blockSize - remainder).abs() < epsilon;
  }

  @override
  int compareTo(ByteConverter other) => _bits.compareTo(other._bits);

  // Optimized string handling
  String _calculateString() {
    final unit = _selectBestUnit();
    final value = _convertToUnit(unit);
    return '${_withPrecision(value, 2)}${_units[unit]}';
  }

  SizeUnit _selectBestUnit() {
    if (_bytes >= _PB) return SizeUnit.PB;
    if (_bytes >= _TB) return SizeUnit.TB;
    if (_bytes >= _GB) return SizeUnit.GB;
    if (_bytes >= _MB) return SizeUnit.MB;
    if (_bytes >= _KB) return SizeUnit.KB;
    return SizeUnit.B;
  }

  double _convertToUnit(SizeUnit unit) => switch (unit) {
        SizeUnit.PB => petaBytes,
        SizeUnit.TB => teraBytes,
        SizeUnit.GB => gigaBytes,
        SizeUnit.MB => megaBytes,
        SizeUnit.KB => kiloBytes,
        SizeUnit.B => _bytes,
      };

  num _withPrecision(double value, int precision) {
    if (precision < 0) return value;
    // Handle whole numbers without decimal places
    if (value % 1 == 0) return value.toInt();
    final factor = math.pow(10, precision);
    return (value * factor).round() / factor;
  }

  String toHumanReadable(SizeUnit unit, {int precision = 2}) {
    final value = _convertToUnit(unit);
    return '${_withPrecision(value, precision)}${_units[unit]}';
  }

  /// Formats this value automatically choosing best unit, supporting SI/IEC/JEDEC and bits.
  String toHumanReadableAuto({
    ByteStandard standard = ByteStandard.si,
    bool useBits = false,
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
  }) {
    final res = humanize(
      _bytes,
      HumanizeOptions(
        standard: standard,
        useBits: useBits,
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
    return res.text;
  }

  /// Convenience overload using ByteFormatOptions.
  String toHumanReadableAutoWith(ByteFormatOptions options) =>
      toHumanReadableAuto(
        standard: options.standard,
        // options.useBytes true -> bytes; false -> bits
        useBits: !options.useBytes,
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
      );

  /// Compound mixed-unit formatting, e.g., "1 GiB 234 MiB 12 KiB".
  String toHumanReadableCompound(
      {CompoundFormatOptions options = const CompoundFormatOptions()}) {
    return formatCompound(_bytes, options);
  }

  /// Parses a string like "1.5 GB", "2GiB", "100 KB", "10 Mbit" into a ByteConverter.
  static ByteConverter parse(
    String input, {
    ByteStandard standard = ByteStandard.si,
    bool strictBits = false,
  }) {
    final r = parseSize<SizeUnit>(
      input: input,
      standard: standard,
      strictBits: strictBits,
    );
    return ByteConverter(r.valueInBytes);
  }

  /// Safe parsing variant that never throws and returns diagnostics on failure.
  static ParseResult<ByteConverter> tryParse(
    String input, {
    ByteStandard standard = ByteStandard.si,
    bool strictBits = false,
  }) {
    try {
      final r = parseSize<SizeUnit>(
        input: input,
        standard: standard,
        strictBits: strictBits,
      );
      if (r.valueInBytes.isNaN || r.valueInBytes.isInfinite) {
        throw FormatException('Invalid numeric value in input: $input');
      }
      if (r.valueInBytes < 0) {
        return ParseResult.failure(
          originalInput: input,
          error: const ParseError(message: 'Bytes cannot be negative'),
          normalizedInput: r.normalizedInput,
        );
      }
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
        normalizedInput: input.trim().isEmpty ? null : input.trim(),
      );
    }
  }

  // Override Object methods
  @override
  String toString() => _cachedString;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      identical(this, other) || other is ByteConverter && _bits == other._bits;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => _bits.hashCode;

  // JSON serialization
  Map<String, dynamic> toJson() => {'bytes': _bytes};

  /// Pattern-based formatter:
  /// Supported tokens:
  ///  - 'u': unit symbol (KB, MiB, Mb)
  ///  - 'U': unit full word (localized when available)
  /// Numerics use current options (min/max digits, separator/grouping) set via [options].
  String formatWith(String pattern,
      {ByteFormatOptions options = const ByteFormatOptions()}) {
    // Force a single space spacer to reliably split value and unit
    final res = humanize(
      _bytes,
      HumanizeOptions(
        standard: options.standard,
        useBits: false,
        precision: options.precision,
        showSpace: true,
        nonBreakingSpace: false,
        fullForm: false,
        separator: options.separator,
        spacer: ' ',
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
      ),
    );
    final symbol = res.symbol;
    // final text = res.text; // not needed after compact computation
    // Derive numeric part robustly by reformatting with no spacer and forced unit
    final compact = humanize(
      _bytes,
      HumanizeOptions(
        standard: options.standard,
        useBits: false,
        precision: options.precision,
        showSpace: true,
        nonBreakingSpace: false,
        fullForm: false,
        separator: options.separator,
        spacer: '',
        minimumFractionDigits: options.minimumFractionDigits,
        maximumFractionDigits: options.maximumFractionDigits,
        truncate: options.truncate,
        signed: options.signed,
        forceUnit: symbol,
        locale: options.locale,
        useGrouping: options.useGrouping,
        siKSymbolCase: options.siKSymbolCase,
        fixedWidth: options.fixedWidth,
        includeSignInWidth: options.includeSignInWidth,
      ),
    ).text;
    final valuePart = compact.substring(0, compact.length - symbol.length);
    final unitSymbol = () {
      // Recompute to respect siKSymbolCase on KB
      if (symbol == 'KB' && options.siKSymbolCase == SiKSymbolCase.lowerK) {
        return 'kB';
      }
      return symbol;
    }();
    String fullWord() {
      final sym = unitSymbol;
      final loc = options.locale ?? 'en';
      return localizedUnitName(sym, locale: loc) ?? unitSymbol;
    }

    // Replace numeric token greedily to handle patterns like 0.0 or 0##
    final numericRe = RegExp(r'0[#0\.,]*');
    var out = pattern.replaceAll('U', fullWord()).replaceAll('u', unitSymbol);
    // 'S' -> sign: '+', '-', or ' ' (when options.signed is true); else empty
    final signChar =
        options.signed ? (_bytes > 0 ? '+' : (_bytes < 0 ? '-' : ' ')) : '';
    out = out.replaceAll('S', signChar);
    out = out.replaceAll(numericRe, valuePart);
    return out;
  }

  /// Convenience full-words output using current defaults.
  String toFullWords({ByteFormatOptions options = const ByteFormatOptions()}) {
    return toHumanReadableAuto(
      standard: options.standard,
      useBits: false,
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
    );
  }

  /// Returns the largest whole-number unit and its value for this size under the given standard.
  /// Example: 1536 B -> { value: 1, symbol: 'KB' } (SI), or 1 KiB (IEC).
  ({int value, String symbol}) largestWholeNumber(
      {ByteStandard standard = ByteStandard.si, bool useBytes = true}) {
    final opt = HumanizeOptions(standard: standard, useBits: !useBytes);
    const thresholdsSi = [1e12, 1e9, 1e6, 1e3];
    const symbolsSi = ['TB', 'GB', 'MB', 'KB'];
    const thresholdsIec = [
      1024.0 * 1024 * 1024 * 1024,
      1024.0 * 1024 * 1024,
      1024.0 * 1024,
      1024.0,
    ];
    const symbolsIec = ['TiB', 'GiB', 'MiB', 'KiB'];
    final isBits = !useBytes;
    final value = isBits ? _bits.toDouble() : _bytes;
    List<double> th;
    List<String> sy;
    switch (opt.standard) {
      case ByteStandard.si:
        th = thresholdsSi;
        sy = symbolsSi;
        break;
      case ByteStandard.jedec:
        th = thresholdsIec;
        sy = ['TB', 'GB', 'MB', 'KB'];
        break;
      case ByteStandard.iec:
        th = thresholdsIec;
        sy = symbolsIec;
        break;
    }
    for (var i = 0; i < th.length; i++) {
      final unitValue = value / th[i];
      if (unitValue.floorToDouble() >= 1) {
        return (value: unitValue.floor(), symbol: sy[i]);
      }
    }
    return (value: value.floor().toInt(), symbol: isBits ? 'b' : 'B');
  }
}
