part of '../_parsing.dart';

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
  double? multiplier;
  BigSizeUnit? unit;
  String? unitSymbol;

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
      'kibibit': 'kib', 'kibibits': 'kib', 'kibit': 'kib', 'kibits': 'kib',
      'mebibit': 'mib', 'mebibits': 'mib', 'mibit': 'mib', 'mibits': 'mib',
      'gibibit': 'gib', 'gibibits': 'gib', 'gibit': 'gib', 'gibits': 'gib',
      'tebibit': 'tib', 'tebibits': 'tib', 'tibit': 'tib', 'tibits': 'tib',
      'pebibit': 'pib', 'pebibits': 'pib', 'pibit': 'pib', 'pibits': 'pib',
      'exbibit': 'eib', 'exbibits': 'eib', 'eibit': 'eib', 'eibits': 'eib',
      'zebibit': 'zib', 'zebibits': 'zib', 'zibit': 'zib', 'zibits': 'zib',
      'yobibit': 'yib', 'yobibits': 'yib', 'yibit': 'yib', 'yibits': 'yib',
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
      bool matchStandard(ByteStandard std) {
        switch (std) {
          case ByteStandard.si:
            final upperNoB =
                isLowerB ? upper.substring(0, upper.length - 1) : upper;
            const map = {
              'QB': 1e30,
              'RB': 1e27,
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
              'QB': BigSizeUnit.QB,
              'RB': BigSizeUnit.RB,
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
            final base = map[upperNoB];
            if (base == null) {
              return false;
            }
            multiplier = isLowerB ? base / 8 : base;
            unit = unitMap[upperNoB];
            unitSymbol = isLowerB
                ? _canonicalizeBitSymbol(u)
                : _canonicalizeByteSymbol(upperNoB);
            return true;
          case ByteStandard.jedec:
            final key = isLowerB ? upper.substring(0, upper.length - 1) : upper;
            const mapJ = {
              'TB': 1024.0 * 1024 * 1024 * 1024,
              'GB': 1024.0 * 1024 * 1024,
              'MB': 1024.0 * 1024,
              'KB': 1024.0,
              'B': 1.0,
            };
            final base = mapJ[key];
            if (base == null) {
              return false;
            }
            multiplier = isLowerB ? base / 8 : base;
            unitSymbol = isLowerB
                ? _canonicalizeBitSymbol('${key.toLowerCase()}b')
                : _canonicalizeByteSymbol(key);
            unit = {
              'TB': BigSizeUnit.TB,
              'GB': BigSizeUnit.GB,
              'MB': BigSizeUnit.MB,
              'KB': BigSizeUnit.KB,
              'B': BigSizeUnit.B,
            }[key];
            return true;
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
            final base = mapI[keyIec];
            if (base == null) {
              return false;
            }
            multiplier = isLowerB ? base / 8 : base;
            unitSymbol = isLowerB
                ? _canonicalizeBitSymbol('${keyIec.toLowerCase()}b')
                : _canonicalizeByteSymbol(keyIec);
            unit = unitMapI[keyIec];
            return true;
        }
      }

      var matched = matchStandard(standard);
      if (!matched) {
        for (final fallback in ByteStandard.values) {
          if (fallback == standard) continue;
          if (matchStandard(fallback)) {
            matched = true;
            break;
          }
        }
      }

      if (!matched) {
        throw FormatException('Unknown unit: $unitStr');
      }
    }
  }

  multiplier ??= 1;
  unit ??= BigSizeUnit.B;
  unitSymbol ??= isBits ? 'b' : 'B';

  final resolvedMultiplier = multiplier!;
  final resolvedUnitSymbol = unitSymbol!;
  final bytes = value * resolvedMultiplier;
  final normalized = _composeNormalizedInput(numStr, resolvedUnitSymbol);
  return ByteParsingResult<BigSizeUnit>(
    valueInBytes: bytes,
    unit: unit,
    isBitInput: isBits,
    normalizedInput: normalized,
    unitSymbol: resolvedUnitSymbol,
    rawValue: value,
  );
}

/// Parses a size [input] into bytes allowing units beyond PB and returning
/// a [ByteParsingResult] with BigSizeUnit metadata. Supports SI/IEC/JEDEC and
/// bit inputs. When [strictBits] is true, fractional bit quantities are
/// rejected with a FormatException.
ByteParsingResult<BigSizeUnit> parseSizeBig({
  required String input,
  required ByteStandard standard,
  bool strictBits = false,
}) {
  final normalized = _trimAndNormalize(input);
  // If there's a division by a trailing duration-like token and it's unknown, surface a duration-specific error
  final slashIdx = normalized.lastIndexOf('/');
  if (slashIdx != -1 && slashIdx < normalized.length - 1) {
    final rhs = normalized.substring(slashIdx + 1).trim();
    if (RegExp(r'^[0-9\.,\u00A0_\s]*[A-Za-zµ]+$', caseSensitive: false)
        .hasMatch(rhs)) {
      try {
        _parseDurationLiteral(rhs);
      } on FormatException catch (e) {
        if (e.message.startsWith('Unknown duration unit')) {
          rethrow;
        }
      }
    }
  }
  if (_containsExpressionOperators(normalized)) {
    final evaluator = _SizeExpressionEvaluator(
      input: normalized,
      standard: standard,
      literalParser: (literal) {
        final result = _parseSizeBigLiteralInternal(
          input: literal,
          standard: standard,
        );
        if (strictBits && result.isBitInput) {
          final isInt = result.rawValue == result.rawValue.truncateToDouble();
          if (!isInt) {
            throw const FormatException('Fractional bits not allowed');
          }
        }
        return result.valueInBytes;
      },
    );
    return evaluator.evaluate<BigSizeUnit>();
  }
  final r = _parseSizeBigLiteralInternal(
    input: input,
    standard: standard,
  );
  if (strictBits && r.isBitInput) {
    final isInt = r.rawValue == r.rawValue.truncateToDouble();
    if (!isInt) {
      throw const FormatException('Fractional bits not allowed');
    }
  }
  return r;
}
