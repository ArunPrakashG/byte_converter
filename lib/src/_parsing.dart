import 'byte_enums.dart';
import 'humanize_number_format.dart';
import 'humanize_options.dart';
import 'localized_unit_names.dart';

export 'humanize_options.dart';

class _UnitDef<TUnit> {
  // relative to 1 byte
  const _UnitDef(this.symbol, this.unit, this.multiplier);
  final String symbol;
  final TUnit unit;
  final double multiplier;
}

class ByteParsingResult<TUnit> {
  const ByteParsingResult({
    required this.valueInBytes,
    required this.unit,
    required this.isBitInput,
    required this.normalizedInput,
    required this.unitSymbol,
    required this.rawValue,
  });
  final double valueInBytes;
  final TUnit? unit;
  final bool isBitInput;
  final String normalizedInput;
  final String unitSymbol;
  final double rawValue;
}

// SI (decimal) definitions for SizeUnit (limited up to PB)
const _siUnits = <_UnitDef<SizeUnit>>[
  _UnitDef('PB', SizeUnit.PB, 1000000000000000),
  _UnitDef('TB', SizeUnit.TB, 1000000000000),
  _UnitDef('GB', SizeUnit.GB, 1000000000),
  _UnitDef('MB', SizeUnit.MB, 1000000),
  _UnitDef('KB', SizeUnit.KB, 1000),
  _UnitDef('B', SizeUnit.B, 1),
];

// JEDEC (binary with decimal symbols KB/MB/GB)
const _jedecMultipliers = <String, double>{
  'KB': 1024,
  'MB': 1024 * 1024,
  'GB': 1024 * 1024 * 1024,
};

// IEC (binary) symbols
const _iecSymbols = <String, double>{
  'YiB': 1208925819614629174706176, // 1024^8
  'ZiB': 1180591620717411303424, // 1024^7
  'EiB': 1152921504606846976, // 1024^6
  'PiB': 1125899906842624, // 1024^5
  'TiB': 1099511627776, // 1024^4
  'GiB': 1073741824, // 1024^3
  'MiB': 1048576, // 1024^2
  'KiB': 1024,
  'B': 1,
};

String _canonicalizeBitSymbol(String symbol) {
  final lower = symbol.toLowerCase();
  if (lower == 'b') return 'b';
  if (lower.endsWith('ib')) {
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }
  if (lower.length <= 1) return lower;
  final prefix = lower.substring(0, lower.length - 1).toUpperCase();
  return '${prefix}b';
}

String _canonicalizeByteSymbol(String symbol) {
  if (symbol.isEmpty) return 'B';
  if (symbol.length <= 2) return symbol.toUpperCase();
  if (symbol.endsWith('iB')) {
    return symbol[0].toUpperCase() + symbol.substring(1);
  }
  return symbol.toUpperCase();
}

String _composeNormalizedInput(String number, String unitSymbol) {
  if (unitSymbol.isEmpty) return number;
  return '$number $unitSymbol'.trim();
}

String _trimAndNormalize(String input) {
  // Collapse whitespace (including NBSP) to single spaces and trim ends
  return input.replaceAll(RegExp(r'[\u00A0\s]+'), ' ').trim();
}

bool _containsExpressionOperators(String input) {
  var previousNonSpace = '';
  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    switch (ch) {
      case '+':
      case '*':
      case '/':
      case '(':
      case ')':
        return true;
      case '-':
        if (previousNonSpace.isEmpty || '+-*/('.contains(previousNonSpace)) {
          // Unary minus, continue scanning.
        } else {
          return true;
        }
        break;
      default:
        if (ch.trim().isNotEmpty) {
          previousNonSpace = ch;
        }
        break;
    }
  }
  return false;
}

/// Normalize a locale-formatted number string into a canonical form Dart can parse.
/// - Removes grouping separators (space, NBSP, underscore)
/// - Resolves decimal separator (comma or dot). If both appear, the last one is taken as decimal.
String _normalizeNumber(String s) {
  // Remove grouping (spaces, NBSP, underscores) but keep sign, digits, separators
  var t = s.replaceAll(RegExp(r'[\u00A0_ ]'), '');
  // Preserve leading sign
  final sign = t.startsWith('-') ? '-' : (t.startsWith('+') ? '+' : '');
  if (sign.isNotEmpty) t = t.substring(1);

  // Determine the position (in digit count) of the last separator to use as decimal
  int? digitDecimalIndex; // number of digits before the decimal point
  var digitCount = 0;
  for (var i = 0; i < t.length; i++) {
    final ch = t[i];
    if (ch == ',' || ch == '.') {
      digitDecimalIndex = digitCount; // decimal after this many digits
    } else if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
      digitCount++;
    } else {
      // Unknown character; let parse fail later
    }
  }
  // Collect only digits
  final digitsOnly = t.replaceAll(RegExp('[^0-9]'), '');
  if (digitsOnly.isEmpty) return '${sign}0';
  if (digitDecimalIndex == null) {
    return sign + digitsOnly; // integer
  }
  final idx = digitDecimalIndex;
  if (idx <= 0) {
    return '${sign}0.$digitsOnly';
  }
  if (idx >= digitsOnly.length) {
    return sign + digitsOnly; // trailing decimal -> integer
  }
  final whole = digitsOnly.substring(0, idx);
  final frac = digitsOnly.substring(idx);
  return '$sign$whole.$frac';
}

