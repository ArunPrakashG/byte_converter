import '../byte_converter_base.dart';

/// Provides accessibility-friendly output formats for byte values.
///
/// Access via the `accessibility` extension property on [ByteConverter]:
/// ```dart
/// final size = ByteConverter.fromMB(1.5);
/// print(size.accessibility.screenReader);  // "one point five megabytes"
/// print(size.accessibility.ariaLabel);     // "File size: one point five megabytes"
/// ```
class ByteAccessibility {
  /// Creates accessibility utilities for the given byte value.
  const ByteAccessibility(this._bytes);

  final double _bytes;

  // Unit thresholds for SI
  static const _kb = 1000.0;
  static const _mb = _kb * 1000;
  static const _gb = _mb * 1000;
  static const _tb = _gb * 1000;
  static const _pb = _tb * 1000;

  // Number words (0-19)
  static const _ones = [
    'zero',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
  ];

  // Tens words
  static const _tens = [
    '',
    '',
    'twenty',
    'thirty',
    'forty',
    'fifty',
    'sixty',
    'seventy',
    'eighty',
    'ninety',
  ];

  // Scale words
  static const _scales = [
    '',
    'thousand',
    'million',
    'billion',
    'trillion',
  ];

  /// Returns a screen reader-friendly representation of the size.
  ///
  /// Numbers are spelled out, units are in full words.
  ///
  /// Examples:
  /// - "one point five megabytes"
  /// - "two hundred thirty four kilobytes"
  /// - "one byte"
  /// - "zero bytes"
  ///
  /// Set [locale] for localized output (future support).
  String screenReader({String? locale}) {
    if (_bytes == 0) return 'zero bytes';

    final (value, unit) = _bestUnit();
    final valueInWords = _numberToWords(value);
    final unitWord = _unitToWord(unit, value == 1);

    return '$valueInWords $unitWord';
  }

  /// Returns an ARIA label suitable for HTML aria-label attributes.
  ///
  /// Examples:
  /// - "File size: one point five megabytes"
  /// - "Storage: two gigabytes"
  ///
  /// Set [prefix] to customize the label prefix (default: "File size").
  String ariaLabel({String prefix = 'File size', String? locale}) {
    return '$prefix: ${screenReader(locale: locale)}';
  }

  /// Returns a verbose description suitable for voice interfaces.
  ///
  /// Examples:
  /// - "This file is one point five megabytes in size"
  /// - "The storage used is two gigabytes"
  String voiceDescription({String context = 'This file', String? locale}) {
    return '$context is ${screenReader(locale: locale)} in size';
  }

  /// Returns a summary suitable for screen reader announcements.
  ///
  /// Example:
  /// - "Size: 1.5 MB, one point five megabytes"
  String summary({String? locale}) {
    final (value, unit) = _bestUnit();
    final shortForm =
        value == value.round() ? '${value.round()} $unit' : '$value $unit';
    return 'Size: $shortForm, ${screenReader(locale: locale)}';
  }

  // Convert number to words
  String _numberToWords(double value) {
    if (value == 0) return 'zero';

    // Handle the integer part
    final intPart = value.floor();
    final fracPart = value - intPart;

    String result = '';

    if (intPart > 0) {
      result = _intToWords(intPart);
    } else {
      result = 'zero';
    }

    // Handle decimal part
    if (fracPart > 0.001) {
      // Round to 2 decimal places and convert
      final decimals = ((fracPart * 100).round() / 100).toString().substring(2);
      if (decimals.isNotEmpty && decimals != '0') {
        result += ' point';
        for (final digit in decimals.split('')) {
          if (digit == '0') {
            result += ' zero';
          } else {
            result += ' ${_ones[int.parse(digit)]}';
          }
        }
      }
    }

    return result.trim();
  }

  // Convert integer to words
  String _intToWords(int number) {
    if (number == 0) return 'zero';
    if (number < 0) return 'negative ${_intToWords(-number)}';
    if (number < 20) return _ones[number];

    if (number < 100) {
      final ten = number ~/ 10;
      final one = number % 10;
      if (one == 0) return _tens[ten];
      return '${_tens[ten]} ${_ones[one]}';
    }

    if (number < 1000) {
      final hundred = number ~/ 100;
      final remainder = number % 100;
      if (remainder == 0) return '${_ones[hundred]} hundred';
      return '${_ones[hundred]} hundred ${_intToWords(remainder)}';
    }

    // Handle thousands and above
    var result = '';
    var remaining = number;
    var scaleIndex = 0;

    while (remaining > 0) {
      final chunk = remaining % 1000;
      if (chunk > 0) {
        final chunkWords = _chunkToWords(chunk);
        final scale = _scales[scaleIndex];
        if (scale.isNotEmpty) {
          result = '$chunkWords $scale $result';
        } else {
          result = '$chunkWords $result';
        }
      }
      remaining ~/= 1000;
      scaleIndex++;
    }

    return result.trim();
  }

  // Convert a 3-digit chunk to words
  String _chunkToWords(int chunk) {
    if (chunk == 0) return '';
    if (chunk < 20) return _ones[chunk];

    if (chunk < 100) {
      final ten = chunk ~/ 10;
      final one = chunk % 10;
      if (one == 0) return _tens[ten];
      return '${_tens[ten]} ${_ones[one]}';
    }

    final hundred = chunk ~/ 100;
    final remainder = chunk % 100;
    if (remainder == 0) return '${_ones[hundred]} hundred';
    return '${_ones[hundred]} hundred ${_chunkToWords(remainder)}';
  }

  // Convert unit abbreviation to full word
  String _unitToWord(String unit, bool singular) {
    return switch (unit) {
      'B' => singular ? 'byte' : 'bytes',
      'KB' => singular ? 'kilobyte' : 'kilobytes',
      'MB' => singular ? 'megabyte' : 'megabytes',
      'GB' => singular ? 'gigabyte' : 'gigabytes',
      'TB' => singular ? 'terabyte' : 'terabytes',
      'PB' => singular ? 'petabyte' : 'petabytes',
      _ => singular ? unit.toLowerCase() : '${unit.toLowerCase()}s',
    };
  }

  // Helper to determine best unit
  (double value, String unit) _bestUnit() {
    if (_bytes >= _pb) return (_roundValue(_bytes / _pb), 'PB');
    if (_bytes >= _tb) return (_roundValue(_bytes / _tb), 'TB');
    if (_bytes >= _gb) return (_roundValue(_bytes / _gb), 'GB');
    if (_bytes >= _mb) return (_roundValue(_bytes / _mb), 'MB');
    if (_bytes >= _kb) return (_roundValue(_bytes / _kb), 'KB');
    return (_bytes, 'B');
  }

  // Round to 2 decimal places
  double _roundValue(double value) {
    return (value * 100).round() / 100;
  }
}
