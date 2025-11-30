import '../byte_converter_base.dart';

/// Provides comparison and relationship utilities for byte values.
///
/// Access via the `compare` extension property on [ByteConverter]:
/// ```dart
/// final used = ByteConverter.fromGB(75);
/// final total = ByteConverter.fromGB(100);
///
/// print(used.compare.percentOf(total));      // 75.0
/// print(used.compare.relativeTo(total));     // "75% of"
/// print(used.compare.percentageBar(total));  // "███████████████░░░░░"
/// ```
class ByteComparison {
  /// Creates comparison utilities for the given byte value.
  const ByteComparison(this._bytes);

  final double _bytes;

  /// Calculates what percentage this value is of [total].
  ///
  /// Returns:
  /// - 0.0 if this value is 0
  /// - [double.infinity] if total is 0 and this value is non-zero
  /// - Percentage as a double (e.g., 75.0 for 75%)
  ///
  /// Example:
  /// ```dart
  /// final used = ByteConverter.fromGB(75);
  /// final total = ByteConverter.fromGB(100);
  /// print(used.compare.percentOf(total));  // 75.0
  /// ```
  double percentOf(ByteConverter total) {
    if (_bytes == 0) return 0.0;
    if (total.bytes == 0) return double.infinity;
    return (_bytes / total.bytes) * 100;
  }

  /// Generates an ASCII progress bar showing percentage of [total].
  ///
  /// Parameters:
  /// - [total]: The total/maximum value
  /// - [width]: Character width of the bar (default: 20)
  /// - [filled]: Character for filled portion (default: '█')
  /// - [empty]: Character for empty portion (default: '░')
  ///
  /// Example:
  /// ```dart
  /// final used = ByteConverter.fromGB(75);
  /// final total = ByteConverter.fromGB(100);
  /// print(used.compare.percentageBar(total));  // "███████████████░░░░░"
  /// ```
  String percentageBar(
    ByteConverter total, {
    int width = 20,
    String filled = '█',
    String empty = '░',
  }) {
    final percent = percentOf(total).clamp(0, 100);
    final filledCount = ((percent / 100) * width).round();
    final emptyCount = width - filledCount;
    return filled * filledCount + empty * emptyCount;
  }

  /// Returns a human-readable description of the relationship to [other].
  ///
  /// Examples:
  /// - "2.5× larger"
  /// - "3× smaller"
  /// - "equal"
  /// - "50% of"
  ///
  /// Set [useMultiplier] to false to prefer percentage format.
  String relativeTo(ByteConverter other, {bool useMultiplier = true}) {
    if (_bytes == other.bytes) return 'equal';
    if (_bytes == 0) return '0% of';
    if (other.bytes == 0) return 'infinitely larger';

    final ratio = _bytes / other.bytes;

    if (useMultiplier) {
      if (ratio > 1) {
        final mult = _formatMultiplier(ratio);
        return '$mult× larger';
      } else {
        final mult = _formatMultiplier(1 / ratio);
        return '$mult× smaller';
      }
    } else {
      final percent = (ratio * 100).round();
      return '$percent% of';
    }
  }

  /// Returns the difference between this value and [other].
  ///
  /// The result is always positive (absolute difference).
  ByteConverter difference(ByteConverter other) {
    final diff = (_bytes - other.bytes).abs();
    return ByteConverter(diff);
  }

  /// Returns the signed difference (this - other).
  ///
  /// Can be negative if this value is smaller than [other].
  double signedDifference(ByteConverter other) {
    return _bytes - other.bytes;
  }

  /// Calculates the ratio of this value to [other].
  ///
  /// Returns 0.0 if other is 0.
  double ratio(ByteConverter other) {
    if (other.bytes == 0) return _bytes == 0 ? 1.0 : double.infinity;
    return _bytes / other.bytes;
  }

  /// Returns true if this value is within [range] of [other].
  ///
  /// The [range] is a [ByteConverter] representing the maximum allowed difference.
  ///
  /// Example:
  /// ```dart
  /// final a = ByteConverter.fromMB(100);
  /// final b = ByteConverter.fromMB(105);
  /// final tolerance = ByteConverter.fromMB(10);
  /// print(a.compare.isWithin(tolerance, of: b));  // true
  /// ```
  bool isWithin(ByteConverter range, {required ByteConverter of}) {
    final diff = (_bytes - of.bytes).abs();
    return diff <= range.bytes;
  }

  /// Returns true if this value is larger than [other].
  bool isLargerThan(ByteConverter other) => _bytes > other.bytes;

  /// Returns true if this value is smaller than [other].
  bool isSmallerThan(ByteConverter other) => _bytes < other.bytes;

  /// Returns true if this value equals [other] (within floating point tolerance).
  bool equals(ByteConverter other, {double tolerance = 1e-9}) {
    return (_bytes - other.bytes).abs() < tolerance;
  }

  /// Formats a compression ratio between [original] and [compressed].
  ///
  /// Returns a string like "3.2:1 (68.7% reduction)" or "1:2.5 (150% expansion)".
  ///
  /// Example:
  /// ```dart
  /// final original = ByteConverter.fromMB(100);
  /// final compressed = ByteConverter.fromMB(25);
  /// print(ByteComparison.compressionRatio(original, compressed));
  /// // "4:1 (75% reduction)"
  /// ```
  static String compressionRatio(
      ByteConverter original, ByteConverter compressed) {
    if (original.bytes == 0) return 'N/A (original is 0)';
    if (compressed.bytes == 0) return '∞:1 (100% reduction)';

    final ratio = original.bytes / compressed.bytes;

    if (ratio >= 1) {
      // Compression occurred
      final reduction = ((1 - (compressed.bytes / original.bytes)) * 100);
      final ratioStr = _formatRatio(ratio);
      final reductionStr = reduction.toStringAsFixed(1);
      return '$ratioStr:1 ($reductionStr% reduction)';
    } else {
      // Expansion occurred
      final expansion = ((compressed.bytes / original.bytes - 1) * 100);
      final ratioStr = _formatRatio(1 / ratio);
      final expansionStr = expansion.toStringAsFixed(1);
      return '1:$ratioStr ($expansionStr% expansion)';
    }
  }

  /// Returns the minimum of this and [other].
  ByteConverter min(ByteConverter other) {
    return _bytes <= other.bytes ? ByteConverter(_bytes) : other;
  }

  /// Returns the maximum of this and [other].
  ByteConverter max(ByteConverter other) {
    return _bytes >= other.bytes ? ByteConverter(_bytes) : other;
  }

  /// Clamps this value to be within [min] and [max].
  ByteConverter clamp(ByteConverter min, ByteConverter max) {
    if (_bytes < min.bytes) return min;
    if (_bytes > max.bytes) return max;
    return ByteConverter(_bytes);
  }

  // Helper to format multiplier values
  String _formatMultiplier(double value) {
    if (value == value.round()) {
      return value.round().toString();
    }
    // Round to 1 decimal place
    final rounded = (value * 10).round() / 10;
    if (rounded == rounded.round()) {
      return rounded.round().toString();
    }
    return rounded.toString();
  }

  // Helper to format ratio values
  static String _formatRatio(double value) {
    if (value == value.round()) {
      return value.round().toString();
    }
    // Round to 1 decimal place
    final rounded = (value * 10).round() / 10;
    if (rounded == rounded.round()) {
      return rounded.round().toString();
    }
    return rounded.toString();
  }
}
