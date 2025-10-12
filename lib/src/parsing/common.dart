part of '../_parsing.dart';

// SI (decimal) definitions for SizeUnit (limited up to PB)
// Note: SizeUnit is limited to PB in this path; larger SI units are handled by BigSizeUnit.
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

// Common helpers and regexes shared across parsing parts
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
        // Treat '/s', '/sec', '/second' (case-insensitive, optional whitespace) as part of rate literal, not expression
        final tail = input.substring(i);
        final rateSuffix =
            RegExp(r"^/\s*(s|sec|second)\b", caseSensitive: false);
        final m = rateSuffix.firstMatch(tail);
        if (m != null) {
          // Skip past the matched suffix and continue scanning
          i += m.group(0)!.length - 1; // -1 because for-loop will i++
          continue;
        }
        return true;
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

final _letterRegExp = RegExp('[A-Za-z]');
final _rateHintRegExp = RegExp(
  r'(?:/s|/sec|/second|\bper\b|bps|ps)',
  caseSensitive: false,
);

bool _looksLikeRateLiteralCandidate(String literal) {
  final lower = literal.trim().toLowerCase();
  return _rateHintRegExp.hasMatch(lower) &&
      // Exclude bare-word literals (no digits) that are likely duration units
      RegExp(r'[0-9]').hasMatch(lower);
}

// Numeric/format helpers shared by humanize and formatters
/// Small numeric helper utilities used by formatters.
class MathHelper {
  /// Returns 10^p as a double. For p <= 0 returns 1.0.
  static double pow10(int p) =>
      p <= 0 ? 1.0 : List.filled(p, 10).fold(1, (a, b) => a * b);
}

String _toFixedTrim(double v, int precision) {
  // Fast path for integers: avoid fixed formatting altogether
  final intV = v.truncateToDouble();
  if (v == intV) return intV.toInt().toString();
  var s = v.toStringAsFixed(precision);
  final dot = s.indexOf('.');
  if (dot == -1) return s;
  var end = s.length;
  // Trim trailing zeros
  while (end > dot + 1 && s.codeUnitAt(end - 1) == 0x30) {
    end--;
  }
  // If only the dot remains, trim it as well
  if (end == dot + 1) end = dot;
  if (end == s.length) return s; // nothing trimmed
  return s.substring(0, end);
}

String _formatNumber(double v, int precision) {
  // Always produce fixed then trim trailing zeros and decimal point
  return _toFixedTrim(v, precision);
}

