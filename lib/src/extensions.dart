import 'big_byte_converter.dart';
import 'byte_converter_base.dart';

/// Extensions for int to create ByteConverter instances.
extension IntByteConverterExtension on int {
  // Basic units
  /// Treats this integer as a number of bytes.
  ByteConverter get bytes => ByteConverter(toDouble());

  /// Treats this integer as a number of bits.
  ByteConverter get bits => ByteConverter.withBits(this);

  // Decimal units
  /// Interprets this integer as kilobytes (SI, 1000^1).
  ByteConverter get kiloBytes => ByteConverter.fromKiloBytes(toDouble());

  /// Interprets this integer as megabytes (SI, 1000^2).
  ByteConverter get megaBytes => ByteConverter.fromMegaBytes(toDouble());

  /// Interprets this integer as gigabytes (SI, 1000^3).
  ByteConverter get gigaBytes => ByteConverter.fromGigaBytes(toDouble());

  /// Interprets this integer as terabytes (SI, 1000^4).
  ByteConverter get teraBytes => ByteConverter.fromTeraBytes(toDouble());

  /// Interprets this integer as petabytes (SI, 1000^5).
  ByteConverter get petaBytes => ByteConverter.fromPetaBytes(toDouble());

  // Binary units
  /// Interprets this integer as kibibytes (IEC, 1024^1).
  ByteConverter get kibiBytes => ByteConverter.fromKibiBytes(toDouble());

  /// Interprets this integer as mebibytes (IEC, 1024^2).
  ByteConverter get mebiBytes => ByteConverter.fromMebiBytes(toDouble());

  /// Interprets this integer as gibibytes (IEC, 1024^3).
  ByteConverter get gibiBytes => ByteConverter.fromGibiBytes(toDouble());

  /// Interprets this integer as tebibytes (IEC, 1024^4).
  ByteConverter get tebiBytes => ByteConverter.fromTebiBytes(toDouble());

  /// Interprets this integer as pebibytes (IEC, 1024^5).
  ByteConverter get pebiBytes => ByteConverter.fromPebiBytes(toDouble());
}

/// Extensions for double to create ByteConverter instances.
extension DoubleByteConverterExtension on double {
  // Basic units
  /// Treats this double as a number of bytes.
  ByteConverter get bytes => ByteConverter(this);

  /// Treats this double as a number of bits (rounded to int).
  ByteConverter get bits => ByteConverter.withBits(toInt());

  // Decimal units
  /// Interprets this double as kilobytes (SI, 1000^1).
  ByteConverter get kiloBytes => ByteConverter.fromKiloBytes(this);

  /// Interprets this double as megabytes (SI, 1000^2).
  ByteConverter get megaBytes => ByteConverter.fromMegaBytes(this);

  /// Interprets this double as gigabytes (SI, 1000^3).
  ByteConverter get gigaBytes => ByteConverter.fromGigaBytes(this);

  /// Interprets this double as terabytes (SI, 1000^4).
  ByteConverter get teraBytes => ByteConverter.fromTeraBytes(this);

  /// Interprets this double as petabytes (SI, 1000^5).
  ByteConverter get petaBytes => ByteConverter.fromPetaBytes(this);

  // Binary units
  /// Interprets this double as kibibytes (IEC, 1024^1).
  ByteConverter get kibiBytes => ByteConverter.fromKibiBytes(this);

  /// Interprets this double as mebibytes (IEC, 1024^2).
  ByteConverter get mebiBytes => ByteConverter.fromMebiBytes(this);

  /// Interprets this double as gibibytes (IEC, 1024^3).
  ByteConverter get gibiBytes => ByteConverter.fromGibiBytes(this);

  /// Interprets this double as tebibytes (IEC, 1024^4).
  ByteConverter get tebiBytes => ByteConverter.fromTebiBytes(this);

  /// Interprets this double as pebibytes (IEC, 1024^5).
  ByteConverter get pebiBytes => ByteConverter.fromPebiBytes(this);
}

/// Extensions for BigInt to create BigByteConverter instances.
extension BigIntByteConverterExtension on BigInt {
  // Basic units
  /// Treats this BigInt as a number of bytes.
  BigByteConverter get bytes => BigByteConverter(this);

  /// Treats this BigInt as a number of bits.
  BigByteConverter get bits => BigByteConverter.withBits(this);

  // Decimal units
  /// Interprets this BigInt as kilobytes (SI, 1000^1).
  BigByteConverter get kiloBytes => BigByteConverter.fromKiloBytes(this);

  /// Interprets this BigInt as megabytes (SI, 1000^2).
  BigByteConverter get megaBytes => BigByteConverter.fromMegaBytes(this);

  /// Interprets this BigInt as gigabytes (SI, 1000^3).
  BigByteConverter get gigaBytes => BigByteConverter.fromGigaBytes(this);

  /// Interprets this BigInt as terabytes (SI, 1000^4).
  BigByteConverter get teraBytes => BigByteConverter.fromTeraBytes(this);

  /// Interprets this BigInt as petabytes (SI, 1000^5).
  BigByteConverter get petaBytes => BigByteConverter.fromPetaBytes(this);

  /// Interprets this BigInt as exabytes (SI, 1000^6).
  BigByteConverter get exaBytes => BigByteConverter.fromExaBytes(this);

  /// Interprets this BigInt as zettabytes (SI, 1000^7).
  BigByteConverter get zettaBytes => BigByteConverter.fromZettaBytes(this);

  /// Interprets this BigInt as yottabytes (SI, 1000^8).
  BigByteConverter get yottaBytes => BigByteConverter.fromYottaBytes(this);

  // Binary units
  /// Interprets this BigInt as kibibytes (IEC, 1024^1).
  BigByteConverter get kibiBytes => BigByteConverter.fromKibiBytes(this);

  /// Interprets this BigInt as mebibytes (IEC, 1024^2).
  BigByteConverter get mebiBytes => BigByteConverter.fromMebiBytes(this);

  /// Interprets this BigInt as gibibytes (IEC, 1024^3).
  BigByteConverter get gibiBytes => BigByteConverter.fromGibiBytes(this);

  /// Interprets this BigInt as tebibytes (IEC, 1024^4).
  BigByteConverter get tebiBytes => BigByteConverter.fromTebiBytes(this);

  /// Interprets this BigInt as pebibytes (IEC, 1024^5).
  BigByteConverter get pebiBytes => BigByteConverter.fromPebiBytes(this);

  /// Interprets this BigInt as exbibytes (IEC, 1024^6).
  BigByteConverter get exbiBytes => BigByteConverter.fromExbiBytes(this);

  /// Interprets this BigInt as zebibytes (IEC, 1024^7).
  BigByteConverter get zebiBytes => BigByteConverter.fromZebiBytes(this);

  /// Interprets this BigInt as yobibytes (IEC, 1024^8).
  BigByteConverter get yobiBytes => BigByteConverter.fromYobiBytes(this);
}
