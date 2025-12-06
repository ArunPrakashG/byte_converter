import 'big_byte_converter.dart';
import 'byte_converter_base.dart';
import 'tdigest.dart';

/// Represents a histogram bucket for double-based magnitudes with an optional
/// inclusive [upperBound] and associated [count].
class HistogramBucket {
  /// Creates a bucket with an inclusive [upperBound] and a sample [count].
  const HistogramBucket({required this.count, this.upperBound});

  /// Inclusive upper bound for this bucket (null indicates the catch-all tail).
  final double? upperBound;

  /// Number of samples that fall into this bucket.
  final int count;
}

/// Histogram of [HistogramBucket]s for double-based magnitudes.
class Histogram {
  /// Creates a histogram from an ordered list of [buckets].
  const Histogram(this.buckets);

  /// Buckets in ascending order by [HistogramBucket.upperBound].
  final List<HistogramBucket> buckets;

  /// Total number of samples across all buckets.
  int get totalCount => buckets.fold<int>(0, (sum, bin) => sum + bin.count);
}

/// Statistical utilities over collections of byte-like values.
class ByteStats {
  /// Sum of values treated as bytes.
  static double sum(Iterable<Object?> values) {
    var total = 0.0;
    for (final value in values) {
      total += _toDouble(value);
    }
    return total;
  }

  /// Arithmetic mean of values treated as bytes.
  static double average(Iterable<Object?> values) {
    var count = 0;
    var total = 0.0;
    for (final value in values) {
      total += _toDouble(value);
      count++;
    }
    if (count == 0) {
      throw ArgumentError('Cannot compute average of empty collection');
    }
    return total / count;
  }

  /// Percentile (0..100) using linear interpolation over sorted byte values.
  static double percentile(Iterable<Object?> values, double percentile) {
    if (percentile < 0 || percentile > 100) {
      throw ArgumentError('Percentile must be between 0 and 100 inclusive');
    }
    final sorted = values.map(_toDouble).toList()..sort();
    if (sorted.isEmpty) {
      throw ArgumentError('Cannot compute percentile of empty collection');
    }
    if (sorted.length == 1) {
      return sorted.first;
    }
    final rank = (percentile / 100) * (sorted.length - 1);
    final lowerIndex = rank.floor();
    final upperIndex = rank.ceil();
    if (lowerIndex == upperIndex) {
      return sorted[lowerIndex];
    }
    final lowerValue = sorted[lowerIndex];
    final upperValue = sorted[upperIndex];
    final weight = rank - lowerIndex;
    return lowerValue + (upperValue - lowerValue) * weight;
  }

  /// Builds a histogram with the provided [buckets] as upper bounds.
  /// Builds a histogram of [values] using the provided ascending [buckets]
  /// as inclusive upper bounds. The final bucket is an open-ended tail.
  static Histogram histogram(
    Iterable<Object?> values, {
    required List<double> buckets,
  }) {
    if (buckets.isEmpty) {
      throw ArgumentError('Histogram requires at least one bucket');
    }
    final sortedBounds = buckets.toList()..sort();
    final counts = List<int>.filled(sortedBounds.length + 1, 0);
    for (final value in values) {
      final v = _toDouble(value);
      var placed = false;
      for (var i = 0; i < sortedBounds.length; i++) {
        if (v <= sortedBounds[i]) {
          counts[i]++;
          placed = true;
          break;
        }
      }
      if (!placed) {
        counts[sortedBounds.length]++;
      }
    }
    final bins = <HistogramBucket>[];
    for (var i = 0; i < sortedBounds.length; i++) {
      bins.add(HistogramBucket(upperBound: sortedBounds[i], count: counts[i]));
    }
    bins.add(HistogramBucket(count: counts.last));
    return Histogram(List.unmodifiable(bins));
  }

  static double _toDouble(Object? value) {
    if (value == null) {
      throw ArgumentError('Null value encountered in ByteStats operation');
    }
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is ByteConverter) return value.bytes;
    if (value is BigByteConverter) return value.bytes.toDouble();
    if (value is BigInt) return value.toDouble();
    throw ArgumentError('Unsupported value type ${value.runtimeType}');
  }
}

/// Represents a histogram bucket for [BigInt]-sized magnitudes.
class BigHistogramBucket {
  /// Creates a BigInt bucket with an inclusive [upperBound] and a [count].
  const BigHistogramBucket({required this.count, this.upperBound});

  /// Inclusive upper bound for this bucket (null indicates the catch-all tail).
  final BigInt? upperBound;

  /// Number of samples that fall into this bucket.
  final int count;
}

/// Histogram of [BigHistogramBucket]s for BigInt magnitudes.
class BigHistogram {
  /// Creates a histogram from an ordered list of BigInt [buckets].
  const BigHistogram(this.buckets);

  /// Buckets in ascending order by [BigHistogramBucket.upperBound].
  final List<BigHistogramBucket> buckets;