double _applyRoundingAndFractionDigits(double v, HumanizeOptions opt) {
  int max =
      opt.maximumFractionDigits ?? opt.minimumFractionDigits ?? opt.precision;
  if (opt.minimumFractionDigits != null || opt.maximumFractionDigits != null) {
    max = opt.maximumFractionDigits ?? opt.minimumFractionDigits ?? 0;
  }
  final factor = MathHelper.pow10(max);
  final scaled = v * factor;
  double rounded;
  if ((opt.minimumFractionDigits != null ||
          opt.maximumFractionDigits != null) &&
      opt.truncate) {
    // Truncate toward zero
    rounded = v.isNegative ? (scaled.ceilToDouble()) : (scaled.floorToDouble());
    return rounded / factor;
  }
  switch (opt.roundingMode) {
    case FormattingRoundingMode.halfAwayFromZero:
      final floor = scaled.floorToDouble();
      final diff = scaled - floor;
      if (diff > 0.5 || (diff == 0.5 && scaled >= 0)) {
        rounded = floor + 1;
      } else if (diff < 0.5 || (diff == 0.5 && scaled < 0)) {
        rounded = floor;
      } else {
        rounded = floor; // default
      }
      break;
    case FormattingRoundingMode.halfToEven:
      final n = scaled.roundToDouble();
      // Dart's round is half away from zero; implement banker's by adjusting when exactly .5
      final floor = scaled.floorToDouble();
      final diff = scaled - floor;
      if (diff == 0.5) {
        final even = (floor.toInt() % 2 == 0) ? floor : floor + 1;
        rounded = even;
      } else if (diff == -0.5) {
        final ceil = floor + 1;
        final even = (ceil.toInt() % 2 == 0) ? ceil : floor;
        rounded = even;
      } else {
        rounded = n;
      }
      break;
  }
  return rounded / factor;
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
    final dot = s.indexOf('.');
    if (dot != -1) {
      final keep = dot + 1 + min;
      if (s.length > keep) {
        s = s.substring(0, keep);
      }
    }
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

// --- Humanize shared constants and helpers ---

// Thresholds and symbols for humanize auto-scale
/// SI thresholds for auto-scaling values (largest-first).
const List<double> kSiThresholds = [
  1e30, // QB (Quettabyte)
  1e27, // RB (Ronnabyte)
  1e24, // YB
  1e21, // ZB
  1e18, // EB
  1e15, // PB
  1e12, // TB
  1e9, // GB
  1e6, // MB
  1e3, // KB
];

/// SI unit symbols aligned to [kSiThresholds].
const List<String> kSiSymbols = [
  'QB',
  'RB',
  'YB',
  'ZB',
  'EB',
  'PB',
  'TB',
  'GB',
  'MB',
  'KB',
];

/// IEC thresholds for auto-scaling values (largest-first).
const List<double> kIecThresholds = [
  1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024, // YiB
  1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024, // ZiB
  1024.0 * 1024 * 1024 * 1024 * 1024 * 1024, // EiB
  1024.0 * 1024 * 1024 * 1024 * 1024, // PiB
  1024.0 * 1024 * 1024 * 1024, // TiB
  1024.0 * 1024 * 1024, // GiB
  1024.0 * 1024, // MiB
  1024.0, // KiB
];

/// IEC unit symbols aligned to [kIecThresholds].
const List<String> kIecSymbols = [
  'YiB',
  'ZiB',
  'EiB',
  'PiB',
  'TiB',
  'GiB',
  'MiB',
  'KiB',
];

/// JEDEC thresholds for auto-scaling values (largest-first).
const List<double> kJedecThresholds = [
  1024.0 * 1024 * 1024 * 1024, // TB
  1024.0 * 1024 * 1024, // GB
  1024.0 * 1024, // MB
  1024.0, // KB
];

/// JEDEC unit symbols aligned to [kJedecThresholds].
const List<String> kJedecSymbols = ['TB', 'GB', 'MB', 'KB'];

/// Resolves the effective [ByteStandard] from [HumanizeOptions] and policy.
ByteStandard _selectEffectiveStandard(HumanizeOptions opt) {
  if (opt.policy == null || opt.policy == UnitPolicy.auto) {
    return opt.standard;
  }
  switch (opt.policy!) {
    case UnitPolicy.preferBinaryPowers:
    case UnitPolicy.memory:
      return ByteStandard.iec;
    case UnitPolicy.storage:
      return ByteStandard.jedec;
    case UnitPolicy.network:
      return ByteStandard.si;
    case UnitPolicy.auto:
      return opt.standard;
  }
}

bool _isFastSiDefault(HumanizeOptions opt) =>
    !opt.useBits &&
    opt.standard == ByteStandard.si &&
    opt.policy == null &&
    opt.forceUnit == null &&
    !opt.fullForm &&
    (opt.locale == null || opt.locale!.isEmpty) &&
    opt.separator == null &&
    opt.minimumFractionDigits == null &&
    opt.maximumFractionDigits == null &&
    !opt.truncate &&
    !opt.signed &&
    opt.spacer == null &&
    opt.showSpace == true &&
    !opt.nonBreakingSpace &&
    opt.siKSymbolCase == SiKSymbolCase.upperK &&
    opt.fixedWidth == null &&
    !opt.includeSignInWidth;

bool _isFastJedecDefault(HumanizeOptions opt) =>
    !opt.useBits &&
    opt.standard == ByteStandard.jedec &&
    opt.policy == null &&
    opt.forceUnit == null &&
    !opt.fullForm &&
    (opt.locale == null || opt.locale!.isEmpty) &&
    opt.separator == null &&
    opt.minimumFractionDigits == null &&
    opt.maximumFractionDigits == null &&
    !opt.truncate &&
    !opt.signed &&
    opt.spacer == null &&
    opt.showSpace == true &&
    !opt.nonBreakingSpace &&
    opt.fixedWidth == null &&
    !opt.includeSignInWidth;

bool _isFastSiBitsDefault(HumanizeOptions opt) =>
    opt.useBits &&
    opt.standard == ByteStandard.si &&
    opt.policy == null &&
    opt.forceUnit == null &&
    !opt.fullForm &&
    (opt.locale == null || opt.locale!.isEmpty) &&
    opt.separator == null &&
    opt.minimumFractionDigits == null &&
    opt.maximumFractionDigits == null &&
    !opt.truncate &&
    !opt.signed &&
    opt.spacer == null &&
    opt.showSpace == true &&
    !opt.nonBreakingSpace &&
    opt.fixedWidth == null &&
    !opt.includeSignInWidth;

bool _isFastIecDefault(HumanizeOptions opt) =>
    !opt.useBits &&
    opt.standard == ByteStandard.iec &&
    opt.policy == null &&
    opt.forceUnit == null &&
    !opt.fullForm &&
    (opt.locale == null || opt.locale!.isEmpty) &&
    opt.separator == null &&
    opt.minimumFractionDigits == null &&
    opt.maximumFractionDigits == null &&
    !opt.truncate &&
    !opt.signed &&
    opt.spacer == null &&
    opt.showSpace == true &&
    !opt.nonBreakingSpace &&
    opt.fixedWidth == null &&
    !opt.includeSignInWidth;

bool _isFastForcedDefault(HumanizeOptions opt) =>
    opt.forceUnit != null &&
    opt.forceUnit!.isNotEmpty &&
    !opt.fullForm &&
    (opt.locale == null || opt.locale!.isEmpty) &&
    opt.separator == null &&
    opt.minimumFractionDigits == null &&
    opt.maximumFractionDigits == null &&
    !opt.truncate &&
    !opt.signed &&
    opt.spacer == null &&
    opt.showSpace == true &&
    !opt.nonBreakingSpace &&
    opt.fixedWidth == null &&
    !opt.includeSignInWidth &&
    opt.siKSymbolCase == SiKSymbolCase.upperK;

String _computeSpace(HumanizeOptions opt) {
  if (opt.spacer != null) return opt.spacer!;
  if (!opt.showSpace) return '';
  return opt.nonBreakingSpace ? '\u00A0' : ' ';
}

String _signedPrefixFor(double v, HumanizeOptions opt) {
  if (!opt.signed) return '';
  if (v > 0) return '+';
  if (v < 0) return '-';
  return ' ';
}

// _unitSymbolFor moved next to humanize() in _parsing.dart
