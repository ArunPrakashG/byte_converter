import 'dart:math' as math;

/// SI (International System of Units) number formatting utilities.
///
/// Converts large or small numbers to human-readable format using SI prefixes.
/// Useful for generic large number display beyond just bytes.
///
/// Example:
/// ```dart
/// print(SINumber.humanize(1500000));     // "1.5M"
/// print(SINumber.humanize(0.000001));    // "1µ"
/// print(SINumber.humanize(1234567890));  // "1.23G"
/// ```
abstract class SINumber {
  SINumber._();

  /// SI prefixes for large numbers (positive exponents).
  static const Map<int, String> _largePrefixes = {
    24: 'Y', // yotta
    21: 'Z', // zetta
    18: 'E', // exa
    15: 'P', // peta
    12: 'T', // tera
    9: 'G', // giga
    6: 'M', // mega
    3: 'k', // kilo
    0: '', // base
  };

  /// SI prefixes for small numbers (negative exponents).
  static const Map<int, String> _smallPrefixes = {
    -3: 'm', // milli
    -6: 'µ', // micro
    -9: 'n', // nano
    -12: 'p', // pico
    -15: 'f', // femto
    -18: 'a', // atto
    -21: 'z', // zepto
    -24: 'y', // yocto
  };

  /// Full names for SI prefixes.
  static const Map<String, String> _prefixNames = {
    'Y': 'yotta',
    'Z': 'zetta',
    'E': 'exa',
    'P': 'peta',
    'T': 'tera',
    'G': 'giga',
    'M': 'mega',
    'k': 'kilo',
    '': '',
    'm': 'milli',
    'µ': 'micro',
    'n': 'nano',
    'p': 'pico',
    'f': 'femto',
    'a': 'atto',
    'z': 'zepto',
    'y': 'yocto',
  };

  /// Converts a number to SI-prefixed format.
  ///
  /// Examples:
  /// - 1500 → "1.5k"
  /// - 1500000 → "1.5M"
  /// - 0.001 → "1m"
  /// - 0.000001 → "1µ"
  ///
  /// [precision] controls decimal places (default: 2).
  /// [unit] is an optional suffix (e.g., "Hz", "W").
  /// [space] adds space before unit/prefix.
  static String humanize(
    num value, {
    int precision = 2,
    String unit = '',
    bool space = false,
  }) {
    if (value == 0) return '0${space ? ' ' : ''}$unit';

    final isNegative = value < 0;
    final absValue = value.abs().toDouble();

    // Find appropriate prefix
    final exponent = _findExponent(absValue);
    final prefix = _getPrefix(exponent);
    final scaled = absValue / math.pow(10, exponent);

    // Format the number
    String formatted;
    if (scaled == scaled.roundToDouble()) {
      formatted = scaled.toInt().toString();
    } else {
      formatted = scaled.toStringAsFixed(precision);
      // Remove trailing zeros
      formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
    }

    final sign = isNegative ? '-' : '';
    final spacer = space ? ' ' : '';

    return '$sign$formatted$spacer$prefix$unit';
  }

  /// Converts a number to SI-prefixed format with full prefix names.
  ///
  /// Example: 1500000 → "1.5 mega"
  static String humanizeFull(
    num value, {
    int precision = 2,
    String unit = '',
  }) {
    if (value == 0) return '0 $unit'.trim();

    final isNegative = value < 0;
    final absValue = value.abs().toDouble();

    final exponent = _findExponent(absValue);
    final prefix = _getPrefix(exponent);
    final prefixName = _prefixNames[prefix] ?? '';
    final scaled = absValue / math.pow(10, exponent);

    String formatted;
    if (scaled == scaled.roundToDouble()) {
      formatted = scaled.toInt().toString();
    } else {
      formatted = scaled.toStringAsFixed(precision);
      formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
    }

    final sign = isNegative ? '-' : '';
    final unitPart = unit.isNotEmpty ? ' $unit' : '';
    final prefixPart = prefixName.isNotEmpty ? prefixName : '';

    return '$sign$formatted $prefixPart$unitPart'.trim();
  }

