import '../big_byte_converter.dart';
import '../byte_converter_base.dart';

/// Modes for displaying negative byte values.
enum NegativeDisplayMode {
  /// Show minus sign prefix: "-500 KB"
  minusSign,

  /// Show parentheses: "(500 KB)"
  parentheses,

  /// Show with decrease suffix: "500 KB decrease"
  decreaseSuffix,

  /// Show with reduction suffix: "500 KB reduction"
  reductionSuffix,

  /// Show with loss suffix: "500 KB loss"
  lossSuffix,

  /// Show absolute value only: "500 KB"
  absolute,

  /// Custom format with callback
  custom,
}

/// Modes for byte delta direction.
enum DeltaDirection {
  /// Value increased
  increase,

  /// Value decreased
  decrease,

  /// No change
  unchanged,
}

/// Configuration for negative value formatting.
class NegativeValueOptions {
  /// Create negative value options.
  const NegativeValueOptions({
    this.mode = NegativeDisplayMode.minusSign,
    this.increasePrefix = '+',
    this.decreasePrefix = '-',
    this.increaseSuffix = '',
    this.decreaseSuffix = '',
    this.unchangedLabel = 'unchanged',
    this.customFormatter,
  });

  /// Display mode for negative values.
  final NegativeDisplayMode mode;

  /// Prefix for positive deltas.
  final String increasePrefix;

  /// Prefix for negative deltas.
  final String decreasePrefix;

  /// Suffix for positive deltas.
  final String increaseSuffix;

  /// Suffix for negative deltas.
  final String decreaseSuffix;

  /// Label for unchanged values.
  final String unchangedLabel;

  /// Custom formatter function.
  final String Function(double bytes, bool isNegative)? customFormatter;

  /// Default options with minus sign.
  static const NegativeValueOptions defaults = NegativeValueOptions();

  /// Parentheses style: (500 KB).
  static const NegativeValueOptions parentheses = NegativeValueOptions(
    mode: NegativeDisplayMode.parentheses,
    increasePrefix: '',
    decreasePrefix: '',
  );

  /// Verbose style: "500 KB reduction".
  static const NegativeValueOptions verbose = NegativeValueOptions(
    mode: NegativeDisplayMode.reductionSuffix,
    increasePrefix: '',
    increaseSuffix: ' increase',
    decreasePrefix: '',
    decreaseSuffix: ' reduction',
  );

  /// Delta style: "+500 KB" / "-500 KB".
  static const NegativeValueOptions delta = NegativeValueOptions(
    increasePrefix: '+',
    decreasePrefix: '-',
  );

  /// Creates a copy with modified options.
  NegativeValueOptions copyWith({
    NegativeDisplayMode? mode,
    String? increasePrefix,
    String? decreasePrefix,
    String? increaseSuffix,
    String? decreaseSuffix,
    String? unchangedLabel,
    String Function(double bytes, bool isNegative)? customFormatter,
  }) {
    return NegativeValueOptions(
      mode: mode ?? this.mode,
      increasePrefix: increasePrefix ?? this.increasePrefix,
      decreasePrefix: decreasePrefix ?? this.decreasePrefix,
      increaseSuffix: increaseSuffix ?? this.increaseSuffix,
      decreaseSuffix: decreaseSuffix ?? this.decreaseSuffix,
      unchangedLabel: unchangedLabel ?? this.unchangedLabel,
      customFormatter: customFormatter ?? this.customFormatter,
    );
  }
}

/// Represents a change in byte size with direction awareness.
class SizeDelta {
  /// Create a byte delta from raw byte values.
  SizeDelta(this.from, this.to);

  /// Create a delta representing a decrease.
  factory SizeDelta.decrease(double amount) {
    return SizeDelta(amount, 0);
  }

  /// Create a delta representing an increase.
  factory SizeDelta.increase(double amount) {
    return SizeDelta(0, amount);
  }

  /// Create a delta from ByteConverter instances.
  factory SizeDelta.fromConverters(ByteConverter from, ByteConverter to) {
    return SizeDelta(from.bytes, to.bytes);
  }

  /// Starting value in bytes.
  final double from;

  /// Ending value in bytes.
  final double to;

  /// The raw difference in bytes (can be negative).
  double get difference => to - from;

  /// The absolute difference in bytes.
  double get absoluteDifference => difference.abs();

  /// Whether the value decreased.
  bool get isDecrease => difference < 0;

  /// Whether the value increased.
  bool get isIncrease => difference > 0;

  /// Whether there was no change.
  bool get isUnchanged => difference == 0;

