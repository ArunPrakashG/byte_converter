import 'dart:math' as math;

import '../byte_converter_base.dart';
import '../byte_enums.dart';

/// Provides structured output formats for programmatic use.
///
/// Access via the `output` extension property on [ByteConverter]:
/// ```dart
/// final size = ByteConverter.fromKB(1536);
/// print(size.output.asArray);   // [1.5, 'MB']
/// print(size.output.asTuple);   // (1.5, 'MB')
/// print(size.output.asMap);     // {'value': 1.5, 'unit': 'MB', 'standard': 'SI'}
/// print(size.output.exponent);  // 6
/// ```
class ByteOutputFormats {
  /// Creates output formats for the given byte value.
  const ByteOutputFormats(this._bytes, {this.standard = ByteStandard.si});

  final double _bytes;

  /// The byte standard to use for unit calculations (SI or IEC).
  final ByteStandard standard;

  // Unit thresholds for SI
  static const _kb = 1000.0;
  static const _mb = _kb * 1000;
  static const _gb = _mb * 1000;
  static const _tb = _gb * 1000;
  static const _pb = _tb * 1000;

  // Unit thresholds for IEC
  static const _kib = 1024.0;
  static const _mib = _kib * 1024;
  static const _gib = _mib * 1024;
  static const _tib = _gib * 1024;
  static const _pib = _tib * 1024;

  /// Returns the size as a list: [value, unit].
  ///
  /// Example: `[1.5, 'MB']`
  List<dynamic> get asArray {
    final (value, unit) = _bestUnit();
    return [value, unit];
  }

  /// Returns the size as a Dart 3 record: (value, unit).
  ///
  /// Example: `(1.5, 'MB')`
  (double, String) get asTuple {
    final (value, unit) = _bestUnit();
    return (value, unit);
  }

  /// Returns the size as a map with metadata.
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'value': 1.5,
  ///   'unit': 'MB',
  ///   'standard': 'SI',
  ///   'bytes': 1500000,
  ///   'bits': 12000000
  /// }
  /// ```
  Map<String, dynamic> get asMap {
    final (value, unit) = _bestUnit();
    return {
      'value': value,
      'unit': unit,
      'standard': standard.name.toUpperCase(),
      'bytes': _bytes,
      'bits': (_bytes * 8).round(),
    };
  }

  /// Returns the SI exponent (power of 10) for the byte value.
  ///
  /// Examples:
  /// - KB (10³) → 3
  /// - MB (10⁶) → 6
  /// - GB (10⁹) → 9
  ///
  /// For IEC standard, returns binary exponent (power of 2).
  int get exponent {
    if (_bytes == 0) return 0;
    if (_bytes < 1) return 0;

    if (standard == ByteStandard.iec) {
      // Binary exponent
      return (math.log(_bytes) / math.ln2).floor();
    }

    // SI decimal exponent (power of 10)
    return (math.log(_bytes) / math.ln10).floor();
  }

  /// Returns the unit exponent level (0 for B, 1 for KB, 2 for MB, etc.).
  ///
  /// This is useful for sorting or grouping by magnitude.
  int get unitLevel {
    final base = standard == ByteStandard.iec ? 1024.0 : 1000.0;
    if (_bytes == 0) return 0;
    if (_bytes < base) return 0;
    return (math.log(_bytes) / math.log(base)).floor();
  }

  /// Returns raw bytes as a BigInt for precision operations.
  BigInt get asBigInt => BigInt.from(_bytes.round());

  /// Returns the size formatted for JSON serialization.
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'bytes': 1500000,
  ///   'formatted': '1.5 MB',
  ///   'unit': 'MB',
  ///   'value': 1.5
  /// }
  /// ```
  Map<String, dynamic> get asJson {
    final (value, unit) = _bestUnit();
    final formatted =
        value == value.round() ? '${value.round()} $unit' : '$value $unit';
    return {
      'bytes': _bytes.round(),
      'formatted': formatted,
      'unit': unit,
      'value': value,
    };
  }

  /// Returns the raw byte count as an integer.
  int get asInt => _bytes.round();

  /// Returns the raw byte count as a double.
  double get asDouble => _bytes;

  // Helper to determine best unit based on standard
  (double value, String unit) _bestUnit() {
    if (standard == ByteStandard.iec) {
      return _bestUnitIec();
    }
    return _bestUnitSi();
  }

  (double value, String unit) _bestUnitSi() {
    if (_bytes >= _pb) return (_roundValue(_bytes / _pb), 'PB');
    if (_bytes >= _tb) return (_roundValue(_bytes / _tb), 'TB');
    if (_bytes >= _gb) return (_roundValue(_bytes / _gb), 'GB');
    if (_bytes >= _mb) return (_roundValue(_bytes / _mb), 'MB');
    if (_bytes >= _kb) return (_roundValue(_bytes / _kb), 'KB');
    return (_bytes, 'B');
  }

  (double value, String unit) _bestUnitIec() {
    if (_bytes >= _pib) return (_roundValue(_bytes / _pib), 'PiB');
    if (_bytes >= _tib) return (_roundValue(_bytes / _tib), 'TiB');
    if (_bytes >= _gib) return (_roundValue(_bytes / _gib), 'GiB');
    if (_bytes >= _mib) return (_roundValue(_bytes / _mib), 'MiB');
    if (_bytes >= _kib) return (_roundValue(_bytes / _kib), 'KiB');
    return (_bytes, 'B');
  }

  // Round to 2 decimal places for clean output
  double _roundValue(double value) {
    return (value * 100).round() / 100;
  }
}
