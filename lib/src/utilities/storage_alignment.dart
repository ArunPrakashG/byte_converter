/// Storage alignment utilities for ByteConverter.
///
/// Provides access to storage-related properties and methods grouped
/// under the `storage` namespace.
library byte_converter.storage_alignment;

import '../byte_converter_base.dart';
import '../byte_enums.dart' show RoundingMode;
import '../storage_profile.dart' show StorageProfile;

/// Storage alignment utilities providing sector, block, page, and word
/// calculations along with rounding and alignment checks.
///
/// Access via the `storage` namespace:
/// ```dart
/// final size = ByteConverter.fromKiloBytes(512);
/// print(size.storage.sectors);        // Number of sectors
/// print(size.storage.isWholeSector);  // true if aligned to sector boundary
/// print(size.storage.roundToBlock()); // Round to block boundary
/// ```
class StorageNamespace {
  /// Creates a StorageNamespace for the given byte count.
  const StorageNamespace(this._bytes);

  final double _bytes;

  // Storage unit sizes
  static const int _sectorSize = 512;
  static const int _blockSize = 4096;
  static const int _pageSize = 4096;
  static const int _wordSize = 8;

  // ─────────────────────────────────────────────────────────────────────────
  // Size Getters
  // ─────────────────────────────────────────────────────────────────────────

  /// Number of 512-byte sectors (rounded up).
  int get sectors => (_bytes / _sectorSize).ceil();

  /// Number of 4096-byte blocks (rounded up).
  int get blocks => (_bytes / _blockSize).ceil();

  /// Number of 4096-byte pages (rounded up).
  int get pages => (_bytes / _pageSize).ceil();

  /// Number of 8-byte words (rounded up).
  int get words => (_bytes / _wordSize).ceil();

  // ─────────────────────────────────────────────────────────────────────────
  // Alignment Checks
  // ─────────────────────────────────────────────────────────────────────────

  /// True if this value is exactly aligned to a sector boundary (512 B).
  bool get isWholeSector => _bytes % _sectorSize == 0;

  /// True if this value is exactly aligned to a block boundary (4096 B).
  bool get isWholeBlock => _bytes % _blockSize == 0;

  /// True if this value is exactly aligned to a page boundary (4096 B).
  bool get isWholePage => _bytes % _pageSize == 0;

  /// True if this value is exactly aligned to a word boundary (8 B).
  bool get isWholeWord => _bytes % _wordSize == 0;

  // ─────────────────────────────────────────────────────────────────────────
  // Rounding Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Rounds up to the next sector boundary (512 B).
  ByteConverter roundToSector() => ByteConverter((sectors * _sectorSize).toDouble());

  /// Rounds up to the next block boundary (4096 B).
  ByteConverter roundToBlock() => ByteConverter((blocks * _blockSize).toDouble());

  /// Rounds up to the next page boundary (4096 B).
  ByteConverter roundToPage() => ByteConverter((pages * _pageSize).toDouble());

  /// Rounds up to the next word boundary (8 B).
  ByteConverter roundToWord() => ByteConverter((words * _wordSize).toDouble());

  /// Aligns to a custom boundary size.
  ///
  /// ```dart
  /// final size = ByteConverter(1000);
  /// print(size.storage.alignTo(256));  // 1024 bytes
  /// ```
  ByteConverter alignTo(int boundarySize) {
    if (boundarySize <= 0) return ByteConverter(_bytes);
    final aligned = (_bytes / boundarySize).ceil() * boundarySize;
    return ByteConverter(aligned.toDouble());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profile-based Alignment
  // ─────────────────────────────────────────────────────────────────────────

  /// Aligns this value to a [StorageProfile] bucket.
  ///
  /// ```dart
  /// final profile = StorageProfile.ssd();
  /// final size = ByteConverter.fromKiloBytes(100);
  /// print(size.storage.roundToProfile(profile));
  /// ```
  ByteConverter roundToProfile(
    StorageProfile profile, {
    String? alignment,
    RoundingMode? rounding,
  }) {
    final resolved = profile.resolve(alignment);
    final blockSize = resolved.blockSizeBytes.toDouble();
    final mode = profile.roundingFor(
      alignment: alignment,
      override: rounding,
    );
    final quotient = _bytes / blockSize;
    final multiplier = switch (mode) {
      RoundingMode.floor => quotient.floor(),
      RoundingMode.ceil => quotient.ceil(),
      RoundingMode.round => quotient.round(),
    };
    return ByteConverter(multiplier * blockSize);
  }

  /// Calculates slack (unused bytes) after alignment.
  ///
  /// ```dart
  /// final size = ByteConverter(1000);
  /// print(size.storage.alignmentSlack(StorageProfile.ssd()));
  /// ```
  ByteConverter alignmentSlack(
    StorageProfile profile, {
    String? alignment,
    RoundingMode? rounding,
  }) {
    final aligned = roundToProfile(
      profile,
      alignment: alignment,
      rounding: rounding,
    );
    final slack = aligned.bytes - _bytes;
    return ByteConverter(slack <= 0 ? 0.0 : slack);
  }

  /// Returns true when this value satisfies the requested profile alignment.
  bool isAligned(StorageProfile profile, {String? alignment}) {
    final blockSize = profile.blockSizeBytes(alignment).toDouble();
    if (blockSize == 0) return false;
    final remainder = _bytes % blockSize;
    const epsilon = 1e-9;
    return remainder.abs() < epsilon ||
        (blockSize - remainder).abs() < epsilon;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Slack Calculations
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns wasted bytes when aligning to sector boundary.
  ByteConverter get sectorSlack {
    final aligned = sectors * _sectorSize;
    return ByteConverter((aligned - _bytes).abs());
  }

  /// Returns wasted bytes when aligning to block boundary.
  ByteConverter get blockSlack {
    final aligned = blocks * _blockSize;
    return ByteConverter((aligned - _bytes).abs());
  }

  /// Returns wasted bytes when aligning to page boundary.
  ByteConverter get pageSlack {
    final aligned = pages * _pageSize;
    return ByteConverter((aligned - _bytes).abs());
  }

  /// Returns wasted bytes when aligning to word boundary.
  ByteConverter get wordSlack {
    final aligned = words * _wordSize;
    return ByteConverter((aligned - _bytes).abs());
  }
}
