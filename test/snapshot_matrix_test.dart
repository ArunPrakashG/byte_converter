import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('Snapshot matrix - sizes', () {
    final samples = <double>[0, 512, 1024, 1500, 1536, 10 * 1024 * 1024];
    final configs = <ByteFormatOptions>[
      const ByteFormatOptions(),
      const ByteFormatOptions(useBytes: true, precision: 1),
      const ByteFormatOptions(useBytes: true, fullForm: true),
      const ByteFormatOptions(useBytes: true, separator: ',', spacer: ''),
      const ByteFormatOptions(
        useBytes: true,
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      ),
      const ByteFormatOptions(useBytes: true, signed: true),
      const ByteFormatOptions(useBytes: true, forceUnit: 'KB'),
    ];

    test('ByteConverter snapshots', () {
      final snapshot = FormatterSnapshot.size(
        sizeSamples: samples,
        options: configs,
        sampleLabeler: (v) => v.toInt().toString(),
      );
      final matrix = snapshot.buildMatrix();
      expect(matrix.length, samples.length * configs.length);
      expect(
        matrix.any((row) => row[2].contains('KB')),
        isTrue,
      );
      expect(snapshot.toMarkdownTable(),
          contains('| sample | option | formatted |'));
    });
  });

  group('Snapshot matrix - rates', () {
    final samples = <DataRate>[
      const DataRate.bitsPerSecond(0),
      const DataRate.bitsPerSecond(800),
      DataRate.kiloBitsPerSecond(1.5),
      DataRate.megaBitsPerSecond(100),
      DataRate.megaBytesPerSecond(12.5),
    ];
    final configs = <ByteFormatOptions>[
      const ByteFormatOptions(),
      const ByteFormatOptions(precision: 1),
      const ByteFormatOptions(separator: ',', spacer: ''),
      const ByteFormatOptions(
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      ),
      const ByteFormatOptions(signed: true),
      const ByteFormatOptions(forceUnit: 'Mb'),
    ];

    test('DataRate snapshots', () {
      final snapshot = FormatterSnapshot.rate(
        rateSamples: samples,
        options: configs,
        sampleLabeler: (rate) => '${rate.bitsPerSecond.toInt()} bps',
      );
      final matrix = snapshot.buildMatrix();
      expect(matrix.length, samples.length * configs.length);
      expect(
        matrix.any((row) => row[2].contains('/s')),
        isTrue,
      );
      expect(snapshot.toCsv(), contains('sample,option,formatted'));
    });
  });
}
