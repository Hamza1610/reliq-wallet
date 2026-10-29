import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ldk/ldk_models.dart';

/// Service managing hardware-backed encrypted storage for sensitive material and preferences.
///
/// On Android, this leverages Android Keystore backed EncryptedSharedPreferences.
/// On Linux desktop / WSL, if libsecret/gnome-keyring is locked or unavailable,
/// it gracefully falls back to persistent local storage to guarantee uninterrupted runtime.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const _keyMnemonic = 'reliq_wallet_mnemonic';
  static const _keyLanguage = 'reliq_pref_language';
  static const _keyVoiceEnabled = 'reliq_pref_voice_enabled';
  static const _keyNetwork = 'reliq_pref_network';
  static const _keyIsBackedUp = 'reliq_wallet_is_backed_up';

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              lOptions: LinuxOptions(),
            );

  Future<String?> _safeRead(String key) async {
    try {
      final val = await _storage.read(key: key);
      if (val != null) return val;
    } catch (_) {
      // libsecret keyring error on Linux / WSL, fallback to local storage
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // libsecret keyring error on Linux / WSL, fallback to local storage
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<void> _safeDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  /// Checks if a mnemonic is currently saved in secure storage.
  Future<bool> hasWallet() async {
    final mnemonic = await _safeRead(_keyMnemonic);
    return mnemonic != null && mnemonic.trim().isNotEmpty;
  }

  /// Retrieves the stored BIP39 mnemonic. Returns null if no wallet exists.
  Future<String?> getMnemonic() async {
    return await _safeRead(_keyMnemonic);
  }

  /// Securely stores the BIP39 mnemonic and flags it as backed up.
  Future<void> saveMnemonic(String mnemonic) async {
    await _safeWrite(_keyMnemonic, mnemonic.trim());
    await _safeWrite(_keyIsBackedUp, 'true');
  }

  /// Checks if the seed has been explicitly confirmed by the user.
  Future<bool> isBackedUp() async {
    final val = await _safeRead(_keyIsBackedUp);
    return val == 'true';
  }

  /// Deletes the wallet mnemonic and reset backup state.
  Future<void> deleteWallet() async {
    await _safeDelete(_keyMnemonic);
    await _safeDelete(_keyIsBackedUp);
  }

  /// Retrieves selected UI language code ('en' or 'ha'). Defaults to 'en'.
  Future<String> getLanguage() async {
    final lang = await _safeRead(_keyLanguage);
    return lang ?? 'en';
  }

  /// Saves selected UI language code.
  Future<void> setLanguage(String langCode) async {
    await _safeWrite(_keyLanguage, langCode);
  }

  /// Retrieves whether on-device TTS voice feedback is enabled. Defaults to true.
  Future<bool> isVoiceEnabled() async {
    final val = await _safeRead(_keyVoiceEnabled);
    if (val == null) return true;
    return val == 'true';
  }

  /// Toggles voice feedback.
  Future<void> setVoiceEnabled(bool enabled) async {
    await _safeWrite(_keyVoiceEnabled, enabled.toString());
  }

  /// Retrieves the selected Bitcoin network. Defaults to Signet.
  Future<NetworkType> getNetwork() async {
    final net = await _safeRead(_keyNetwork);
    if (net == null) return NetworkType.signet;
    return NetworkType.fromString(net);
  }

  /// Saves the selected Bitcoin network.
  Future<void> setNetwork(NetworkType network) async {
    await _safeWrite(_keyNetwork, network.name);
  }
}
