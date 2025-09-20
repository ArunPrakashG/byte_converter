import 'byte_enums.dart';

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
  });
  final double valueInBytes;
  final TUnit? unit;
  final bool isBitInput;
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

String _trimAndNormalize(String input) {
  // Collapse whitespace (including NBSP) to single spaces and trim ends
  return input.replaceAll(RegExp(r'[\u00A0\s]+'), ' ').trim();
}

/// Normalize a locale-formatted number string into a canonical form Dart can parse.
/// - Removes grouping separators (space, NBSP, underscore)
/// - Resolves decimal separator (comma or dot). If both appear, the last one is taken as decimal.
String _normalizeNumber(String s) {
  // Remove grouping (spaces, NBSP, underscores)
  var t = s.replaceAll(RegExp(r'[\u00A0_ ]'), '');
  final hasComma = t.contains(',');
  final hasDot = t.contains('.');
  if (hasComma && hasDot) {
    // Assume last occurrence is decimal separator
    final lastComma = t.lastIndexOf(',');
    final lastDot = t.lastIndexOf('.');
    final decIdx = lastComma > lastDot ? lastComma : lastDot;
    final digitsOnly = t.replaceAll(RegExp(r'[\.,]'), '');
    return '${digitsOnly.substring(0, decIdx)}.${digitsOnly.substring(decIdx)}';
  } else if (hasComma && !hasDot) {
    t = t.replaceAll(',', '.');
  }
  return t;
}

