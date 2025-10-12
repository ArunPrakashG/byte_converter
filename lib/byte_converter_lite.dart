library byte_converter_lite;

import 'src/humanize_number_format.dart';
import 'src/humanize_options.dart';

export 'byte_converter.dart';

/// Enable a lightweight, no-intl number formatter for humanized output.
///
/// This adapter provides localized decimal and grouping separators for a small
/// set of common locales without depending on the intl package. It respects:
/// - locale: language code, with base-locale fallback (e.g., fr-FR -> fr)
/// - minimumFractionDigits / maximumFractionDigits
/// - useGrouping (thousands separators)
///
/// Supported base locales: en, de, fr, es, pt, ja, zh, ru.
/// Unknown locales fall back to English (en).
void enableByteConverterLite() {
  registerHumanizeNumberFormatter(_LiteHumanizeNumberFormatter().format);
}

/// Disable the lightweight number formatter and fall back to defaults.
void disableByteConverterLite() => clearHumanizeNumberFormatter();

class _LocaleSpec {
  const _LocaleSpec(this.decimal, this.group);
  final String decimal;
  final String group;
}

class _LiteHumanizeNumberFormatter {
  static const Map<String, _LocaleSpec> _spec = {
    'en': _LocaleSpec('.', ','),
    'de': _LocaleSpec(',', '.'),
    'fr': _LocaleSpec(',', ' '),
    'es': _LocaleSpec(',', '.'),
    'pt': _LocaleSpec(',', '.'),
    'ja': _LocaleSpec('.', ','),
    'zh': _LocaleSpec('.', ','),
    'ru': _LocaleSpec(',', ' '),
  };

  String format(double value, HumanizeOptions options) {
    final locale = options.locale;
    if (locale == null || locale.isEmpty) {
      // Return empty to allow default fallback when locale is not set.
      return '';
    }
    if (!value.isFinite) {
      // Fallback silently for non-finite values.
      return '';
    }

    // Resolve base locale (e.g., fr-FR -> fr)
    final lower = locale.toLowerCase();
    final sepIndex = lower.indexOf(RegExp(r'[-_]'));
    final base = (sepIndex == -1) ? lower : lower.substring(0, sepIndex);
    final spec = _spec[base] ?? _spec['en']!;

    // Determine fraction digit policy similar to intl adapter
    final min = options.minimumFractionDigits ?? 0;
    final max = options.maximumFractionDigits ??
        (options.minimumFractionDigits ?? options.precision);

    // Format number with max digits first using '.' decimal
    var s = value.toStringAsFixed(max);

    // Split sign, integer and fraction (using '.')
    var negative = false;
    if (s.startsWith('-')) {
      negative = true;
      s = s.substring(1);
    }
    final parts = s.split('.');
    var intPart = parts[0];
    var fracPart = parts.length > 1 ? parts[1] : null;

    // Trim trailing zeros down to the minimum fraction digits
    if (fracPart != null && max > 0) {
      var f = fracPart;
      if (min < max) {
        while (f.isNotEmpty && f.endsWith('0') && f.length > min) {
          f = f.substring(0, f.length - 1);
        }
      }
      // Ensure at least min fraction digits
      while (f.length < min) {
        f = '${f}0';
      }
      if (f.isEmpty) {
        fracPart = null;
      } else {
        fracPart = f;
      }
    }

    // Apply grouping if requested
    if (options.useGrouping && intPart.length > 3) {
      final parts = <String>[];
      var i = intPart.length;
      while (i > 3) {
        final start = i - 3;
        final chunk = intPart.substring(start, i);
        parts.insert(0, chunk);
        i -= 3;
      }
      final head = intPart.substring(0, i);
      intPart = [head, ...parts].where((e) => e.isNotEmpty).join(spec.group);
    }

    // Reassemble with locale decimal
    final dec = spec.decimal;
    var out = (fracPart == null || fracPart.isEmpty)
        ? intPart
        : '$intPart$dec$fracPart';
    if (negative) out = '-$out';
    return out;
  }
}
