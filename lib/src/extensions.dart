import 'big_byte_converter.dart';
import 'byte_converter_base.dart';

/// Extensions for int to create ByteConverter instances
extension IntByteConverterExtension on int {
  // Basic units
  ByteConverter get bytes => ByteConverter(toDouble());
  ByteConverter get bits => ByteConverter.withBits(this);

  // Decimal units
  ByteConverter get kiloBytes => ByteConverter.fromKiloBytes(toDouble());
  ByteConverter get megaBytes => ByteConverter.fromMegaBytes(toDouble());
  ByteConverter get gigaBytes => ByteConverter.fromGigaBytes(toDouble());
  ByteConverter get teraBytes => ByteConverter.fromTeraBytes(toDouble());
  ByteConverter get petaBytes => ByteConverter.fromPetaBytes(toDouble());

  // Binary units
  ByteConverter get kibiBytes => ByteConverter.fromKibiBytes(toDouble());
  ByteConverter get mebiBytes => ByteConverter.fromMebiBytes(toDouble());
  ByteConverter get gibiBytes => ByteConverter.fromGibiBytes(toDouble());
  ByteConverter get tebiBytes => ByteConverter.fromTebiBytes(toDouble());
  ByteConverter get pebiBytes => ByteConverter.fromPebiBytes(toDouble());
}

/// Extensions for double to create ByteConverter instances
extension DoubleByteConverterExtension on double {
  // Basic units
  ByteConverter get bytes => ByteConverter(this);
  ByteConverter get bits => ByteConverter.withBits(toInt());

  // Decimal units
  ByteConverter get kiloBytes => ByteConverter.fromKiloBytes(this);
  ByteConverter get megaBytes => ByteConverter.fromMegaBytes(this);
  ByteConverter get gigaBytes => ByteConverter.fromGigaBytes(this);
  ByteConverter get teraBytes => ByteConverter.fromTeraBytes(this);
  ByteConverter get petaBytes => ByteConverter.fromPetaBytes(this);

  // Binary units
  ByteConverter get kibiBytes => ByteConverter.fromKibiBytes(this);
  ByteConverter get mebiBytes => ByteConverter.fromMebiBytes(this);
  ByteConverter get gibiBytes => ByteConverter.fromGibiBytes(this);
  ByteConverter get tebiBytes => ByteConverter.fromTebiBytes(this);
  ByteConverter get pebiBytes => ByteConverter.fromPebiBytes(this);
}

/// Extensions for BigInt to create BigByteConverter instances
extension BigIntByteConverterExtension on BigInt {
  // Basic units
  BigByteConverter get bytes => BigByteConverter(this);
  BigByteConverter get bits => BigByteConverter.withBits(this);

  // Decimal units
  BigByteConverter get kiloBytes => BigByteConverter.fromKiloBytes(this);
  BigByteConverter get megaBytes => BigByteConverter.fromMegaBytes(this);
  BigByteConverter get gigaBytes => BigByteConverter.fromGigaBytes(this);
  BigByteConverter get teraBytes => BigByteConverter.fromTeraBytes(this);
  BigByteConverter get petaBytes => BigByteConverter.fromPetaBytes(this);
  BigByteConverter get exaBytes => BigByteConverter.fromExaBytes(this);
  BigByteConverter get zettaBytes => BigByteConverter.fromZettaBytes(this);
  BigByteConverter get yottaBytes => BigByteConverter.fromYottaBytes(this);

  // Binary units
  BigByteConverter get kibiBytes => BigByteConverter.fromKibiBytes(this);
  BigByteConverter get mebiBytes => BigByteConverter.fromMebiBytes(this);
  BigByteConverter get gibiBytes => BigByteConverter.fromGibiBytes(this);
  BigByteConverter get tebiBytes => BigByteConverter.fromTebiBytes(this);
  BigByteConverter get pebiBytes => BigByteConverter.fromPebiBytes(this);
  BigByteConverter get exbiBytes => BigByteConverter.fromExbiBytes(this);
  BigByteConverter get zebiBytes => BigByteConverter.fromZebiBytes(this);
  BigByteConverter get yobiBytes => BigByteConverter.fromYobiBytes(this);
}