  /// Total number of samples across all buckets.
  int get totalCount => buckets.fold<int>(0, (sum, bin) => sum + bin.count);
}

/// Statistical utilities operating on very large byte magnitudes using BigInt.
class BigByteStats {
  /// Sum of values treated as bytes, returned as BigInt.
  static BigInt sum(Iterable<Object?> values) {
    var total = BigInt.zero;
    for (final value in values) {
      total += _toBigInt(value);
    }
    return total;
  }

  /// Arithmetic mean (double) of values treated as bytes.
  static double average(Iterable<Object?> values) {
    var count = 0;
    var total = BigInt.zero;
    for (final value in values) {
      total += _toBigInt(value);
      count++;
    }
    if (count == 0) {
      throw ArgumentError('Cannot compute average of empty collection');
    }
    return total.toDouble() / count;
  }

  /// Percentile (0..100) over BigInt magnitudes using weighted approach.
  static double percentile(Iterable<Object?> values, double percentile) {
    if (percentile < 0 || percentile > 100) {
      throw ArgumentError('Percentile must be between 0 and 100 inclusive');
    }
    final sorted = values.map(_toBigInt).toList()..sort();
    if (sorted.isEmpty) {
      throw ArgumentError('Cannot compute percentile of empty collection');
    }
    if (sorted.length == 1) {
      return sorted.first.toDouble();
    }
    // Weighted percentile by byte magnitude: pick the smallest value where
    // cumulative sum >= percentile% of total.
    final total = sorted.fold<BigInt>(BigInt.zero, (a, b) => a + b);
    if (total == BigInt.zero) return 0.0;
    if (percentile <= 0) return sorted.first.toDouble();
    if (percentile >= 100) return sorted.last.toDouble();
    final target = total.toDouble() * (percentile / 100.0);
    var cumulative = 0.0;
    for (final v in sorted) {
      cumulative += v.toDouble();
      if (cumulative >= target) {
        return v.toDouble();
      }
    }
    return sorted.last.toDouble();
  }

  /// Builds a histogram for BigInt magnitudes with [buckets] as upper bounds.
  /// Builds a histogram of [values] using BigInt [buckets] as inclusive
  /// upper bounds. The final bucket is an open-ended tail.
  static BigHistogram histogram(
    Iterable<Object?> values, {
    required List<BigInt> buckets,
  }) {
    if (buckets.isEmpty) {
      throw ArgumentError('Histogram requires at least one bucket');
    }
    final sortedBounds = buckets.toList()..sort();
    final counts = List<int>.filled(sortedBounds.length + 1, 0);
    for (final value in values) {
      final v = _toBigInt(value);
      var placed = false;
      for (var i = 0; i < sortedBounds.length; i++) {
        if (v <= sortedBounds[i]) {
          counts[i]++;
          placed = true;
          break;
        }
      }
      if (!placed) {
        counts[sortedBounds.length]++;
      }
    }
    final bins = <BigHistogramBucket>[];
    for (var i = 0; i < sortedBounds.length; i++) {
      bins.add(
        BigHistogramBucket(upperBound: sortedBounds[i], count: counts[i]),
      );
    }
    bins.add(BigHistogramBucket(count: counts.last));
    return BigHistogram(List.unmodifiable(bins));
  }

  static BigInt _toBigInt(Object? value) {
    if (value == null) {
      throw ArgumentError('Null value encountered in BigByteStats operation');
    }
    if (value is BigInt) return value;
    if (value is int) return BigInt.from(value);
    if (value is ByteConverter) {
      // Use ceil to avoid downward rounding impacting order for percentile tests
      return BigInt.from(value.bytes.ceil());
    }
    if (value is BigByteConverter) return value.bytes;
    if (value is double) {
      if (value.isNaN || value.isInfinite) {
        throw ArgumentError('Cannot convert non-finite double to BigInt');
      }
      return BigInt.from(value);
    }
    if (value is num) {
      return BigInt.from(value.toDouble());
    }
    throw ArgumentError('Unsupported value type ${value.runtimeType}');
  }
}

/// Streaming quantile estimator interface with factory constructors for
/// P² (default) and TDigest implementations.
abstract class StreamingQuantiles {
  /// Creates a P² streaming quantile estimator that maintains approximate
  /// positions for the provided [quantiles] (expressed as 0..1 fractions).
  factory StreamingQuantiles(List<double> quantiles) = _P2Quantiles;

  /// Creates a TDigest-based streaming quantile estimator. Optional
  /// [compression] controls accuracy vs memory usage (higher is more accurate).
  factory StreamingQuantiles.tDigest({int compression}) = _TDigestQuantiles;

  /// Adds a sample value to the estimator. Accepts any byte-like value type
  /// supported by the underlying implementation.
  void add(Object? value);

  /// Returns the estimated value at [percentile], where 0..100 indicates the
  /// desired percentile (for example, 50 for median, 99 for P99).
  double estimate(double percentile);
}