ByteParsingResult<TUnit> _parseSizeLiteralInternal<TUnit>({
  required String input,
  required ByteStandard standard,
}) {
  final text = _trimAndNormalize(input);
  final regex = RegExp(
    r'^\s*([+-]?[0-9\.,\u00A0_\s]+)\s*([A-Za-z]+)?\s*$',
  );
  final match = regex.firstMatch(text);
  if (match == null) {
    throw FormatException('Invalid size format: $input');
  }

  final numStr = _normalizeNumber(match.group(1)!);
  final unitStrRaw = (match.group(2) ?? '').trim();
  final value = double.parse(numStr);

  var normalizedToken = unitStrRaw;
  var isBits = false;
  double? multiplier;
  TUnit? unit;

  if (unitStrRaw.isEmpty) {
    multiplier = 1;
    unit = null;
    normalizedToken = '';
  } else {
    var token = unitStrRaw;
    final lowerTrim = token.toLowerCase();

    const normalizedWordToSymbol = <String, String>{
      // bytes
      'byte': 'B',
      'bytes': 'B',
      'kilobyte': 'KB',
      'kilobytes': 'KB',
      'megabyte': 'MB',
      'megabytes': 'MB',
      'gigabyte': 'GB',
      'gigabytes': 'GB',
      'terabyte': 'TB',
      'terabytes': 'TB',
      'petabyte': 'PB',
      'petabytes': 'PB',
      'exabyte': 'EB',
      'exabytes': 'EB',
      'zettabyte': 'ZB',
      'zettabytes': 'ZB',
      'yottabyte': 'YB',
      'yottabytes': 'YB',
      // bits
      'bit': 'b',
      'bits': 'b',
      'kilobit': 'kb',
      'kilobits': 'kb',
      'megabit': 'mb',
      'megabits': 'mb',
      'gigabit': 'gb',
      'gigabits': 'gb',
      'terabit': 'tb',
      'terabits': 'tb',
      'petabit': 'pb',
      'petabits': 'pb',
      'exabit': 'eb',
      'exabits': 'eb',
      'zettabit': 'zb',
      'zettabits': 'zb',
      'yottabit': 'yb',
      'yottabits': 'yb',
      // IEC bytes
      'kibibyte': 'KiB',
      'kibibytes': 'KiB',
      'mebibyte': 'MiB',
      'mebibytes': 'MiB',
      'gibibyte': 'GiB',
      'gibibytes': 'GiB',
      'tebibyte': 'TiB',
      'tebibytes': 'TiB',
      'pebibyte': 'PiB',
      'pebibytes': 'PiB',
      'exbibyte': 'EiB',
      'exbibytes': 'EiB',
      'zebibyte': 'ZiB',
      'zebibytes': 'ZiB',
      'yobibyte': 'YiB',
      'yobibytes': 'YiB',
      // IEC bits
      'kibibit': 'kib',
      'kibibits': 'kib',
      'mebibit': 'mib',
      'mebibits': 'mib',
      'gibibit': 'gib',
      'gibibits': 'gib',
      'tebibit': 'tib',
      'tebibits': 'tib',
      'pebibit': 'pib',
      'pebibits': 'pib',
      'exbibit': 'eib',
      'exbibits': 'eib',
      'zebibit': 'zib',
      'zebibits': 'zib',
      'yobibit': 'yib',
      'yobibits': 'yib',
    };

    if (normalizedWordToSymbol.containsKey(lowerTrim)) {
      token = normalizedWordToSymbol[lowerTrim]!;
    }

    normalizedToken = token;
    final endsWithLowerB =
        token.isNotEmpty && token[token.length - 1] == 'b' && token != 'B';
    if (endsWithLowerB) {
      isBits = true;
    }

    var handledExplicitBit = false;
    if (endsWithLowerB) {
      const siBit = {
        'kb': 1e3,
        'mb': 1e6,
        'gb': 1e9,
        'tb': 1e12,
        'pb': 1e15,
        'eb': 1e18,
        'zb': 1e21,
        'yb': 1e24,
      };
      const iecBit = {
        'kib': 1024.0,
        'mib': 1024.0 * 1024,
        'gib': 1024.0 * 1024 * 1024,
        'tib': 1024.0 * 1024 * 1024 * 1024,
        'pib': 1024.0 * 1024 * 1024 * 1024 * 1024,
        'eib': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024,
        'zib': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
        'yib': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
      };
      final lowerToken = token.toLowerCase();
      if (siBit.containsKey(lowerToken)) {
        multiplier = siBit[lowerToken]! / 8.0;
        normalizedToken = lowerToken;
        handledExplicitBit = true;
      } else if (iecBit.containsKey(lowerToken)) {
        multiplier = iecBit[lowerToken]! / 8.0;
        normalizedToken = lowerToken;
        handledExplicitBit = true;
      }
    }

    if (!handledExplicitBit) {
      if (token == 'b' || lowerTrim == 'bit' || lowerTrim == 'bits') {
        isBits = true;
        multiplier = 1 / 8;
        normalizedToken = 'b';
        unit = null;
      } else if (token.toUpperCase() == 'B') {
        multiplier = 1;
        normalizedToken = 'B';
        unit = null;
        isBits = false;
      } else {
        switch (standard) {
          case ByteStandard.si:
            final upper = token.toUpperCase();
            final isLowerB = token.isNotEmpty && token[token.length - 1] == 'b';
            final upperNoB =
                isLowerB ? upper.substring(0, upper.length - 1) : upper;
            final candidates =
                _siUnits.where((e) => e.symbol.toUpperCase() == upperNoB);
            if (candidates.isEmpty) {
              throw FormatException('Unknown SI unit: $unitStrRaw');
            }
            final found = candidates.first;
            multiplier = found.multiplier;
            if (isLowerB) {
              multiplier = multiplier / 8;
              isBits = true;
              normalizedToken = '${found.symbol}b'.toLowerCase();
            } else {
              normalizedToken = found.symbol;
            }
            unit = found.unit as TUnit;
            break;
          case ByteStandard.jedec:
            final upper = token.toUpperCase();
            final isLowerB = token.isNotEmpty && token[token.length - 1] == 'b';
            final key = isLowerB ? upper.substring(0, upper.length - 1) : upper;
            if (_jedecMultipliers.containsKey(key)) {
              final base = _jedecMultipliers[key]!;
              multiplier = base;
              if (isLowerB) {
                multiplier = base / 8;
                isBits = true;
                normalizedToken = '${key}b'.toLowerCase();
              } else {
                normalizedToken = key;
              }
              final map = {
                'KB': SizeUnit.KB,
                'MB': SizeUnit.MB,
                'GB': SizeUnit.GB,
              };
              unit = map[key] as TUnit?;
            } else if (key == 'B') {
              multiplier = 1;
              normalizedToken = 'B';
            } else {
              throw FormatException('Unknown unit for JEDEC: $unitStrRaw');
            }
            break;
          case ByteStandard.iec:
            final isLowerB = token.isNotEmpty && token[token.length - 1] == 'b';
            final key = isLowerB ? token.substring(0, token.length - 1) : token;
            if (_iecSymbols.containsKey(key)) {
              final base = _iecSymbols[key]!;
              multiplier = base;
              if (isLowerB) {
                multiplier = base / 8;
                isBits = true;
                normalizedToken = '${key}b'.toLowerCase();
              } else {
                normalizedToken = key;
              }
              unit = null;
            } else {
              throw FormatException('Unknown IEC unit: $unitStrRaw');
            }
            break;
        }
      }
    }
  }

  multiplier ??= 1;
  final bytes = value * multiplier;

  final canonicalSymbol = () {
    if ((unitStrRaw.isEmpty || normalizedToken.isEmpty) && !isBits) {
      return 'B';
    }
    if ((unitStrRaw.isEmpty || normalizedToken.isEmpty) && isBits) {
      return 'b';
    }
    return isBits
        ? _canonicalizeBitSymbol(normalizedToken.toLowerCase())
        : _canonicalizeByteSymbol(normalizedToken);
  }();

  final normalizedInput = unitStrRaw.isEmpty && normalizedToken.isEmpty
      ? numStr
      : _composeNormalizedInput(numStr, canonicalSymbol);

  return ByteParsingResult<TUnit>(
    valueInBytes: bytes,
    unit: unit,
    isBitInput: isBits,
    normalizedInput: normalizedInput,
    unitSymbol: canonicalSymbol,
    rawValue: value,
  );
}

