import 'big_byte_converter.dart';
import 'byte_converter_base.dart';

class HistogramBucket {
  const HistogramBucket({required this.count, this.upperBound});

  final double? upperBound;
  final int count;
}

class Histogram {
  const Histogram(this.buckets);

  final List<HistogramBucket> buckets;

  int get totalCount => buckets.fold<int>(0, (sum, bin) => sum + bin.count);
}

class ByteStats {
  static double sum(Iterable<Object?> values) {
    var total = 0.0;
    for (final value in values) {
      total += _toDouble(value);
    }
    return total;
  }

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

class BigHistogramBucket {
  const BigHistogramBucket({required this.count, this.upperBound});

  final BigInt? upperBound;
  final int count;
}

class BigHistogram {
  const BigHistogram(this.buckets);

  final List<BigHistogramBucket> buckets;

  int get totalCount => buckets.fold<int>(0, (sum, bin) => sum + bin.count);
}

class BigByteStats {
  static BigInt sum(Iterable<Object?> values) {
    var total = BigInt.zero;
    for (final value in values) {
      total += _toBigInt(value);
    }
    return total;
  }

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
    final rank = (percentile / 100) * (sorted.length - 1);
    final lowerIndex = rank.floor();
    final upperIndex = rank.ceil();
    if (lowerIndex == upperIndex) {
      return sorted[lowerIndex].toDouble();
    }
    final lowerValue = sorted[lowerIndex].toDouble();
    final upperValue = sorted[upperIndex].toDouble();
    final weight = rank - lowerIndex;
    return lowerValue + (upperValue - lowerValue) * weight;
  }

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
      return BigInt.from(value.bytes.round());
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
