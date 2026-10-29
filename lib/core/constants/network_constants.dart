import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/ldk/ldk_models.dart';

class NetworkConstants {
  // Regtest defaults (Android emulator uses 10.0.2.2, desktop/Linux uses 127.0.0.1)
  static String get defaultEsploraRegtest {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://127.0.0.1:3000';
  }

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
        return defaultEsploraSignet;
      case NetworkType.regtest:
      default:
        return defaultEsploraRegtest;
    }
  }

  static String? getRgsUrl(NetworkType network) {
    switch (network) {
      case NetworkType.mainnet:
        return defaultRgsMainnet;
      case NetworkType.signet:
      case NetworkType.mutinynet:
        return defaultRgsSignet;
      case NetworkType.regtest:
      default:
        return null;
    }
  }
}