/// Parses size strings like "1.5 GB", "2GiB", "1024 B", "100 KB", "10 Mb".
/// Supports SI, IEC, and JEDEC standards. Bits are recognized via suffix (bit, b, kb, Mb, etc.).
ByteParsingResult<TUnit> parseSize<TUnit>({
  required String input,
  required ByteStandard standard,
}) {
  final normalized = _trimAndNormalize(input);
  if (_containsExpressionOperators(normalized)) {
    final evaluator = _SizeExpressionEvaluator(
      input: normalized,
      literalParser: (literal) {
        final result = _parseSizeLiteralInternal<SizeUnit>(
          input: literal,
          standard: standard,
        );
        return result.valueInBytes;
      },
    );
    return evaluator.evaluate<TUnit>();
  }
  return _parseSizeLiteralInternal<TUnit>(
    input: input,
    standard: standard,
  );
}

HumanizeResult humanize(double bytes, HumanizeOptions opt) {
  const List<double> si = [
    1e24, // YB
    1e21, // ZB
    1e18, // EB
    1e15, // PB
    1e12, // TB
    1e9, // GB
    1e6, // MB
    1e3, // KB
  ];
  const List<String> siSym = ['YB', 'ZB', 'EB', 'PB', 'TB', 'GB', 'MB', 'KB'];
  const List<double> iec = [
    1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024, // YiB
    1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024, // ZiB
    1024.0 * 1024 * 1024 * 1024 * 1024 * 1024, // EiB
    1024.0 * 1024 * 1024 * 1024 * 1024, // PiB
    1024.0 * 1024 * 1024 * 1024, // TiB
    1024.0 * 1024 * 1024, // GiB
    1024.0 * 1024, // MiB
    1024.0, // KiB
  ];
  const List<String> iecSym = [
    'YiB',
    'ZiB',
    'EiB',
    'PiB',
    'TiB',
    'GiB',
    'MiB',
    'KiB'
  ];
  const List<double> jedec = [
    1024.0 * 1024 * 1024 * 1024, // TB
    1024.0 * 1024 * 1024, // GB
    1024.0 * 1024, // MB
    1024.0, // KB
  ];
  const List<String> jedecSym = ['TB', 'GB', 'MB', 'KB'];

  var value = bytes;
  final symbol = opt.useBits ? 'b' : 'B';
  final space = opt.spacer ?? (opt.showSpace ? ' ' : '');
  if (opt.useBits) value = bytes * 8;

  late final List<double> thresholds;
  late final List<String> symbols;
  switch (opt.standard) {
    case ByteStandard.si:
      thresholds = si;
      symbols = siSym;
      break;
    case ByteStandard.iec:
      thresholds = iec;
      symbols = iecSym;
      break;
    case ByteStandard.jedec:
      thresholds = jedec;
      symbols = jedecSym;
      break;
  }

  var base = 1.0;
  var chosenSymbol = symbol;
  // Forced unit selection (no auto-scale)
  if (opt.forceUnit != null && opt.forceUnit!.isNotEmpty) {
    final u = opt.forceUnit!;
    chosenSymbol = u;
    // Determine base from provided unit symbol for the selected standard
    double? forcedBase;
    final upper = u.toUpperCase();
    final isBitUnit = u.endsWith('b') && !u.endsWith('B');
    final normalized = isBitUnit ? upper.substring(0, upper.length - 1) : upper;
    switch (opt.standard) {
      case ByteStandard.si:
        final idx = ['YB', 'ZB', 'EB', 'PB', 'TB', 'GB', 'MB', 'KB']
            .indexOf(normalized);
        if (idx != -1) forcedBase = si[idx];
        // Support bit units like 'Mb','Gb' by mapping single-letter SI to base10
        if (forcedBase == null && isBitUnit) {
          const single = {
            'Y': 1e24,
            'Z': 1e21,
            'E': 1e18,
            'P': 1e15,
            'T': 1e12,
            'G': 1e9,
            'M': 1e6,
            'K': 1e3,
          };
          if (single.containsKey(normalized)) forcedBase = single[normalized];
        }
        if (normalized == 'B') forcedBase = 1.0;
        break;
      case ByteStandard.jedec:
        final idxJ = ['TB', 'GB', 'MB', 'KB'].indexOf(normalized);
        if (idxJ != -1) forcedBase = jedec[idxJ];
        if (normalized == 'B') forcedBase = 1.0;
        break;
      case ByteStandard.iec:
        final idxI =
            ['YiB', 'ZiB', 'EiB', 'PiB', 'TiB', 'GiB', 'MiB', 'KiB'].indexOf(u);
        if (idxI != -1) forcedBase = iec[idxI];
        if (u == 'B' || normalized == 'B') forcedBase = 1.0;
        break;
    }
    base = forcedBase ?? 1.0;
  } else {
    // Auto-scale selection
    for (var i = 0; i < thresholds.length; i++) {
      final threshold = thresholds[i];
      if ((opt.useBits ? value : bytes) >= threshold) {
        base = threshold;
        chosenSymbol = symbols[i];
        break;
      }
    }
    if (base == 1.0) {
      chosenSymbol = opt.useBits ? 'b' : 'B';
    }
  }

  // Compute value and unit symbol
  final vRaw = (opt.useBits ? value : bytes) / base;
  final v = _applyRoundingAndFractionDigits(vRaw, opt);
  final unitSymbol = () {
    final sym = chosenSymbol;
    if (opt.useBits) {
      if (sym == 'B') return 'b';
      if (sym.endsWith('B')) return sym.replaceAll('B', 'b');
      if (sym.endsWith('b')) return sym; // already a bit unit like 'Mb'
      return 'b';
    }
    return sym;
  }();

  // Number formatting with separator/min/max fraction digits
  final numStr = _formatHumanizedNumber(v, opt);

  // Full-form unit names
  String unitOut;
  if (opt.fullForm) {
    final full = _fullFormName(
      unitSymbol,
      opt.useBits,
      locale: opt.locale,
    );
    unitOut = opt.fullForms != null && opt.fullForms!.containsKey(full)
        ? opt.fullForms![full]!
        : full;
  } else {
    unitOut = unitSymbol;
  }

  // Signed formatting
  final signedPrefix = () {
    if (!opt.signed) return '';
    if (v > 0) return '+';
    if (v < 0) return '-';
    return ' ';
  }();

  final text = '$signedPrefix$numStr$space$unitOut';
  return HumanizeResult(v, chosenSymbol, text);
}

