import '../byte_converter_base.dart';

/// Named constants for common byte sizes.
///
/// Provides easy access to well-known sizes for media, cloud services,
/// and common file size limits.
///
/// Example:
/// ```dart
/// // Check if file exceeds GitHub's limit
/// if (fileSize > ByteConstants.githubMaxFile) {
///   print('File too large for GitHub!');
/// }
///
/// // Compare to media capacity
/// print('This would fill ${fileSize.bytes / ByteConstants.cd700.bytes} CDs');
/// ```
abstract class ByteConstants {
  ByteConstants._();

  // ============================================
  // Physical Media
  // ============================================

  /// 3.5" High Density Floppy Disk (1.44 MB)
  static final floppy144 = ByteConverter.fromKiloBytes(1440);

  /// 3.5" Double Density Floppy Disk (720 KB)
  static final floppy720 = ByteConverter.fromKiloBytes(720);

  /// Zip Disk 100 MB
  static final zip100 = ByteConverter.fromMegaBytes(100);

  /// Zip Disk 250 MB
  static final zip250 = ByteConverter.fromMegaBytes(250);

  /// CD-ROM (700 MB)
  static final cd700 = ByteConverter.fromMegaBytes(700);

  /// CD-ROM (650 MB, older standard)
  static final cd650 = ByteConverter.fromMegaBytes(650);

  /// DVD Single Layer (4.7 GB)
  static final dvdSingleLayer = ByteConverter.fromGigaBytes(4.7);

  /// DVD Dual Layer (8.5 GB)
  static final dvdDualLayer = ByteConverter.fromGigaBytes(8.5);

  /// Blu-ray Single Layer (25 GB)
  static final bluray25 = ByteConverter.fromGigaBytes(25);

  /// Blu-ray Dual Layer (50 GB)
  static final bluray50 = ByteConverter.fromGigaBytes(50);

  /// Blu-ray Triple Layer (100 GB)
  static final bluray100 = ByteConverter.fromGigaBytes(100);

  /// Blu-ray Quad Layer (128 GB)
  static final bluray128 = ByteConverter.fromGigaBytes(128);

  // ============================================
  // Cloud Service Limits
  // ============================================

  /// GitHub maximum file size (100 MB)
  static final githubMaxFile = ByteConverter.fromMegaBytes(100);

  /// GitHub recommended large file threshold (50 MB)
  static final githubLargeFileWarning = ByteConverter.fromMegaBytes(50);

  /// GitHub repository recommended limit (1 GB)
  static final githubRepoWarning = ByteConverter.fromGigaBytes(1);

  /// npm package maximum size (bundled)
  static final npmMaxPackage = ByteConverter.fromMegaBytes(50);

  /// Docker layer size warning threshold
  static final dockerLayerWarning = ByteConverter.fromMegaBytes(100);

  /// AWS Lambda deployment package limit (50 MB zipped)
  static final awsLambdaZipped = ByteConverter.fromMegaBytes(50);

  /// AWS Lambda deployment package limit (250 MB unzipped)
  static final awsLambdaUnzipped = ByteConverter.fromMegaBytes(250);

  /// Google Cloud Functions limit (100 MB)
  static final gcfLimit = ByteConverter.fromMegaBytes(100);

  /// Azure Functions limit (1.5 GB)
  static final azureFunctionsLimit = ByteConverter.fromGigaBytes(1.5);

  // ============================================
  // Email Attachment Limits
  // ============================================

  /// Gmail attachment limit (25 MB)
  static final gmailAttachment = ByteConverter.fromMegaBytes(25);

  /// Outlook/Office 365 attachment limit (20 MB, may vary)
  static final outlookAttachment = ByteConverter.fromMegaBytes(20);

  /// Yahoo Mail attachment limit (25 MB)
  static final yahooAttachment = ByteConverter.fromMegaBytes(25);

  // ============================================
  // Video/Audio Standards
  // ============================================

  /// Typical 1-minute MP3 at 128 kbps (~1 MB)
  static final mp3PerMinute128 = ByteConverter.fromMegaBytes(1);

  /// Typical 1-minute MP3 at 320 kbps (~2.4 MB)
  static final mp3PerMinute320 = ByteConverter.fromMegaBytes(2.4);

  /// Typical 1-minute FLAC (~25 MB)
  static final flacPerMinute = ByteConverter.fromMegaBytes(25);

  /// Typical 1-minute 1080p video (~150 MB)
  static final video1080pPerMinute = ByteConverter.fromMegaBytes(150);

  /// Typical 1-minute 4K video (~350 MB)
  static final video4kPerMinute = ByteConverter.fromMegaBytes(350);

  // ============================================
  // Memory/Storage Boundaries
  // ============================================

