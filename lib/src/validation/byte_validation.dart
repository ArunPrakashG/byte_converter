import '../byte_converter_base.dart';

/// Input validation utilities for byte values.
///
/// Provides helpers for validating file sizes, quota checks,
/// and assertion helpers.
///
/// Example:
/// ```dart
/// // Validate file size before upload
/// if (!ByteValidation.isValidFileSize(fileSize, maxSize: ByteConverter.fromMB(100))) {
///   throw ArgumentError('File too large');
/// }
///
/// // Check quota
/// if (!ByteValidation.isWithinQuota(currentUsage, quota: ByteConverter.fromGB(5))) {
///   print('Quota exceeded!');
/// }
/// ```
class ByteValidation {
  ByteValidation._();

  /// Validates that [size] is within the allowed [maxSize].
  ///
  /// Returns true if size <= maxSize.
  static bool isValidFileSize(
    ByteConverter size, {
    required ByteConverter maxSize,
    ByteConverter? minSize,
  }) {
    if (minSize != null && size.bytes < minSize.bytes) {
      return false;
    }
    return size.bytes <= maxSize.bytes;
  }

  /// Validates that [currentUsage] is within [quota].
  ///
  /// Optionally specify a [warningThreshold] (0.0 to 1.0) to check
  /// if approaching quota.
  static bool isWithinQuota(
    ByteConverter currentUsage, {
    required ByteConverter quota,
  }) {
    return currentUsage.bytes <= quota.bytes;
  }

  /// Checks if [currentUsage] exceeds [warningThreshold] of [quota].
  ///
  /// [warningThreshold] should be between 0.0 and 1.0 (e.g., 0.8 for 80%).
  static bool isApproachingQuota(
    ByteConverter currentUsage, {
    required ByteConverter quota,
    double warningThreshold = 0.8,
  }) {
    if (quota.bytes == 0) return true;
    return (currentUsage.bytes / quota.bytes) >= warningThreshold;
  }

  /// Returns the percentage of quota used.
  static double quotaUsedPercent(
    ByteConverter currentUsage, {
    required ByteConverter quota,
  }) {
    if (quota.bytes == 0) return currentUsage.bytes > 0 ? 100.0 : 0.0;
    return (currentUsage.bytes / quota.bytes) * 100;
  }

  /// Validates that [size] is positive (> 0).
  static bool isPositive(ByteConverter size) {
    return size.bytes > 0;
  }

  /// Validates that [size] is non-negative (>= 0).
  static bool isNonNegative(ByteConverter size) {
    return size.bytes >= 0;
  }

  /// Validates that [size] is within the specified range.
  static bool isInRange(
    ByteConverter size, {
    required ByteConverter min,
    required ByteConverter max,
  }) {
    return size.bytes >= min.bytes && size.bytes <= max.bytes;
  }

  /// Asserts that [size] is positive, throwing [ArgumentError] if not.
  static void assertPositive(ByteConverter size, [String? name]) {
    if (size.bytes <= 0) {
      throw ArgumentError.value(
        size.bytes,
        name ?? 'size',
        'must be positive',
      );
    }
  }

  /// Asserts that [size] is non-negative, throwing [ArgumentError] if not.
  static void assertNonNegative(ByteConverter size, [String? name]) {
    if (size.bytes < 0) {
      throw ArgumentError.value(
        size.bytes,
        name ?? 'size',
        'must be non-negative',
      );
    }
  }

  /// Asserts that [size] does not exceed [maxSize].
  static void assertMaxSize(
    ByteConverter size, {
    required ByteConverter maxSize,
    String? name,
  }) {
    if (size.bytes > maxSize.bytes) {
      throw ArgumentError.value(
        size.bytes,
        name ?? 'size',
        'must not exceed ${maxSize.toHumanReadableAuto()}',
      );
    }
  }

  /// Asserts that [size] is at least [minSize].
  static void assertMinSize(
    ByteConverter size, {
    required ByteConverter minSize,
    String? name,
  }) {
    if (size.bytes < minSize.bytes) {
      throw ArgumentError.value(
        size.bytes,
        name ?? 'size',
        'must be at least ${minSize.toHumanReadableAuto()}',
      );
    }
  }

  /// Asserts that [size] is within the specified range.
  static void assertInRange(
    ByteConverter size, {
    required ByteConverter min,
    required ByteConverter max,
    String? name,
  }) {
    if (size.bytes < min.bytes || size.bytes > max.bytes) {
      throw ArgumentError.value(
        size.bytes,
        name ?? 'size',
        'must be between ${min.toHumanReadableAuto()} and ${max.toHumanReadableAuto()}',
      );
    }
  }

  /// Validates the result and returns a [ValidationResult].
  static ValidationResult validate(
    ByteConverter size, {
    ByteConverter? maxSize,
    ByteConverter? minSize,
    bool requirePositive = false,
  }) {
    final errors = <String>[];

    if (requirePositive && size.bytes <= 0) {
      errors.add('Size must be positive');
    } else if (size.bytes < 0) {
      errors.add('Size cannot be negative');
    }

    if (minSize != null && size.bytes < minSize.bytes) {
      errors.add('Size must be at least ${minSize.toHumanReadableAuto()}');
    }

    if (maxSize != null && size.bytes > maxSize.bytes) {
      errors.add('Size must not exceed ${maxSize.toHumanReadableAuto()}');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      size: size,
    );
  }
}

/// Result of a validation operation.
class ValidationResult {
  /// Creates a validation result.
  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.size,
  });

  /// Whether the validation passed.
  final bool isValid;

  /// List of validation error messages (empty if valid).
  final List<String> errors;

  /// The size that was validated.
  final ByteConverter size;

  /// Returns the first error message, or null if valid.
  String? get firstError => errors.isEmpty ? null : errors.first;

  /// Throws [ArgumentError] if validation failed.
  void throwIfInvalid([String? name]) {
    if (!isValid) {
      throw ArgumentError.value(
        size.bytes,
        name ?? 'size',
        errors.join('; '),
      );
    }
  }
}

/// Extension to add validation methods to ByteConverter.
extension ByteValidationExtension on ByteConverter {
  /// Validates this size against the given constraints.
  ValidationResult validate({
    ByteConverter? maxSize,
    ByteConverter? minSize,
    bool requirePositive = false,
  }) {
    return ByteValidation.validate(
      this,
      maxSize: maxSize,
      minSize: minSize,
      requirePositive: requirePositive,
    );
  }

  /// Returns true if this size is within the specified range.
  bool isInRange({required ByteConverter min, required ByteConverter max}) {
    return ByteValidation.isInRange(this, min: min, max: max);
  }

  /// Returns true if this size is within [quota].
  bool isWithinQuota(ByteConverter quota) {
    return ByteValidation.isWithinQuota(this, quota: quota);
  }

  /// Asserts that this size is positive.
  void assertPositive([String? name]) {
    ByteValidation.assertPositive(this, name);
  }

  /// Asserts that this size does not exceed [maxSize].
  void assertMaxSize(ByteConverter maxSize, [String? name]) {
    ByteValidation.assertMaxSize(this, maxSize: maxSize, name: name);
  }
}