class MathHelper {
  static double pow10(int p) =>
      p <= 0 ? 1.0 : List.filled(p, 10).fold(1, (a, b) => a * b);
}

String _formatNumber(double v, int precision) {
  // Always produce fixed then trim trailing zeros and decimal point
  final s = v.toStringAsFixed(precision);
  if (!s.contains('.')) return s;
  final t = s.replaceFirstMapped(RegExp(r'(\.\d*?)0+$'), (m) => m.group(1)!);
  return t.endsWith('.') ? t.substring(0, t.length - 1) : t;
}

double _applyRoundingAndFractionDigits(double v, HumanizeOptions opt) {
  if (opt.minimumFractionDigits != null || opt.maximumFractionDigits != null) {
    final max = opt.maximumFractionDigits ?? opt.minimumFractionDigits ?? 0;
    final factor = MathHelper.pow10(max);
    return (v * factor).round() / factor;
  }
  final factor = MathHelper.pow10(opt.precision);
  return (v * factor).round() / factor;
}

String _formatNumberAdvanced(double v, HumanizeOptions opt) {
  if (opt.minimumFractionDigits == null &&
      opt.maximumFractionDigits == null &&
      opt.separator == null) {
    return _formatNumber(v, opt.precision);
  }
  final min = opt.minimumFractionDigits ?? 0;
  final max = opt.maximumFractionDigits ?? min;
  var s = v.toStringAsFixed(max);
  if (max > min) {
    // Trim to minimum
    final regex = RegExp(r'(\.\d{' + min.toString() + r'})\d+$');
    s = s.replaceFirstMapped(regex, (m) => m.group(1)!);
  }
  if (opt.separator != null && opt.separator != '.') {
    s = s.replaceAll('.', opt.separator!);
  }
  return s;
}

String _formatHumanizedNumber(double v, HumanizeOptions opt) {
  final locale = opt.locale;
  if (locale != null && locale.isNotEmpty) {
    final formatter = humanizeNumberFormatter;
    if (formatter != null) {
      try {
        final formatted = formatter(v, opt);
        if (formatted.isNotEmpty) {
          return formatted;
        }
      } catch (_) {
        // Swallow and fall back to default formatting if formatter fails
      }
    }
  }
  return _formatNumberAdvanced(v, opt);
}

String _fullFormName(String symbol, bool bits, {String? locale}) {
  final localized = localizedUnitName(
    bits ? symbol.toLowerCase() : symbol,
    locale: locale,
  );
  if (localized != null) {
    return localized;
  }

  // English defaults (fallback)
  final map = localizedUnitNameMapForDefaultLocale();
  final key = bits ? symbol.toLowerCase() : symbol;
  return map[key] ?? symbol;
}

class RateParsingResult {
  const RateParsingResult({
    required this.bitsPerSecond,
    required this.normalizedInput,
    required this.unitSymbol,
    required this.isBitInput,
    required this.rawValue,
  });
  final double bitsPerSecond;
  final String normalizedInput;
  final String unitSymbol;
  final bool isBitInput;
  final double rawValue;
}

RateParsingResult _parseRateLiteralInternal({
  required String input,
  required ByteStandard standard,
}) {
  final text = _trimAndNormalize(input);
  final regex = RegExp(
    r'^\s*([+-]?(?:[\d_\u00A0\s]+(?:[\.,][\d_\u00A0\s]+)?)|\d+)\s*([A-Za-z/]+)?\s*$',
  );
  final m = regex.firstMatch(text);
  if (m == null) throw FormatException('Invalid rate format: $input');
  final numStr = _normalizeNumber(m.group(1)!);
  final unitStr = (m.group(2) ?? '').trim();
  final v = double.parse(numStr);

  if (unitStr.isEmpty) {
    final normalized = '${_composeNormalizedInput(numStr, 'b')}/s';
    return RateParsingResult(
      bitsPerSecond: v,
      normalizedInput: normalized,
      unitSymbol: 'b',
      isBitInput: true,
      rawValue: v,
    );
  }
  // Normalize: remove '/s' or 'ps' (case-insensitive)
  var u = unitStr
      .replaceAll(RegExp('/s', caseSensitive: false), '')
      .replaceAll(RegExp('ps', caseSensitive: false), '');
  // Check for bits vs bytes
  final lower = u.toLowerCase();
  final isBits = lower.contains('bit') ||
      lower.endsWith('bps') ||
      (u.isNotEmpty && u[u.length - 1] == 'b');
  final lastChar = u.isNotEmpty ? u[u.length - 1] : '';
  if (lastChar == 's' || lastChar == 'S') {
    u = u.substring(0, u.length - 1);
  }
  // Strip explicit "bps" and "bit(s)"
  u = u.replaceAll(RegExp('bps', caseSensitive: false), '');
  u = u.replaceAll(RegExp('bits?', caseSensitive: false), '');
  // Remove trailing singular b/B (already captured by isBits)
  if (u.isNotEmpty && (u.endsWith('b') || u.endsWith('B'))) {
    u = u.substring(0, u.length - 1);
  }

  final upper = u.toUpperCase();

  double mult;
  switch (standard) {
    case ByteStandard.si:
      const map = {
        '': 1.0,
        'K': 1e3,
        'KB': 1e3,
        'M': 1e6,
        'MB': 1e6,
        'G': 1e9,
        'GB': 1e9,
        'T': 1e12,
        'TB': 1e12,
        'P': 1e15,
        'PB': 1e15,
        'E': 1e18,
        'EB': 1e18,
        'Z': 1e21,
        'ZB': 1e21,
        'Y': 1e24,
        'YB': 1e24,
      };
      if (!map.containsKey(upper)) {
        throw FormatException('Unknown SI rate unit: $unitStr');
      }
      mult = map[upper]!;
      break;
    case ByteStandard.jedec:
      const mapJ = {
        'KB': 1024.0,
        'MB': 1024.0 * 1024,
        'GB': 1024.0 * 1024 * 1024,
        'TB': 1024.0 * 1024 * 1024 * 1024,
      };
      if (!mapJ.containsKey(upper) && upper != '') {
        throw FormatException('Unknown JEDEC rate unit: $unitStr');
      }
      mult = mapJ[upper] ?? 1.0;
      break;
    case ByteStandard.iec:
      const mapI = {
        'KI': 1024.0,
        'KIB': 1024.0,
        'MI': 1024.0 * 1024,
        'MIB': 1024.0 * 1024,
        'GI': 1024.0 * 1024 * 1024,
        'GIB': 1024.0 * 1024 * 1024,
        'TI': 1024.0 * 1024 * 1024 * 1024,
        'TIB': 1024.0 * 1024 * 1024 * 1024,
        'PI': 1024.0 * 1024 * 1024 * 1024 * 1024,
        'PIB': 1024.0 * 1024 * 1024 * 1024 * 1024,
        'EI': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024,
        'EIB': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024,
        'ZI': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
        'ZIB': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
        'YI': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
        'YIB': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
      };
      if (!mapI.containsKey(upper)) {
        throw FormatException('Unknown IEC rate unit: $unitStr');
      }
      mult = mapI[upper]!;
      break;
  }

  final bytesPerSecond = isBits ? (v * mult) / 8.0 : (v * mult);
  final bps = bytesPerSecond * 8.0;
  final canonicalSymbol = isBits
      ? _canonicalizeBitSymbol(
          u.isEmpty ? 'b' : '${u.toLowerCase()}b',
        )
      : _canonicalizeByteSymbol(u.isEmpty ? 'B' : '${u}B');
  final normalized = '${_composeNormalizedInput(numStr, canonicalSymbol)}/s';
  return RateParsingResult(
    bitsPerSecond: bps,
    normalizedInput: normalized,
    unitSymbol: canonicalSymbol,
    isBitInput: isBits,
    rawValue: v,
  );
}

