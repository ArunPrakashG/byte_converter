import 'byte_enums.dart';
import 'humanize_number_format.dart';
import 'humanize_options.dart';
import 'localized_unit_names.dart';

export 'humanize_options.dart';

part 'parsing/big_size.dart';
part 'parsing/common.dart';
part 'parsing/duration.dart';
part 'parsing/expression.dart';
part 'parsing/humanize_forced.dart';
part 'parsing/rate.dart';
part 'parsing/size.dart';
part 'parsing/testing_helpers.dart';

// Typedef used by the expression parser to resolve literals
/// Resolver used by the expression parser to convert tokens into literal
/// values (numbers, identifiers) during evaluation.
typedef _LiteralResolver = _ExprValue Function(_Token token);

class _UnitDef<TUnit> {
  // relative to 1 byte
  const _UnitDef(this.symbol, this.unit, this.multiplier);
  final String symbol;
  final TUnit unit;
  final double multiplier;
}

/// Internal structure returned by literal parsers containing normalized bytes
/// and metadata about the parsed unit and input.
class ByteParsingResult<TUnit> {
  /// Creates a parsing result with normalized bytes and unit metadata.
  const ByteParsingResult({
    required this.valueInBytes,
    required this.unit,
    required this.isBitInput,
    required this.normalizedInput,
    required this.unitSymbol,
    required this.rawValue,
  });

  /// Parsed value normalized to bytes.
  final double valueInBytes;

  /// The resolved unit type when available (may be null for ambiguous inputs).
  final TUnit? unit;

  /// Whether the input was specified as bits.
  final bool isBitInput;

  /// Canonical representation of the parsed input (trimmed, normalized symbol).
  final String normalizedInput;

  /// Canonical unit symbol detected from input (e.g., `MB`, `MiB`, `kb`).
  final String unitSymbol;

  /// The numeric component parsed from the input before unit conversion.
  final double rawValue;
}

// Local helper to compute unit symbol considering bits and SI k-case
String _unitSymbolFor(
  String chosenSymbol,
  bool useBits,
  ByteStandard effectiveStandard,
  HumanizeOptions opt,
) {
  final sym = chosenSymbol;
  if (useBits) {
    if (sym == 'B') return 'b';
    if (sym.endsWith('B')) return sym.replaceAll('B', 'b');
    if (sym.endsWith('b')) return sym; // already a bit unit like 'Mb'
    return 'b';
  }
  // Apply SI k-case preference only for SI symbols that use K prefix
  if (effectiveStandard == ByteStandard.si &&
      sym.length == 2 &&
      sym.endsWith('B') &&
      sym.startsWith('K')) {
    return opt.siKSymbolCase == SiKSymbolCase.lowerK ? 'kB' : 'KB';
  }
  return sym;
}

