import 'dart:math' as math;

import '_parsing.dart';
import 'byte_converter_base.dart';
import 'byte_enums.dart';
// ignore_for_file: non_constant_identifier_names, avoid_equals_and_hash_code_on_mutable_classes, prefer_constructors_over_static_methods
import 'format_options.dart';
import 'parse_result.dart';
import 'storage_profile.dart';

/// High-performance byte unit converter using BigInt for arbitrary precision
class BigByteConverter implements Comparable<BigByteConverter> {
  BigByteConverter(BigInt bytes) : this._(bytes, bytes * BigInt.from(8));

  // Private constructor
  BigByteConverter._(this._bytes, this._bits) {
    if (_bytes.isNegative) throw ArgumentError('Bytes cannot be negative');
  }

  factory BigByteConverter.withBits(BigInt bits) {
    if (bits.isNegative) throw ArgumentError('Bits cannot be negative');
    return BigByteConverter._(bits ~/ BigInt.from(8), bits);
  }

  // Named constructors for decimal units
  BigByteConverter.fromKiloBytes(BigInt value) : this(value * _KB);
  BigByteConverter.fromMegaBytes(BigInt value) : this(value * _MB);
  BigByteConverter.fromGigaBytes(BigInt value) : this(value * _GB);
  BigByteConverter.fromTeraBytes(BigInt value) : this(value * _TB);
  BigByteConverter.fromPetaBytes(BigInt value) : this(value * _PB);
  BigByteConverter.fromExaBytes(BigInt value) : this(value * _EB);
  BigByteConverter.fromZettaBytes(BigInt value) : this(value * _ZB);
  BigByteConverter.fromYottaBytes(BigInt value) : this(value * _YB);

  // Named constructors for binary units
  BigByteConverter.fromKibiBytes(BigInt value) : this(value * _KIB);
  BigByteConverter.fromMebiBytes(BigInt value) : this(value * _MIB);
  BigByteConverter.fromGibiBytes(BigInt value) : this(value * _GIB);
  BigByteConverter.fromTebiBytes(BigInt value) : this(value * _TIB);
  BigByteConverter.fromPebiBytes(BigInt value) : this(value * _PIB);
  BigByteConverter.fromExbiBytes(BigInt value) : this(value * _EIB);
  BigByteConverter.fromZebiBytes(BigInt value) : this(value * _ZIB);
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
  BigInt get sectors => (_bytes + _SECTOR_SIZE - BigInt.one) ~/ _SECTOR_SIZE;
  BigInt get blocks => (_bytes + _BLOCK_SIZE - BigInt.one) ~/ _BLOCK_SIZE;
  BigInt get pages => (_bytes + _PAGE_SIZE - BigInt.one) ~/ _PAGE_SIZE;
  BigInt get words => (_bytes + _WORD_SIZE - BigInt.one) ~/ _WORD_SIZE;

  // Network rates - return double for practical use
  BigInt get bitsPerSecond => _bits;
  double get kiloBitsPerSecond => _bits.toDouble() / 1000;
  double get megaBitsPerSecond => kiloBitsPerSecond / 1000;
  double get gigaBitsPerSecond => megaBitsPerSecond / 1000;

  // Time-based methods
  Duration transferTimeAt(double bitsPerSecond) => Duration(
        microseconds: (_bits.toDouble() / bitsPerSecond * 1000000).ceil(),
      );

  Duration downloadTimeAt(double bytesPerSecond) => Duration(
        microseconds: (_bytes.toDouble() / bytesPerSecond * 1000000).ceil(),
      );

  // Convenience getters
  bool get isWholeSector => _bytes % _SECTOR_SIZE == BigInt.zero;
  bool get isWholeBlock => _bytes % _BLOCK_SIZE == BigInt.zero;
  bool get isWholePage => _bytes % _PAGE_SIZE == BigInt.zero;
  bool get isWholeWord => _bytes % _WORD_SIZE == BigInt.zero;

  // Unit getters - return double for practical calculations
  BigInt get asBytes => _bytes;
  BigInt get bits => _bits;
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
    return BigByteConverter(diff);
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
    final res = humanize(
      _bytes.toDouble(),
      HumanizeOptions(
        standard: standard,
        useBits: useBits,
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
    return res.text;
  }

  /// Convenience overload using ByteFormatOptions.
  String toHumanReadableAutoWith(ByteFormatOptions options) =>
      toHumanReadableAuto(
        standard: options.standard,
        useBits: !options.useBytes,
        precision: options.precision,
        showSpace: options.showSpace,
        fullForm: options.fullForm,
        fullForms: options.fullForms,
        separator: options.separator,
        spacer: options.spacer,
        minimumFractionDigits: options.minimumFractionDigits,
        maximumFractionDigits: options.maximumFractionDigits,
        signed: options.signed,
        forceUnit: options.forceUnit,
        locale: options.locale,
        useGrouping: options.useGrouping,
      );

  double _convertToUnit(BigSizeUnit unit) => switch (unit) {
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

  /// Parses a size string into BigByteConverter using the given standard.
  /// If the parsed number is fractional, rounding is applied as per mode.
  static BigByteConverter parse(
    String input, {
    ByteStandard standard = ByteStandard.si,
    RoundingMode rounding = RoundingMode.round,
  }) {
    final r = parseSizeBig(input: input, standard: standard);
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
  }) {
    try {
      final r = parseSizeBig(input: input, standard: standard);
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
