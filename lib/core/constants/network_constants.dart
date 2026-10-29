import '../../data/ldk/ldk_models.dart';

class NetworkConstants {
  static const String defaultEsploraSignet = 'https://mutinynet.com/api';
  static const String defaultRgsSignet = 'https://rgs.mutinynet.com/snapshot';

  static const String defaultEsploraMainnet = 'https://blockstream.info/api';
  static const String defaultRgsMainnet = 'https://rapidsync.lightningdevkit.org/snapshot';

  static String getEsploraUrl(NetworkType network) {
    switch (network) {
      case NetworkType.mainnet:
        return defaultEsploraMainnet;
      case NetworkType.signet:
      case NetworkType.mutinynet:
      default:
        return defaultEsploraSignet;
    }
  }

  static String? getRgsUrl(NetworkType network) {
    switch (network) {
      case NetworkType.mainnet:
        return defaultRgsMainnet;
      case NetworkType.signet:
      case NetworkType.mutinynet:
        return defaultRgsSignet;
      default:
        return null;
    }
  }
}
