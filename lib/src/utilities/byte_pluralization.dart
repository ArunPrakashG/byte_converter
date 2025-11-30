/// Pluralization utilities for byte-related terms.
///
/// Provides smart pluralization that handles:
/// - Basic English pluralization (singular vs plural)
/// - Locale-aware pluralization rules
/// - Custom plural forms
///
/// Example:
/// ```dart
/// BytePluralization.format(1, 'byte')    // "1 byte"
/// BytePluralization.format(2, 'byte')    // "2 bytes"
/// BytePluralization.format(0, 'byte')    // "0 bytes"
/// BytePluralization.format(1, 'kilobyte') // "1 kilobyte"
/// BytePluralization.format(1.5, 'megabyte') // "1.5 megabytes"
///
/// // With custom plural forms
/// BytePluralization.format(2, 'byte', plural: 'octets') // "2 octets"
///
/// // Formatting with value
/// BytePluralization.formatWithValue(1536, 'byte') // "1,536 bytes"
/// ```
library;

/// Pluralization rules for different locales.
enum PluralizationRule {
  /// English-style: singular for 1, plural otherwise (0, 2, 3...)
  english,

  /// French-style: singular for 0 and 1, plural for 2+
  french,

  /// Slavic-style: complex rules based on number endings
  slavic,

  /// East Asian: no grammatical plural
  eastAsian,

  /// Arabic: complex plural forms (singular, dual, plural)
  arabic,
}

/// Configuration for pluralization behavior.
class PluralizationOptions {
  /// Creates pluralization options.
  const PluralizationOptions({
    this.rule = PluralizationRule.english,
    this.includeValue = true,
    this.useCommaSeparator = false,
    this.precision = 2,
    this.locale,
  });

  /// The pluralization rule to use.
  final PluralizationRule rule;

  /// Whether to include the numeric value in output.
  final bool includeValue;

  /// Whether to use comma separators for large numbers.
  final bool useCommaSeparator;

  /// Decimal precision for non-integer values.
  final int precision;

  /// Optional locale for locale-specific formatting.
  final String? locale;

  /// Default English pluralization options.
  static const PluralizationOptions defaults = PluralizationOptions();

  /// French pluralization options.
  static const PluralizationOptions french = PluralizationOptions(
    rule: PluralizationRule.french,
  );

  /// East Asian options (no pluralization).
  static const PluralizationOptions eastAsian = PluralizationOptions(
    rule: PluralizationRule.eastAsian,
  );
}

/// Smart pluralization utilities for byte-related terms.
///
/// Handles singular/plural forms correctly for different languages and contexts.
abstract class BytePluralization {
  BytePluralization._();

  /// Common irregular plurals in English.
  static const Map<String, String> _irregularPlurals = {
    'byte': 'bytes',
    'kilobyte': 'kilobytes',
    'megabyte': 'megabytes',
    'gigabyte': 'gigabytes',
    'terabyte': 'terabytes',
    'petabyte': 'petabytes',
    'exabyte': 'exabytes',
    'zettabyte': 'zettabytes',
    'yottabyte': 'yottabytes',
    'kibibyte': 'kibibytes',
    'mebibyte': 'mebibytes',
    'gibibyte': 'gibibytes',
    'tebibyte': 'tebibytes',
    'pebibyte': 'pebibytes',
    'exbibyte': 'exbibytes',
    'zebibyte': 'zebibytes',
    'yobibyte': 'yobibytes',
    'bit': 'bits',
    'kilobit': 'kilobits',
    'megabit': 'megabits',
    'gigabit': 'gigabits',
    'terabit': 'terabits',
    'kibibit': 'kibibits',
    'mebibit': 'mebibits',
    'gibibit': 'gibibits',
    'tebibit': 'tebibits',
  };