  /// The direction of change.
  DeltaDirection get direction {
    if (isIncrease) return DeltaDirection.increase;
    if (isDecrease) return DeltaDirection.decrease;
    return DeltaDirection.unchanged;
  }

  /// The percentage change (0.5 = 50% increase, -0.5 = 50% decrease).
  double get percentageChange {
    if (from == 0) return isIncrease ? double.infinity : 0;
    return difference / from;
  }

  /// The percentage change as a formatted string.
  String get percentageChangeFormatted {
    final pct = percentageChange * 100;
    if (pct == double.infinity) return '+∞%';
    if (pct == double.negativeInfinity) return '-∞%';
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  /// As a ByteConverter for the difference.
  ByteConverter get asConverter => ByteConverter(absoluteDifference);

  /// Formats the delta with the given options.
  String format({
    NegativeValueOptions options = NegativeValueOptions.defaults,
    int decimals = 2,
  }) {
    return NegativeByteFormatter.formatDelta(
      this,
      options: options,
      decimals: decimals,
    );
  }

  @override
  String toString() => format();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SizeDelta && other.from == from && other.to == to;
  }

  @override
  int get hashCode => Object.hash(from, to);
}

/// Utilities for formatting negative byte values.
abstract class NegativeByteFormatter {
  NegativeByteFormatter._();

  /// Format a byte value that can be negative.
  ///
  /// Example:
  /// ```dart
  /// print(NegativeByteFormatter.format(-500000));
  /// // "-488.28 KB" (default)
  ///
  /// print(NegativeByteFormatter.format(
  ///   -500000,
  ///   options: NegativeValueOptions.parentheses,
  /// ));
  /// // "(488.28 KB)"
  /// ```
  static String format(
    double bytes, {
    NegativeValueOptions options = NegativeValueOptions.defaults,
    int decimals = 2,
  }) {
    final isNegative = bytes < 0;
    final absBytes = bytes.abs();
    final converter = ByteConverter(absBytes);
    final baseStr = converter.toHumanReadableAuto(precision: decimals);

    if (options.mode == NegativeDisplayMode.custom &&
        options.customFormatter != null) {
      return options.customFormatter!(bytes, isNegative);
    }

    if (!isNegative) {
      return '${options.increasePrefix}$baseStr${options.increaseSuffix}';
    }

    switch (options.mode) {
      case NegativeDisplayMode.minusSign:
        return '${options.decreasePrefix}$baseStr${options.decreaseSuffix}';
      case NegativeDisplayMode.parentheses:
        return '($baseStr)';
      case NegativeDisplayMode.decreaseSuffix:
        return '$baseStr decrease';
      case NegativeDisplayMode.reductionSuffix:
        return '$baseStr reduction';
      case NegativeDisplayMode.lossSuffix:
        return '$baseStr loss';
      case NegativeDisplayMode.absolute:
        return baseStr;
      case NegativeDisplayMode.custom:
        // Already handled above
        return baseStr;
    }
  }

  /// Format a byte delta with direction awareness.
  static String formatDelta(
    SizeDelta delta, {
    NegativeValueOptions options = NegativeValueOptions.defaults,
    int decimals = 2,
  }) {
    if (delta.isUnchanged) {
      return options.unchangedLabel;
    }

    final converter = ByteConverter(delta.absoluteDifference);
    final baseStr = converter.toHumanReadableAuto(precision: decimals);

    if (options.mode == NegativeDisplayMode.custom &&
        options.customFormatter != null) {
      return options.customFormatter!(delta.difference, delta.isDecrease);
    }

    if (delta.isIncrease) {
      return '${options.increasePrefix}$baseStr${options.increaseSuffix}';
    }

    switch (options.mode) {
      case NegativeDisplayMode.minusSign:
        return '${options.decreasePrefix}$baseStr${options.decreaseSuffix}';
      case NegativeDisplayMode.parentheses:
        return '($baseStr)';
      case NegativeDisplayMode.decreaseSuffix:
        return '$baseStr decrease';
      case NegativeDisplayMode.reductionSuffix:
        return '$baseStr reduction';
      case NegativeDisplayMode.lossSuffix:
        return '$baseStr loss';
      case NegativeDisplayMode.absolute:
        return baseStr;
      case NegativeDisplayMode.custom:
        return baseStr;
    }
  }

