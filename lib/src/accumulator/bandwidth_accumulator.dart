import '../byte_converter_base.dart';
import '../data_rate.dart';

/// Accumulates byte values over time for streaming scenarios.
///
/// Useful for tracking bandwidth usage, download progress, and network monitoring.
///
/// Example:
/// ```dart
/// final accumulator = BandwidthAccumulator();
///
/// accumulator.add(ByteConverter.fromKB(100));
/// accumulator.add(ByteConverter.fromKB(250));
///
/// print(accumulator.total);    // ByteConverter representing 350 KB
/// print(accumulator.average);  // ByteConverter representing 175 KB
/// print(accumulator.peak);     // ByteConverter representing 250 KB
/// print(accumulator.count);    // 2
/// ```
class BandwidthAccumulator {
  /// Creates a new bandwidth accumulator.
  ///
  /// If [trackTimestamps] is true, timestamps are recorded for rate calculations.
  BandwidthAccumulator({this.trackTimestamps = false});

  /// Whether to track timestamps for rate calculations.
  final bool trackTimestamps;

  final List<ByteConverter> _samples = [];
  final List<DateTime> _timestamps = [];
  DateTime? _startTime;

  /// Adds a byte sample to the accumulator.
  ///
  /// If [trackTimestamps] is enabled, the current time is recorded.
  void add(ByteConverter sample) {
    _startTime ??= DateTime.now();
    _samples.add(sample);
    if (trackTimestamps) {
      _timestamps.add(DateTime.now());
    }
  }

  /// Adds a byte sample with a specific timestamp.
  void addAt(ByteConverter sample, DateTime timestamp) {
    _startTime ??= timestamp;
    _samples.add(sample);
    _timestamps.add(timestamp);
  }

  /// Total accumulated bytes.
  ByteConverter get total {
    if (_samples.isEmpty) return ByteConverter(0);
    return _samples.reduce((a, b) => a + b);
  }

  /// Average bytes per sample.
  ByteConverter get average {
    if (_samples.isEmpty) return ByteConverter(0);
    return ByteConverter(total.bytes / _samples.length);
  }

  /// Peak (maximum) sample value.
  ByteConverter get peak {
    if (_samples.isEmpty) return ByteConverter(0);
    return _samples.reduce((a, b) => a.bytes > b.bytes ? a : b);
  }

  /// Minimum sample value.
  ByteConverter get min {
    if (_samples.isEmpty) return ByteConverter(0);
    return _samples.reduce((a, b) => a.bytes < b.bytes ? a : b);
  }

  /// Number of samples collected.
  int get count => _samples.length;

  /// Whether any samples have been collected.
  bool get isEmpty => _samples.isEmpty;

  /// Whether samples have been collected.
  bool get isNotEmpty => _samples.isNotEmpty;

  /// All collected samples.
  List<ByteConverter> get samples => List.unmodifiable(_samples);

  /// Duration since the first sample was added.
  Duration get elapsed {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }

  /// Calculates the data rate based on total bytes and elapsed time.
  ///
  /// Returns null if no samples or no elapsed time.
  DataRate? get rate {
    if (_samples.isEmpty || _startTime == null) return null;
    final elapsedSeconds = elapsed.inMicroseconds / 1000000;
    if (elapsedSeconds <= 0) return null;
    final bytesPerSecond = total.bytes / elapsedSeconds;
    return DataRate.bytesPerSecond(bytesPerSecond);
  }

  /// Calculates the average rate between consecutive samples.
  ///
  /// Requires [trackTimestamps] to be enabled.
  DataRate? get averageRate {
    if (_timestamps.length < 2) return null;

    double totalBytesPerSecond = 0;
    int intervals = 0;

    for (var i = 1; i < _samples.length; i++) {
      final duration = _timestamps[i].difference(_timestamps[i - 1]);
      if (duration.inMicroseconds > 0) {
        final bytesPerSecond =
            _samples[i].bytes / (duration.inMicroseconds / 1000000);
        totalBytesPerSecond += bytesPerSecond;
        intervals++;
      }
    }

    if (intervals == 0) return null;
    return DataRate.bytesPerSecond(totalBytesPerSecond / intervals);
  }

  /// Gets the last N samples.
  List<ByteConverter> lastSamples(int n) {
    if (n >= _samples.length) return List.unmodifiable(_samples);
    return List.unmodifiable(_samples.sublist(_samples.length - n));
  }

  /// Calculates a moving average over the last [windowSize] samples.
  ByteConverter movingAverage(int windowSize) {
    if (_samples.isEmpty) return ByteConverter(0);
    final window = lastSamples(windowSize);
    final sum = window.reduce((a, b) => a + b);
    return ByteConverter(sum.bytes / window.length);
  }

  /// Resets the accumulator, clearing all samples.
  void reset() {
    _samples.clear();
    _timestamps.clear();
    _startTime = null;
  }

  /// Standard deviation of sample values.
  double get standardDeviation {
    if (_samples.length < 2) return 0;
    final avg = average.bytes;
    final sumSquaredDiff = _samples
        .map((s) => (s.bytes - avg) * (s.bytes - avg))
        .reduce((a, b) => a + b);
    return _sqrt(sumSquaredDiff / (_samples.length - 1));
  }

  /// Variance of sample values.
  double get variance {
    if (_samples.length < 2) return 0;
    final avg = average.bytes;
    final sumSquaredDiff = _samples
        .map((s) => (s.bytes - avg) * (s.bytes - avg))
        .reduce((a, b) => a + b);
    return sumSquaredDiff / (_samples.length - 1);
  }

  /// Returns a summary map of the accumulator state.
  Map<String, dynamic> toSummary() {
    return {
      'count': count,
      'total': total.bytes,
      'average': average.bytes,
      'peak': peak.bytes,
      'min': min.bytes,
      'elapsedMs': elapsed.inMilliseconds,
      if (rate != null) 'bytesPerSecond': rate!.bytesPerSecond,
    };
  }

  // Simple square root implementation to avoid dart:math import
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (var i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