/// Parses rate strings like '100 Mbps', '12.5 MB/s', '1Gbps', '800 kb/s'.
RateParsingResult parseRate({
  required String input,
  required ByteStandard standard,
}) {
  final normalized = _trimAndNormalize(input);
  if (_containsExpressionOperators(normalized)) {
    final evaluator = _RateExpressionEvaluator(
      input: normalized,
      standard: standard,
      sizeLiteralParser: (literal) {
        final result = _parseSizeLiteralInternal<SizeUnit>(
          input: literal,
          standard: standard,
        );
        return result.valueInBytes;
      },
    );
    return evaluator.evaluate();
  }
  return _parseRateLiteralInternal(
    input: input,
    standard: standard,
  );
}

ByteParsingResult<BigSizeUnit> _parseSizeBigLiteralInternal({
  required String input,
  required ByteStandard standard,
}) {
  final text = _trimAndNormalize(input);
  final regex = RegExp(
    r'^\s*([+-]?[0-9\.,\u00A0_\s]+)\s*([A-Za-z]+)?\s*$',
  );
  final m = regex.firstMatch(text);
  if (m == null) {
    throw FormatException('Invalid size format: $input');
  }
  final numStr = _normalizeNumber(m.group(1)!);
  final unitStrRaw = (m.group(2) ?? '').trim();
  final unitStr = unitStrRaw.isEmpty ? '' : unitStrRaw;
  final value = double.parse(numStr);

  var isBits = false;
  double multiplier;
  BigSizeUnit? unit;
  String unitSymbol;

  if (unitStr.isEmpty) {
    multiplier = 1;
    unit = BigSizeUnit.B;
    unitSymbol = 'B';
  } else {
    var u = unitStr;
    final lowerTrim = u.toLowerCase();
    const normalizedWordToSymbol = <String, String>{
      // bytes
      'byte': 'B', 'bytes': 'B',
      'kilobyte': 'KB', 'kilobytes': 'KB',
      'megabyte': 'MB', 'megabytes': 'MB',
      'gigabyte': 'GB', 'gigabytes': 'GB',
      'terabyte': 'TB', 'terabytes': 'TB',
      'petabyte': 'PB', 'petabytes': 'PB',
      'exabyte': 'EB', 'exabytes': 'EB',
      'zettabyte': 'ZB', 'zettabytes': 'ZB',
      'yottabyte': 'YB', 'yottabytes': 'YB',
      // bits
      'bit': 'b', 'bits': 'b',
      'kilobit': 'kb', 'kilobits': 'kb',
      'megabit': 'mb', 'megabits': 'mb',
      'gigabit': 'gb', 'gigabits': 'gb',
      'terabit': 'tb', 'terabits': 'tb',
      'petabit': 'pb', 'petabits': 'pb',
      'exabit': 'eb', 'exabits': 'eb',
      'zettabit': 'zb', 'zettabits': 'zb',
      'yottabit': 'yb', 'yottabits': 'yb',
      // IEC bytes
      'kibibyte': 'KiB', 'kibibytes': 'KiB',
      'mebibyte': 'MiB', 'mebibytes': 'MiB',
      'gibibyte': 'GiB', 'gibibytes': 'GiB',
      'tebibyte': 'TiB', 'tebibytes': 'TiB',
      'pebibyte': 'PiB', 'pebibytes': 'PiB',
      'exbibyte': 'EiB', 'exbibytes': 'EiB',
      'zebibyte': 'ZiB', 'zebibytes': 'ZiB',
      'yobibyte': 'YiB', 'yobibytes': 'YiB',
      // IEC bits
      'kibibit': 'kib', 'kibibits': 'kib',
      'mebibit': 'mib', 'mebibits': 'mib',
      'gibibit': 'gib', 'gibibits': 'gib',
      'tebibit': 'tib', 'tebibits': 'tib',
      'pebibit': 'pib', 'pebibits': 'pib',
      'exbibit': 'eib', 'exbibits': 'eib',
      'zebibit': 'zib', 'zebibits': 'zib',
      'yobibit': 'yib', 'yobibits': 'yib',
    };
    if (normalizedWordToSymbol.containsKey(lowerTrim)) {
      u = normalizedWordToSymbol[lowerTrim]!;
    }
    final upper = u.toUpperCase();
    final isLowerB = u.isNotEmpty && u[u.length - 1] == 'b' && u != 'B';
    if (isLowerB) isBits = true;

    if (isLowerB) {
      const siBit = {
        'kb': 1000.0,
        'mb': 1000.0 * 1000,
        'gb': 1000.0 * 1000 * 1000,
        'tb': 1000.0 * 1000 * 1000 * 1000,
        'pb': 1000.0 * 1000 * 1000 * 1000 * 1000,
        'eb': 1000.0 * 1000 * 1000 * 1000 * 1000 * 1000,
        'zb': 1000.0 * 1000.0 * 1000 * 1000 * 1000 * 1000 * 1000,
        'yb': 1000.0 * 1000.0 * 1000 * 1000 * 1000 * 1000 * 1000 * 1000,
      };
      const iecBit = {
        'kib': 1024.0,
        'mib': 1024.0 * 1024,
        'gib': 1024.0 * 1024 * 1024,
        'tib': 1024.0 * 1024 * 1024 * 1024,
        'pib': 1024.0 * 1024 * 1024 * 1024 * 1024,
        'eib': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024,
        'zib': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
        'yib': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
      };
      final lowerU = u.toLowerCase();
      final canonicalBitSymbol = _canonicalizeBitSymbol(lowerU);
      if (siBit.containsKey(lowerU)) {
        multiplier = siBit[lowerU]! / 8.0;
        final bytes = value * multiplier;
        return ByteParsingResult<BigSizeUnit>(
          valueInBytes: bytes,
          unit: BigSizeUnit.B,
          isBitInput: true,
          normalizedInput: _composeNormalizedInput(numStr, canonicalBitSymbol),
          unitSymbol: canonicalBitSymbol,
          rawValue: value,
        );
      }
      if (iecBit.containsKey(lowerU)) {
        multiplier = iecBit[lowerU]! / 8.0;
        final bytes = value * multiplier;
        return ByteParsingResult<BigSizeUnit>(
          valueInBytes: bytes,
          unit: BigSizeUnit.B,
          isBitInput: true,
          normalizedInput: _composeNormalizedInput(numStr, canonicalBitSymbol),
          unitSymbol: canonicalBitSymbol,
          rawValue: value,
        );
      }
    }

    if (u == 'b' || lowerTrim == 'bit' || lowerTrim == 'bits') {
      isBits = true;
      multiplier = 1 / 8;
      unit = BigSizeUnit.B;
      unitSymbol = 'b';
    } else if (upper == 'B') {
      multiplier = 1;
      unit = BigSizeUnit.B;
      unitSymbol = 'B';
    } else {
      switch (standard) {
        case ByteStandard.si:
          final upperNoB =
              isLowerB ? upper.substring(0, upper.length - 1) : upper;
          const map = {
            'YB': 1e24,
            'ZB': 1e21,
            'EB': 1e18,
            'PB': 1e15,
            'TB': 1e12,
            'GB': 1e9,
            'MB': 1e6,
            'KB': 1e3,
            'B': 1.0,
          };
          const unitMap = {
            'YB': BigSizeUnit.YB,
            'ZB': BigSizeUnit.ZB,
            'EB': BigSizeUnit.EB,
            'PB': BigSizeUnit.PB,
            'TB': BigSizeUnit.TB,
            'GB': BigSizeUnit.GB,
            'MB': BigSizeUnit.MB,
            'KB': BigSizeUnit.KB,
            'B': BigSizeUnit.B,
          };
          if (!map.containsKey(upperNoB)) {
            throw FormatException('Unknown SI unit: $unitStr');
          }
          multiplier = map[upperNoB]!;
          unit = unitMap[upperNoB];
          if (isLowerB) {
            multiplier /= 8;
            unitSymbol = _canonicalizeBitSymbol(u);
          } else {
            unitSymbol = _canonicalizeByteSymbol(upperNoB);
          }
          break;
        case ByteStandard.jedec:
          final key = isLowerB ? upper.substring(0, upper.length - 1) : upper;
          const mapJ = {
            'TB': 1024.0 * 1024 * 1024 * 1024,
            'GB': 1024.0 * 1024 * 1024,
            'MB': 1024.0 * 1024,
            'KB': 1024.0,
            'B': 1.0,
          };
          multiplier = mapJ[key] ?? 1.0;
          if (isLowerB) {
            multiplier /= 8;
            unitSymbol = _canonicalizeBitSymbol('${key.toLowerCase()}b');
          } else {
            unitSymbol = _canonicalizeByteSymbol(key);
          }
          unit = {
            'TB': BigSizeUnit.TB,
            'GB': BigSizeUnit.GB,
            'MB': BigSizeUnit.MB,
            'KB': BigSizeUnit.KB,
            'B': BigSizeUnit.B,
          }[key];
          break;
        case ByteStandard.iec:
          final keyIec = isLowerB ? u.substring(0, u.length - 1) : u;
          const mapI = {
            'YiB': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
            'ZiB': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
            'EiB': 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024,
            'PiB': 1024.0 * 1024 * 1024 * 1024 * 1024,
            'TiB': 1024.0 * 1024 * 1024 * 1024,
            'GiB': 1024.0 * 1024 * 1024,
            'MiB': 1024.0 * 1024,
            'KiB': 1024.0,
            'B': 1.0,
          };
          const unitMapI = {
            'YiB': BigSizeUnit.YB,
            'ZiB': BigSizeUnit.ZB,
            'EiB': BigSizeUnit.EB,
            'PiB': BigSizeUnit.PB,
            'TiB': BigSizeUnit.TB,
            'GiB': BigSizeUnit.GB,
            'MiB': BigSizeUnit.MB,
            'KiB': BigSizeUnit.KB,
            'B': BigSizeUnit.B,
          };
          multiplier = mapI[keyIec] ?? 1.0;
          if (isLowerB) {
            multiplier /= 8;
            unitSymbol = _canonicalizeBitSymbol('${keyIec.toLowerCase()}b');
          } else {
            unitSymbol = _canonicalizeByteSymbol(keyIec);
          }
          unit = unitMapI[keyIec];
          break;
      }
    }
  }

  final bytes = value * multiplier;
  final normalized = _composeNormalizedInput(numStr, unitSymbol);
  return ByteParsingResult<BigSizeUnit>(
    valueInBytes: bytes,
    unit: unit,
    isBitInput: isBits,
    normalizedInput: normalized,
    unitSymbol: unitSymbol,
    rawValue: value,
  );
}