  /// Formats a value with its pluralized unit.
  ///
  /// ```dart
  /// BytePluralization.format(1, 'byte')     // "1 byte"
  /// BytePluralization.format(2, 'byte')     // "2 bytes"
  /// BytePluralization.format(0, 'byte')     // "0 bytes"
  /// BytePluralization.format(1.5, 'megabyte') // "1.5 megabytes"
  /// ```
  static String format(
    num value,
    String singular, {
    String? plural,
    PluralizationOptions options = PluralizationOptions.defaults,
  }) {
    final pluralForm = plural ?? pluralize(singular, options: options);
    final unit =
        shouldUseSingular(value, options: options) ? singular : pluralForm;

    if (!options.includeValue) {
      return unit;
    }

    final formattedValue = _formatNumber(value, options);
    return '$formattedValue $unit';
  }

  /// Returns just the pluralized unit name without the value.
  ///
  /// ```dart
  /// BytePluralization.unitFor(1, 'byte')   // "byte"
  /// BytePluralization.unitFor(2, 'byte')   // "bytes"
  /// BytePluralization.unitFor(0, 'byte')   // "bytes"
  /// ```
  static String unitFor(
    num value,
    String singular, {
    String? plural,
    PluralizationOptions options = PluralizationOptions.defaults,
  }) {
    final pluralForm = plural ?? pluralize(singular, options: options);
    return shouldUseSingular(value, options: options) ? singular : pluralForm;
  }

  /// Pluralizes a singular word.
  ///
  /// ```dart
  /// BytePluralization.pluralize('byte')     // "bytes"
  /// BytePluralization.pluralize('kilobyte') // "kilobytes"
  /// ```
  static String pluralize(
    String singular, {
    PluralizationOptions options = PluralizationOptions.defaults,
  }) {
    // Check for known irregular plurals
    final lower = singular.toLowerCase();
    if (_irregularPlurals.containsKey(lower)) {
      // Preserve case
      if (singular == singular.toUpperCase()) {
        return _irregularPlurals[lower]!.toUpperCase();
      }
      if (singular[0] == singular[0].toUpperCase()) {
        final plural = _irregularPlurals[lower]!;
        return plural[0].toUpperCase() + plural.substring(1);
      }
      return _irregularPlurals[lower]!;
    }

    // Standard English pluralization rules
    if (singular.endsWith('s') ||
        singular.endsWith('x') ||
        singular.endsWith('z') ||
        singular.endsWith('ch') ||
        singular.endsWith('sh')) {
      return '${singular}es';
    }

    if (singular.endsWith('y') && singular.length > 1) {
      final beforeY = singular[singular.length - 2];
      if (!'aeiou'.contains(beforeY.toLowerCase())) {
        return '${singular.substring(0, singular.length - 1)}ies';
      }
    }

    return '${singular}s';
  }

  /// Determines if singular form should be used for the given value.
  ///
  /// ```dart
  /// BytePluralization.shouldUseSingular(1)   // true
  /// BytePluralization.shouldUseSingular(2)   // false
  /// BytePluralization.shouldUseSingular(0)   // false (English)
  /// BytePluralization.shouldUseSingular(1.0) // true
  /// BytePluralization.shouldUseSingular(1.5) // false
  /// ```
  static bool shouldUseSingular(
    num value, {
    PluralizationOptions options = PluralizationOptions.defaults,
  }) {
    switch (options.rule) {
      case PluralizationRule.english:
        // Singular only for exactly 1
        return value == 1 || value == 1.0;

      case PluralizationRule.french:
        // Singular for 0 and 1 in French
        return value == 0 || value == 1 || value == 0.0 || value == 1.0;

      case PluralizationRule.eastAsian:
        // No grammatical plural in East Asian languages
        return true;

      case PluralizationRule.slavic:
        // Simplified Slavic rules (Russian, Polish, etc.)
        // 1 -> singular
        // 2-4 -> plural (genitive singular in Russian)
        // 5-20 -> plural (genitive plural)
        // 21 -> singular (like 1)
        // etc.
        final absValue = value.abs().toInt();
        final lastTwoDigits = absValue % 100;
        final lastDigit = absValue % 10;

        if (lastTwoDigits >= 11 && lastTwoDigits <= 19) {
          return false; // Always plural for 11-19
        }
        return lastDigit == 1;

      case PluralizationRule.arabic:
        // Simplified Arabic: singular for 1, dual for 2, plural for 3+
        // For simplicity, we just use singular for 1
        return value == 1 || value == 1.0;
    }
  }

