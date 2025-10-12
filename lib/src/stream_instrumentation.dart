import 'dart:async';

import 'byte_converter_base.dart';
import 'data_rate.dart';

/// Snapshot of a transfer stream's progress.
class StreamProgress {
  /// Creates a progress snapshot for a transfer stream.
  StreamProgress({
    required this.transferred,
    required this.instantaneous,
    required this.average,
    required this.elapsed,
    required this.total,
  });

  /// Total bytes transferred so far.
  final ByteConverter transferred;

  /// Instantaneous data rate over the last sampling window.
  final DataRate instantaneous;

  /// Average data rate since the beginning.
  final DataRate average;

  /// Elapsed time since the start.
  final Duration elapsed;

  /// Optional known total for computing percentage and ETA.
  final ByteConverter? total;

  /// Fractional completion in [0,1], or null if [total] is unknown or zero.
  double? get progressFraction => (total == null || total!.bytes <= 0)
      ? null
      : (transferred.bytes / total!.bytes).clamp(0.0, 1.0);

  /// Estimated time to completion based on [average]. Returns null when the
  /// average rate is zero or [total] is unknown.
  Duration? get eta {
    final avg = average.bitsPerSecond;
    if (avg <= 0 || total == null) return null;
    final remaining = total!.bytes - transferred.bytes;
    if (remaining <= 0) return Duration.zero;
    final seconds = (remaining * 8.0) / avg;
    return Duration(microseconds: (seconds * 1e6).ceil());
  }
}

/// Callback for reporting stream progress samples.
typedef ProgressCallback = void Function(StreamProgress);

/// Wraps a byte stream and periodically reports throughput statistics.
Stream<List<int>> trackBytes(
  Stream<List<int>> source, {
  ProgressCallback? onProgress,
  Duration sample = const Duration(seconds: 1),
  ByteConverter? total,
  bool emitImmediate = true,
}) {
  final controller = StreamController<List<int>>();
  var transferred = 0.0;
  var windowBytes = 0.0;
  final start = DateTime.now();
  Timer? timer;

  void emit() {
    final elapsed = DateTime.now().difference(start);
    final instBps = sample.inMicroseconds > 0
        ? (windowBytes * 8.0) / (sample.inMicroseconds / 1e6)
        : 0.0;
    final avgBps = elapsed.inMicroseconds > 0
        ? (transferred * 8.0) / (elapsed.inMicroseconds / 1e6)
        : 0.0;
    onProgress?.call(StreamProgress(
      transferred: ByteConverter(transferred),
      instantaneous: DataRate.bitsPerSecond(instBps),
      average: DataRate.bitsPerSecond(avgBps),
      elapsed: elapsed,
      total: total,
    ));
    windowBytes = 0.0;
  }

  source.listen((chunk) {
    controller.add(chunk);
    transferred += chunk.length;
    windowBytes += chunk.length;
  }, onDone: () {
    timer?.cancel();
    emit();
    controller.close();
  }, onError: controller.addError, cancelOnError: false);

  if (emitImmediate && onProgress != null) emit();
  timer = Timer.periodic(sample, (_) => emit());
  return controller.stream;
}

/// A transformer that reports byte throughput while passing data through.
class BytesMeter extends StreamTransformerBase<List<int>, List<int>> {
  /// Creates a transformer that samples progress every [sample] interval and
  /// reports via [onProgress]. If [total] is provided, percentage and ETA are
  /// also computed.
  BytesMeter(
      {this.onProgress, this.sample = const Duration(seconds: 1), this.total});

  /// Called when a sample is ready.
  final ProgressCallback? onProgress;

  /// Sampling interval.
  final Duration sample;

  /// Optional known total payload for progress percentage.
  final ByteConverter? total;

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) =>
      trackBytes(stream, onProgress: onProgress, sample: sample, total: total);
}