ByteParsingResult<BigSizeUnit> parseSizeBig({
  required String input,
  required ByteStandard standard,
}) {
  final normalized = _trimAndNormalize(input);
  if (_containsExpressionOperators(normalized)) {
    final evaluator = _SizeExpressionEvaluator(
      input: normalized,
      literalParser: (literal) {
        final result = _parseSizeBigLiteralInternal(
          input: literal,
          standard: standard,
        );
        return result.valueInBytes;
      },
    );
    return evaluator.evaluate<BigSizeUnit>();
  }
  return _parseSizeBigLiteralInternal(
    input: input,
    standard: standard,
  );
}

final _letterRegExp = RegExp('[A-Za-z]');
final _durationHintRegExp = RegExp(
  r'(ns|nano(?:second)?s?|us|µs|μs|micro(?:second)?s?|ms|millisecond(?:s)?|s|sec|secs|second(?:s)?|m|min|mins|minute(?:s)?|h|hr|hrs|hour(?:s)?|d|day|days)\s*$',
  caseSensitive: false,
);
final _rateHintRegExp = RegExp(
  r'(?:/s|/sec|/second|\bper\b|bps|ps)',
  caseSensitive: false,
);

typedef _LiteralResolver = _ExprValue Function(_Token token);

class _SizeExpressionEvaluator {
  _SizeExpressionEvaluator({
    required this.input,
    required double Function(String literal) literalParser,
  }) : _sizeLiteralParser = literalParser;