/// Parses size strings like "1.5 GB", "2GiB", "1024 B", "100 KB", "10 Mb".
/// Supports SI, IEC, and JEDEC standards. Bits are recognized via suffix (bit, b, kb, Mb, etc.).
ByteParsingResult<TUnit> parseSize<TUnit>({
  required String input,
  required ByteStandard standard,
}) {
  final text = _trimAndNormalize(input);
  final regex = RegExp(
    r'^\s*([+-]?(?:[\d_\u00A0\s]+(?:[\.,][\d_\u00A0\s]+)?)|\d+)\s*([A-Za-z]+)?\s*$',
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
  TUnit? unit;

  if (unitStr.isEmpty) {
    // default bytes
    multiplier = 1;
    unit = null;
  } else {
    // Normalize common full-form words to symbols (e.g., 'megabytes' -> 'MB', 'kibibits' -> 'kib')
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
    if (isLowerB) {
      isBits = true;
    }
    const iec = _iecSymbols;

    // Handle explicit bit-based units like 'kb','Mb','gib','kib' directly
    if (isLowerB) {
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
      final lowerU = u.toLowerCase();
      if (siBit.containsKey(lowerU)) {
        isBits = true;
        multiplier = siBit[lowerU]! / 8.0;
        unit = null;
        final bytes = value * multiplier;
        return ByteParsingResult<TUnit>(
          valueInBytes: bytes,
          unit: unit,
          isBitInput: isBits,
        );
      }
      if (iecBit.containsKey(lowerU)) {
        isBits = true;
        multiplier = iecBit[lowerU]! / 8.0;
        unit = null;
        final bytes = value * multiplier;
        return ByteParsingResult<TUnit>(
          valueInBytes: bytes,
          unit: unit,
          isBitInput: isBits,
        );
      }
    }

    if (u == 'b' || lowerTrim == 'bit' || lowerTrim == 'bits') {
      isBits = true;
      multiplier = 1 / 8;
      unit = null;
    } else if (upper == 'B') {
      multiplier = 1;
      unit = null;
    } else {
      switch (standard) {
        case ByteStandard.si:
          // SI expects symbols like KB, MB, GB; also Mb, Gb etc for bits
          final upperNoB =
              isLowerB ? upper.substring(0, upper.length - 1) : upper;
          final match = _siUnits.firstWhere(
            (e) => e.symbol.toUpperCase() == upperNoB,
            orElse: () => const _UnitDef('B', SizeUnit.B, 1),
          );
          multiplier = match.multiplier;
          if (isLowerB) multiplier /= 8; // bits to bytes
          unit = match.unit as TUnit;
          break;
        case ByteStandard.jedec:
          final key = isLowerB ? upper.substring(0, upper.length - 1) : upper;
          if (_jedecMultipliers.containsKey(key)) {
            multiplier = _jedecMultipliers[key]!;
            if (isLowerB) multiplier /= 8;
            // Map to nearest SizeUnit
            final map = {
              'KB': SizeUnit.KB,
              'MB': SizeUnit.MB,
              'GB': SizeUnit.GB,
            };
            unit = map[key] as TUnit?;
          } else if (key == 'B') {
            multiplier = 1;
          } else {
            throw FormatException('Unknown unit for JEDEC: $unitStr');
          }
          break;
        case ByteStandard.iec:
          final keyIec = isLowerB ? u.substring(0, u.length - 1) : u;
          if (iec.containsKey(keyIec)) {
            multiplier = iec[keyIec]!;
          } else {
            throw FormatException('Unknown IEC unit: $unitStr');
          }
          if (isLowerB) multiplier /= 8;
          unit = null; // IEC uses separate enum in Big but we keep null here
          break;
      }
    }
  }

  final bytes = value * multiplier;
  return ByteParsingResult<TUnit>(
    valueInBytes: bytes,
    unit: unit,
    isBitInput: isBits,
  );
}

class HumanizeOptions {
  const HumanizeOptions({
    this.standard = ByteStandard.si,
    this.useBits = false,
    this.precision = 2,
    this.showSpace = true,
    this.fullForm = false,
    this.fullForms,
    this.separator,
    this.spacer,
    this.minimumFractionDigits,
    this.maximumFractionDigits,
    this.signed = false,
    this.forceUnit,
  });
  final ByteStandard standard;
  final bool useBits;
  final int precision;
  final bool showSpace;
  final bool fullForm;
  final Map<String, String>? fullForms;
  final String? separator;
  final String? spacer;
  final int? minimumFractionDigits;
  final int? maximumFractionDigits;
  final bool signed;
  final String? forceUnit;
}

class HumanizeResult {
  const HumanizeResult(this.value, this.symbol, this.text);
  final double value;
  final String symbol;
  final String text;
}

HumanizeResult humanize(double bytes, HumanizeOptions opt) {
  const si = [
    1e24, // YB
    1e21, // ZB
    1e18, // EB
    1e15, // PB
    1e12, // TB
    1e9, // GB
    1e6, // MB
    1e3, // KB
  ];
  const siSym = ['YB', 'ZB', 'EB', 'PB', 'TB', 'GB', 'MB', 'KB'];
  const iec = [
    1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024, // YiB
    1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024, // ZiB
    1024.0 * 1024 * 1024 * 1024 * 1024 * 1024, // EiB
    1024.0 * 1024 * 1024 * 1024 * 1024, // PiB
    1024.0 * 1024 * 1024 * 1024, // TiB
    1024.0 * 1024 * 1024, // GiB
    1024.0 * 1024, // MiB
    1024.0, // KiB
  ];
  const iecSym = ['YiB', 'ZiB', 'EiB', 'PiB', 'TiB', 'GiB', 'MiB', 'KiB'];
  const jedec = [
    1024.0 * 1024 * 1024 * 1024, // TB
    1024.0 * 1024 * 1024, // GB
    1024.0 * 1024, // MB
    1024.0, // KB
  ];
  const jedecSym = ['TB', 'GB', 'MB', 'KB'];

  var value = bytes;
  final symbol = opt.useBits ? 'b' : 'B';
  final space = opt.spacer ?? (opt.showSpace ? ' ' : '');
  if (opt.useBits) value = bytes * 8;

  List numList;
  List<String> symList;
  switch (opt.standard) {
    case ByteStandard.si:
      numList = si;
      symList = siSym;
      break;
    case ByteStandard.iec:
      numList = iec;
      symList = iecSym;
      break;
    case ByteStandard.jedec:
      numList = jedec;
      symList = jedecSym;
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
    for (var i = 0; i < numList.length; i++) {
      final threshold = (numList[i] as num).toDouble();
      if ((opt.useBits ? value : bytes) >= threshold) {
        base = threshold;
        chosenSymbol = symList[i];
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
  final numStr = _formatNumberAdvanced(v, opt);

  // Full-form unit names
  String unitOut;
  if (opt.fullForm) {
    final full = _fullFormName(unitSymbol, opt.useBits);
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

String _fullFormName(String symbol, bool bits) {
  // Map common symbols to full names (English defaults)
  final map = <String, String>{
    'YB': 'yottabytes',
    'ZB': 'zettabytes',
    'EB': 'exabytes',
    'PB': 'petabytes',
    'TB': 'terabytes',
    'GB': 'gigabytes',
    'MB': 'megabytes',
    'KB': 'kilobytes',
    'B': 'bytes',
    'YiB': 'yobibytes',
    'ZiB': 'zebibytes',
    'EiB': 'exbibytes',
    'PiB': 'pebibytes',
    'TiB': 'tebibytes',
    'GiB': 'gibibytes',
    'MiB': 'mebibytes',
    'KiB': 'kibibytes',
    'yb': 'yottabits',
    'zb': 'zettabits',
    'eb': 'exabits',
    'pb': 'petabits',
    'tb': 'terabits',
    'gb': 'gigabits',
    'mb': 'megabits',
    'kb': 'kilobits',
    'b': 'bits',
    'yib': 'yobibits',
    'zib': 'zebibits',
    'eib': 'exbibits',
    'pib': 'pebibits',
    'tib': 'tebibits',
    'gib': 'gibibits',
    'mib': 'mebibits',
    'kib': 'kibibits',
  };
  if (bits) {
    final key = symbol.toLowerCase();
    return map[key] ?? symbol;
  }
  return map[symbol] ?? symbol;
}

class RateParsingResult {
  const RateParsingResult(this.bitsPerSecond);
  final double bitsPerSecond;
}

/// Parses rate strings like '100 Mbps', '12.5 MB/s', '1Gbps', '800 kb/s'.
RateParsingResult parseRate({
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
    // default bits per second
    return RateParsingResult(v);
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
  return RateParsingResult(bps);
}

ByteParsingResult<BigSizeUnit> parseSizeBig({
  required String input,
  required ByteStandard standard,
}) {
  final text = _trimAndNormalize(input);
  final regex = RegExp(
    r'^\s*([+-]?(?:[\d_\u00A0\s]+(?:[\.,][\d_\u00A0\s]+)?)|\d+)\s*([A-Za-z]+)?\s*$',
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

  if (unitStr.isEmpty) {
    multiplier = 1;
    unit = BigSizeUnit.B;
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

    // Direct lowercase bit symbols handling only if it's actually a bit unit
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
      if (siBit.containsKey(lowerU)) {
        multiplier = siBit[lowerU]! / 8.0;
        final bytes = value * multiplier;
        return ByteParsingResult<BigSizeUnit>(
          valueInBytes: bytes,
          unit: BigSizeUnit.B,
          isBitInput: true,
        );
      }
      if (iecBit.containsKey(lowerU)) {
        multiplier = iecBit[lowerU]! / 8.0;
        final bytes = value * multiplier;
        return ByteParsingResult<BigSizeUnit>(
          valueInBytes: bytes,
          unit: BigSizeUnit.B,
          isBitInput: true,
        );
      }
    }

    if (u == 'b' || lowerTrim == 'bit' || lowerTrim == 'bits') {
      isBits = true;
      multiplier = 1 / 8;
      unit = BigSizeUnit.B;
    } else if (upper == 'B') {
      multiplier = 1;
      unit = BigSizeUnit.B;
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
          multiplier = map[upperNoB] ?? 1.0;
          unit = unitMap[upperNoB];
          if (isLowerB) multiplier /= 8;
          break;
        case ByteStandard.jedec:
          // Only up to TB/JB common JEDEC symbols
          final key = isLowerB ? upper.substring(0, upper.length - 1) : upper;
          const mapJ = {
            'TB': 1024.0 * 1024 * 1024 * 1024,
            'GB': 1024.0 * 1024 * 1024,
            'MB': 1024.0 * 1024,
            'KB': 1024.0,
            'B': 1.0,
          };
          multiplier = mapJ[key] ?? 1.0;
          if (isLowerB) multiplier /= 8;
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
          if (isLowerB) multiplier /= 8;
          unit = unitMapI[keyIec];
          break;
      }
    }
  }
  return ByteParsingResult<BigSizeUnit>(
    valueInBytes: value * multiplier,
    unit: unit,
    isBitInput: isBits,
  );
}
