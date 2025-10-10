import 'byte_converter_base.dart';
import 'data_rate.dart';

class TransferPlan {
  TransferPlan({
    required this.totalBytes,
    required this.rate,
    ByteConverter? transferredBytes,
    Duration? elapsed,
  })  : _transferredBytes = transferredBytes,
        _elapsed = elapsed {
    if (rate.bitsPerSecond < 0) {
      throw ArgumentError('Transfer rate cannot be negative');
    }
    if (totalBytes.bytes < 0) {
      throw ArgumentError('Total bytes cannot be negative');
    }
  }

  final ByteConverter totalBytes;
  final DataRate rate;
  final ByteConverter? _transferredBytes;
  final Duration? _elapsed;

  ByteConverter get transferredBytes {
    final existing = _transferredBytes;
    if (existing != null) {
      return _clampToTotal(existing);
    }
    final elapsed = _elapsed;
    if (elapsed == null) {
      return ByteConverter(0);
    }
    final seconds = elapsed.inMicroseconds / 1e6;
    final bytes = rate.bytesPerSecond * seconds;
    return _clampToTotal(ByteConverter(bytes));
  }

  Duration get elapsed {
    final existing = _elapsed;
    if (existing != null) return existing;
    final transferred = _transferredBytes;
    if (transferred == null || rate.bitsPerSecond == 0) {
      return Duration.zero;
    }
    final seconds = transferred.bytes / rate.bytesPerSecond;
    return Duration(microseconds: (seconds * 1e6).round());
  }

  double get progressFraction {
    final total = totalBytes.bytes;
    if (total <= 0) return 1;
    return (transferredBytes.bytes / total).clamp(0.0, 1.0);
  }

  double get percentComplete => progressFraction * 100;

  ByteConverter get remainingBytes {
    final remaining = totalBytes.bytes - transferredBytes.bytes;
    return remaining <= 0 ? ByteConverter(0) : ByteConverter(remaining);
  }

  Duration? get estimatedTotalDuration {
    if (rate.bitsPerSecond == 0) return null;
    final totalSeconds = totalBytes.bytes / rate.bytesPerSecond;
    return Duration(microseconds: (totalSeconds * 1e6).round());
  }

  Duration? get remainingDuration {
    if (rate.bitsPerSecond == 0) return null;
    final remainingSeconds = remainingBytes.bytes / rate.bytesPerSecond;
    return Duration(microseconds: (remainingSeconds * 1e6).ceil());
  }

  String etaString({String pending = 'pending', String done = 'done'}) {
    final remaining = remainingDuration;
    if (remaining == null) return pending;
    if (remaining.inMicroseconds <= 0) return done;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  TransferPlan copyWith({
    ByteConverter? total,
    DataRate? rate,
    ByteConverter? transferred,
    Duration? elapsed,
  }) {
    final plan = TransferPlan(
      totalBytes: total ?? totalBytes,
      rate: rate ?? this.rate,
      transferredBytes: transferred ?? _transferredBytes,
      elapsed: elapsed ?? _elapsed,
    );
    return plan;
  }

  ByteConverter _clampToTotal(ByteConverter value) {
    final max = totalBytes.bytes;
    final bytes = value.bytes;
    if (bytes <= 0) return ByteConverter(0);
    if (bytes >= max) return totalBytes;
    return value;
  }
}

extension ByteConverterTransfer on ByteConverter {
  TransferPlan estimateTransfer(
    DataRate rate, {
    Duration? elapsed,
    ByteConverter? transferredBytes,
  }) {
    return TransferPlan(
      totalBytes: this,
      rate: rate,
      transferredBytes: transferredBytes,
      elapsed: elapsed,
    );
  }
}

extension DataRatePlanning on DataRate {
  ByteConverter transferableBytes(Duration window) {
    final seconds = window.inMicroseconds / 1e6;
    final bytes = bytesPerSecond * seconds;
    return ByteConverter(bytes);
  }
}