  final String input;
  final double Function(String literal) _sizeLiteralParser;

  ByteParsingResult<TUnit> evaluate<TUnit>() {
    final parser = _ExpressionParser(
      input: input,
      literalResolver: _resolveLiteral,
    );
    final value = parser.parse();
    if (value.sizePower != 1 || value.timePower != 0) {
      throw FormatException(
          'Expression does not resolve to a byte size', input);
    }
    final bytes = value.value;
    if (bytes.isNaN || bytes.isInfinite) {
      throw FormatException('Expression produced an invalid byte value', input);
    }
    return ByteParsingResult<TUnit>(
      valueInBytes: bytes,
      unit: null,
      isBitInput: false,
      normalizedInput: input,
      unitSymbol: 'B',
      rawValue: bytes,
    );
  }

  _ExprValue _resolveLiteral(_Token token) {
    final text = token.lexeme.trim();
    if (text.isEmpty) {
      throw FormatException('Unexpected empty literal', input, token.start);
    }
    if (!_letterRegExp.hasMatch(text)) {
      final normalized = _normalizeNumber(text);
      double numeric;
      try {
        numeric = double.parse(normalized);
      } catch (_) {
        throw FormatException(
            'Invalid numeric literal: $text', input, token.start);
      }
      return _ExprValue(numeric, 0, 0);
    }
    try {
      final bytes = _sizeLiteralParser(text);
      if (bytes.isNaN || bytes.isInfinite) {
        throw FormatException('Literal produced an invalid byte value: $text');
      }
      return _ExprValue(bytes, 1, 0);
    } on FormatException catch (e) {
      throw FormatException(
        e.message,
        input,
        token.start + (e.offset ?? 0),
      );
    }
  }
}

class _RateExpressionEvaluator {
  _RateExpressionEvaluator({
    required this.input,
    required this.standard,
    required double Function(String literal) sizeLiteralParser,
  }) : _sizeLiteralParser = sizeLiteralParser;

  final String input;
  final ByteStandard standard;
  final double Function(String literal) _sizeLiteralParser;

  RateParsingResult evaluate() {
    final parser = _ExpressionParser(
      input: input,
      literalResolver: _resolveLiteral,
    );
    final value = parser.parse();
    if (value.sizePower != 1 || value.timePower != -1) {
      throw FormatException(
          'Expression does not resolve to a data rate', input);
    }
    final bytesPerSecond = value.value;
    if (bytesPerSecond.isNaN || bytesPerSecond.isInfinite) {
      throw FormatException('Expression produced an invalid rate', input);
    }
    return RateParsingResult(
      bitsPerSecond: bytesPerSecond * 8.0,
      normalizedInput: input,
      unitSymbol: 'expression',
      isBitInput: false,
      rawValue: bytesPerSecond,
    );
  }

  _ExprValue _resolveLiteral(_Token token) {
    final text = token.lexeme.trim();
    if (text.isEmpty) {
      throw FormatException('Unexpected empty literal', input, token.start);
    }

    if (_looksLikeDurationLiteral(text)) {
      try {
        final seconds = _parseDurationLiteral(text);
        return _ExprValue(seconds, 0, 1);
      } on FormatException catch (e) {
        throw FormatException(
          e.message,
          input,
          token.start + (e.offset ?? 0),
        );
      }
    }

    if (_looksLikeRateLiteralCandidate(text)) {
      try {
        final result = _parseRateLiteralInternal(
          input: text,
          standard: standard,
        );
        final bytesPerSecond = result.bitsPerSecond / 8.0;
        return _ExprValue(bytesPerSecond, 1, -1);
      } on FormatException catch (e) {
        throw FormatException(
          e.message,
          input,
          token.start + (e.offset ?? 0),
        );
      }
    }

    if (_letterRegExp.hasMatch(text)) {
      try {
        final bytes = _sizeLiteralParser(text);
        if (bytes.isNaN || bytes.isInfinite) {
          throw FormatException(
              'Literal produced an invalid byte value: $text');
        }
        return _ExprValue(bytes, 1, 0);
      } on FormatException catch (e) {
        throw FormatException(
          e.message,
          input,
          token.start + (e.offset ?? 0),
        );
      }
    }

    final normalized = _normalizeNumber(text);
    double numeric;
    try {
      numeric = double.parse(normalized);
    } catch (_) {
      throw FormatException('Unrecognized literal: $text', input, token.start);
    }
    return _ExprValue(numeric, 0, 0);
  }
}

class _ExpressionParser {
  _ExpressionParser({
    required this.input,
    required _LiteralResolver literalResolver,
  })  : _tokens = _tokenizeExpression(input),
        _literalResolver = literalResolver;

  final String input;
  final List<_Token> _tokens;
  final _LiteralResolver _literalResolver;
  int _current = 0;

  _ExprValue parse() {
    final value = _expression();
    _consume(_TokenType.eof, 'Unexpected trailing tokens');
    return value;
  }

  _ExprValue _expression() {
    var value = _term();
    while (true) {
      if (_match(_TokenType.plus)) {
        final op = _previous;
        final right = _term();
        value = _combineAdd(value, right, op, true);
        continue;
      }
      if (_match(_TokenType.minus)) {
        final op = _previous;
        final right = _term();
        value = _combineAdd(value, right, op, false);
        continue;
      }
      break;
    }
    return value;
  }

  _ExprValue _term() {
    var value = _factor();
    while (true) {
      if (_match(_TokenType.star)) {
        final op = _previous;
        final right = _factor();
        value = _combineMultiply(value, right, op);
        continue;
      }
      if (_match(_TokenType.slash)) {
        final op = _previous;
        final right = _factor();
        value = _combineDivide(value, right, op);
        continue;
      }
      break;
    }
    return value;
  }

