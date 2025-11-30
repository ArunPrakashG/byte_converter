import 'dart:math' as math;

/// Extended rounding strategies for byte value formatting.
///
/// Provides additional rounding methods beyond the standard `round`, `floor`,
/// and `ceil` operations, including banker's rounding and various
/// tie-breaking strategies.
///
/// Example:
/// ```dart
/// final value = 1.5;
/// print(ByteRounding.round(value, precision: 0));      // 2.0
/// print(ByteRounding.floor(value, precision: 0));      // 1.0
/// print(ByteRounding.ceil(value, precision: 0));       // 2.0
/// print(ByteRounding.truncate(value, precision: 0));   // 1.0
/// print(ByteRounding.halfUp(value, precision: 0));     // 2.0
/// print(ByteRounding.halfEven(value, precision: 0));   // 2.0 (banker's)
/// ```
abstract class ByteRounding {
  ByteRounding._();

  /// Standard rounding (rounds halves away from zero).
  ///
  /// 1.5 → 2, 2.5 → 3, -1.5 → -2
  static double round(double value, {int precision = 2}) {
    final factor = math.pow(10, precision);
    return (value * factor).roundToDouble() / factor;
  }

  /// Rounds toward negative infinity.
  ///
  /// 1.9 → 1, -1.1 → -2
  static double floor(double value, {int precision = 2}) {
    final factor = math.pow(10, precision);
    return (value * factor).floorToDouble() / factor;
  }

  /// Rounds toward positive infinity.
  ///
  /// 1.1 → 2, -1.9 → -1
  static double ceil(double value, {int precision = 2}) {
    final factor = math.pow(10, precision);
    return (value * factor).ceilToDouble() / factor;
  }

  /// Rounds toward zero (truncation).
  ///
  /// 1.9 → 1, -1.9 → -1
  static double truncate(double value, {int precision = 2}) {
    final factor = math.pow(10, precision);
    return (value * factor).truncateToDouble() / factor;
  }

  /// Rounds halves up (toward positive infinity).
  ///
  /// 1.5 → 2, 2.5 → 3, -1.5 → -1, -2.5 → -2
  static double halfUp(double value, {int precision = 2}) {
    final factor = math.pow(10, precision);
    final scaled = value * factor;
    if (scaled >= 0) {
      return (scaled + 0.5).floorToDouble() / factor;
    } else {
      return (scaled + 0.5).ceilToDouble() / factor;
    }
  }

  /// Rounds halves down (toward negative infinity).
  ///
  /// 1.5 → 1, 2.5 → 2, -1.5 → -2, -2.5 → -3
  static double halfDown(double value, {int precision = 2}) {
    final factor = math.pow(10, precision);
    final scaled = value * factor;
    if (scaled >= 0) {
      return (scaled - 0.5 + 1).floorToDouble() / factor;
    } else {
      return (scaled - 0.5).ceilToDouble() / factor;
    }
  }

  /// Banker's rounding (rounds halves to nearest even).
  ///
  /// Also known as "round half to even" or "unbiased rounding".
  /// This minimizes cumulative rounding errors over many operations.
  ///
  /// 1.5 → 2, 2.5 → 2, 3.5 → 4, 4.5 → 4
  static double halfEven(double value, {int precision = 2}) {
    final factor = math.pow(10, precision);
    final scaled = value * factor;
    final integer = scaled.truncateToDouble();
    final fraction = (scaled - integer).abs();

    // Check if it's exactly a half
    if ((fraction - 0.5).abs() < 1e-10) {
      // Round to nearest even
      if (integer.toInt().isEven) {
        return integer / factor;
      } else {
        return (scaled >= 0 ? integer + 1 : integer - 1) / factor;
      }
    }

    // Not a half, use standard rounding
    return scaled.roundToDouble() / factor;
  }

  /// Rounds halves away from zero.
  ///
  /// 1.5 → 2, 2.5 → 3, -1.5 → -2, -2.5 → -3
  static double halfAwayFromZero(double value, {int precision = 2}) {
    final factor = math.pow(10, precision);
    final scaled = value * factor;
    final sign = scaled >= 0 ? 1 : -1;
    return (scaled.abs() + 0.5).floorToDouble() * sign / factor;
  }

  /// Rounds halves toward zero.
  ///
  /// 1.5 → 1, 2.5 → 2, -1.5 → -1, -2.5 → -2
  static double halfTowardZero(double value, {int precision = 2}) {
    final factor = math.pow(10, precision);
    final scaled = value * factor;
    final integer = scaled.truncateToDouble();
    final fraction = (scaled - integer).abs();

    // Check if it's exactly a half
    if ((fraction - 0.5).abs() < 1e-10) {
      return integer / factor;
    }

    // Not a half, use standard rounding
    return scaled.roundToDouble() / factor;
  }

  /// Rounds using the specified [RoundingMode].
  static double withMode(
    double value, {
    int precision = 2,
    ByteRoundingMode mode = ByteRoundingMode.round,
  }) {
    switch (mode) {
      case ByteRoundingMode.round:
        return round(value, precision: precision);
      case ByteRoundingMode.floor:
        return floor(value, precision: precision);
      case ByteRoundingMode.ceil:
        return ceil(value, precision: precision);
      case ByteRoundingMode.truncate:
        return truncate(value, precision: precision);
      case ByteRoundingMode.halfUp:
        return halfUp(value, precision: precision);
      case ByteRoundingMode.halfDown:
        return halfDown(value, precision: precision);
      case ByteRoundingMode.halfEven:
        return halfEven(value, precision: precision);
      case ByteRoundingMode.halfAwayFromZero:
        return halfAwayFromZero(value, precision: precision);
      case ByteRoundingMode.halfTowardZero:
        return halfTowardZero(value, precision: precision);
    }
  }
}

/// Rounding mode enumeration for byte formatting.
enum ByteRoundingMode {
  /// Standard rounding (rounds halves away from zero).
  round,

  /// Rounds toward negative infinity.
  floor,

  /// Rounds toward positive infinity.
  ceil,

  /// Rounds toward zero (truncation).
  truncate,

  /// Rounds halves toward positive infinity.
  halfUp,

  /// Rounds halves toward negative infinity.
  halfDown,

  /// Banker's rounding (rounds halves to nearest even).
  halfEven,

  /// Rounds halves away from zero.
  halfAwayFromZero,

  /// Rounds halves toward zero.
  halfTowardZero,
}

/// Provides convenience methods for rounding byte values.
extension ByteRoundingExtension on double {
  /// Rounds this value using the specified [RoundingMode].
  double roundWithMode({
    int precision = 2,
    ByteRoundingMode mode = ByteRoundingMode.round,
  }) {
    return ByteRounding.withMode(this, precision: precision, mode: mode);
  }

  /// Rounds using banker's rounding (half to even).
  double roundHalfEven({int precision = 2}) {
    return ByteRounding.halfEven(this, precision: precision);
  }

  /// Truncates toward zero with specified precision.
  double truncateWithPrecision({int precision = 2}) {
    return ByteRounding.truncate(this, precision: precision);
  }
}
