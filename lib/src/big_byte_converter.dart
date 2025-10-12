import 'dart:math' as math;

import '_parsing.dart';
import 'byte_converter_base.dart';
import 'byte_enums.dart';
import 'compound_format.dart';
// ignore_for_file: non_constant_identifier_names, avoid_equals_and_hash_code_on_mutable_classes, prefer_constructors_over_static_methods
import 'format_options.dart';
import 'localized_unit_names.dart' show localizedUnitName;
import 'parse_result.dart';
import 'storage_profile.dart';

/// High-performance byte unit converter using BigInt for arbitrary precision.
///
/// Suitable for extremely large sizes without precision loss. Mirrors most of
/// [ByteConverter]'s surface with BigInt-backed storage and exact arithmetic.
class BigByteConverter implements Comparable<BigByteConverter> {
  /// Creates a converter from a [bytes] BigInt value.
  BigByteConverter(BigInt bytes) : this._(bytes, bytes * BigInt.from(8));

  // Private constructor
  BigByteConverter._(this._bytes, this._bits) {
    if (_bytes.isNegative) throw ArgumentError('Bytes cannot be negative');
  }

  /// Creates a converter from [bits] (BigInt).
  factory BigByteConverter.withBits(BigInt bits) {
    if (bits.isNegative) throw ArgumentError('Bits cannot be negative');
    return BigByteConverter._(bits ~/ BigInt.from(8), bits);
  }

  // Named constructors for decimal units
  /// Creates from kilobytes (SI, 1000^1) as BigInt.
  BigByteConverter.fromKiloBytes(BigInt value) : this(value * _KB);

  /// Creates from megabytes (SI, 1000^2) as BigInt.
  BigByteConverter.fromMegaBytes(BigInt value) : this(value * _MB);

  /// Creates from gigabytes (SI, 1000^3) as BigInt.
  BigByteConverter.fromGigaBytes(BigInt value) : this(value * _GB);

  /// Creates from terabytes (SI, 1000^4) as BigInt.
  BigByteConverter.fromTeraBytes(BigInt value) : this(value * _TB);

  /// Creates from petabytes (SI, 1000^5) as BigInt.
  BigByteConverter.fromPetaBytes(BigInt value) : this(value * _PB);

  /// Creates from exabytes (SI, 1000^6) as BigInt.
  BigByteConverter.fromExaBytes(BigInt value) : this(value * _EB);

  /// Creates from zettabytes (SI, 1000^7) as BigInt.
  BigByteConverter.fromZettaBytes(BigInt value) : this(value * _ZB);

  /// Creates from yottabytes (SI, 1000^8) as BigInt.
  BigByteConverter.fromYottaBytes(BigInt value) : this(value * _YB);

  // Named constructors for binary units
  /// Creates from kibibytes (IEC, 1024^1) as BigInt.
  BigByteConverter.fromKibiBytes(BigInt value) : this(value * _KIB);

  /// Creates from mebibytes (IEC, 1024^2) as BigInt.
  BigByteConverter.fromMebiBytes(BigInt value) : this(value * _MIB);

  /// Creates from gibibytes (IEC, 1024^3) as BigInt.
  BigByteConverter.fromGibiBytes(BigInt value) : this(value * _GIB);

  /// Creates from tebibytes (IEC, 1024^4) as BigInt.
  BigByteConverter.fromTebiBytes(BigInt value) : this(value * _TIB);

  /// Creates from pebibytes (IEC, 1024^5) as BigInt.
  BigByteConverter.fromPebiBytes(BigInt value) : this(value * _PIB);

  /// Creates from exbibytes (IEC, 1024^6) as BigInt.
  BigByteConverter.fromExbiBytes(BigInt value) : this(value * _EIB);

  /// Creates from zebibytes (IEC, 1024^7) as BigInt.
  BigByteConverter.fromZebiBytes(BigInt value) : this(value * _ZIB);

  /// Creates from yobibytes (IEC, 1024^8) as BigInt.
  BigByteConverter.fromYobiBytes(BigInt value) : this(value * _YIB);

  // Factory constructor for JSON deserialization
  factory BigByteConverter.fromJson(Map<String, dynamic> json) {
    return BigByteConverter(BigInt.parse(json['bytes'] as String));
  }

