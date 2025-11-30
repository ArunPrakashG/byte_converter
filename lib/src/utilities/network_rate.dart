/// Network rate utilities for ByteConverter.
///
/// Provides access to network rate properties and transfer time calculations
/// grouped under the `rate` namespace.
library byte_converter.network_rate;

import '../byte_converter_base.dart';
import '../data_rate.dart';

/// Network rate utilities providing bits/bytes per second conversions
/// and transfer time calculations.
///
/// Access via the `rate` namespace:
/// ```dart
/// final size = ByteConverter.fromMegaBytes(100);
/// print(size.rate.bitsPerSecond);  // Raw bits per second value
/// print(size.rate.transferTime(DataRate.megaBitsPerSecond(100)));
/// ```
class NetworkRate {
  /// Creates a NetworkRate for the given byte count.
  const NetworkRate(this._bytes);

  final double _bytes;

  // ─────────────────────────────────────────────────────────────────────────
  // Rate Getters (assuming 1 second transfer)
  // ─────────────────────────────────────────────────────────────────────────

  /// Bits per second if this size were transferred in 1 second.
  double get bitsPerSecond => _bytes * 8.0;

  /// Kilobits per second (SI: 1000 bits) if transferred in 1 second.
  double get kiloBitsPerSecond => bitsPerSecond / 1000.0;

  /// Megabits per second (SI: 1000² bits) if transferred in 1 second.
  double get megaBitsPerSecond => bitsPerSecond / 1000000.0;

  /// Gigabits per second (SI: 1000³ bits) if transferred in 1 second.
  double get gigaBitsPerSecond => bitsPerSecond / 1000000000.0;

  /// Kibibits per second (IEC: 1024 bits) if transferred in 1 second.
  double get kibiBitsPerSecond => bitsPerSecond / 1024.0;

  /// Mebibits per second (IEC: 1024² bits) if transferred in 1 second.
  double get mebiBitsPerSecond => bitsPerSecond / (1024.0 * 1024.0);

  /// Gibibits per second (IEC: 1024³ bits) if transferred in 1 second.
  double get gibiBitsPerSecond => bitsPerSecond / (1024.0 * 1024.0 * 1024.0);

  // ─────────────────────────────────────────────────────────────────────────
  // Byte-based Rate Getters
  // ─────────────────────────────────────────────────────────────────────────

  /// Bytes per second if transferred in 1 second.
  double get bytesPerSecond => _bytes;

  /// Kilobytes per second (SI) if transferred in 1 second.
  double get kiloBytesPerSecond => _bytes / 1000.0;

  /// Megabytes per second (SI) if transferred in 1 second.
  double get megaBytesPerSecond => _bytes / 1000000.0;

  /// Gigabytes per second (SI) if transferred in 1 second.
  double get gigaBytesPerSecond => _bytes / 1000000000.0;

  // ─────────────────────────────────────────────────────────────────────────
  // Transfer Time Calculations
  // ─────────────────────────────────────────────────────────────────────────

  /// Time required to transfer this size at the given [rate].
  ///
  /// ```dart
  /// final fileSize = ByteConverter.fromGigaBytes(4);
  /// final speed = DataRate.megaBitsPerSecond(100);
  /// print(fileSize.rate.transferTime(speed));  // ~5.3 minutes
  /// ```
  Duration transferTime(DataRate rate) {
    if (rate.bitsPerSecond == 0) return Duration.zero;
    final seconds = bitsPerSecond / rate.bitsPerSecond;
    return Duration(microseconds: (seconds * 1e6).ceil());
  }

  /// Time required to transfer this size at a rate specified as [ByteConverter] per second.
  ///
  /// ```dart
  /// final fileSize = ByteConverter.fromGigaBytes(10);
  /// final speed = ByteConverter.fromMegaBytes(100);  // 100 MB/s
  /// print(fileSize.rate.transferTimeAt(speed));  // 100 seconds
  /// ```
  Duration transferTimeAt(ByteConverter ratePerSecond) {
    if (ratePerSecond.bytes == 0) return Duration.zero;
    final seconds = _bytes / ratePerSecond.bytes;
    return Duration(microseconds: (seconds * 1e6).ceil());
  }

  /// Time to download this size at the given [rate].
  ///
  /// Alias for [transferTime] with clearer intent.
  Duration downloadTime(DataRate rate) => transferTime(rate);

  /// Time to upload this size at the given [rate].
  ///
  /// Alias for [transferTime] with clearer intent.
  Duration uploadTime(DataRate rate) => transferTime(rate);

  // ─────────────────────────────────────────────────────────────────────────
  // Rate Conversions
  // ─────────────────────────────────────────────────────────────────────────

  /// Creates a [DataRate] representing this size transferred per second.
  ///
  /// ```dart
  /// final size = ByteConverter.fromMegaBytes(10);
  /// final rate = size.rate.asDataRate;  // 10 MB/s = 80 Mbps
  /// ```
  DataRate get asDataRate => DataRate.bytesPerSecond(_bytes);

  /// Creates a [DataRate] for transferring this size over [duration].
  ///
  /// ```dart
  /// final size = ByteConverter.fromGigaBytes(1);
  /// final rate = size.rate.rateOver(Duration(minutes: 10));
  /// print(rate.toHumanReadable());  // ~13.3 Mbps
  /// ```
  DataRate rateOver(Duration duration) {
    if (duration.inMicroseconds == 0) return DataRate.bitsPerSecond(0);
    final seconds = duration.inMicroseconds / 1e6;
    return DataRate.bytesPerSecond(_bytes / seconds);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Formatted Output
  // ─────────────────────────────────────────────────────────────────────────

  /// Human-readable transfer time at the given [rate].
  ///
  /// ```dart
  /// final size = ByteConverter.fromGigaBytes(4);
  /// print(size.rate.formattedTransferTime(DataRate.megaBitsPerSecond(100)));
  /// // "5 minutes 22 seconds"
  /// ```
  String formattedTransferTime(DataRate rate) {
    final duration = transferTime(rate);
    return _formatDuration(duration);
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      return hours > 0 ? '$days days $hours hours' : '$days days';
    }
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '$hours hours $minutes minutes' : '$hours hours';
    }
    if (duration.inMinutes > 0) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return seconds > 0
          ? '$minutes minutes $seconds seconds'
          : '$minutes minutes';
    }
    if (duration.inSeconds > 0) {
      return '${duration.inSeconds} seconds';
    }
    return '${duration.inMilliseconds} milliseconds';
  }
}
