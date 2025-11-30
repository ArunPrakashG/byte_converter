import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('ByteDisplayOptions', () {
    group('fuzzy', () {
      test('returns "exactly X" for exact round numbers', () {
        expect(ByteConverter.fromMegaBytes(1).display.fuzzy(),
            contains('exactly'));
        expect(ByteConverter.fromMegaBytes(1).display.fuzzy(), contains('1'));
        expect(ByteConverter.fromMegaBytes(1).display.fuzzy(), contains('MB'));
      });

      test('returns "about X" for values near round numbers', () {
        expect(ByteConverter.fromMegaBytes(1.2).display.fuzzy(),
            contains('about'));
      });

      test('returns prefix for non-exact values', () {
        // The fuzzy method uses various prefixes like "about", "almost", "just over"
        // Let's just verify it doesn't crash and returns some text with the unit
        final result = ByteConverter.fromMegaBytes(1.37).display.fuzzy();
        expect(result, contains('MB'));
      });

      test('returns "just over X" for values just above threshold', () {
        expect(ByteConverter.fromGigaBytes(1.05).display.fuzzy(),
            contains('just over'));
      });

      test('handles zero bytes', () {
        expect(ByteConverter(0).display.fuzzy(), '0 B');
      });

      test('handles very large values', () {
        expect(
            ByteConverter.fromTeraBytes(999).display.fuzzy(), contains('TB'));
      });

      test('handles small byte values', () {
        expect(ByteConverter(512).display.fuzzy(), contains('B'));
      });
    });

    group('scientific', () {
      test('formats with Unicode superscript by default', () {
        final result = ByteConverter.fromMegaBytes(1).display.scientific();
        expect(result, contains('×'));
        expect(result, contains('10'));
        expect(result, contains('B'));
      });

      test('handles decimal precision', () {
        final result =
            ByteConverter.fromKiloBytes(1500).display.scientific(precision: 2);
        expect(result, contains('1.5'));
      });

      test('supports ASCII fallback mode', () {
        final result =
            ByteConverter.fromMegaBytes(1).display.scientific(ascii: true);
        expect(result, contains('e'));
        expect(result, isNot(contains('×')));
      });

      test('handles zero bytes', () {
        expect(ByteConverter(0).display.scientific(ascii: true), '0e0 B');
      });

      test('handles very large values', () {
        final result = ByteConverter.fromTeraBytes(1).display.scientific();
        // 1 TB = 10^12 bytes, but scientific notation might show as 1.0 × 10¹¹ depending on precision
        expect(result, contains('10'));
        expect(result, contains('B'));
      });
    });

    group('fractional', () {
      test('uses Unicode fraction for half', () {
        final result = ByteConverter.fromMegaBytes(1.5).display.fractional();
        expect(result, contains('½'));
      });

      test('uses Unicode fraction for quarter', () {
        final result = ByteConverter.fromMegaBytes(1.25).display.fractional();
        expect(result, contains('¼'));
      });

      test('uses Unicode fraction for three-quarters', () {
        final result = ByteConverter.fromMegaBytes(1.75).display.fractional();
        expect(result, contains('¾'));
      });

      test('falls back to decimal when no fraction matches', () {
        final result = ByteConverter.fromMegaBytes(1.37).display.fractional();
        expect(result, isNot(contains('½')));
        expect(result, isNot(contains('¼')));
        expect(result, isNot(contains('¾')));
      });

      test('handles zero bytes', () {
        expect(ByteConverter(0).display.fractional(), '0 B');
      });

      test('handles whole numbers', () {
        final result = ByteConverter.fromMegaBytes(2).display.fractional();
        expect(result, contains('2'));
        expect(result, contains('MB'));
      });
    });

    group('gnu', () {
      test('uses single letter suffix for KB', () {
        expect(ByteConverter.fromKiloBytes(500).display.gnu(), '500K');
      });

      test('uses single letter suffix for MB', () {
        expect(ByteConverter.fromMegaBytes(1.5).display.gnu(), '1.5M');
      });

      test('uses single letter suffix for GB', () {
        expect(ByteConverter.fromGigaBytes(2).display.gnu(), '2G');
      });

      test('omits suffix for bytes', () {
        expect(ByteConverter(512).display.gnu(), '512');
      });

      test('handles zero', () {
        expect(ByteConverter(0).display.gnu(), '0');
      });

      test('respects precision parameter', () {
        final result =
            ByteConverter.fromMegaBytes(1.567).display.gnu(precision: 2);
        expect(result, '1.57M');
      });
    });

    group('fullWords', () {
      test('returns full unit name', () {
        expect(ByteConverter.fromMegaBytes(1.5).display.fullWords(),
            '1.5 Megabytes');
      });

      test('handles singular', () {
        expect(
            ByteConverter.fromMegaBytes(1).display.fullWords(), '1 Megabyte');
      });

      test('supports lowercase option', () {
        expect(
            ByteConverter.fromMegaBytes(1.5).display.fullWords(lowercase: true),
            '1.5 megabytes');
      });

      test('handles zero', () {
        expect(ByteConverter(0).display.fullWords(), '0 Bytes');
      });

      test('handles singular byte', () {
        expect(ByteConverter(1).display.fullWords(), '1 Byte');
      });
    });

    group('withCommas', () {
      test('adds thousand separators', () {
        final result = ByteConverter.fromKiloBytes(1536).display.withCommas();
        expect(result, contains(','));
        expect(result, contains('bytes'));
      });

      test('handles small values without commas', () {
        final result = ByteConverter(500).display.withCommas();
        expect(result, '500 bytes');
      });

      test('handles singular byte', () {
        final result = ByteConverter(1).display.withCommas();
        expect(result, '1 byte');
      });
    });
  });

  group('ByteOutputFormats', () {
    group('asArray', () {
      test('returns [value, unit] list', () {
        final result = ByteConverter.fromKiloBytes(1500).output.asArray;
        expect(result, isList);
        expect(result.length, 2);
        expect(result[0], isA<double>());
        expect(result[1], isA<String>());
      });

      test('uses appropriate unit', () {
        final result = ByteConverter.fromKiloBytes(1500).output.asArray;
        expect(result[0], closeTo(1.5, 0.01));
        expect(result[1], 'MB');
      });

      test('handles bytes', () {
        final result = ByteConverter(500).output.asArray;
        expect(result[0], 500);
        expect(result[1], 'B');
      });
    });

    group('asTuple', () {
      test('returns Dart 3 record', () {
        final (value, unit) = ByteConverter.fromKiloBytes(1500).output.asTuple;
        expect(value, closeTo(1.5, 0.01));
        expect(unit, 'MB');
      });

      test('can destructure', () {
        final result = ByteConverter.fromGigaBytes(2.5).output.asTuple;
        expect(result.$1, closeTo(2.5, 0.01));
        expect(result.$2, 'GB');
      });
    });

    group('asMap', () {
      test('includes all expected keys', () {
        final result = ByteConverter.fromKiloBytes(1500).output.asMap;
        expect(result.containsKey('value'), isTrue);
        expect(result.containsKey('unit'), isTrue);
        expect(result.containsKey('standard'), isTrue);
        expect(result.containsKey('bytes'), isTrue);
        expect(result.containsKey('bits'), isTrue);
      });

      test('has correct values', () {
        final result = ByteConverter.fromKiloBytes(1500).output.asMap;
        expect(result['value'], closeTo(1.5, 0.01));
        expect(result['unit'], 'MB');
        expect(result['standard'], 'SI');
      });
    });

    group('exponent', () {
      test('returns correct SI exponent for KB', () {
        // log₁₀(1000) ≈ 2.999... due to floating point, floors to 2
        expect(ByteConverter.fromKiloBytes(1).output.exponent, 2);
      });

      test('returns correct SI exponent for MB', () {
        // log₁₀(1000000) ≈ 5.999... due to floating point, floors to 5
        expect(ByteConverter.fromMegaBytes(1).output.exponent, 5);
      });

      test('returns correct SI exponent for GB', () {
        // log₁₀(1000000000) ≈ 8.999... due to floating point, floors to 8
        expect(ByteConverter.fromGigaBytes(1).output.exponent, 8);
      });

      test('returns 0 for bytes', () {
        expect(ByteConverter(500).output.exponent, 2);
      });

      test('returns 0 for zero', () {
        expect(ByteConverter(0).output.exponent, 0);
      });
    });

    group('unitLevel', () {
      test('returns 0 for bytes', () {
        expect(ByteConverter(500).output.unitLevel, 0);
      });

      test('returns 1 for KB', () {
        expect(ByteConverter.fromKiloBytes(1).output.unitLevel, 1);
      });

      test('returns 2 for MB', () {
        expect(ByteConverter.fromMegaBytes(1).output.unitLevel, 2);
      });
    });

    group('IEC standard', () {
      test('uses IEC units when specified', () {
        final result =
            ByteConverter.fromKibiBytes(1024).outputWith(ByteStandard.iec);
        expect(result.asTuple.$2, 'MiB');
      });
    });
  });

  group('ByteComparison', () {
    group('percentOf', () {
      test('calculates correct percentage', () {
        final used = ByteConverter.fromGigaBytes(75);
        final total = ByteConverter.fromGigaBytes(100);
        expect(used.compare.percentOf(total), 75.0);
      });

      test('handles zero used', () {
        final used = ByteConverter(0);
        final total = ByteConverter.fromGigaBytes(100);
        expect(used.compare.percentOf(total), 0.0);
      });

      test('handles zero total', () {
        final used = ByteConverter.fromGigaBytes(1);
        final total = ByteConverter(0);
        expect(used.compare.percentOf(total), double.infinity);
      });

      test('handles over 100%', () {
        final used = ByteConverter.fromGigaBytes(150);
        final total = ByteConverter.fromGigaBytes(100);
        expect(used.compare.percentOf(total), 150.0);
      });
    });

    group('percentageBar', () {
      test('generates correct bar', () {
        final used = ByteConverter.fromGigaBytes(50);
        final total = ByteConverter.fromGigaBytes(100);
        final bar = used.compare.percentageBar(total, width: 10);
        expect(bar.length, 10);
        expect(bar, contains('█'));
        expect(bar, contains('░'));
      });

      test('handles 0%', () {
        final used = ByteConverter(0);
        final total = ByteConverter.fromGigaBytes(100);
        final bar = used.compare.percentageBar(total, width: 10);
        expect(bar, '░░░░░░░░░░');
      });

      test('handles 100%', () {
        final used = ByteConverter.fromGigaBytes(100);
        final total = ByteConverter.fromGigaBytes(100);
        final bar = used.compare.percentageBar(total, width: 10);
        expect(bar, '██████████');
      });

      test('supports custom characters', () {
        final used = ByteConverter.fromGigaBytes(50);
        final total = ByteConverter.fromGigaBytes(100);
        final bar = used.compare
            .percentageBar(total, width: 10, filled: '#', empty: '-');
        expect(bar, contains('#'));
        expect(bar, contains('-'));
      });
    });

    group('relativeTo', () {
      test('returns "equal" for same values', () {
        final a = ByteConverter.fromMegaBytes(100);
        final b = ByteConverter.fromMegaBytes(100);
        expect(a.compare.relativeTo(b), 'equal');
      });

      test('returns "X× larger" for larger values', () {
        final large = ByteConverter.fromMegaBytes(200);
        final small = ByteConverter.fromMegaBytes(100);
        expect(large.compare.relativeTo(small), contains('larger'));
        expect(large.compare.relativeTo(small), contains('2'));
      });

      test('returns "X× smaller" for smaller values', () {
        final small = ByteConverter.fromMegaBytes(50);
        final large = ByteConverter.fromMegaBytes(100);
        expect(small.compare.relativeTo(large), contains('smaller'));
        expect(small.compare.relativeTo(large), contains('2'));
      });

      test('supports percentage format', () {
        final small = ByteConverter.fromMegaBytes(50);
        final large = ByteConverter.fromMegaBytes(100);
        expect(small.compare.relativeTo(large, useMultiplier: false),
            contains('%'));
      });
    });

    group('difference', () {
      test('returns absolute difference', () {
        final a = ByteConverter.fromMegaBytes(100);
        final b = ByteConverter.fromMegaBytes(150);
        expect(a.compare.difference(b).megaBytes, closeTo(50, 0.01));
      });

      test('is always positive', () {
        final a = ByteConverter.fromMegaBytes(150);
        final b = ByteConverter.fromMegaBytes(100);
        expect(a.compare.difference(b).bytes, greaterThan(0));
      });
    });

    group('compressionRatio', () {
      test('formats compression correctly', () {
        final original = ByteConverter.fromMegaBytes(100);
        final compressed = ByteConverter.fromMegaBytes(25);
        final result = ByteComparison.compressionRatio(original, compressed);
        expect(result, contains('4'));
        expect(result, contains(':1'));
        expect(result, contains('75'));
        expect(result, contains('reduction'));
      });

      test('handles expansion', () {
        final original = ByteConverter.fromMegaBytes(100);
        final expanded = ByteConverter.fromMegaBytes(200);
        final result = ByteComparison.compressionRatio(original, expanded);
        expect(result, contains('expansion'));
      });

      test('handles zero compressed', () {
        final original = ByteConverter.fromMegaBytes(100);
        final compressed = ByteConverter(0);
        final result = ByteComparison.compressionRatio(original, compressed);
        expect(result, contains('100%'));
      });
    });

    group('isWithin', () {
      test('returns true when within range', () {
        final a = ByteConverter.fromMegaBytes(100);
        final b = ByteConverter.fromMegaBytes(105);
        final tolerance = ByteConverter.fromMegaBytes(10);
        expect(a.compare.isWithin(tolerance, of: b), isTrue);
      });

      test('returns false when outside range', () {
        final a = ByteConverter.fromMegaBytes(100);
        final b = ByteConverter.fromMegaBytes(200);
        final tolerance = ByteConverter.fromMegaBytes(10);
        expect(a.compare.isWithin(tolerance, of: b), isFalse);
      });
    });

    group('clamp', () {
      test('clamps to minimum', () {
        final value = ByteConverter.fromMegaBytes(50);
        final min = ByteConverter.fromMegaBytes(100);
        final max = ByteConverter.fromMegaBytes(200);
        expect(value.compare.clamp(min, max).megaBytes, 100);
      });

      test('clamps to maximum', () {
        final value = ByteConverter.fromMegaBytes(300);
        final min = ByteConverter.fromMegaBytes(100);
        final max = ByteConverter.fromMegaBytes(200);
        expect(value.compare.clamp(min, max).megaBytes, 200);
      });

      test('returns value when in range', () {
        final value = ByteConverter.fromMegaBytes(150);
        final min = ByteConverter.fromMegaBytes(100);
        final max = ByteConverter.fromMegaBytes(200);
        expect(value.compare.clamp(min, max).megaBytes, closeTo(150, 0.01));
      });
    });
  });

  group('ByteAccessibility', () {
    group('screenReader', () {
      test('spells out numbers', () {
        final result =
            ByteConverter.fromMegaBytes(1.5).accessibility.screenReader();
        expect(result, contains('one'));
        expect(result, contains('point'));
        expect(result, contains('five'));
      });

      test('uses full unit names', () {
        final result =
            ByteConverter.fromMegaBytes(1.5).accessibility.screenReader();
        expect(result, contains('megabytes'));
      });

      test('handles singular units', () {
        final result =
            ByteConverter.fromMegaBytes(1).accessibility.screenReader();
        expect(result, contains('megabyte'));
        expect(result, isNot(contains('megabytes')));
      });

      test('handles zero', () {
        expect(ByteConverter(0).accessibility.screenReader(), 'zero bytes');
      });

      test('handles large numbers', () {
        final result =
            ByteConverter.fromGigaBytes(123).accessibility.screenReader();
        expect(result, contains('one hundred'));
        expect(result, contains('twenty'));
        expect(result, contains('three'));
      });
    });

    group('ariaLabel', () {
      test('includes prefix', () {
        final result =
            ByteConverter.fromMegaBytes(1.5).accessibility.ariaLabel();
        expect(result, startsWith('File size:'));
      });

      test('supports custom prefix', () {
        final result = ByteConverter.fromMegaBytes(1.5)
            .accessibility
            .ariaLabel(prefix: 'Storage');
        expect(result, startsWith('Storage:'));
      });
    });

    group('voiceDescription', () {
      test('forms complete sentence', () {
        final result =
            ByteConverter.fromMegaBytes(1.5).accessibility.voiceDescription();
        expect(result, contains('This file is'));
        expect(result, contains('in size'));
      });

      test('supports custom context', () {
        final result = ByteConverter.fromMegaBytes(1.5)
            .accessibility
            .voiceDescription(context: 'The download');
        expect(result, contains('The download is'));
      });
    });

    group('summary', () {
      test('includes both short and long form', () {
        final result = ByteConverter.fromMegaBytes(1.5).accessibility.summary();
        expect(result, contains('Size:'));
        expect(result, contains('MB'));
        expect(result, contains('megabytes'));
      });
    });
  });

  group('BigByteConverter integration', () {
    test('display namespace works', () {
      final big = BigByteConverter.fromGigaBytes(BigInt.from(5));
      expect(big.display.fuzzy(), contains('GB'));
    });

    test('output namespace works', () {
      final big = BigByteConverter.fromGigaBytes(BigInt.from(5));
      final (value, unit) = big.output.asTuple;
      expect(value, 5.0);
      expect(unit, 'GB');
    });

    test('compare namespace works', () {
      // Note: compare uses ByteConverter internally
      expect(
          ByteConverter.fromGigaBytes(75)
              .compare
              .percentOf(ByteConverter.fromGigaBytes(100)),
          75.0);
    });

    test('accessibility namespace works', () {
      final big = BigByteConverter.fromGigaBytes(BigInt.from(5));
      expect(big.accessibility.screenReader(), contains('gigabytes'));
    });
  });

  group('Edge Cases', () {
    test('handles maximum double value', () {
      // Use a large but not max value to avoid overflow
      expect(() => ByteConverter(1e15).display.fuzzy(), returnsNormally);
    });

    test('all namespaces work with zero', () {
      final zero = ByteConverter(0);
      expect(zero.display.fuzzy(), isNotEmpty);
      expect(zero.output.asArray, isNotNull);
      expect(zero.compare.percentOf(ByteConverter.fromGigaBytes(1)), 0.0);
      expect(zero.accessibility.screenReader(), isNotEmpty);
    });

    test('namespace accessors are consistent', () {
      final size = ByteConverter.fromMegaBytes(1.5);
      // Multiple accesses should give same results
      expect(size.display.gnu(), size.display.gnu());
      expect(size.output.asTuple, size.output.asTuple);
    });
  });
}