class _P2Quantiles implements StreamingQuantiles {
  _P2Quantiles(List<double> quantiles)
      : assert(quantiles.isNotEmpty),
        _q = quantiles.map((q) => q.clamp(0.0, 1.0)).toList();

  final List<double> _q; // desired quantiles as fractions (0..1)
  bool _init = false;
  final List<_P2Estimator> _estimators = [];
  final List<double> _buffer = [];

  @override
  void add(Object? value) {
    final v = ByteStats._toDouble(value);
    if (!_init) {
      _buffer.add(v);
      if (_buffer.length >= 5) {
        _buffer.sort();
        for (final q in _q) {
          _estimators.add(_P2Estimator.initialize(_buffer, q));
        }
        _init = true;
        _buffer.clear();
      }
      return;
    }
    for (final est in _estimators) {
      est.addSample(v);
    }
  }

  @override
  double estimate(double percentile) {
    if (!_init) {
      if (_buffer.isEmpty) {
        throw StateError('No samples');
      }
      final sorted = _buffer.toList()..sort();
      final p = percentile.clamp(0, 100) / 100.0;
      final rank = p * (sorted.length - 1);
      final lo = rank.floor();
      final hi = rank.ceil();
      if (lo == hi) return sorted[lo];
      return sorted[lo] + (sorted[hi] - sorted[lo]) * (rank - lo);
    }
    final p = percentile.clamp(0, 100) / 100.0;
    _P2Estimator? closest;
    var best = double.infinity;
    for (final est in _estimators) {
      final diff = (est.p - p).abs();
      if (diff < best) {
        best = diff;
        closest = est;
      }
    }
    return closest!.estimate;
  }
}

class _TDigestQuantiles implements StreamingQuantiles {
  _TDigestQuantiles({int compression = 200})
      : _td = TDigest(compression: compression);
  final TDigest _td;

  @override
  void add(Object? value) {
    final v = ByteStats._toDouble(value);
    _td.add(v);
  }

  @override
  double estimate(double percentile) {
    if (_td.count == 0) {
      throw StateError('No samples');
    }
    final q = percentile.clamp(0, 100) / 100.0;
    return _td.quantile(q);
  }
}

class _P2Estimator {
  _P2Estimator(this.p, this.n, this.np, this.q);
  final double p; // desired quantile 0..1
  final List<int> n; // marker positions
  final List<double> np; // desired positions
  final List<double> q; // marker heights

  static _P2Estimator initialize(List<double> sorted, double p) {
    // Use 5 markers, equidistant in initial sample
    final m0 = sorted.first;
    final m1 = sorted[(sorted.length - 1) * 1 ~/ 4];
    final m2 = sorted[(sorted.length - 1) * 2 ~/ 4];
    final m3 = sorted[(sorted.length - 1) * 3 ~/ 4];
    final m4 = sorted.last;
    final q = <double>[m0, m1, m2, m3, m4];
    final n = <int>[0, 1, 2, 3, 4];
    final np = <double>[0.0, p * 2, p * 4, p * 6, p * 8];
    return _P2Estimator(p, n, np, q);
  }

  void addSample(double x) {
    // Find k s.t. q[k] <= x < q[k+1]
    int k;
    if (x < q[0]) {
      q[0] = x;
      k = 0;
    } else if (x >= q[4]) {
      q[4] = x;
      k = 3;
    } else {
      k = 0;
      while (k < 3 && !(q[k] <= x && x < q[k + 1])) {
        k++;
      }
    }
    // increment positions
    for (var i = k + 1; i < 5; i++) {
      n[i]++;
    }
    for (var i = 0; i < 5; i++) {
      np[i] += <double>[0.0, p / 2, p, (1 + p) / 2, 1.0][i];
    }
    // adjust heights
    for (var i = 1; i < 4; i++) {
      final d = np[i] - n[i].toDouble();
      if ((d >= 1 && n[i + 1] - n[i] > 1) ||
          (d <= -1 && n[i - 1] - n[i] < -1)) {
        final di = d.sign;
        final qi = _parabolic(i, di);
        if (q[i - 1] < qi && qi < q[i + 1]) {
          q[i] = qi;
        } else {
          q[i] = _linear(i, di);
        }
        n[i] += di.toInt();
      }
    }
  }

  double get estimate => q[2];

  double _parabolic(int i, double d) {
    final a = d / (n[i + 1] - n[i - 1]).toDouble();
    return q[i] +
        a *
            ((n[i] - n[i - 1] + d) *
                    (q[i + 1] - q[i]) /
                    (n[i + 1] - n[i]).toDouble() +
                (n[i + 1] - n[i] - d) *
                    (q[i] - q[i - 1]) /
                    (n[i] - n[i - 1]).toDouble());
  }

  double _linear(int i, double d) {
    return q[i] +
        d * (q[i + d.toInt()] - q[i]) / (n[i + d.toInt()] - n[i]).toDouble();
  }
}