  // Factory constructor from regular ByteConverter
  factory BigByteConverter.fromByteConverter(ByteConverter converter) {
    final bytes = converter.asBytes();
    return BigByteConverter(BigInt.from(bytes.toInt()));
  }

  // Unit conversion constants (using BigInt)
  static final _KB = BigInt.from(1000);
  static final _MB = _KB * BigInt.from(1000);
  static final _GB = _MB * BigInt.from(1000);
  static final _TB = _GB * BigInt.from(1000);
  static final _PB = _TB * BigInt.from(1000);
  static final _EB = _PB * BigInt.from(1000);
  static final _ZB = _EB * BigInt.from(1000);
  static final _YB = _ZB * BigInt.from(1000);
  static final _RB = _YB * BigInt.from(1000); // Ronnabyte 10^27
  static final _QB = _RB * BigInt.from(1000); // Quettabyte 10^30

  static final _KIB = BigInt.from(1024);
  static final _MIB = _KIB * BigInt.from(1024);
  static final _GIB = _MIB * BigInt.from(1024);
  static final _TIB = _GIB * BigInt.from(1024);
  static final _PIB = _TIB * BigInt.from(1024);
  static final _EIB = _PIB * BigInt.from(1024);
  static final _ZIB = _EIB * BigInt.from(1024);
  static final _YIB = _ZIB * BigInt.from(1024);

  // Storage constants
  static final _SECTOR_SIZE = BigInt.from(512); // Traditional sector size
  static final _BLOCK_SIZE = BigInt.from(4096); // Common filesystem block
  static final _PAGE_SIZE = BigInt.from(4096); // Memory page size
  static final _WORD_SIZE = BigInt.from(8); // 64-bit word

  // Core data
  final BigInt _bytes;
  final BigInt _bits;

  // Storage units
  /// Number of sectors (512 B) rounding up.
  BigInt get sectors => (_bytes + _SECTOR_SIZE - BigInt.one) ~/ _SECTOR_SIZE;

  /// Number of blocks (4096 B) rounding up.
  BigInt get blocks => (_bytes + _BLOCK_SIZE - BigInt.one) ~/ _BLOCK_SIZE;

  /// Number of pages (4096 B) rounding up.
  BigInt get pages => (_bytes + _PAGE_SIZE - BigInt.one) ~/ _PAGE_SIZE;

  /// Number of 64-bit words (8 B) rounding up.
  BigInt get words => (_bytes + _WORD_SIZE - BigInt.one) ~/ _WORD_SIZE;

  // Network rates - return double for practical use
  BigInt get bitsPerSecond => _bits;
  double get kiloBitsPerSecond => _bits.toDouble() / 1000;
  double get megaBitsPerSecond => kiloBitsPerSecond / 1000;
  double get gigaBitsPerSecond => megaBitsPerSecond / 1000;

  // Time-based methods
  /// Estimated duration to transfer this payload at [bitsPerSecond].
  Duration transferTimeAt(double bitsPerSecond) => Duration(
        microseconds: (_bits.toDouble() / bitsPerSecond * 1000000).ceil(),
      );

  /// Estimated duration to download this payload at [bytesPerSecond].
  Duration downloadTimeAt(double bytesPerSecond) => Duration(
        microseconds: (_bytes.toDouble() / bytesPerSecond * 1000000).ceil(),
      );

  // Convenience getters
  bool get isWholeSector => _bytes % _SECTOR_SIZE == BigInt.zero;
  bool get isWholeBlock => _bytes % _BLOCK_SIZE == BigInt.zero;
  bool get isWholePage => _bytes % _PAGE_SIZE == BigInt.zero;
  bool get isWholeWord => _bytes % _WORD_SIZE == BigInt.zero;

  // Unit getters - return double for practical calculations
  /// Exact bytes as BigInt.
  BigInt get asBytes => _bytes;

  /// Exact bits as BigInt.
  BigInt get bits => _bits;

  /// Exact bytes as BigInt (alias of [asBytes]).
  BigInt get bytes => _bytes;

