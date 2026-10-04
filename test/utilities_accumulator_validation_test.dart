import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('BandwidthAccumulator', () {
    group('basic operations', () {
      test('starts empty', () {
        final acc = BandwidthAccumulator();
        expect(acc.isEmpty, isTrue);
        expect(acc.count, 0);
        expect(acc.total.bytes, 0);
      });

      test('adds samples', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));
        acc.add(ByteConverter.fromKiloBytes(200));

        expect(acc.count, 2);
        expect(acc.isNotEmpty, isTrue);
      });

      test('calculates total', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));
        acc.add(ByteConverter.fromKiloBytes(200));
        acc.add(ByteConverter.fromKiloBytes(50));

        expect(acc.total.kiloBytes, closeTo(350, 0.01));
      });

      test('calculates average', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));
        acc.add(ByteConverter.fromKiloBytes(200));
        acc.add(ByteConverter.fromKiloBytes(300));

        expect(acc.average.kiloBytes, closeTo(200, 0.01));
      });

      test('finds peak', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));
        acc.add(ByteConverter.fromKiloBytes(500));
        acc.add(ByteConverter.fromKiloBytes(200));

        expect(acc.peak.kiloBytes, closeTo(500, 0.01));
      });

      test('finds minimum', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));
        acc.add(ByteConverter.fromKiloBytes(500));
        acc.add(ByteConverter.fromKiloBytes(50));

        expect(acc.min.kiloBytes, closeTo(50, 0.01));
      });
    });

    group('reset', () {
      test('clears all data', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));
        acc.add(ByteConverter.fromKiloBytes(200));

        acc.reset();

        expect(acc.isEmpty, isTrue);
        expect(acc.count, 0);
        expect(acc.total.bytes, 0);
      });
    });

    group('lastSamples', () {
      test('returns last N samples', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));
        acc.add(ByteConverter.fromKiloBytes(200));
        acc.add(ByteConverter.fromKiloBytes(300));
        acc.add(ByteConverter.fromKiloBytes(400));

        final last2 = acc.lastSamples(2);
        expect(last2.length, 2);
        expect(last2[0].kiloBytes, closeTo(300, 0.01));
        expect(last2[1].kiloBytes, closeTo(400, 0.01));
      });

      test('returns all samples if N > count', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));
        acc.add(ByteConverter.fromKiloBytes(200));

        final last = acc.lastSamples(10);
        expect(last.length, 2);
      });
    });

    group('movingAverage', () {
      test('calculates moving average over window', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));
        acc.add(ByteConverter.fromKiloBytes(200));
        acc.add(ByteConverter.fromKiloBytes(300));
        acc.add(ByteConverter.fromKiloBytes(400));

        final ma = acc.movingAverage(2);
        expect(ma.kiloBytes, closeTo(350, 0.01)); // (300 + 400) / 2
      });
    });

    group('statistics', () {
      test('calculates variance', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));
        acc.add(ByteConverter.fromKiloBytes(200));
        acc.add(ByteConverter.fromKiloBytes(300));

        expect(acc.variance, greaterThan(0));
      });

      test('calculates standard deviation', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));
        acc.add(ByteConverter.fromKiloBytes(200));
        acc.add(ByteConverter.fromKiloBytes(300));

        expect(acc.standardDeviation, greaterThan(0));
      });

      test('variance is zero for single sample', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));

        expect(acc.variance, 0);
        expect(acc.standardDeviation, 0);
      });
    });

    group('toSummary', () {
      test('returns summary map', () {
        final acc = BandwidthAccumulator();
        acc.add(ByteConverter.fromKiloBytes(100));
        acc.add(ByteConverter.fromKiloBytes(200));

        final summary = acc.toSummary();
        expect(summary['count'], 2);
        expect(summary['total'], isNotNull);
        expect(summary['average'], isNotNull);
        expect(summary['peak'], isNotNull);
        expect(summary['min'], isNotNull);
      });
    });

    group('with timestamps', () {
      test('tracks elapsed time', () async {
        final acc = BandwidthAccumulator(trackTimestamps: true);
        acc.add(ByteConverter.fromKiloBytes(100));
        await Future<void>.delayed(Duration(milliseconds: 10));
        acc.add(ByteConverter.fromKiloBytes(200));

        expect(acc.elapsed.inMilliseconds, greaterThanOrEqualTo(10));
      });

      test('calculates rate', () async {
        final acc = BandwidthAccumulator(trackTimestamps: true);
        acc.add(ByteConverter.fromKiloBytes(100));
        await Future<void>.delayed(Duration(milliseconds: 100));
        acc.add(ByteConverter.fromKiloBytes(200));

        final rate = acc.rate;
        expect(rate, isNotNull);
        expect(rate!.bytesPerSecond, greaterThan(0));
      });
    });
  });

  group('NaturalTimeDelta', () {
    group('natural', () {
      test('less than a second', () {
        final d = Duration(milliseconds: 500);
        expect(d.natural, 'less than a second');
      });

      test('a few seconds', () {
        final d = Duration(seconds: 3);
        expect(d.natural, 'a few seconds');
      });

      test('about N seconds', () {
        final d = Duration(seconds: 45);
        expect(d.natural, contains('seconds'));
      });

      test('about a minute', () {
        final d = Duration(seconds: 65);
        expect(d.natural, 'about a minute');
      });

      test('about N minutes', () {
        final d = Duration(minutes: 15);
        expect(d.natural, 'about 15 minutes');
      });

      test('about an hour', () {
        final d = Duration(minutes: 65);
        expect(d.natural, 'about an hour');
      });

      test('about N hours', () {
        final d = Duration(hours: 5);
        expect(d.natural, 'about 5 hours');
      });

      test('about a day', () {
        final d = Duration(hours: 30);
        expect(d.natural, 'about a day');
      });

      test('about N days', () {
        final d = Duration(days: 5);
        expect(d.natural, 'about 5 days');
      });
    });

    group('precise', () {
      test('returns precise format', () {
        final d = Duration(hours: 2, minutes: 30, seconds: 15);
        expect(d.naturalPrecise, contains('hour'));
        expect(d.naturalPrecise, contains('minute'));
      });

      test('handles single unit', () {
        final d = Duration(minutes: 5);
        expect(d.naturalPrecise, '5 minutes');
      });

      test('handles two units', () {
        final d = Duration(hours: 1, minutes: 30);
        expect(d.naturalPrecise, '1 hour and 30 minutes');
      });
    });

    group('short', () {
      test('returns short format', () {
        final d = Duration(hours: 2, minutes: 30);
        expect(d.naturalShort, '2h 30m');
      });

      test('handles seconds', () {
        final d = Duration(seconds: 45);
        expect(d.naturalShort, '45s');
      });

      test('handles days', () {
        final d = Duration(days: 2, hours: 5);
        expect(d.naturalShort, '2d 5h');
      });

      test('handles sub-second', () {
        final d = Duration(milliseconds: 500);
        expect(d.naturalShort, '< 1s');
      });
    });

    group('countdown', () {
      test('formats as countdown', () {
        final d = Duration(minutes: 2, seconds: 30);
        expect(d.countdown, '2:30');
      });

      test('includes hours when present', () {
        final d = Duration(hours: 1, minutes: 5, seconds: 30);
        expect(d.countdown, '1:05:30');
      });

      test('pads with zeros', () {
        final d = Duration(minutes: 5, seconds: 5);
        expect(d.countdown, '5:05');
      });
    });
  });

  group('ByteConstants', () {
    group('physical media', () {
      test('floppy disk values', () {
        expect(ByteConstants.floppy144.kiloBytes, closeTo(1440, 0.01));
        expect(ByteConstants.floppy720.kiloBytes, closeTo(720, 0.01));
      });

      test('CD values', () {
        expect(ByteConstants.cd700.megaBytes, closeTo(700, 0.01));
        expect(ByteConstants.cd650.megaBytes, closeTo(650, 0.01));
      });

      test('DVD values', () {
        expect(ByteConstants.dvdSingleLayer.gigaBytes, closeTo(4.7, 0.01));
        expect(ByteConstants.dvdDualLayer.gigaBytes, closeTo(8.5, 0.01));
      });

      test('Blu-ray values', () {
        expect(ByteConstants.bluray25.gigaBytes, closeTo(25, 0.01));
        expect(ByteConstants.bluray50.gigaBytes, closeTo(50, 0.01));
      });
    });

    group('cloud limits', () {
      test('GitHub limits', () {
        expect(ByteConstants.githubMaxFile.megaBytes, closeTo(100, 0.01));
        expect(
            ByteConstants.githubLargeFileWarning.megaBytes, closeTo(50, 0.01));
      });

      test('email limits', () {
        expect(ByteConstants.gmailAttachment.megaBytes, closeTo(25, 0.01));
        expect(ByteConstants.outlookAttachment.megaBytes, closeTo(20, 0.01));
      });
    });

    group('helper methods', () {
      test('physicalMedia returns list', () {
        expect(ByteConstants.physicalMedia, isNotEmpty);
        expect(ByteConstants.physicalMedia.first.name, isNotEmpty);
      });

      test('cloudLimits returns list', () {
        expect(ByteConstants.cloudLimits, isNotEmpty);
      });

      test('emailLimits returns list', () {
        expect(ByteConstants.emailLimits, isNotEmpty);
      });

      test('closestMediaFor finds appropriate media', () {
        final size = ByteConverter.fromMegaBytes(500);
        final media = ByteConstants.closestMediaFor(size);
        expect(media, isNotNull);
        expect(media!.size.bytes, greaterThanOrEqualTo(size.bytes));
      });

      test('mediaCountNeeded calculates correctly', () {
        final size = ByteConverter.fromMegaBytes(1500);
        final count = ByteConstants.mediaCountNeeded(size, ByteConstants.cd700);
        expect(count, 3); // 1500 / 700 = 2.14, ceil = 3
      });
    });
  });

  group('ByteValidation', () {
    group('isValidFileSize', () {
      test('returns true when size is within limit', () {
        final size = ByteConverter.fromMegaBytes(50);
        final maxSize = ByteConverter.fromMegaBytes(100);
        expect(ByteValidation.isValidFileSize(size, maxSize: maxSize), isTrue);
      });

      test('returns false when size exceeds limit', () {
        final size = ByteConverter.fromMegaBytes(150);
        final maxSize = ByteConverter.fromMegaBytes(100);
        expect(ByteValidation.isValidFileSize(size, maxSize: maxSize), isFalse);
      });

      test('respects minimum size', () {
        final size = ByteConverter.fromKiloBytes(50);
        final maxSize = ByteConverter.fromMegaBytes(100);
        final minSize = ByteConverter.fromKiloBytes(100);
        expect(
          ByteValidation.isValidFileSize(size,
              maxSize: maxSize, minSize: minSize),
          isFalse,
        );
      });
    });

    group('isWithinQuota', () {
      test('returns true when within quota', () {
        final usage = ByteConverter.fromGigaBytes(3);
        final quota = ByteConverter.fromGigaBytes(5);
        expect(ByteValidation.isWithinQuota(usage, quota: quota), isTrue);
      });

      test('returns false when exceeding quota', () {
        final usage = ByteConverter.fromGigaBytes(6);
        final quota = ByteConverter.fromGigaBytes(5);
        expect(ByteValidation.isWithinQuota(usage, quota: quota), isFalse);
      });
    });

    group('isApproachingQuota', () {
      test('returns true when above threshold', () {
        final usage = ByteConverter.fromGigaBytes(4.5);
        final quota = ByteConverter.fromGigaBytes(5);
        expect(
          ByteValidation.isApproachingQuota(usage,
              quota: quota, warningThreshold: 0.8),
          isTrue,
        );
      });

      test('returns false when below threshold', () {
        final usage = ByteConverter.fromGigaBytes(2);
        final quota = ByteConverter.fromGigaBytes(5);
        expect(
          ByteValidation.isApproachingQuota(usage,
              quota: quota, warningThreshold: 0.8),
          isFalse,
        );
      });
    });

    group('quotaUsedPercent', () {
      test('calculates percentage correctly', () {
        final usage = ByteConverter.fromGigaBytes(25);
        final quota = ByteConverter.fromGigaBytes(100);
        expect(ByteValidation.quotaUsedPercent(usage, quota: quota), 25.0);
      });
    });

    group('assertions', () {
      test('assertPositive throws for zero', () {
        final size = ByteConverter(0);
        expect(() => ByteValidation.assertPositive(size), throwsArgumentError);
      });

      test('assertPositive passes for positive', () {
        final size = ByteConverter(1);
        expect(() => ByteValidation.assertPositive(size), returnsNormally);
      });

      test('assertMaxSize throws when exceeded', () {
        final size = ByteConverter.fromMegaBytes(150);
        final maxSize = ByteConverter.fromMegaBytes(100);
        expect(
          () => ByteValidation.assertMaxSize(size, maxSize: maxSize),
          throwsArgumentError,
        );
      });

      test('assertInRange throws when outside range', () {
        final size = ByteConverter.fromMegaBytes(50);
        final min = ByteConverter.fromMegaBytes(100);
        final max = ByteConverter.fromMegaBytes(200);
        expect(
          () => ByteValidation.assertInRange(size, min: min, max: max),
          throwsArgumentError,
        );
      });
    });

    group('validate', () {
      test('returns valid result for valid size', () {
        final size = ByteConverter.fromMegaBytes(50);
        final result = ByteValidation.validate(
          size,
          maxSize: ByteConverter.fromMegaBytes(100),
        );
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('returns invalid result with errors', () {
        final size = ByteConverter.fromMegaBytes(150);
        final result = ByteValidation.validate(
          size,
          maxSize: ByteConverter.fromMegaBytes(100),
        );
        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.firstError, isNotNull);
      });

      test('throwIfInvalid throws for invalid', () {
        final size = ByteConverter.fromMegaBytes(150);
        final result = ByteValidation.validate(
          size,
          maxSize: ByteConverter.fromMegaBytes(100),
        );
        expect(() => result.throwIfInvalid(), throwsArgumentError);
      });
    });

    group('extension methods', () {
      test('validate extension works', () {
        final size = ByteConverter.fromMegaBytes(50);
        final result = size.validate(maxSize: ByteConverter.fromMegaBytes(100));
        expect(result.isValid, isTrue);
      });

      test('isInRange extension works', () {
        final size = ByteConverter.fromMegaBytes(50);
        expect(
          size.isInRange(
            min: ByteConverter.fromMegaBytes(10),
            max: ByteConverter.fromMegaBytes(100),
          ),
          isTrue,
        );
      });

      test('isWithinQuota extension works', () {
        final size = ByteConverter.fromGigaBytes(3);
        expect(size.isWithinQuota(ByteConverter.fromGigaBytes(5)), isTrue);
      });
    });
  });
}
