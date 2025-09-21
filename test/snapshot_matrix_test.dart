import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

String snap(dynamic v) => v.toString();

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
      final out = <String>[];
      for (final s in samples) {
        final bc = ByteConverter(s);
        for (final cfg in configs) {
          out.add('${s.toInt()}|$cfg|${bc.toHumanReadableAutoWith(cfg)}');
        }
      }
      // Snapshot: deterministic list joined
      expect(out.join('\n'), contains('KB')); // sanity check
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
      final out = <String>[];
      for (final r in samples) {
        for (final cfg in configs) {
          out.add(
            '${r.bitsPerSecond.toInt()}|$cfg|${r.toHumanReadableAutoWith(cfg)}',
          );
        }
      }
      expect(out.join('\n'), contains('/s')); // sanity check
    });
  });
}
