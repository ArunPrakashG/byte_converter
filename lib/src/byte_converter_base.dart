import 'dart:math' as math;

import 'byte_enums.dart';

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

  @override
  int compareTo(ByteConverter other) => _bits.compareTo(other._bits);

  // Optimized string handling
  String _calculateString() {
    final unit = _selectBestUnit();
    final value = _convertToUnit(unit);
    return '${_withPrecision(value, 2)}${_units[unit]}';
  }

  SizeUnit _selectBestUnit() {
    if (_bytes >= _TB) return SizeUnit.TB;
    if (_bytes >= _GB) return SizeUnit.GB;
    if (_bytes >= _MB) return SizeUnit.MB;
    if (_bytes >= _KB) return SizeUnit.KB;
    return SizeUnit.B;
  }

  double _convertToUnit(SizeUnit unit) => switch (unit) {
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
}
