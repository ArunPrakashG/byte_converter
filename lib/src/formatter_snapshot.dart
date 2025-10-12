import 'byte_converter_base.dart';
import 'data_rate.dart';
import 'format_options.dart';

enum _SnapshotKind { size, rate }

/// Utility for generating snapshot matrices of formatted byte sizes or data rates.
///
/// Useful for documentation tables, CSV exports, and snapshot tests that
/// assert formatting stability across option combinations.
class FormatterSnapshot {
  /// Builds a snapshot for size samples (in raw bytes as doubles).
  FormatterSnapshot.size({
    required Iterable<double> sizeSamples,
    required Iterable<ByteFormatOptions> options,
    String Function(double sample)? sampleLabeler,
    String Function(ByteFormatOptions option)? optionLabeler,
  })  : _kind = _SnapshotKind.size,
        _sizeSamples = List<double>.from(sizeSamples, growable: false),
        _rateSamples = const [],
        _options = List<ByteFormatOptions>.from(options, growable: false),
        _sizeLabeler = sampleLabeler ?? _defaultSizeLabeler,
        _rateLabeler = _defaultRateLabeler,
        _optionLabeler = optionLabeler ?? _defaultOptionLabeler;

  /// Builds a snapshot for [DataRate] samples.
  FormatterSnapshot.rate({
    required Iterable<DataRate> rateSamples,
    required Iterable<ByteFormatOptions> options,
    String Function(DataRate sample)? sampleLabeler,
    String Function(ByteFormatOptions option)? optionLabeler,
  })  : _kind = _SnapshotKind.rate,
        _sizeSamples = const [],
        _rateSamples = List<DataRate>.from(rateSamples, growable: false),
        _options = List<ByteFormatOptions>.from(options, growable: false),
        _sizeLabeler = _defaultSizeLabeler,
        _rateLabeler = sampleLabeler ?? _defaultRateLabeler,
        _optionLabeler = optionLabeler ?? _defaultOptionLabeler;

  final _SnapshotKind _kind;
  final List<double> _sizeSamples;
  final List<DataRate> _rateSamples;
  final List<ByteFormatOptions> _options;
  final String Function(double sample) _sizeLabeler;
  final String Function(DataRate sample) _rateLabeler;
  final String Function(ByteFormatOptions option) _optionLabeler;

  /// Returns the matrix as an immutable list of rows: [sample, option, formatted].
  List<List<String>> buildMatrix() => List<List<String>>.unmodifiable(_matrix);

  /// Renders the matrix as a Markdown table.
  String toMarkdownTable({bool includeHeader = true}) {
    final rows = _matrix;
    final buffer = StringBuffer();
    if (includeHeader) {
      buffer.writeln('| sample | option | formatted |');
      buffer.writeln('| --- | --- | --- |');
    }
    for (final row in rows) {
      buffer.writeln('| ${row[0]} | ${row[1]} | ${row[2]} |');
    }
    return buffer.toString().trim();
  }

  /// Renders the matrix as CSV text.
  String toCsv({String delimiter = ',', bool includeHeader = true}) {
    final rows = _matrix;
    final buffer = StringBuffer();
    if (includeHeader) {
      buffer.writeln(['sample', 'option', 'formatted'].join(delimiter));
    }
    for (final row in rows) {
      buffer.writeln(row.join(delimiter));
    }
    return buffer.toString().trim();
  }

  List<List<String>> get _matrix => _cachedMatrix ??= _build();
  List<List<String>>? _cachedMatrix;

  List<List<String>> _build() {
    final rows = <List<String>>[];
    switch (_kind) {
      case _SnapshotKind.size:
        for (final sample in _sizeSamples) {
          final formattedSample = _sizeLabeler(sample);
          final converter = ByteConverter(sample);
          for (final option in _options) {
            rows.add([
              formattedSample,
              _optionLabeler(option),
              converter.toHumanReadableAutoWith(option),
            ]);
          }
        }
        break;
      case _SnapshotKind.rate:
        for (final sample in _rateSamples) {
          final formattedSample = _rateLabeler(sample);
          for (final option in _options) {
            rows.add([
              formattedSample,
              _optionLabeler(option),
              sample.toHumanReadableAutoWith(option),
            ]);
          }
        }
        break;
    }
    return List<List<String>>.unmodifiable(rows);
  }

  static String _defaultSizeLabeler(double value) =>
      value % 1 == 0 ? '${value.toInt()} bytes' : '$value bytes';

  static String _defaultRateLabeler(DataRate rate) =>
      '${rate.bitsPerSecond.toStringAsFixed(0)} bps';

  static String _defaultOptionLabeler(ByteFormatOptions option) =>
      option.toString();
}
