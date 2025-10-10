import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('StorageProfile', () {
    final profile = StorageProfile(
      alignments: const [
        StorageAlignment(name: 'sector', blockSizeBytes: 512),
        StorageAlignment(name: 'block', blockSizeBytes: 4096),
      ],
      defaultAlignment: 'block',
    );

    test('roundToProfile respects rounding mode', () {
      final value = ByteConverter(1500);
      final ceil = value.roundToProfile(
        profile,
        alignment: 'sector',
        rounding: RoundingMode.ceil,
      );
      final floor = value.roundToProfile(
        profile,
        alignment: 'sector',
        rounding: RoundingMode.floor,
      );
      final round = value.roundToProfile(
        profile,
        alignment: 'sector',
        rounding: RoundingMode.round,
      );
      expect(ceil.asBytes(), closeTo(1536, 1e-9));
      expect(floor.asBytes(), closeTo(1024, 1e-9));
      expect(round.asBytes(), closeTo(1536, 1e-9));
    });

    test('alignment slack and isAligned', () {
      final value = ByteConverter(1500);
      final slackDefault = value.alignmentSlack(profile);
      expect(slackDefault.asBytes(), closeTo(4096 - 1500, 1e-9));

      final slackFloor = value.alignmentSlack(
        profile,
        alignment: 'sector',
        rounding: RoundingMode.floor,
      );
      expect(slackFloor.asBytes(), equals(0));

      final aligned = ByteConverter(4096);
      expect(aligned.isAligned(profile), isTrue);
      expect(aligned.isAligned(profile, alignment: 'sector'), isTrue);
    });

    test('BigByteConverter integration', () {
      final bigValue = BigByteConverter(BigInt.from(512 * 1024 + 1));
      final aligned = bigValue.roundToProfile(
        profile,
        alignment: 'sector',
      );
      expect(aligned.isAligned(profile, alignment: 'sector'), isTrue);

      final slack = bigValue.alignmentSlack(
        profile,
        alignment: 'sector',
      );
      expect(slack.asBytes > BigInt.zero, isTrue);
      expect(slack.isAligned(profile, alignment: 'sector'), isTrue);
    });
  });
}
