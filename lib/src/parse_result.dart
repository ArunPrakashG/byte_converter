/// Result and error types returned by non-throwing parse helpers.
///
/// Provides [ParseResult] as a wrapper around successful or failed parse
/// attempts and [ParseError] with structured failure details.
///
/// Diagnostics returned by `tryParse` helpers for byte and data rate parsing.
library byte_converter.parse_result;

/// Structured error information produced by parse helpers.
class ParseError {
  /// Creates an error with a human-readable [message] and optional failure
  /// [position] within the input and original [exception].
  const ParseError({
    required this.message,
    this.position,
    this.exception,
  });

  /// Human-readable description of the failure.
  final String message;

  /// Optional character position in the input where parsing failed.
  final int? position;

  /// Original exception that was raised internally, useful for debugging.
  final Object? exception;

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (position != null) {
      buffer.write(' (at position $position)');
    }
    return buffer.toString();
  }
}

/// Result wrapper for non-throwing parse helpers.
class ParseResult<T> {
  /// Internal constructor used by the success/failure factories.
  const ParseResult._({
    required this.originalInput,
    this.value,
    this.normalizedInput,
    this.detectedUnit,
    this.isBitInput,
    this.parsedNumber,
    this.error,
  });

  /// Creates a successful parse result.
  factory ParseResult.success({
    required String originalInput,
    required T value,
    required String normalizedInput,
    String? detectedUnit,
    bool? isBitInput,
    double? parsedNumber,
  }) =>
      ParseResult._(
        originalInput: originalInput,
        value: value,
        normalizedInput: normalizedInput,
        detectedUnit: detectedUnit,
        isBitInput: isBitInput,
        parsedNumber: parsedNumber,
      );

  /// Creates a failed parse result.
  factory ParseResult.failure({
    required String originalInput,
    required ParseError error,
    String? normalizedInput,
  }) =>
      ParseResult._(
        originalInput: originalInput,
        error: error,
        normalizedInput: normalizedInput,
      );

  /// The input string exactly as provided by the caller.
  final String originalInput;

  /// The successfully parsed value, null if parsing failed.
  final T? value;

  /// Normalized representation of the input (trimmed, canonical unit symbols).
  final String? normalizedInput;

  /// Canonical unit symbol detected from the input (e.g., `MB`, `MiB`, `Mb`).
  final String? detectedUnit;

  /// Indicates whether the user-input unit was expressed in bits.
  final bool? isBitInput;

  /// Numeric portion parsed from the input prior to unit conversion.
  final double? parsedNumber;

  /// Error information when parsing fails.
  final ParseError? error;

  /// Whether the parse completed without errors.
  /// True when parsing completed successfully and [value] is available.
  bool get isSuccess => value != null && error == null;

  /// Convenience accessor that throws if the parse failed.
  /// Returns [value] when [isSuccess] is true, otherwise throws [StateError].
  T get requireValue {
    final result = value;
    if (!isSuccess || result == null) {
      throw StateError('ParseResult does not contain a value');
    }
    return result;
  }
}
