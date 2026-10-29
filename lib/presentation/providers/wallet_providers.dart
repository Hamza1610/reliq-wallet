import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/network_constants.dart';
import '../../data/ldk/ldk_models.dart';
import '../../data/ldk/ldk_node_service.dart';
import '../../data/storage/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final ldkNodeServiceProvider = Provider<LdkNodeService>((ref) {
  final service = LdkNodeService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

class WalletState {
  final bool isLoading;
  final bool hasWallet;
  final bool isNodeRunning;
  final WalletBalance balance;
  final NetworkType network;
  final bool isVoiceEnabled;
  final String language;
  final String? errorMessage;

  const WalletState({
    required this.isLoading,
    required this.hasWallet,
    required this.isNodeRunning,
    required this.balance,
    required this.network,
    required this.isVoiceEnabled,
    required this.language,
    this.errorMessage,
  });

  factory WalletState.initial() => const WalletState(
        isLoading: true,
        hasWallet: false,
        isNodeRunning: false,
        balance: WalletBalance.zero,
        network: NetworkType.signet,
        isVoiceEnabled: true,
        language: 'en',
      );

  WalletState copyWith({
    bool? isLoading,
    bool? hasWallet,
    bool? isNodeRunning,
    WalletBalance? balance,
    NetworkType? network,
    bool? isVoiceEnabled,
    String? language,
    String? errorMessage,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      hasWallet: hasWallet ?? this.hasWallet,
      isNodeRunning: isNodeRunning ?? this.isNodeRunning,
      balance: balance ?? this.balance,
      network: network ?? this.network,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
      language: language ?? this.language,
      errorMessage: errorMessage,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final SecureStorageService _storage;
  final LdkNodeService _ldk;

  WalletNotifier(this._storage, this._ldk) : super(WalletState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final hasWallet = await _storage.hasWallet();
      final network = await _storage.getNetwork();
      final voiceEnabled = await _storage.isVoiceEnabled();
      final language = await _storage.getLanguage();

      if (hasWallet) {
        final mnemonic = await _storage.getMnemonic();
        if (mnemonic != null) {
          await _startNodeWithMnemonic(mnemonic, network);
        }
      }

      state = state.copyWith(
        isLoading: false,
        hasWallet: hasWallet,
        network: network,
        isVoiceEnabled: voiceEnabled,
        language: language,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize wallet: $e',
      );
    }
  }

  Future<void> _startNodeWithMnemonic(String mnemonic, NetworkType network) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final storageDir = '${docsDir.path}/ldk_${network.name}';
    final dir = Directory(storageDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final config = NodeConfig(
      network: network,
      esploraUrl: NetworkConstants.getEsploraUrl(network),
      rgsUrl: NetworkConstants.getRgsUrl(network),
      storageDir: storageDir,
      mnemonic: mnemonic,
    );

    _ldk.initNode(config);
    await _ldk.startNode();
    final balances = _ldk.getBalances();

    state = state.copyWith(
      isNodeRunning: true,
      balance: balances,
    );
  }

  /// Generates a fresh uncommitted mnemonic for backup flow
  String generateFreshMnemonic({int wordCount = 12}) {
    return _ldk.generateMnemonic(wordCount: wordCount);
  }

  /// Validates a candidate mnemonic
  bool validateMnemonic(String mnemonic) {
    return _ldk.validateMnemonic(mnemonic);
  }

  /// Finalizes wallet creation after user successfully verifies backup words
  Future<void> confirmBackupAndCreateWallet(String mnemonic) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _storage.saveMnemonic(mnemonic);
      await _startNodeWithMnemonic(mnemonic, state.network);
      state = state.copyWith(
        isLoading: false,
        hasWallet: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to start wallet node: $e',
      );
      rethrow;
    }
  }

  /// Restores wallet from a user-provided mnemonic phrase
  Future<void> restoreWallet(String mnemonic) async {
    final trimmed = mnemonic.trim();
    if (!_ldk.validateMnemonic(trimmed)) {
      throw ArgumentError('Invalid BIP39 mnemonic phrase');
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _storage.saveMnemonic(trimmed);
      await _startNodeWithMnemonic(trimmed, state.network);
      state = state.copyWith(
        isLoading: false,
        hasWallet: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to restore wallet: $e',
      );
      rethrow;
    }
  }

  /// Refreshes balances from LDK and BDK
  void refreshBalance() {
    if (_ldk.isInitialized) {
      final balances = _ldk.getBalances();
      state = state.copyWith(balance: balances);
    }
  }

  /// Toggles voice speech synthesis
  Future<void> toggleVoice() async {
    final newVoice = !state.isVoiceEnabled;
    await _storage.setVoiceEnabled(newVoice);
    state = state.copyWith(isVoiceEnabled: newVoice);
  }

  /// Changes UI language
  Future<void> setLanguage(String lang) async {
    await _storage.setLanguage(lang);
    state = state.copyWith(language: lang);
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final ldk = ref.watch(ldkNodeServiceProvider);
  return WalletNotifier(storage, ldk);
});
