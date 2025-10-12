import 'byte_converter_base.dart';
import 'data_rate.dart';

/// Simple transfer planning model for estimating ETAs and progress.
class TransferPlan {
  /// Creates a new plan for transferring [totalBytes] at a nominal [rate].
  /// Optional [transferredBytes] or [elapsed] allow seeding the current state.
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

  /// Total payload to be transferred.
  final ByteConverter totalBytes;

  /// Nominal transfer rate.
  /// Nominal data rate used for duration estimates.
  final DataRate rate;
  final ByteConverter? _transferredBytes;
  final Duration? _elapsed;
  bool _paused = false;
  double _throttle = 1.0; // 0..1 multiplier

  // Variable schedule support
  final List<RateWindow> _schedule = [];

  /// Bytes transferred so far; either provided or derived from [elapsed].
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

  /// Elapsed time; either provided or derived from [transferredBytes].
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

  /// Progress as a fraction in [0,1].
  double get progressFraction {
    final total = totalBytes.bytes;
    if (total <= 0) return 1;
    return (transferredBytes.bytes / total).clamp(0.0, 1.0);
  }

  /// Progress as percent in [0,100].
  double get percentComplete => progressFraction * 100;

  /// Remaining bytes to transfer (never negative).
  ByteConverter get remainingBytes {
    final remaining = totalBytes.bytes - transferredBytes.bytes;
    return remaining <= 0 ? ByteConverter(0) : ByteConverter(remaining);
  }

  /// Estimated total duration at the effective rate (may be null if paused/zero rate).
  Duration? get estimatedTotalDuration {
    final bps = _effectiveBitsPerSecond();
    if (bps == 0) return null;
    final totalSeconds = (totalBytes.bytes * 8.0) / bps;
    return Duration(microseconds: (totalSeconds * 1e6).round());
  }

  /// Estimated remaining duration (may be null if paused/zero rate).
  Duration? get remainingDuration {
    final bps = _effectiveBitsPerSecond();
    if (bps == 0) return null;
    final remainingSeconds = (remainingBytes.bytes * 8.0) / bps;
    return Duration(microseconds: (remainingSeconds * 1e6).ceil());
  }

  /// Humanized ETA string. Returns [pending] if unknown, [done] if complete.
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

  /// Returns a new plan with selected fields replaced.
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
    plan._schedule.addAll(_schedule);
    plan._paused = _paused;
    plan._throttle = _throttle;
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

/// ByteConverter helpers for transfer planning.
extension ByteConverterTransfer on ByteConverter {
  /// Creates a [TransferPlan] assuming transfer at [rate].
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

/// DataRate helpers for planning.
extension DataRatePlanning on DataRate {
  /// Returns the maximum transferable bytes in the given [window] at this rate.
  ByteConverter transferableBytes(Duration window) {
    final seconds = window.inMicroseconds / 1e6;
    final bytes = bytesPerSecond * seconds;
    return ByteConverter(bytes);
  }
}

/// Represents a window of rate over a time span, for planning variable schedules.
class RateWindow {
  /// A window of [rate] sustained for [duration].
  RateWindow({required this.rate, required this.duration});

  /// Data rate for this window.
  final DataRate rate;

  /// Duration for which [rate] applies. Must be positive.
  final Duration duration; // duration > 0
}

/// Advanced controls: schedules, pause/resume, and throttling.
extension TransferPlanAdvanced on TransferPlan {
  /// Adds a [RateWindow] to the schedule used to compute effective rate.
  void addRateWindow(RateWindow window) {
    if (window.duration <= Duration.zero) {
      throw ArgumentError('RateWindow duration must be positive');
    }
    _schedule.add(window);
  }

  /// Removes all scheduled rate windows.
  void clearSchedule() => _schedule.clear();

  /// Pauses the plan; effective rate becomes zero.
  void pause() => _paused = true;

  /// Resumes the plan after a [pause].
  void resume() => _paused = false;

  /// Applies a multiplicative throttle [factor] in [0,1] to the effective rate.
  void setThrottle(double factor) {
    if (factor.isNaN || factor.isInfinite || factor < 0 || factor > 1) {
      throw ArgumentError('Throttle must be between 0 and 1');
    }
    _throttle = factor;
  }

  double _effectiveBitsPerSecond() {
    if (_paused) return 0.0;
    // If schedule exists, compute weighted average bps across windows, then apply throttle.
    if (_schedule.isNotEmpty) {
      var totalMicros = 0;
      var bits = 0.0;
      for (final w in _schedule) {
        final micros = w.duration.inMicroseconds;
        totalMicros += micros;
        bits += w.rate.bitsPerSecond * (micros / 1e6);
      }
      if (totalMicros == 0) return 0.0;
      final avgBps = bits / (totalMicros / 1e6);
      return avgBps * _throttle;
    }
    return rate.bitsPerSecond * _throttle;
  }
}