  /// 1 byte
  static final byte = ByteConverter(1);

  /// 1 kilobyte (SI)
  static final kilobyte = ByteConverter.fromKiloBytes(1);

  /// 1 megabyte (SI)
  static final megabyte = ByteConverter.fromMegaBytes(1);

  /// 1 gigabyte (SI)
  static final gigabyte = ByteConverter.fromGigaBytes(1);

  /// 1 terabyte (SI)
  static final terabyte = ByteConverter.fromTeraBytes(1);

  /// 1 petabyte (SI)
  static final petabyte = ByteConverter.fromPetaBytes(1);

  /// 1 kibibyte (IEC, 1024 bytes)
  static final kibibyte = ByteConverter.fromKibiBytes(1);

  /// 1 mebibyte (IEC, 1024² bytes)
  static final mebibyte = ByteConverter.fromMebiBytes(1);

  /// 1 gibibyte (IEC, 1024³ bytes)
  static final gibibyte = ByteConverter.fromGibiBytes(1);

  /// 1 tebibyte (IEC, 1024⁴ bytes)
  static final tebibyte = ByteConverter.fromTebiBytes(1);

  /// 1 pebibyte (IEC, 1024⁵ bytes)
  static final pebibyte = ByteConverter.fromPebiBytes(1);

  // ============================================
  // Common Device Storage
  // ============================================

  /// 32-bit address space limit (4 GB)
  static final addressSpace32bit = ByteConverter.fromGigaBytes(4);

  /// FAT32 maximum file size (4 GB - 1 byte, rounded)
  static final fat32MaxFile = ByteConverter.fromGigaBytes(4);

  /// MBR partition limit (2 TB)
  static final mbrPartitionLimit = ByteConverter.fromTeraBytes(2);

  // ============================================
  // Network
  // ============================================

  /// Typical MTU for Ethernet (1500 bytes)
  static final ethernetMtu = ByteConverter(1500);

  /// Jumbo frame MTU (9000 bytes)
  static final jumboFrameMtu = ByteConverter(9000);

  /// TCP maximum segment size typical (1460 bytes)
  static final tcpMss = ByteConverter(1460);

  // ============================================
  // Helper Methods
  // ============================================

  /// Returns a list of all physical media constants.
  static List<({String name, ByteConverter size})> get physicalMedia => [
        (name: 'Floppy 1.44MB', size: floppy144),
        (name: 'Floppy 720KB', size: floppy720),
        (name: 'Zip 100MB', size: zip100),
        (name: 'Zip 250MB', size: zip250),
        (name: 'CD 650MB', size: cd650),
        (name: 'CD 700MB', size: cd700),
        (name: 'DVD SL', size: dvdSingleLayer),
        (name: 'DVD DL', size: dvdDualLayer),
        (name: 'Blu-ray 25GB', size: bluray25),
        (name: 'Blu-ray 50GB', size: bluray50),
        (name: 'Blu-ray 100GB', size: bluray100),
        (name: 'Blu-ray 128GB', size: bluray128),
      ];

  /// Returns a list of all cloud service limits.
  static List<({String name, ByteConverter size})> get cloudLimits => [
        (name: 'GitHub Max File', size: githubMaxFile),
        (name: 'GitHub Large Warning', size: githubLargeFileWarning),
        (name: 'GitHub Repo Warning', size: githubRepoWarning),
        (name: 'npm Max Package', size: npmMaxPackage),
        (name: 'Docker Layer Warning', size: dockerLayerWarning),
        (name: 'AWS Lambda (zipped)', size: awsLambdaZipped),
        (name: 'AWS Lambda (unzipped)', size: awsLambdaUnzipped),
        (name: 'Google Cloud Functions', size: gcfLimit),
        (name: 'Azure Functions', size: azureFunctionsLimit),
      ];

  /// Returns a list of email attachment limits.
  static List<({String name, ByteConverter size})> get emailLimits => [
        (name: 'Gmail', size: gmailAttachment),
        (name: 'Outlook', size: outlookAttachment),
        (name: 'Yahoo', size: yahooAttachment),
      ];

  /// Finds the closest physical media that can hold the given size.
  static ({String name, ByteConverter size})? closestMediaFor(
      ByteConverter size) {
    final sorted = [...physicalMedia]
      ..sort((a, b) => a.size.bytes.compareTo(b.size.bytes));
    for (final media in sorted) {
      if (media.size.bytes >= size.bytes) {
        return media;
      }
    }
    return null;
  }

  /// Calculates how many of a given media type would be needed.
  static int mediaCountNeeded(ByteConverter size, ByteConverter mediaSize) {
    if (mediaSize.bytes == 0) return 0;
    return (size.bytes / mediaSize.bytes).ceil();
  }
}