  // Decimal unit getters
  double get kiloBytes => _bytes.toDouble() / _KB.toDouble();
  double get megaBytes => _bytes.toDouble() / _MB.toDouble();
  double get gigaBytes => _bytes.toDouble() / _GB.toDouble();
  double get teraBytes => _bytes.toDouble() / _TB.toDouble();
  double get petaBytes => _bytes.toDouble() / _PB.toDouble();
  double get exaBytes => _bytes.toDouble() / _EB.toDouble();
  double get zettaBytes => _bytes.toDouble() / _ZB.toDouble();
  double get yottaBytes => _bytes.toDouble() / _YB.toDouble();
  double get ronnaBytes => _bytes.toDouble() / _RB.toDouble();
  double get quettaBytes => _bytes.toDouble() / _QB.toDouble();

  // Binary unit getters
  double get kibiBytes => _bytes.toDouble() / _KIB.toDouble();
  double get mebiBytes => _bytes.toDouble() / _MIB.toDouble();
  double get gibiBytes => _bytes.toDouble() / _GIB.toDouble();
  double get tebiBytes => _bytes.toDouble() / _TIB.toDouble();
  double get pebiBytes => _bytes.toDouble() / _PIB.toDouble();
  double get exbiBytes => _bytes.toDouble() / _EIB.toDouble();
  double get zebiBytes => _bytes.toDouble() / _ZIB.toDouble();
  double get yobiBytes => _bytes.toDouble() / _YIB.toDouble();

  // Exact BigInt unit getters for precise calculations
  BigInt get kiloBytesExact => _bytes ~/ _KB;
  BigInt get megaBytesExact => _bytes ~/ _MB;
  BigInt get gigaBytesExact => _bytes ~/ _GB;
  BigInt get teraBytesExact => _bytes ~/ _TB;
  BigInt get petaBytesExact => _bytes ~/ _PB;
  BigInt get exaBytesExact => _bytes ~/ _EB;
  BigInt get zettaBytesExact => _bytes ~/ _ZB;
  BigInt get yottaBytesExact => _bytes ~/ _YB;
  BigInt get ronnaBytesExact => _bytes ~/ _RB;
  BigInt get quettaBytesExact => _bytes ~/ _QB;

  BigInt get kibiBytesExact => _bytes ~/ _KIB;
  BigInt get mebiBytesExact => _bytes ~/ _MIB;
  BigInt get gibiBytesExact => _bytes ~/ _GIB;
  BigInt get tebiBytesExact => _bytes ~/ _TIB;
  BigInt get pebiBytesExact => _bytes ~/ _PIB;
  BigInt get exbiBytesExact => _bytes ~/ _EIB;
  BigInt get zebiBytesExact => _bytes ~/ _ZIB;
  BigInt get yobiBytesExact => _bytes ~/ _YIB;

  // Math operations
  BigByteConverter operator +(BigByteConverter other) {
    return BigByteConverter._(
      _bytes + other._bytes,
      _bits + other._bits,
    );
  }

  BigByteConverter operator -(BigByteConverter other) {
    return BigByteConverter._(
      _bytes - other._bytes,
      _bits - other._bits,
    );
  }

  BigByteConverter operator *(BigInt factor) =>
      BigByteConverter(_bytes * factor);

  BigByteConverter operator ~/(BigInt divisor) =>
      BigByteConverter(_bytes ~/ divisor);

  // Comparison operators
  bool operator >(BigByteConverter other) => _bits > other._bits;
  bool operator <(BigByteConverter other) => _bits < other._bits;
  bool operator <=(BigByteConverter other) => _bits <= other._bits;
  bool operator >=(BigByteConverter other) => _bits >= other._bits;

  // Rounding methods
  BigByteConverter roundToSector() => BigByteConverter(sectors * _SECTOR_SIZE);
  BigByteConverter roundToBlock() => BigByteConverter(blocks * _BLOCK_SIZE);
  BigByteConverter roundToPage() => BigByteConverter(pages * _PAGE_SIZE);
  BigByteConverter roundToWord() => BigByteConverter(words * _WORD_SIZE);

