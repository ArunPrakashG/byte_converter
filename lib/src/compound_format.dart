import 'byte_enums.dart';
import 'localized_unit_names.dart';

class CompoundFormatOptions {
  const CompoundFormatOptions({
    this.standard = ByteStandard.iec,
    this.useBits = false,
    this.maxParts = 2,
    this.separator = ' ',
    this.spacer = ' ',
    this.zeroSuppress = true,
    this.smallestUnit,
    this.fullForm = false,
    this.fullForms,
    this.locale,
    this.useGrouping = true,
  });

  final ByteStandard standard;
  final bool useBits;
  final int maxParts;
  final String separator;
  final String spacer;
  final bool zeroSuppress;

  /// Force the smallest unit displayed (e.g., 'B' or 'b'). If null, stops at last non-zero.
  final String? smallestUnit;
  final bool fullForm;
  final Map<String, String>? fullForms;
  final String? locale;
  final bool useGrouping;
}

String _pluralize(String symbol, double value, bool bits,
    {String? locale, Map<String, String>? overrides}) {
  if (!bits) {
    final n = localizedUnitName(symbol, locale: locale) ?? symbol;
    final name =
        overrides != null && overrides.containsKey(n) ? overrides[n]! : n;
    return name;
  } else {
    final n = localizedUnitName(symbol.toLowerCase(), locale: locale) ??
        symbol.toLowerCase();
    final name =
        overrides != null && overrides.containsKey(n) ? overrides[n]! : n;
    return name;
  }
}

/// Break a byte count (or bit count) into compound parts according to the chosen standard.
/// Returns parts as pairs (value, symbol) from largest to smallest.
List<(double, String)> _decompose(double quantity, CompoundFormatOptions opt) {
  // Build unit tables based on standard & useBits
  late final List<(double, String)> table;
  switch (opt.standard) {
    case ByteStandard.si:
      table = opt.useBits
          ? [
              (1e30, 'qb'),
              (1e27, 'rb'),
              (1e24, 'yb'),
              (1e21, 'zb'),
              (1e18, 'eb'),
              (1e15, 'pb'),
              (1e12, 'tb'),
              (1e9, 'gb'),
              (1e6, 'mb'),
              (1e3, 'kb'),
              (1, 'b')
            ]
          : [
              (1e30, 'QB'),
              (1e27, 'RB'),
              (1e24, 'YB'),
              (1e21, 'ZB'),
              (1e18, 'EB'),
              (1e15, 'PB'),
              (1e12, 'TB'),
              (1e9, 'GB'),
              (1e6, 'MB'),
              (1e3, 'KB'),
              (1, 'B')
            ];
      break;
    case ByteStandard.iec:
      const k = 1024.0;
      table = opt.useBits
          ? [
              (k * k * k * k * k * k * k * k, 'yib'),
              (k * k * k * k * k * k * k, 'zib'),
              (k * k * k * k * k * k, 'eib'),
              (k * k * k * k * k, 'pib'),
              (k * k * k * k, 'tib'),
              (k * k * k, 'gib'),
              (k * k, 'mib'),
              (k, 'kib'),
              (1, 'b'),
            ]
          : [
              (k * k * k * k * k * k * k * k, 'YiB'),
              (k * k * k * k * k * k * k, 'ZiB'),
              (k * k * k * k * k * k, 'EiB'),
              (k * k * k * k * k, 'PiB'),
              (k * k * k * k, 'TiB'),
              (k * k * k, 'GiB'),
              (k * k, 'MiB'),
              (k, 'KiB'),
              (1, 'B'),
            ];
      break;
    case ByteStandard.jedec:
      const k = 1024.0;
      // JEDEC primarily for bytes KB/MB/GB/TB; we’ll include B as smallest.
      table = opt.useBits
          ? [
              // Bit decomposition under JEDEC isn’t standard; we’ll convert bits to bytes*8 and reuse SI bit symbols at the bottom.
              (k * k * k * k, 'tb'), (k * k * k, 'gb'), (k * k, 'mb'),
              (k, 'kb'), (1, 'b')
            ]
          : [
              (k * k * k * k, 'TB'),
              (k * k * k, 'GB'),
              (k * k, 'MB'),
              (k, 'KB'),
              (1, 'B')
            ];
      break;
  }

  // Determine stop unit if provided
  int minIndex = table.length - 1;
  if (opt.smallestUnit != null) {
    final idx = table.indexWhere(
        (e) => e.$2.toLowerCase() == opt.smallestUnit!.toLowerCase());
    if (idx != -1) minIndex = idx;
  }

  final parts = <(double, String)>[];
  var remaining = quantity;
  for (var i = 0; i < table.length; i++) {
    final (base, sym) = table[i];
    if (i < minIndex && remaining < base) continue;
    final count = (remaining / base).floorToDouble();
    if (count <= 0 && opt.zeroSuppress && parts.isEmpty) {
      continue;
    }
    if (count > 0 || !opt.zeroSuppress || i == minIndex) {
      parts.add((count, sym));
      remaining -= count * base;
    }
    if (parts.length >= opt.maxParts) break;
  }
  // If nothing was added, include smallest unit with zero
  if (parts.isEmpty) {
    final end = table[minIndex];
    parts.add((0, end.$2));
  }
  return parts;
}

String formatCompound(double bytes, CompoundFormatOptions opt) {
  final quantity = opt.useBits ? (bytes * 8.0) : bytes;
  final parts = _decompose(quantity, opt);
  final locale = opt.locale;
  final fullForms = opt.fullForms;
  final unitTexts = parts.map((p) {
    final value = p.$1;
    final sym = p.$2;
    final name = opt.fullForm
        ? _pluralize(sym, value, opt.useBits,
            locale: locale, overrides: fullForms)
        : sym;
    final numStr = value.toStringAsFixed(0);
    return '$numStr${opt.spacer}$name';
  }).toList();
  return unitTexts.join(opt.separator);
}