  /// Formats a number with optional comma separators and precision.
  static String _formatNumber(num value, PluralizationOptions options) {
    String formatted;

    if (value is int || value == value.toInt()) {
      formatted = value.toInt().toString();
    } else {
      formatted = value.toStringAsFixed(options.precision);
      // Remove trailing zeros
      formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
    }

    if (options.useCommaSeparator) {
      formatted = _addCommas(formatted);
    }

    return formatted;
  }

  /// Adds comma separators to a number string.
  static String _addCommas(String number) {
    final parts = number.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();

    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    if (parts.length > 1) {
      buffer.write('.');
      buffer.write(parts[1]);
    }

    return buffer.toString();
  }

  /// Returns the rule for a given locale.
  ///
  /// ```dart
  /// BytePluralization.ruleForLocale('en')    // PluralizationRule.english
  /// BytePluralization.ruleForLocale('fr')    // PluralizationRule.french
  /// BytePluralization.ruleForLocale('ja')    // PluralizationRule.eastAsian
  /// BytePluralization.ruleForLocale('ru')    // PluralizationRule.slavic
  /// ```
  static PluralizationRule ruleForLocale(String locale) {
    final baseLocale = locale.split('_').first.split('-').first.toLowerCase();

    switch (baseLocale) {
      case 'fr': // French
      case 'pt': // Portuguese (Brazilian)
        return PluralizationRule.french;

      case 'ja': // Japanese
      case 'zh': // Chinese
      case 'ko': // Korean
      case 'vi': // Vietnamese
      case 'th': // Thai
        return PluralizationRule.eastAsian;

      case 'ru': // Russian
      case 'uk': // Ukrainian
      case 'pl': // Polish
      case 'cs': // Czech
      case 'sk': // Slovak
      case 'hr': // Croatian
      case 'sr': // Serbian
      case 'sl': // Slovenian
      case 'bg': // Bulgarian
        return PluralizationRule.slavic;

      case 'ar': // Arabic
      case 'he': // Hebrew
        return PluralizationRule.arabic;

      default:
        return PluralizationRule.english;
    }
  }

  /// Creates options for a specific locale.
  ///
  /// ```dart
  /// final options = BytePluralization.optionsForLocale('fr');
  /// BytePluralization.format(0, 'octet', options: options) // "0 octet" (singular in French)
  /// ```
  static PluralizationOptions optionsForLocale(String locale) {
    return PluralizationOptions(
      rule: ruleForLocale(locale),
      locale: locale,
    );
  }
}

/// Extension on [int] for quick pluralization.
extension IntPluralizationExtension on int {
  /// Formats this integer with a pluralized unit.
  ///
  /// ```dart
  /// 1.withUnit('byte')   // "1 byte"
  /// 2.withUnit('byte')   // "2 bytes"
  /// 1536.withUnit('byte', useCommas: true) // "1,536 bytes"
  /// ```
  String withUnit(
    String singular, {
    String? plural,
    bool useCommas = false,
  }) {
    return BytePluralization.format(
      this,
      singular,
      plural: plural,
      options: PluralizationOptions(
        useCommaSeparator: useCommas,
      ),
    );
  }
}

/// Extension on [double] for quick pluralization.
extension DoublePluralizationExtension on double {
  /// Formats this double with a pluralized unit.
  ///
  /// ```dart
  /// 1.0.withUnit('megabyte')   // "1 megabyte"
  /// 1.5.withUnit('megabyte')   // "1.5 megabytes"
  /// ```
  String withUnit(
    String singular, {
    String? plural,
    int precision = 2,
  }) {
    return BytePluralization.format(
      this,
      singular,
      plural: plural,
      options: PluralizationOptions(
        precision: precision,
      ),
    );
  }
}
