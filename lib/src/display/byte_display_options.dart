import 'dart:math' as math;

import '../_parsing.dart' show humanize;
import '../byte_converter_base.dart';
import '../byte_enums.dart';
import '../compound_format.dart';
import '../format_options.dart';
import '../humanize_options.dart';
import '../localized_unit_names.dart' show localizedUnitName;

/// Provides alternative display formats for byte values.
///
/// Access via the `display` extension property on [ByteConverter]:
/// ```dart
/// final size = ByteConverter.fromMB(1.5);
/// print(size.display.fuzzy);       // "about 1.5 MB"
/// print(size.display.scientific);  // "1.5 × 10⁶ B"
/// print(size.display.fractional);  // "1½ MB"
/// print(size.display.gnu);         // "1.5M"
/// ```
class ByteDisplayOptions {
  /// Creates display options for the given byte value.
  const ByteDisplayOptions(this._bytes);

  final double _bytes;

  // Unit thresholds for SI
  static const _kb = 1000.0;
  static const _mb = _kb * 1000;
  static const _gb = _mb * 1000;
  static const _tb = _gb * 1000;
  static const _pb = _tb * 1000;

  // Unicode superscript digits
  static const _superscripts = {
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

  // Unicode fraction characters - using final instead of const to avoid double key issues
  static final Map<double, String> _fractions = {
    0.25: '¼',
    0.5: '½',
    0.75: '¾',
    0.33: '⅓',
    0.67: '⅔',
    0.2: '⅕',
    0.4: '⅖',
    0.6: '⅗',
    0.8: '⅘',
    0.17: '⅙',
    0.83: '⅚',
    0.14: '⅐',
    0.13: '⅛',
    0.38: '⅜',
    0.63: '⅝',
    0.88: '⅞',
    0.11: '⅑',
    0.1: '⅒',
  };

  /// Returns a fuzzy/approximate description of the size.
  ///
  /// Examples:
  /// - "about 1.5 MB"
  /// - "almost 2 GB"
  /// - "just over 1 TB"
  /// - "exactly 1 KB"
  ///
  /// Set [locale] for localized output (future support).
  String fuzzy({String? locale}) {
    if (_bytes == 0) return '0 B';

    final (value, unit) = _bestUnit();
    final rounded = value.round();
    final diff = value - rounded;
    final absDiff = diff.abs();

    // Determine the fuzzy prefix
    String prefix;
    String displayValue;

    if (absDiff < 0.02) {
      // Very close to exact
      prefix = 'exactly';
      displayValue = rounded.toString();
    } else if (diff > 0 && diff < 0.15) {
      // Just over
      prefix = 'just over';
      displayValue = rounded.toString();
    } else if (diff < 0 && absDiff < 0.15) {
      // Just under
      prefix = 'just under';
      displayValue = rounded.toString();
    } else if (diff > 0 && diff >= 0.15 && diff < 0.35) {
      // About (above)
      prefix = 'about';
      displayValue = _formatValue(value);
    } else if (diff < 0 && absDiff >= 0.15 && absDiff < 0.35) {
      // Almost
      prefix = 'almost';
      displayValue = rounded.toString();
    } else {
      // Generic about
      prefix = 'about';
      displayValue = _formatValue(value);
    }

    return '$prefix $displayValue $unit';
  }

  /// Returns the size in scientific notation.
  ///
  /// Examples:
  /// - "1.5 × 10⁶ B" (default)
  /// - "1.5e6 B" (ascii mode)
  ///
  /// Set [ascii] to true for ASCII-only output (e.g., "1.5e6").
  /// Set [precision] to control decimal places (default: 2).
  String scientific({bool ascii = false, int precision = 2}) {
    if (_bytes == 0) return ascii ? '0e0 B' : '0 × 10⁰ B';
    if (_bytes < 1) {
      // Handle sub-byte values
      final exp = (math.log(_bytes) / math.ln10).floor();
      final mantissa = _bytes / math.pow(10, exp);
      final mantissaStr = mantissa.toStringAsFixed(precision);
      if (ascii) {
        return '${mantissaStr}e$exp B';
      }
      return '$mantissaStr × 10${_toSuperscript(exp.toString())} B';
    }

    final exp = (math.log(_bytes) / math.ln10).floor();
    final mantissa = _bytes / math.pow(10, exp);
    final mantissaStr = mantissa.toStringAsFixed(precision);

    if (ascii) {
      return '${mantissaStr}e$exp B';
    }

    return '$mantissaStr × 10${_toSuperscript(exp.toString())} B';
  }

  /// Returns the size with fractional Unicode characters.
  ///
  /// Examples:
  /// - "1½ MB"
  /// - "2¾ GB"
  /// - "3 TB" (when no suitable fraction)
  String fractional() {
    if (_bytes == 0) return '0 B';

    final (value, unit) = _bestUnit();
    final whole = value.floor();
    final frac = value - whole;

    // Find the closest fraction character
    String? fracChar;
    double minDiff = 0.05; // Tolerance for matching

    for (final entry in _fractions.entries) {
      final diff = (frac - entry.key).abs();
      if (diff < minDiff) {
        minDiff = diff;
        fracChar = entry.value;
      }
    }

    if (fracChar != null) {
      if (whole == 0) {
        return '$fracChar $unit';
      }
      return '$whole$fracChar $unit';
    }

    // No matching fraction, use regular formatting
    return '${_formatValue(value)} $unit';
  }

  /// Returns the size in GNU short format (like `ls -h` or `du -h`).
  ///
  /// Examples:
  /// - "500K"
  /// - "1.5M"
  /// - "2G"
  /// - "512" (for bytes)
  ///
  /// Set [precision] to control decimal places (default: 1).
  String gnu({int precision = 1}) {
    if (_bytes == 0) return '0';

    if (_bytes < _kb) {
      return _bytes.round().toString();
    }

    final (value, unit) = _bestUnit();
    final gnuSuffix = switch (unit) {
      'KB' => 'K',
      'MB' => 'M',
      'GB' => 'G',
      'TB' => 'T',
      'PB' => 'P',
      _ => '',
    };

    // Format value, removing trailing zeros
    String valueStr;
    if (value == value.roundToDouble() && value == value.round()) {
      valueStr = value.round().toString();
    } else {
      valueStr = value.toStringAsFixed(precision);
      // Remove trailing zeros after decimal
      if (valueStr.contains('.')) {
        valueStr = valueStr.replaceAll(RegExp(r'\.?0+$'), '');
      }
    }

    return '$valueStr$gnuSuffix';
  }

  /// Returns the size with full word unit names.
  ///
  /// Examples:
  /// - "1.5 Megabytes"
  /// - "250 Kilobytes"
  /// - "1 Byte"
  ///
  /// Set [lowercase] to true for lowercase output.
  String fullWords({bool lowercase = false}) {
    if (_bytes == 0) return lowercase ? '0 bytes' : '0 Bytes';

    final (value, unit) = _bestUnit();
    final fullUnit = switch (unit) {
      'B' => value == 1 ? 'Byte' : 'Bytes',
      'KB' => value == 1 ? 'Kilobyte' : 'Kilobytes',
      'MB' => value == 1 ? 'Megabyte' : 'Megabytes',
      'GB' => value == 1 ? 'Gigabyte' : 'Gigabytes',
      'TB' => value == 1 ? 'Terabyte' : 'Terabytes',
      'PB' => value == 1 ? 'Petabyte' : 'Petabytes',
      _ => unit,
    };

    final result = '${_formatValue(value)} $fullUnit';
    return lowercase ? result.toLowerCase() : result;
  }

  /// Returns the size with comma-separated byte count.
  ///
  /// Examples:
  /// - "1,536,000 bytes"
  /// - "1.536.000 bytes" (German locale)
  ///
  /// Set [locale] for locale-aware separators (future support).
  String withCommas({String? locale}) {
    final bytesInt = _bytes.round();
    final formatted = _addThousandsSeparator(bytesInt, locale: locale);
    final unit = bytesInt == 1 ? 'byte' : 'bytes';
    return '$formatted $unit';
  }

  // Helper to determine best unit
  (double value, String unit) _bestUnit() {
    if (_bytes >= _pb) return (_bytes / _pb, 'PB');
    if (_bytes >= _tb) return (_bytes / _tb, 'TB');
    if (_bytes >= _gb) return (_bytes / _gb, 'GB');
    if (_bytes >= _mb) return (_bytes / _mb, 'MB');
    if (_bytes >= _kb) return (_bytes / _kb, 'KB');
    return (_bytes, 'B');
  }

  // Format value with smart precision
  String _formatValue(double value) {
    if (value == value.roundToDouble() && value == value.round()) {
      return value.round().toString();
    }
    // Use 1 decimal for values >= 10, 2 for smaller
    final precision = value >= 10 ? 1 : 2;
    var str = value.toStringAsFixed(precision);
    // Remove trailing zeros
    if (str.contains('.')) {
      str = str.replaceAll(RegExp(r'\.?0+$'), '');
    }
    return str;
  }

  // Convert number string to superscript
  String _toSuperscript(String num) {
    final buffer = StringBuffer();
    for (final char in num.split('')) {
      if (char == '-') {
        buffer.write('⁻');
      } else {
        buffer.write(_superscripts[char] ?? char);
      }
    }
    return buffer.toString();
  }

  // Add thousands separator
  String _addThousandsSeparator(int number, {String? locale}) {
    final sep = locale == 'de' ? '.' : ',';
    final str = number.toString();
    final result = StringBuffer();
    var count = 0;

    for (var i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write(sep);
      }
      result.write(str[i]);
      count++;
    }

    return result.toString().split('').reversed.join();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Extended API Methods (for namespace consolidation)
  // ─────────────────────────────────────────────────────────────────────────

  /// Formats with automatic unit selection and configurable options.
  ///
  /// This is the namespace equivalent of `ByteConverter.toHumanReadableAuto()`.
  ///
  /// ```dart
  /// final size = ByteConverter.fromGigaBytes(1.5);
  /// print(size.display.auto()); // "1.5 GB"
  /// print(size.display.auto(standard: ByteStandard.iec)); // "1.4 GiB"
  /// print(size.display.auto(precision: 3)); // "1.500 GB"
  /// ```
  String auto({
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

  /// Formats using [ByteFormatOptions] configuration object.
  ///
  /// ```dart
  /// final size = ByteConverter.fromMegaBytes(100);
  /// final options = ByteFormatOptions(standard: ByteStandard.iec, precision: 1);
  /// print(size.display.format(options)); // "95.4 MiB"
  /// ```
  String format(ByteFormatOptions options) => auto(
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

  /// Compound mixed-unit formatting, e.g., "1 GB 234 MB 12 KB".
  ///
  /// This is the namespace equivalent of `ByteConverter.toHumanReadableCompound()`.
  ///
  /// ```dart
  /// final size = ByteConverter.fromMegaBytes(1536);
  /// print(size.display.compound()); // "1 GB 512 MB"
  /// ```
  String compound(
      {CompoundFormatOptions options = const CompoundFormatOptions()}) {
    return formatCompound(_bytes, options);
  }

  /// Formats the size in a specific [unit].
  ///
  /// This is the namespace equivalent of `ByteConverter.toHumanReadable(unit)`.
  ///
  /// ```dart
  /// final size = ByteConverter.fromMegaBytes(1.5);
  /// print(size.display.inUnit(SizeUnit.KB)); // "1500 KB"
  /// print(size.display.inUnit(SizeUnit.GB, precision: 3)); // "0.002 GB"
  /// ```
  String inUnit(SizeUnit unit, {int precision = 2}) {
    final value = _convertToUnit(unit);
    return '${_withPrecision(value, precision)} ${_unitSymbol(unit)}';
  }

  double _convertToUnit(SizeUnit unit) => switch (unit) {
        SizeUnit.PB => _bytes / _pb,
        SizeUnit.TB => _bytes / _tb,
        SizeUnit.GB => _bytes / _gb,
        SizeUnit.MB => _bytes / _mb,
        SizeUnit.KB => _bytes / _kb,
        SizeUnit.B => _bytes,
      };

  String _unitSymbol(SizeUnit unit) => switch (unit) {
        SizeUnit.PB => 'PB',
        SizeUnit.TB => 'TB',
        SizeUnit.GB => 'GB',
        SizeUnit.MB => 'MB',
        SizeUnit.KB => 'KB',
        SizeUnit.B => 'B',
      };

  num _withPrecision(double value, int precision) {
    if (precision < 0) return value;
    if (value % 1 == 0) return value.toInt();
    final factor = math.pow(10, precision);
    return (value * factor).round() / factor;
  }

  /// Pattern-based formatting with custom templates.
  ///
  /// Supported tokens:
  /// - `0.00` or `0#` - numeric value
  /// - `u` - unit symbol (KB, MiB, Mb)
  /// - `U` - unit full word (localized when available)
  /// - `S` - sign (+, -, or space when signed is true)
  ///
  /// ```dart
  /// final size = ByteConverter.fromMegaBytes(1.5);
  /// print(size.display.pattern('0.0 u'));   // "1.5 MB"
  /// print(size.display.pattern('0.00 U')); // "1.50 Megabytes"
  /// ```
  String pattern(String formatPattern,
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
    var out =
        formatPattern.replaceAll('U', fullWord()).replaceAll('u', unitSymbol);
    // 'S' -> sign: '+', '-', or ' ' (when options.signed is true); else empty
    final signChar =
        options.signed ? (_bytes > 0 ? '+' : (_bytes < 0 ? '-' : ' ')) : '';
    out = out.replaceAll('S', signChar);
    out = out.replaceAll(numericRe, valuePart);
    return out;
  }
}