  BigByteConverter roundToProfile(
    StorageProfile profile, {
    String? alignment,
    RoundingMode? rounding,
  }) {
    final resolved = profile.resolve(alignment);
    final blockSize = BigInt.from(resolved.blockSizeBytes);
    final mode = profile.roundingFor(
      alignment: alignment,
      override: rounding,
    );
    final remainder = _bytes % blockSize;
    if (remainder == BigInt.zero) {
      return BigByteConverter(_bytes);
    }
    final quotient = _bytes ~/ blockSize;
    final floorAligned = BigByteConverter(blockSize * quotient);
    switch (mode) {
      case RoundingMode.floor:
        return floorAligned;
      case RoundingMode.ceil:
        return BigByteConverter(blockSize * (quotient + BigInt.one));
      case RoundingMode.round:
        final half = blockSize >> 1;
        final shouldRoundUp = remainder >= half;
        return shouldRoundUp
            ? BigByteConverter(blockSize * (quotient + BigInt.one))
            : floorAligned;
    }
  }

  BigByteConverter alignmentSlack(
    StorageProfile profile, {
    String? alignment,
    RoundingMode? rounding,
  }) {
    final aligned = roundToProfile(
      profile,
      alignment: alignment,
      rounding: rounding,
    );
    final diff = aligned._bytes - _bytes;
    if (diff <= BigInt.zero) {
      return BigByteConverter(BigInt.zero);
    }
    // Return slack expressed as an aligned quantity so that it satisfies alignment checks
    // (i.e., a multiple of the requested block size).
    final blockSize = BigInt.from(profile.blockSizeBytes(alignment));
    final slackBlocks = (diff + blockSize - BigInt.one) ~/ blockSize;
    final alignedSlackBytes = slackBlocks * blockSize;
    return BigByteConverter(alignedSlackBytes);
  }

  bool isAligned(
    StorageProfile profile, {
    String? alignment,
  }) {
    final blockSize = BigInt.from(profile.blockSizeBytes(alignment));
    if (blockSize == BigInt.zero) return false;
    return _bytes % blockSize == BigInt.zero;
  }

  @override
  int compareTo(BigByteConverter other) => _bits.compareTo(other._bits);

  // String formatting
  String toHumanReadable(BigSizeUnit unit, {int precision = 2}) {
    final value = _convertToUnit(unit);
    return '${_withPrecision(value, precision)}${_getUnitString(unit)}';
  }

  /// Auto humanize with SI/IEC/JEDEC using helper
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
      _bytes.toDouble(),
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

  /// Compound mixed-unit formatting for Big values.
  String toHumanReadableCompound(
      {CompoundFormatOptions options = const CompoundFormatOptions()}) {
    return formatCompound(_bytes.toDouble(), options);
  }

  double _convertToUnit(BigSizeUnit unit) => switch (unit) {
        BigSizeUnit.QB => quettaBytes,
        BigSizeUnit.RB => ronnaBytes,
        BigSizeUnit.YB => yottaBytes,
        BigSizeUnit.ZB => zettaBytes,
        BigSizeUnit.EB => exaBytes,
        BigSizeUnit.PB => petaBytes,
        BigSizeUnit.TB => teraBytes,
        BigSizeUnit.GB => gigaBytes,
        BigSizeUnit.MB => megaBytes,
        BigSizeUnit.KB => kiloBytes,
        BigSizeUnit.B => _bytes.toDouble(),
      };

  String _getUnitString(BigSizeUnit unit) => switch (unit) {
        BigSizeUnit.QB => ' QB',
        BigSizeUnit.RB => ' RB',
        BigSizeUnit.YB => ' YB',
        BigSizeUnit.ZB => ' ZB',
        BigSizeUnit.EB => ' EB',
        BigSizeUnit.PB => ' PB',
        BigSizeUnit.TB => ' TB',
        BigSizeUnit.GB => ' GB',
        BigSizeUnit.MB => ' MB',
        BigSizeUnit.KB => ' KB',
        BigSizeUnit.B => ' B',
      };

  BigSizeUnit _selectBestUnit() {
    if (_bytes >= _QB) return BigSizeUnit.QB;
    if (_bytes >= _RB) return BigSizeUnit.RB;
    if (_bytes >= _YB) return BigSizeUnit.YB;
    if (_bytes >= _ZB) return BigSizeUnit.ZB;
    if (_bytes >= _EB) return BigSizeUnit.EB;
    if (_bytes >= _PB) return BigSizeUnit.PB;
    if (_bytes >= _TB) return BigSizeUnit.TB;
    if (_bytes >= _GB) return BigSizeUnit.GB;
    if (_bytes >= _MB) return BigSizeUnit.MB;
    if (_bytes >= _KB) return BigSizeUnit.KB;
    return BigSizeUnit.B;
  }