  /// Parses an SI-prefixed string back to a number.
  ///
  /// Example: "1.5M" → 1500000.0
  static double? parse(String input) {
    final cleaned = input.trim();
    if (cleaned.isEmpty) return null;

    // Try to extract number and prefix
    final match =
        RegExp(r'^(-?\d+\.?\d*)\s*([YZEPTGMkmµnpfazy]?)').firstMatch(cleaned);
    if (match == null) return null;

    final numberStr = match.group(1);
    final prefix = match.group(2) ?? '';

    final number = double.tryParse(numberStr ?? '');
    if (number == null) return null;

    final exponent = _getExponent(prefix);
    return number * math.pow(10, exponent);
  }

  /// Formats a number in engineering notation (exponents in multiples of 3).
  ///
  /// Example: 1500 → "1.5 × 10³"
  static String engineering(
    num value, {
    int precision = 2,
    bool unicode = true,
  }) {
    if (value == 0) return '0';

    final isNegative = value < 0;
    final absValue = value.abs().toDouble();

    final exponent = _findExponent(absValue);
    final scaled = absValue / math.pow(10, exponent);

    String formatted;
    if (scaled == scaled.roundToDouble()) {
      formatted = scaled.toInt().toString();
    } else {
      formatted = scaled.toStringAsFixed(precision);
      formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
    }

    final sign = isNegative ? '-' : '';

    if (exponent == 0) {
      return '$sign$formatted';
    }

    if (unicode) {
      return '$sign$formatted × 10${_toSuperscript(exponent)}';
    } else {
      return '$sign${formatted}e$exponent';
    }
  }

  /// Converts a percentage to basis points (bps).
  ///
  /// Example: 0.25 (25%) → "2500 bps"
  static String toBasisPoints(double percentage) {
    final bps = (percentage * 10000).round();
    return '$bps bps';
  }

  /// Formats a ratio as a percentage with SI prefix if needed.
  ///
  /// Example: 0.0015 → "0.15%" or "1.5‰" (per mille)
  static String toPercentage(
    double ratio, {
    int precision = 2,
    bool usePerMille = false,
  }) {
    if (usePerMille && ratio < 0.01) {
      final perMille = ratio * 1000;
      return '${perMille.toStringAsFixed(precision)}‰';
    }

    final percentage = ratio * 100;
    return '${percentage.toStringAsFixed(precision)}%';
  }

  // Helper methods

  static int _findExponent(double value) {
    if (value == 0) return 0;

    final log10 = math.log(value) / math.ln10;
    int exponent = (log10 / 3).floor() * 3;

    // Clamp to valid SI prefix range
    if (exponent > 24) exponent = 24;
    if (exponent < -24) exponent = -24;

    return exponent;
  }

  static String _getPrefix(int exponent) {
    if (_largePrefixes.containsKey(exponent)) {
      return _largePrefixes[exponent]!;
    }
    if (_smallPrefixes.containsKey(exponent)) {
      return _smallPrefixes[exponent]!;
    }
    return '';
  }

  static int _getExponent(String prefix) {
    for (final entry in _largePrefixes.entries) {
      if (entry.value == prefix) return entry.key;
    }
    for (final entry in _smallPrefixes.entries) {
      if (entry.value == prefix) return entry.key;
    }
    return 0;
  }

  static String _toSuperscript(int number) {
    const superscripts = {
      '-': '⁻',
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
    };

    return number.toString().split('').map((c) => superscripts[c] ?? c).join();
  }
}

/// Extension for SI number formatting on num types.
extension SINumberExtension on num {
  /// Converts this number to SI-prefixed format.
  ///
  /// Example: `1500000.si` returns "1.5M"
  String get si => SINumber.humanize(this);

  /// Converts this number to SI format with specified options.
  String toSI({int precision = 2, String unit = '', bool space = false}) {
    return SINumber.humanize(this,
        precision: precision, unit: unit, space: space);
  }

  /// Converts this number to engineering notation.
  String get engineering => SINumber.engineering(this);
}
