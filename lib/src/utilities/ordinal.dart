/// Ordinal number formatting utilities.
///
/// Converts numbers to their ordinal representations (1st, 2nd, 3rd, etc.).
/// Useful for ranking displays, file versioning, and position indicators.
///
/// Example:
/// ```dart
/// print(ByteOrdinal.format(1));   // "1st"
/// print(ByteOrdinal.format(2));   // "2nd"
/// print(ByteOrdinal.format(3));   // "3rd"
/// print(ByteOrdinal.format(11));  // "11th"
/// print(ByteOrdinal.format(21));  // "21st"
/// print(ByteOrdinal.format(100)); // "100th"
/// ```
abstract class ByteOrdinal {
  ByteOrdinal._();

  /// Converts a number to its ordinal string representation.
  ///
  /// Examples:
  /// - 1 → "1st"
  /// - 2 → "2nd"
  /// - 3 → "3rd"
  /// - 4 → "4th"
  /// - 11 → "11th"
  /// - 12 → "12th"
  /// - 13 → "13th"
  /// - 21 → "21st"
  /// - 22 → "22nd"
  /// - 23 → "23rd"
  /// - 100 → "100th"
  /// - 101 → "101st"
  static String format(int number) {
    if (number < 0) {
      return '-${format(-number)}';
    }

    final suffix = getSuffix(number);
    return '$number$suffix';
  }

  /// Gets just the ordinal suffix for a number.
  ///
  /// Examples:
  /// - 1 → "st"
  /// - 2 → "nd"
  /// - 3 → "rd"
  /// - 4 → "th"
  static String getSuffix(int number) {
    final absNumber = number.abs();

    // Special case: 11, 12, 13 always use "th"
    final lastTwoDigits = absNumber % 100;
    if (lastTwoDigits >= 11 && lastTwoDigits <= 13) {
      return 'th';
    }

    // Otherwise, based on last digit
    final lastDigit = absNumber % 10;
    switch (lastDigit) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  /// Converts a number to its ordinal word representation.
  ///
  /// Examples:
  /// - 1 → "first"
  /// - 2 → "second"
  /// - 3 → "third"
  /// - 21 → "twenty-first"
  static String toWords(int number) {
    if (number < 0) {
      return 'negative ${toWords(-number)}';
    }

    if (number == 0) return 'zeroth';

    // Special cases for 1-19
    const ordinalWords = <int, String>{
      1: 'first',
      2: 'second',
      3: 'third',
      4: 'fourth',
      5: 'fifth',
      6: 'sixth',
      7: 'seventh',
      8: 'eighth',
      9: 'ninth',
      10: 'tenth',
      11: 'eleventh',
      12: 'twelfth',
      13: 'thirteenth',
      14: 'fourteenth',
      15: 'fifteenth',
      16: 'sixteenth',
      17: 'seventeenth',
      18: 'eighteenth',
      19: 'nineteenth',
    };

    if (ordinalWords.containsKey(number)) {
      return ordinalWords[number]!;
    }

    // Tens
    const tensWords = <int, String>{
      20: 'twent',
      30: 'thirt',
      40: 'fort',
      50: 'fift',
      60: 'sixt',
      70: 'sevent',
      80: 'eight',
      90: 'ninet',
    };

    const tensCardinal = <int, String>{
      20: 'twenty',
      30: 'thirty',
      40: 'forty',
      50: 'fifty',
      60: 'sixty',
      70: 'seventy',
      80: 'eighty',
      90: 'ninety',
    };

    if (number < 100) {
      final tens = (number ~/ 10) * 10;
      final ones = number % 10;

      if (ones == 0) {
        return '${tensWords[tens]}ieth';
      } else {
        return '${tensCardinal[tens]}-${ordinalWords[ones]}';
      }
    }

    // For larger numbers, just use the numeric format
    return format(number);
  }

  /// Formats a number with its ordinal for ranking display.
  ///
  /// Example:
  /// - 1 → "1st place"
  /// - 2 → "2nd place"
  static String rank(int position, {String suffix = 'place'}) {
    return '${format(position)} $suffix';
  }

  /// Formats a file version number.
  ///
  /// Example:
  /// - 1 → "v1"
  /// - 2, true → "2nd version"
  static String version(int number, {bool verbose = false}) {
    if (verbose) {
      return '${format(number)} version';
    }
    return 'v$number';
  }
}

/// Extension for ordinal formatting on integers.
extension OrdinalExtension on int {
  /// Converts this integer to its ordinal string.
  ///
  /// Example: `1.ordinal` returns "1st"
  String get ordinal => ByteOrdinal.format(this);

  /// Gets just the ordinal suffix for this number.
  ///
  /// Example: `1.ordinalSuffix` returns "st"
  String get ordinalSuffix => ByteOrdinal.getSuffix(this);

  /// Converts this integer to ordinal words.
  ///
  /// Example: `1.ordinalWords` returns "first"
  String get ordinalWords => ByteOrdinal.toWords(this);
}