  _ExprValue _factor() {
    if (_match(_TokenType.plus)) {
      return _factor();
    }
    if (_match(_TokenType.minus)) {
      final value = _factor();
      return _ExprValue(-value.value, value.sizePower, value.timePower);
    }
    if (_match(_TokenType.leftParen)) {
      final expr = _expression();
      _consume(_TokenType.rightParen, 'Missing closing parenthesis');
      return expr;
    }
    if (_match(_TokenType.literal)) {
      return _literalResolver(_previous);
    }
    final token = _currentToken;
    throw FormatException('Unexpected token in expression', input, token.start);
  }

  bool _match(_TokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }
    return false;
  }

  bool _check(_TokenType type) {
    if (_current >= _tokens.length) return false;
    return _tokens[_current].type == type;
  }

  _Token _advance() {
    if (_current < _tokens.length) {
      _current++;
    }
    return _previous;
  }

  _Token get _previous => _tokens[_current - 1];

  _Token get _currentToken => _tokens[_current];

  _Token _consume(_TokenType type, String message) {
    if (_check(type)) return _advance();
    final token = _currentToken;
    throw FormatException(message, input, token.start);
  }

  _ExprValue _combineAdd(
    _ExprValue left,
    _ExprValue right,
    _Token op,
    bool isAddition,
  ) {
    if (left.sizePower != right.sizePower ||
        left.timePower != right.timePower) {
      final opName = isAddition ? 'add' : 'subtract';
      throw FormatException(
        'Cannot $opName values with incompatible units',
        input,
        op.start,
      );
    }
    final resultValue =
        isAddition ? left.value + right.value : left.value - right.value;
    if (resultValue.isNaN || resultValue.isInfinite) {
      throw FormatException(
          'Expression produced a non-finite result', input, op.start);
    }
    return _ExprValue(resultValue, left.sizePower, left.timePower);
  }

  _ExprValue _combineMultiply(
    _ExprValue left,
    _ExprValue right,
    _Token op,
  ) {
    final resultValue = left.value * right.value;
    if (resultValue.isNaN || resultValue.isInfinite) {
      throw FormatException(
          'Expression produced a non-finite result', input, op.start);
    }
    return _ExprValue(
      resultValue,
      left.sizePower + right.sizePower,
      left.timePower + right.timePower,
    );
  }

  _ExprValue _combineDivide(
    _ExprValue left,
    _ExprValue right,
    _Token op,
  ) {
    if (right.value == 0) {
      throw FormatException('Division by zero in expression', input, op.start);
    }
    final resultValue = left.value / right.value;
    if (resultValue.isNaN || resultValue.isInfinite) {
      throw FormatException(
          'Expression produced a non-finite result', input, op.start);
    }
    return _ExprValue(
      resultValue,
      left.sizePower - right.sizePower,
      left.timePower - right.timePower,
    );
  }
}

enum _TokenType {
  literal,
  plus,
  minus,
  star,
  slash,
  leftParen,
  rightParen,
  eof
}

class _Token {
  const _Token(this.type, this.lexeme, this.start);

  final _TokenType type;
  final String lexeme;
  final int start;
}

class _ExprValue {
  const _ExprValue(this.value, this.sizePower, this.timePower);

  final double value;
  final int sizePower;
  final int timePower;
}

List<_Token> _tokenizeExpression(String input) {
  final tokens = <_Token>[];
  var index = 0;
  while (index < input.length) {
    final ch = input[index];
    if (ch.trim().isEmpty) {
      index++;
      continue;
    }
    if (_isOperatorOrParen(ch)) {
      final type = switch (ch) {
        '+' => _TokenType.plus,
        '-' => _TokenType.minus,
        '*' => _TokenType.star,
        '/' => _TokenType.slash,
        '(' => _TokenType.leftParen,
        ')' => _TokenType.rightParen,
        _ => _TokenType.literal,
      };
      tokens.add(_Token(type, ch, index));
      index++;
      continue;
    }
    final start = index;
    while (index < input.length && !_isOperatorOrParen(input[index])) {
      index++;
    }
    final lexeme = input.substring(start, index);
    tokens.add(_Token(_TokenType.literal, lexeme, start));
  }
  tokens.add(_Token(_TokenType.eof, '', input.length));
  return tokens;
}

bool _isOperatorOrParen(String ch) {
  return ch == '+' ||
      ch == '-' ||
      ch == '*' ||
      ch == '/' ||
      ch == '(' ||
      ch == ')';
}

double _parseDurationLiteral(String literal) {
  final text = _trimAndNormalize(literal).replaceAll('μ', 'µ');
  final regex = RegExp(
    r'^([+-]?[0-9\.,\u00A0_\s]+)\s*([a-zµ]+)$',
    caseSensitive: false,
  );
  final match = regex.firstMatch(text);
  if (match == null) {
    throw FormatException('Invalid duration literal: $literal');
  }
  final number = double.parse(_normalizeNumber(match.group(1)!));
  final unitRaw = match.group(2)!.toLowerCase();
  final unit = unitRaw.replaceAll('μ', 'µ');
  const factors = {
    'ns': 1e-9,
    'nanosecond': 1e-9,
    'nanoseconds': 1e-9,
    'us': 1e-6,
    'µs': 1e-6,
    'microsecond': 1e-6,
    'microseconds': 1e-6,
    'ms': 1e-3,
    'millisecond': 1e-3,
    'milliseconds': 1e-3,
    's': 1.0,
    'sec': 1.0,
    'secs': 1.0,
    'second': 1.0,
    'seconds': 1.0,
    'm': 60.0,
    'min': 60.0,
    'mins': 60.0,
    'minute': 60.0,
    'minutes': 60.0,
    'h': 3600.0,
    'hr': 3600.0,
    'hrs': 3600.0,
    'hour': 3600.0,
    'hours': 3600.0,
    'd': 86400.0,
    'day': 86400.0,
    'days': 86400.0,
  };
  final factor = factors[unit];
  if (factor == null) {
    throw FormatException('Unknown duration unit: $unitRaw');
  }
  final seconds = number * factor;
  if (seconds.isNaN || seconds.isInfinite) {
    throw FormatException('Duration evaluates to an invalid value: $literal');
  }
  return seconds;
}

bool _looksLikeDurationLiteral(String literal) {
  final lower = literal.trim().toLowerCase();
  return _durationHintRegExp.hasMatch(lower);
}

bool _looksLikeRateLiteralCandidate(String literal) {
  final lower = literal.trim().toLowerCase();
  return _rateHintRegExp.hasMatch(lower);
}
