/// Extensions providing namespace access for ByteConverter display, output,
/// comparison, and accessibility features.
library byte_converter.namespaces;

import 'accessibility/byte_accessibility.dart';
import 'big_byte_converter.dart';
import 'byte_converter_base.dart';
import 'byte_enums.dart';
import 'comparison/byte_comparison.dart';
import 'display/byte_display_options.dart';
import 'output/byte_output_formats.dart';
import 'utilities/network_rate.dart';
import 'utilities/storage_alignment.dart' show StorageNamespace;

export 'accessibility/byte_accessibility.dart';
export 'accumulator/bandwidth_accumulator.dart';
export 'bits/bit_operations.dart';
export 'comparison/byte_comparison.dart';
export 'constants/byte_constants.dart';
export 'display/byte_display_options.dart';
export 'output/byte_output_formats.dart';
export 'utilities/byte_rounding.dart';
export 'utilities/natural_time_delta.dart';
export 'utilities/negative_value.dart';
export 'utilities/network_rate.dart';
export 'utilities/ordinal.dart';
export 'utilities/relative_time.dart';
export 'utilities/si_number.dart';
export 'utilities/storage_alignment.dart';
export 'validation/byte_validation.dart';

/// Extension providing namespace accessors for [ByteConverter].
///
/// Example usage:
/// ```dart
/// final size = ByteConverter.fromMB(1.5);
///
/// // Display namespace
/// print(size.display.fuzzy);       // "about 1.5 MB"
/// print(size.display.scientific);  // "1.5 × 10⁶ B"
/// print(size.display.gnu);         // "1.5M"
///
/// // Output namespace
/// print(size.output.asArray);      // [1.5, 'MB']
/// print(size.output.asTuple);      // (1.5, 'MB')
///
/// // Comparison namespace
/// final total = ByteConverter.fromGB(1);
/// print(size.compare.percentOf(total));  // 0.15
///
/// // Accessibility namespace
/// print(size.accessibility.screenReader);  // "one point five megabytes"
/// ```
extension ByteConverterNamespaces on ByteConverter {
  /// Access alternative display formats (fuzzy, scientific, fractional, GNU).
  ///
  /// Example:
  /// ```dart
  /// final size = ByteConverter.fromMB(1.5);
  /// print(size.display.fuzzy);  // "about 1.5 MB"
  /// ```
  ByteDisplayOptions get display => ByteDisplayOptions(bytes);

  /// Access structured output formats (array, tuple, map, exponent).
  ///
  /// Example:
  /// ```dart
  /// final size = ByteConverter.fromKB(1536);
  /// print(size.output.asArray);  // [1.5, 'MB']
  /// ```
  ByteOutputFormats get output => ByteOutputFormats(bytes);

  /// Access output formats with a specific standard.
  ///
  /// Example:
  /// ```dart
  /// final size = ByteConverter.fromKB(1024);
  /// print(size.outputWith(ByteStandard.iec).asArray);  // [1.0, 'MiB']
  /// ```
  ByteOutputFormats outputWith(ByteStandard standard) =>
      ByteOutputFormats(bytes, standard: standard);

  /// Access comparison and relationship utilities.
  ///
  /// Example:
  /// ```dart
  /// final used = ByteConverter.fromGB(75);
  /// final total = ByteConverter.fromGB(100);
  /// print(used.compare.percentOf(total));  // 75.0
  /// ```
  ByteComparison get compare => ByteComparison(bytes);

  /// Access accessibility-friendly output formats.
  ///
  /// Example:
  /// ```dart
  /// final size = ByteConverter.fromMB(1.5);
  /// print(size.accessibility.screenReader);  // "one point five megabytes"
  /// ```
  ByteAccessibility get accessibility => ByteAccessibility(bytes);

  /// Access storage alignment utilities (sectors, blocks, pages, words).
  ///
  /// Example:
  /// ```dart
  /// final size = ByteConverter.fromKiloBytes(512);
  /// print(size.storage.sectors);        // Number of 512-byte sectors
  /// print(size.storage.isWholeSector);  // true if aligned
  /// print(size.storage.roundToBlock()); // Round to 4096-byte boundary
  /// ```
  StorageNamespace get storage => StorageNamespace(bytes);

  /// Access network rate utilities (bits per second, transfer times).
  ///
  /// Example:
  /// ```dart
  /// final size = ByteConverter.fromMegaBytes(100);
  /// print(size.rate.bitsPerSecond);                  // 800000000.0
  /// print(size.rate.transferTime(DataRate.megaBitsPerSecond(100)));
  /// ```
  NetworkRate get rate => NetworkRate(bytes);
}

/// Extension providing namespace accessors for [BigByteConverter].
///
/// Mirrors the [ByteConverterNamespaces] extension but for BigInt-backed values.
extension BigByteConverterNamespaces on BigByteConverter {
  /// Access alternative display formats (fuzzy, scientific, fractional, GNU).
  ByteDisplayOptions get display => ByteDisplayOptions(bytes.toDouble());

  /// Access structured output formats (array, tuple, map, exponent).
  ByteOutputFormats get output => ByteOutputFormats(bytes.toDouble());

  /// Access output formats with a specific standard.
  ByteOutputFormats outputWith(ByteStandard standard) =>
      ByteOutputFormats(bytes.toDouble(), standard: standard);

  /// Access comparison utilities.
  ///
  /// Note: For BigByteConverter comparisons, values are converted to double
  /// which may lose precision for extremely large values.
  ByteComparison get compare => ByteComparison(bytes.toDouble());

  /// Access accessibility-friendly output formats.
  ByteAccessibility get accessibility => ByteAccessibility(bytes.toDouble());

  /// Access storage alignment utilities.
  ///
  /// Note: Values are converted to double which may lose precision
  /// for extremely large values.
  StorageNamespace get storage => StorageNamespace(bytes.toDouble());

  /// Access network rate utilities.
  ///
  /// Note: Values are converted to double which may lose precision
  /// for extremely large values.
  NetworkRate get rate => NetworkRate(bytes.toDouble());
}