  /// Format a comparison between two values.
  ///
  /// Example:
  /// ```dart
  /// print(NegativeByteFormatter.formatComparison(1000000, 500000));
  /// // "976.56 KB → 488.28 KB (-488.28 KB, -50.0%)"
  /// ```
  static String formatComparison(
    double fromBytes,
    double toBytes, {
    int decimals = 2,
    bool showPercentage = true,
  }) {
    final fromConverter = ByteConverter(fromBytes);
    final toConverter = ByteConverter(toBytes);
    final delta = SizeDelta(fromBytes, toBytes);

    final fromStr = fromConverter.toHumanReadableAuto(precision: decimals);
    final toStr = toConverter.toHumanReadableAuto(precision: decimals);
    final deltaStr = delta.format(decimals: decimals);

    if (showPercentage && !delta.isUnchanged) {
      return '$fromStr → $toStr ($deltaStr, ${delta.percentageChangeFormatted})';
    }

    return '$fromStr → $toStr ($deltaStr)';
  }

  /// Format with up/down arrows for visual indication.
  static String formatWithArrow(
    double bytes, {
    int decimals = 2,
    String upArrow = '↑',
    String downArrow = '↓',
    String noChangeSymbol = '–',
  }) {
    final absBytes = bytes.abs();
    final converter = ByteConverter(absBytes);
    final baseStr = converter.toHumanReadableAuto(precision: decimals);

    if (bytes > 0) {
      return '$upArrow $baseStr';
    } else if (bytes < 0) {
      return '$downArrow $baseStr';
    }
    return '$noChangeSymbol $baseStr';
  }

  /// Format multiple deltas as a summary.
  ///
  /// Example:
  /// ```dart
  /// print(NegativeByteFormatter.formatSummary([
  ///   SizeDelta(1000, 500),
  ///   SizeDelta(2000, 3000),
  /// ]));
  /// // "Net: +512 B (1 increase, 1 decrease)"
  /// ```
  static String formatSummary(
    List<SizeDelta> deltas, {
    int decimals = 2,
  }) {
    if (deltas.isEmpty) return 'No changes';

    final netChange = deltas.fold<double>(
      0,
      (sum, delta) => sum + delta.difference,
    );

    final increases = deltas.where((d) => d.isIncrease).length;
    final decreases = deltas.where((d) => d.isDecrease).length;
    final unchanged = deltas.where((d) => d.isUnchanged).length;

    final netStr = format(netChange,
        decimals: decimals, options: NegativeValueOptions.delta);

    final parts = <String>[];
    if (increases > 0) {
      parts.add('$increases increase${increases > 1 ? 's' : ''}');
    }
    if (decreases > 0) {
      parts.add('$decreases decrease${decreases > 1 ? 's' : ''}');
    }
    if (unchanged > 0) {
      parts.add('$unchanged unchanged');
    }

    return 'Net: $netStr (${parts.join(', ')})';
  }
}

/// Extension on [ByteConverter] for negative value support.
extension NegativeByteConverterExtension on ByteConverter {
  /// Create a delta from this value to another.
  SizeDelta deltaTo(ByteConverter other) {
    return SizeDelta.fromConverters(this, other);
  }

  /// Create a delta from another value to this.
  SizeDelta deltaFrom(ByteConverter other) {
    return SizeDelta.fromConverters(other, this);
  }

  /// Format as a potentially negative value.
  String formatSigned({
    bool showPlus = false,
    int decimals = 2,
  }) {
    final options =
        showPlus ? NegativeValueOptions.delta : NegativeValueOptions.defaults;
    return NegativeByteFormatter.format(bytes,
        options: options, decimals: decimals);
  }
}

/// Extension on [BigByteConverter] for negative value support.
extension NegativeBigByteConverterExtension on BigByteConverter {
  /// Format as a potentially negative value.
  String formatSigned({
    bool showPlus = false,
    int decimals = 2,
  }) {
    final bytesVal = bytes.toDouble();
    final options =
        showPlus ? NegativeValueOptions.delta : NegativeValueOptions.defaults;
    return NegativeByteFormatter.format(bytesVal,
        options: options, decimals: decimals);
  }
}

/// Extension on [double] for negative byte formatting.
extension NegativeBytesDoubleExtension on double {
  /// Format as bytes with negative value support.
  String formatAsSignedBytes({
    NegativeValueOptions options = NegativeValueOptions.defaults,
    int decimals = 2,
  }) {
    return NegativeByteFormatter.format(this,
        options: options, decimals: decimals);
  }

  /// Format with arrow indicator.
  String formatWithArrow({
    int decimals = 2,
    String upArrow = '↑',
    String downArrow = '↓',
  }) {
    return NegativeByteFormatter.formatWithArrow(
      this,
      decimals: decimals,
      upArrow: upArrow,
      downArrow: downArrow,
    );
  }
}
