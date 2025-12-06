/// Byte-level division and chunking utilities.
///
/// Provides helpers for splitting, distributing, and partitioning byte values
/// across multiple segments or chunks.
///
/// Example:
/// ```dart
/// final size = ByteConverter.fromMegaBytes(100);
/// final chunks = size.divide.split(4.kiloBytes);
/// print(chunks.numChunks);        // 25600 chunks
/// print(chunks.chunkSize);        // 4096 bytes
/// print(chunks.remainder);        // 0 bytes
/// ```
library byte_converter.byte_division;

import '../byte_converter_base.dart';

/// Represents a division result showing how bytes are split into chunks.
class ChunkDivision {
  /// Creates a chunk division result.
  const ChunkDivision({
    required this.numChunks,
    required this.chunkSize,
    required this.remainder,
  });

  /// Number of full chunks that fit evenly.
  final int numChunks;

  /// Size of each individual chunk in bytes.
  final int chunkSize;

  /// Remaining bytes that don't fit into a complete chunk.
  final int remainder;

  /// Total bytes accounted for (numChunks * chunkSize + remainder).
  int get totalBytes => numChunks * chunkSize + remainder;

  /// Whether the division is exact with no remainder.
  bool get isExact => remainder == 0;

  /// Fraction of the last chunk that is used (0.0 to 1.0).
  ///
  /// Returns 1.0 if exact division, or the fraction filled for a partial chunk.
  double get lastChunkUtilization {
    if (isExact) return 1.0;
    return remainder / chunkSize;
  }

  /// Total wasted bytes if this chunk pattern were padded to full chunks.
  int get wastedBytes => isExact ? 0 : (chunkSize - remainder);

  @override
  String toString() =>
      'ChunkDivision($numChunks chunks × $chunkSize B + $remainder B remainder)';
}

/// Represents a distribution result showing how bytes are allocated across parts.
class ByteDistribution {
  /// Creates a byte distribution result.
  const ByteDistribution({
    required this.partSize,
    required this.numParts,
    required this.remainder,
  });

  /// Bytes allocated to each part (equal distribution).
  final int partSize;

  /// Number of parts that receive [partSize] bytes.
  final int numParts;

  /// Remaining bytes after equal distribution.
  ///
  /// These bytes are distributed one per part to the first [remainder] parts.
  final int remainder;

  /// Total bytes being distributed.
  int get totalBytes => partSize * numParts + remainder;

  /// Size of the largest part (with one extra byte if remainder exists).
  int get largestPartSize => partSize + (remainder > 0 ? 1 : 0);

  /// Size of the smallest part (base allocation).
  int get smallestPartSize => partSize;

  /// Whether distribution is perfectly even with no remainder.
  bool get isExact => remainder == 0;

  /// Maximum difference between parts (always 0 or 1).
  int get maxDeviation => remainder > 0 ? 1 : 0;

  @override
  String toString() =>
      'ByteDistribution($numParts parts: $partSize B each + $remainder B remainder)';
}

/// Division namespace providing chunking and distribution utilities.
///
/// Access via the `divide` extension property on [ByteConverter]:
/// ```dart
/// final size = ByteConverter.fromMegaBytes(100);
/// final chunks = size.divide.split(4.kiloBytes);
/// final dist = size.divide.distribute(4);
/// ```
class ByteDivisionNamespace {
  /// Creates division utilities for the given byte value.
  const ByteDivisionNamespace(this._bytes);

  final double _bytes;

  /// Divides this byte value into fixed-size chunks.
  ///
  /// Returns a [ChunkDivision] showing how many complete chunks fit,
  /// plus any remainder.
  ///
  /// Example:
  /// ```dart
  /// final size = ByteConverter.fromMegaBytes(10);  // 10,485,760 bytes
  /// final chunks = size.divide.split(4096);         // 4 KB chunks
  /// print(chunks.numChunks);   // 2560
  /// print(chunks.remainder);   // 0
  /// ```
  ChunkDivision split(int chunkSize) {
    if (chunkSize <= 0) {
      throw ArgumentError('Chunk size must be positive, got $chunkSize');
    }
    final totalBytes = _bytes.toInt();
    final numChunks = totalBytes ~/ chunkSize;
    final remainder = totalBytes % chunkSize;
    return ChunkDivision(
      numChunks: numChunks,
      chunkSize: chunkSize,
      remainder: remainder,
    );
  }

  /// Distributes this byte value evenly across a number of parts.
  ///
  /// Returns a [ByteDistribution] showing the base size per part and remainder.
  /// The first [remainder] parts get one extra byte each.
  ///
  /// Example:
  /// ```dart
  /// final size = ByteConverter.fromKiloBytes(100);  // 102,400 bytes
  /// final dist = size.divide.distribute(3);
  /// print(dist.partSize);   // 34,133 bytes
  /// print(dist.remainder);  // 1 byte (first part gets 34,134)
  /// ```
  ByteDistribution distribute(int numParts) {
    if (numParts <= 0) {
      throw ArgumentError('Number of parts must be positive, got $numParts');
    }
    final totalBytes = _bytes.toInt();
    final partSize = totalBytes ~/ numParts;
    final remainder = totalBytes % numParts;
    return ByteDistribution(
      partSize: partSize,
      numParts: numParts,
      remainder: remainder,
    );
  }

  /// Computes the remainder (modulo) when dividing by a boundary.
  ///
  /// Useful for alignment calculations and determining padding needed.
  ///
  /// Example:
  /// ```dart
  /// final size = ByteConverter(1000);
  /// print(size.divide.modulo(512));  // 488 (1000 % 512)
  /// ```
  int modulo(int boundary) {
    if (boundary <= 0) {
      throw ArgumentError('Boundary must be positive, got $boundary');
    }
    return _bytes.toInt() % boundary;
  }

  /// Computes padding needed to reach the next boundary (ceiling).
  ///
  /// Example:
  /// ```dart
  /// final size = ByteConverter(1000);
  /// print(size.divide.paddingTo(512));  // 24 bytes needed
  /// // 1000 + 24 = 1024 (next 512-byte boundary)
  /// ```
  int paddingTo(int boundary) {
    if (boundary <= 0) {
      throw ArgumentError('Boundary must be positive, got $boundary');
    }
    final remainder = _bytes.toInt() % boundary;
    return remainder == 0 ? 0 : (boundary - remainder);
  }
}

/// Extension providing division utilities on [ByteConverter].
extension ByteDivisionExtension on ByteConverter {
  /// Accesses byte division utilities (split, distribute, modulo).
  ByteDivisionNamespace get divide => ByteDivisionNamespace(bytes);
}