  String _withPrecision(double value, int precision) {
    if (precision < 0) return value.toString();
    // Handle whole numbers without decimal places
    if (value % 1 == 0) return value.toInt().toString();
    final factor = math.pow(10, precision);
    final result = (value * factor).round() / factor;
    return result.toString();
  }

  // Override Object methods
  @override
  String toString() {
    final unit = _selectBestUnit();
    final value = _convertToUnit(unit);
    return '${_withPrecision(value, 2)}${_getUnitString(unit)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BigByteConverter && _bits == other._bits;

  @override
  int get hashCode => _bits.hashCode;

  // JSON serialization
  Map<String, dynamic> toJson() => {'bytes': _bytes.toString()};

  // Conversion to regular ByteConverter (may lose precision)
  ByteConverter toByteConverter() {
    return ByteConverter(_bytes.toDouble());
  }

  String formatWith(String pattern,
      {ByteFormatOptions options = const ByteFormatOptions()}) {
    final res = humanize(
      _bytes.toDouble(),
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
    // Derive value by reformatting with no spacer and forced unit
    final compact = humanize(
      _bytes.toDouble(),
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

    final numericRe = RegExp(r'0[#0\.,]*');
    var out = pattern.replaceAll('U', fullWord()).replaceAll('u', unitSymbol);
    final signChar = options.signed
        ? (_bytes > BigInt.zero ? '+' : (_bytes < BigInt.zero ? '-' : ' '))
        : '';
    out = out.replaceAll('S', signChar);
    out = out.replaceAll(numericRe, valuePart);
    return out;
  }

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

  ({int value, String symbol}) largestWholeNumber(
      {ByteStandard standard = ByteStandard.si, bool useBytes = true}) {
    return toByteConverter()
        .largestWholeNumber(standard: standard, useBytes: useBytes);
  }

  /// Parses a size string into BigByteConverter using the given standard.
  /// If the parsed number is fractional, rounding is applied as per mode.
  static BigByteConverter parse(
    String input, {
    ByteStandard standard = ByteStandard.si,
    RoundingMode rounding = RoundingMode.round,
    bool strictBits = false,
  }) {
    // Fast-path: integer numeric literal with known large units -> use BigInt math to avoid precision loss
    final simple = RegExp(r'^\s*([+-]?\d+)\s*([A-Za-z]+)?\s*$');
    final m = simple.firstMatch(input);
    if (m != null) {
      final numStr = m.group(1)!;
      final unitStr = (m.group(2) ?? '').trim();
      try {
        final n = BigInt.parse(numStr);
        if (unitStr.isEmpty || unitStr.toUpperCase() == 'B') {
          return BigByteConverter(n);
        }
        final u = unitStr;
        final isBit = u.isNotEmpty && u[u.length - 1] == 'b' && u != 'B';
        final upper = u.toUpperCase();
        // Bytes base maps (SI/IEC/JEDEC)
        final Map<String, BigInt> byteBase = {
          // SI
          'KB': BigInt.from(10).pow(3),
          'MB': BigInt.from(10).pow(6),
          'GB': BigInt.from(10).pow(9),
          'TB': BigInt.from(10).pow(12),
          'PB': BigInt.from(10).pow(15),
          'EB': BigInt.from(10).pow(18),
          'ZB': BigInt.from(10).pow(21),
          'YB': BigInt.from(10).pow(24),
          'RB': BigInt.from(10).pow(27),
          'QB': BigInt.from(10).pow(30),
          // IEC
          'KIB': BigInt.from(1024).pow(1),
          'MIB': BigInt.from(1024).pow(2),
          'GIB': BigInt.from(1024).pow(3),
          'TIB': BigInt.from(1024).pow(4),
          'PIB': BigInt.from(1024).pow(5),
          'EIB': BigInt.from(1024).pow(6),
          'ZIB': BigInt.from(1024).pow(7),
          'YIB': BigInt.from(1024).pow(8),
        };
        // JEDEC (KB/MB/GB/TB as 1024^n). Only when standard == jedec or explicit expectation.
        final Map<String, BigInt> jedecBase = {
          'KB': BigInt.from(1024).pow(1),
          'MB': BigInt.from(1024).pow(2),
          'GB': BigInt.from(1024).pow(3),
          'TB': BigInt.from(1024).pow(4),
        };
        // Bits base maps (SI/IEC)
        final Map<String, BigInt> bitBase = {
          'KB': BigInt.from(10).pow(3) ~/ BigInt.from(8),
          'MB': BigInt.from(10).pow(6) ~/ BigInt.from(8),
          'GB': BigInt.from(10).pow(9) ~/ BigInt.from(8),
          'TB': BigInt.from(10).pow(12) ~/ BigInt.from(8),
          'PB': BigInt.from(10).pow(15) ~/ BigInt.from(8),
          'EB': BigInt.from(10).pow(18) ~/ BigInt.from(8),
          'ZB': BigInt.from(10).pow(21) ~/ BigInt.from(8),
          'YB': BigInt.from(10).pow(24) ~/ BigInt.from(8),
          'RB': BigInt.from(10).pow(27) ~/ BigInt.from(8),
          'QB': BigInt.from(10).pow(30) ~/ BigInt.from(8),
          'KIB': BigInt.from(1024).pow(1) ~/ BigInt.from(8),
          'MIB': BigInt.from(1024).pow(2) ~/ BigInt.from(8),
          'GIB': BigInt.from(1024).pow(3) ~/ BigInt.from(8),
          'TIB': BigInt.from(1024).pow(4) ~/ BigInt.from(8),
          'PIB': BigInt.from(1024).pow(5) ~/ BigInt.from(8),
          'EIB': BigInt.from(1024).pow(6) ~/ BigInt.from(8),
          'ZIB': BigInt.from(1024).pow(7) ~/ BigInt.from(8),
          'YIB': BigInt.from(1024).pow(8) ~/ BigInt.from(8),
        };

        BigInt? base;
        if (isBit) {
          final key = upper.endsWith('B')
              ? upper.substring(0, upper.length - 1)
              : upper;
          base = bitBase[key];
        } else {
          base = byteBase[upper];
          if (base == null && standard == ByteStandard.jedec) {
            base = jedecBase[upper];
          }
        }

        if (base != null) {
          return BigByteConverter(n * base);
        }
      } catch (_) {
        // fall through to generic path
      }
    }

    // Generic path with double math and rounding
    final r =
        parseSizeBig(input: input, standard: standard, strictBits: strictBits);
    final bytes = r.valueInBytes;
    BigInt result;
    switch (rounding) {
      case RoundingMode.floor:
        result = BigInt.from(bytes.floor());
        break;
      case RoundingMode.ceil:
        result = BigInt.from(bytes.ceil());
        break;
      case RoundingMode.round:
        result = BigInt.from(bytes.round());
        break;
    }
    return BigByteConverter(result);
  }

  /// Safe parsing variant that returns diagnostics instead of throwing exceptions.
  static ParseResult<BigByteConverter> tryParse(
    String input, {
    ByteStandard standard = ByteStandard.si,
    RoundingMode rounding = RoundingMode.round,
    bool strictBits = false,
  }) {
    try {
      final r = parseSizeBig(
          input: input, standard: standard, strictBits: strictBits);
      if (r.valueInBytes.isNaN || r.valueInBytes.isInfinite) {
        throw FormatException('Invalid numeric value in input: $input');
      }
      BigInt bytes;
      switch (rounding) {
        case RoundingMode.floor:
          bytes = BigInt.from(r.valueInBytes.floor());
          break;
        case RoundingMode.ceil:
          bytes = BigInt.from(r.valueInBytes.ceil());
          break;
        case RoundingMode.round:
          bytes = BigInt.from(r.valueInBytes.round());
          break;
      }
      if (bytes.isNegative) {
        return ParseResult.failure(
          originalInput: input,
          error: const ParseError(message: 'Bytes cannot be negative'),
          normalizedInput: r.normalizedInput,
        );
      }
      final value = BigByteConverter(bytes);
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
}
