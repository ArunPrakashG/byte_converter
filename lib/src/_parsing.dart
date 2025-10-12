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
  // Common fast paths with early returns
  if (_isFastSiDefault(opt)) {
    // Limit SI fast path to TB and below; larger magnitudes (PB, EB, YB, RB, QB)
    // require the full path to select correct extended units.
    if (bytes < 1e15) {
      return _humanizeFastSi(bytes, opt.precision);
    }
  }

  if (_isFastJedecDefault(opt)) {
    return _humanizeFastJedec(bytes, opt.precision);
  }

  if (_isFastSiBitsDefault(opt)) {
    return _humanizeFastSiBits(bytes, opt.precision);
  }

  if (_isFastIecDefault(opt)) {
    return _humanizeFastIec(bytes, opt.precision);
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
    final singular = (v.abs() == 1.0)
        ? localizedUnitSingularName(unitSymbol,
            locale: opt.locale, bits: opt.useBits)
        : null;
    final chosen = singular ?? full;
    unitOut = opt.fullForms != null && opt.fullForms!.containsKey(chosen)
        ? opt.fullForms![chosen]!
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

// Extremely fast SI-bytes humanizer for the default/common case only.
// - Units: B, KB, MB, GB, TB, PB (SI base 1000)
// - Precision: trim trailing zeros and decimal point
// - Spacer: single space
HumanizeResult _humanizeFastSi(double bytes, int precision) {
  const tb = 1e12;
  const gb = 1e9;
  const mb = 1e6;
  const kb = 1e3;
  String sym;
  double base;
  if (bytes >= tb) {
    base = tb;
    sym = 'TB';
  } else if (bytes >= gb) {
    base = gb;
    sym = 'GB';
  } else if (bytes >= mb) {
    base = mb;
    sym = 'MB';
  } else if (bytes >= kb) {
    base = kb;
    sym = 'KB';
  } else {
    base = 1.0;
    sym = 'B';
  }
  final v = bytes / base;
  final s = _toFixedTrim(v, precision);
  final text = '$s $sym';
  return HumanizeResult(v, sym, text);
}

HumanizeResult _humanizeFastJedec(double bytes, int precision) {
  const tb = 1099511627776.0; // 1024^4
  const gb = 1073741824.0; // 1024^3
  const mb = 1048576.0; // 1024^2
  const kb = 1024.0; // 1024^1
  String sym;
  double base;
  if (bytes >= tb) {
    base = tb;
    sym = 'TB';
  } else if (bytes >= gb) {
    base = gb;
    sym = 'GB';
  } else if (bytes >= mb) {
    base = mb;
    sym = 'MB';
  } else if (bytes >= kb) {
    base = kb;
    sym = 'KB';
  } else {
    base = 1.0;
    sym = 'B';
  }
  final v = bytes / base;
  final s = _toFixedTrim(v, precision);
  final text = '$s $sym';
  return HumanizeResult(v, sym, text);
}

HumanizeResult _humanizeFastSiBits(double bytes, int precision) {
  final bits = bytes * 8.0;
  const tb = 1e12;
  const gb = 1e9;
  const mb = 1e6;
  const kb = 1e3;
  String sym;
  double base;
  if (bits >= tb) {
    base = tb;
    sym = 'Tb';
  } else if (bits >= gb) {
    base = gb;
    sym = 'Gb';
  } else if (bits >= mb) {
    base = mb;
    sym = 'Mb';
  } else if (bits >= kb) {
    base = kb;
    sym = 'Kb';
  } else {
    base = 1.0;
    sym = 'b';
  }
  final v = bits / base;
  final s = _toFixedTrim(v, precision);
  final text = '$s $sym';
  return HumanizeResult(v, sym, text);
}

HumanizeResult _humanizeFastIec(double bytes, int precision) {
  const tib = 1099511627776.0; // 1024^4
  const gib = 1073741824.0; // 1024^3
  const mib = 1048576.0; // 1024^2
  const kib = 1024.0; // 1024^1
  String sym;
  double base;
  if (bytes >= tib) {
    base = tib;
    sym = 'TiB';
  } else if (bytes >= gib) {
    base = gib;
    sym = 'GiB';
  } else if (bytes >= mib) {
    base = mib;
    sym = 'MiB';
  } else if (bytes >= kib) {
    base = kib;
    sym = 'KiB';
  } else {
    base = 1.0;
    sym = 'B';
  }
  final v = bytes / base;
  final s = _toFixedTrim(v, precision);
  final text = '$s $sym';
  return HumanizeResult(v, sym, text);
}
