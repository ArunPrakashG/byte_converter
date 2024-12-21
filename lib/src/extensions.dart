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