/// Formats a raw byte quantity according to [opt] producing a value, symbol,
/// and final text. Supports SI/IEC/JEDEC, bits/bytes, locale/grouping, min/max
/// fraction digits, rounding strategies, fixed-width padding, and optional
/// forced units.
HumanizeResult humanize(double bytes, HumanizeOptions opt) {
  // Common fast paths with early returns. Each returns null when the value
  // needs a unit the table lacks (or rounding forces promotion beyond it), in
  // which case the general path below handles it.
  if (_isFastSiDefault(opt) && bytes < 1e15) {
    final r = _humanizeFastSi(bytes, opt.precision);
    if (r != null) return r;
  }

  if (_isFastJedecDefault(opt)) {
    final r = _humanizeFastJedec(bytes, opt.precision);
    if (r != null) return r;
  }

  if (_isFastSiBitsDefault(opt) && bytes * 8.0 < 1e15) {
    final r = _humanizeFastSiBits(bytes, opt.precision);
    if (r != null) return r;
  }

  if (_isFastIecDefault(opt) && bytes < 1e15) {
    final r = _humanizeFastIec(bytes, opt.precision);
    if (r != null) return r;
  }

  if (_isFastForcedDefault(opt)) {
    final u = opt.forceUnit!;

    // Micro-specialized fast paths for very common forced units
    if (!opt.useBits) {
      switch (opt.standard) {
        case ByteStandard.si:
          switch (u) {
            case 'KB':
              {
                final v = bytes / 1e3;
                final s = _toFixedTrim(v, opt.precision);
                return HumanizeResult(v, u, '$s $u');
              }
            case 'MB':
              {
                final v = bytes / 1e6;
                final s = _toFixedTrim(v, opt.precision);
                return HumanizeResult(v, u, '$s $u');
              }
            case 'GB':
              {
                final v = bytes / 1e9;
                final s = _toFixedTrim(v, opt.precision);
                return HumanizeResult(v, u, '$s $u');
              }
            case 'TB':
              {
                final v = bytes / 1e12;
                final s = _toFixedTrim(v, opt.precision);
                return HumanizeResult(v, u, '$s $u');
              }
          }
          break;
        case ByteStandard.jedec:
          switch (u) {
            case 'KB':
              {
                final v = bytes / 1024.0;
                final s = _toFixedTrim(v, opt.precision);
                return HumanizeResult(v, u, '$s $u');
              }
            case 'MB':
              {
                final v = bytes / 1048576.0;
                final s = _toFixedTrim(v, opt.precision);
                return HumanizeResult(v, u, '$s $u');
              }
            case 'GB':
              {
                final v = bytes / 1073741824.0;
                final s = _toFixedTrim(v, opt.precision);
                return HumanizeResult(v, u, '$s $u');
              }
            case 'TB':
              {
                final v = bytes / 1099511627776.0;
                final s = _toFixedTrim(v, opt.precision);
                return HumanizeResult(v, u, '$s $u');
              }
          }
          break;
        case ByteStandard.iec:
          switch (u) {
            case 'KiB':
              {
                final v = bytes / 1024.0;
                final s = _toFixedTrim(v, opt.precision);
                return HumanizeResult(v, u, '$s $u');
              }
            case 'MiB':
              {
                final v = bytes / 1048576.0;
                final s = _toFixedTrim(v, opt.precision);
                return HumanizeResult(v, u, '$s $u');
              }
            case 'GiB':
              {
                final v = bytes / 1073741824.0;
                final s = _toFixedTrim(v, opt.precision);
                return HumanizeResult(v, u, '$s $u');
              }
            case 'TiB':
              {
                final v = bytes / 1099511627776.0;
                final s = _toFixedTrim(v, opt.precision);
                return HumanizeResult(v, u, '$s $u');
              }
          }
          break;
      }
    } else {
      switch (u) {
        case 'Kb':
          {
            final v = (bytes * 8.0) / 1e3;
            final s = _toFixedTrim(v, opt.precision);
            return HumanizeResult(v, u, '$s $u');
          }
        case 'Mb':
          {
            final v = (bytes * 8.0) / 1e6;
            final s = _toFixedTrim(v, opt.precision);
            return HumanizeResult(v, u, '$s $u');
          }
        case 'Gb':
          {
            final v = (bytes * 8.0) / 1e9;
            final s = _toFixedTrim(v, opt.precision);
            return HumanizeResult(v, u, '$s $u');
          }
        case 'Tb':
          {
            final v = (bytes * 8.0) / 1e12;
            final s = _toFixedTrim(v, opt.precision);
            return HumanizeResult(v, u, '$s $u');
          }
      }
    }

    final res =
        _humanizeFastForced(bytes, u, opt.useBits, opt.standard, opt.precision);
    if (res != null) return res;
  }

  // Resolve policy -> standard bias unless overridden by caller
  final effectiveStandard = _selectEffectiveStandard(opt);

  var value = bytes;
  final symbol = opt.useBits ? 'b' : 'B';

  final space = _computeSpace(opt);

  if (opt.useBits) {
    value = bytes * 8.0;
  }

  late final List<double> thresholds;
  late final List<String> symbols;
  switch (effectiveStandard) {
    case ByteStandard.si:
      thresholds = kSiThresholds;
      symbols = kSiSymbols;
      break;
    case ByteStandard.iec:
      thresholds = kIecThresholds;
      symbols = kIecSymbols;
      break;
    case ByteStandard.jedec:
      thresholds = kJedecThresholds;
      symbols = kJedecSymbols;
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

    switch (effectiveStandard) {
      case ByteStandard.si:
        {
          final idx = [
            'QB',
            'RB',
            'YB',
            'ZB',
            'EB',
            'PB',
            'TB',
            'GB',
            'MB',
            'KB'
          ].indexOf(normalized);
          if (idx != -1) forcedBase = kSiThresholds[idx];
          // Support bit units like 'Mb','Gb' by mapping single-letter SI to base10
          if (forcedBase == null && isBitUnit) {
            const single = {
              'Q': 1e30,
              'R': 1e27,
              'Y': 1e24,
              'Z': 1e21,
              'E': 1e18,
              'P': 1e15,
              'T': 1e12,
              'G': 1e9,
              'M': 1e6,
              'K': 1e3,
            };
            if (single.containsKey(normalized)) {
              forcedBase = single[normalized];
            }
          }
          if (normalized == 'B') forcedBase = 1.0;
        }
        break;
      case ByteStandard.jedec:
        {
          final idxJ = ['TB', 'GB', 'MB', 'KB'].indexOf(normalized);
          if (idxJ != -1) forcedBase = kJedecThresholds[idxJ];
          if (normalized == 'B') forcedBase = 1.0;
        }
        break;
      case ByteStandard.iec:
        {
          final idxI = ['YiB', 'ZiB', 'EiB', 'PiB', 'TiB', 'GiB', 'MiB', 'KiB']
              .indexOf(u);
          if (idxI != -1) forcedBase = kIecThresholds[idxI];
          if (u == 'B' || normalized == 'B') forcedBase = 1.0;
        }
        break;
    }

    base = forcedBase ?? 1.0;
  } else {
    // Auto-scale selection
    final scaled = opt.useBits ? value : bytes;
    for (var i = 0; i < thresholds.length; i++) {
      final threshold = thresholds[i];
      if (scaled >= threshold) {
        base = threshold;
        chosenSymbol = symbols[i];
        // Promote when rounding would print the unit ratio ("1000 KB").
        final truncating = opt.truncate &&
            (opt.minimumFractionDigits != null ||
                opt.maximumFractionDigits != null);
        if (i > 0 && !truncating) {
          final ratio = thresholds[i - 1] / threshold;
          final digits = opt.maximumFractionDigits ??
              opt.minimumFractionDigits ??
              opt.precision;
          if (_roundsToRatio(scaled / threshold, digits, ratio)) {
            base = thresholds[i - 1];
            chosenSymbol = symbols[i - 1];
          }
        }
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

  final unitSymbol =
      _unitSymbolFor(chosenSymbol, opt.useBits, effectiveStandard, opt);

  // Number formatting with separator/min/max fraction digits
  String numStr = _formatHumanizedNumber(v, opt);

  // Full-form unit names
  String unitOut;
  if (opt.fullForm) {
    final full = _fullFormName(
      unitSymbol,
      opt.useBits,
      locale: opt.locale,
    );
    final isOne = v.abs() == 1.0;
    var singular = isOne
        ? localizedUnitSingularName(unitSymbol,
            locale: opt.locale, bits: opt.useBits)
        : null;
    // English has no registered singular forms: derive them ("1 byte").
    final loc = (opt.locale ?? '').toLowerCase();
    final isEnglish = loc.isEmpty ||
        loc == 'en' ||
        loc.startsWith('en-') ||
        loc.startsWith('en_');
    if (isOne &&
        isEnglish &&
        (singular == null || singular == full) &&
        full.length > 1 &&
        full.endsWith('s') &&
        full != unitSymbol) {
      singular = full.substring(0, full.length - 1);
    }
    final chosen = singular ?? full;
    final overrides = opt.fullForms;
    unitOut = overrides != null
        ? (overrides[chosen] ?? overrides[full] ?? chosen)
        : chosen;
  } else {
    unitOut = unitSymbol;
  }

  // Signed formatting
  String signedPrefix = _signedPrefixFor(v, opt);

  // Fixed-width padding: pad the numeric portion (left) with spaces.
  // When includeSignInWidth is true, include the sign in the padding width.
  if (opt.fixedWidth != null && opt.fixedWidth! > 0) {
    final w = opt.fixedWidth!;
    if (opt.includeSignInWidth && signedPrefix.isNotEmpty) {
      final combined = '$signedPrefix$numStr';
      if (combined.length < w) {
        final padded = combined.padLeft(w);
        // Split back to sign + number, preserving sign char
        if (padded.isNotEmpty) {
          signedPrefix = padded.substring(0, 1);
          numStr = padded.substring(1);
        } else {
          numStr = padded; // degenerate
        }
      }
    } else if (numStr.length < w) {
      numStr = numStr.padLeft(w);
    }
  }

  final text = '$signedPrefix$numStr$space$unitOut';
  return HumanizeResult(v, chosenSymbol, text);
}

const _fastSiTh = <double>[1e12, 1e9, 1e6, 1e3, 1.0];
const _fastSiSym = <String>['TB', 'GB', 'MB', 'KB', 'B'];
const _fastSiBitSym = <String>['Tb', 'Gb', 'Mb', 'Kb', 'b'];
const _fastBinTh = <double>[
  1099511627776.0, // 1024^4
  1073741824.0, // 1024^3
  1048576.0, // 1024^2
  1024.0,
  1.0,
];
const _fastIecSym = <String>['TiB', 'GiB', 'MiB', 'KiB', 'B'];
const _fastJedecSym = <String>['TB', 'GB', 'MB', 'KB', 'B'];

/// Shared table-driven scaler for the fast paths.
///
/// Picks the largest unit not exceeding [x], then promotes to the next larger
/// unit when rounding to [precision] digits would otherwise print the
/// unit-ratio itself (e.g. `1000 KB` instead of `1 MB`). Returns null when
/// promotion is required but the table has no larger unit, so the caller can
/// fall back to the general path.
HumanizeResult? _fastScale(
  double x,
  int precision,
  List<double> th,
  List<String> sym,
  double ratio,
) {
  var i = 0;
  while (i < th.length - 1 && x < th[i]) {
    i++;
  }
  var v = x / th[i];
  if (i < th.length - 1 && _roundsToRatio(v, precision, ratio)) {
    if (i == 0) return null;
    i--;
    v = x / th[i];
  }
  final s = _toFixedTrim(v, precision);
  return HumanizeResult(v, sym[i], '$s ${sym[i]}');
}

HumanizeResult? _humanizeFastSi(double bytes, int precision) =>
    _fastScale(bytes, precision, _fastSiTh, _fastSiSym, 1000.0);

HumanizeResult? _humanizeFastJedec(double bytes, int precision) =>
    _fastScale(bytes, precision, _fastBinTh, _fastJedecSym, 1024.0);

HumanizeResult? _humanizeFastSiBits(double bytes, int precision) =>
    _fastScale(bytes * 8.0, precision, _fastSiTh, _fastSiBitSym, 1000.0);

HumanizeResult? _humanizeFastIec(double bytes, int precision) =>
    _fastScale(bytes, precision, _fastBinTh, _fastIecSym, 1024.0);
