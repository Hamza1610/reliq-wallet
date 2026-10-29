import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'ldk_models.dart';

// Native function typedefs
typedef _GenerateMnemonicNative = Pointer<Utf8> Function(Uint32);
typedef _GenerateMnemonicDart = Pointer<Utf8> Function(int);

typedef _ValidateMnemonicNative = Bool Function(Pointer<Utf8>);
typedef _ValidateMnemonicDart = bool Function(Pointer<Utf8>);

typedef _NodeNewNative = Pointer<Void> Function(Pointer<Utf8>);
typedef _NodeNewDart = Pointer<Void> Function(Pointer<Utf8>);

typedef _NodeStartNative = Int32 Function(Pointer<Void>);
typedef _NodeStartDart = int Function(Pointer<Void>);

typedef _NodeStopNative = Int32 Function(Pointer<Void>);
typedef _NodeStopDart = int Function(Pointer<Void>);

typedef _BalanceNative = Uint64 Function(Pointer<Void>);
typedef _BalanceDart = int Function(Pointer<Void>);

typedef _NewAddressNative = Pointer<Utf8> Function(Pointer<Void>);
typedef _NewAddressDart = Pointer<Utf8> Function(Pointer<Void>);

typedef _ReceivePaymentNative = Pointer<Utf8> Function(
    Pointer<Void>, Uint64, Pointer<Utf8>, Uint32);
typedef _ReceivePaymentDart = Pointer<Utf8> Function(
    Pointer<Void>, int, Pointer<Utf8>, int);

typedef _SendPaymentNative = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);
typedef _SendPaymentDart = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);

typedef _DecodePaymentNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _DecodePaymentDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef _NodeFreeNative = Void Function(Pointer<Void>);
typedef _NodeFreeDart = void Function(Pointer<Void>);

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

/// Service managing the native Rust Lightning (LDK) and On-Chain (BDK) engine.
class LdkNodeService {
  late final DynamicLibrary _lib;

  late final _GenerateMnemonicDart _generateMnemonic;
  late final _ValidateMnemonicDart _validateMnemonic;
  late final _NodeNewDart _nodeNew;
  late final _NodeStartDart _nodeStart;
  late final _NodeStopDart _nodeStop;
  late final _BalanceDart _spendableLightningBalance;
  late final _BalanceDart _totalOnchainBalance;
  late final _NewAddressDart _newOnchainAddress;
  late final _ReceivePaymentDart _receivePayment;
  late final _SendPaymentDart _sendPayment;
  late final _DecodePaymentDart _decodePaymentRequest;
  late final _NodeFreeDart _nodeFree;
  late final _FreeStringDart _freeString;

  Pointer<Void>? _nodeHandle;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  bool get isInitialized => _nodeHandle != null && _nodeHandle != nullptr;

  LdkNodeService({DynamicLibrary? customLib}) {
    _lib = customLib ?? _loadLibrary();
    _bindFunctions();
  }

  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libreliq_native.so');
    } else if (Platform.isLinux) {
      // Look in standard development locations
      final searchPaths = [
        '${File(Platform.resolvedExecutable).parent.path}/lib/libreliq_native.so',
        'libreliq_native.so',
        './native/lib/libreliq_native.so',
        '../native/lib/libreliq_native.so',
        '/home/maheer-wsl/.cargo-target/reliq/release/libreliq_native.so',
      ];
      for (final path in searchPaths) {
        if (File(path).existsSync()) {
          return DynamicLibrary.open(path);
        }
      }
      return DynamicLibrary.process();
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('reliq_native.dll');
    }
    return DynamicLibrary.process();
  }

  void _bindFunctions() {
    _generateMnemonic = _lib
        .lookupFunction<_GenerateMnemonicNative, _GenerateMnemonicDart>(
            'generate_entropy_mnemonic');
    _validateMnemonic = _lib
        .lookupFunction<_ValidateMnemonicNative, _ValidateMnemonicDart>(
            'validate_mnemonic');
    _nodeNew = _lib
        .lookupFunction<_NodeNewNative, _NodeNewDart>('node_new');
    _nodeStart = _lib
        .lookupFunction<_NodeStartNative, _NodeStartDart>('node_start');
    _nodeStop = _lib
        .lookupFunction<_NodeStopNative, _NodeStopDart>('node_stop');
    _spendableLightningBalance = _lib
        .lookupFunction<_BalanceNative, _BalanceDart>(
            'spendable_lightning_balance_sats');
    _totalOnchainBalance = _lib
        .lookupFunction<_BalanceNative, _BalanceDart>(
            'total_onchain_balance_sats');
    _newOnchainAddress = _lib
        .lookupFunction<_NewAddressNative, _NewAddressDart>(
            'new_onchain_address');
    _receivePayment = _lib
        .lookupFunction<_ReceivePaymentNative, _ReceivePaymentDart>(
            'receive_payment');
    _sendPayment = _lib
        .lookupFunction<_SendPaymentNative, _SendPaymentDart>(
            'send_payment');
    _decodePaymentRequest = _lib
        .lookupFunction<_DecodePaymentNative, _DecodePaymentDart>(
            'decode_payment_request');
    _nodeFree = _lib
        .lookupFunction<_NodeFreeNative, _NodeFreeDart>('node_free');
    _freeString = _lib
        .lookupFunction<_FreeStringNative, _FreeStringDart>('free_string');
  }

  /// Generates a fresh BIP39 mnemonic (12 or 24 words).
  String generateMnemonic({int wordCount = 12}) {
    final ptr = _generateMnemonic(wordCount);
    if (ptr == nullptr) {
      throw Exception('Failed to generate mnemonic from native entropy');
    }
    try {
      return ptr.toDartString();
    } finally {
      _freeString(ptr);
    }
  }

  /// Validates a BIP39 mnemonic phrase.
  bool validateMnemonic(String mnemonic) {
    final ptr = mnemonic.toNativeUtf8();
    try {
      return _validateMnemonic(ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  /// Initializes the LDK & BDK Node with the given configuration.
  void initNode(NodeConfig config) {
    if (isInitialized) {
      stopNode();
    }

    final jsonStr = config.toJsonString();
    final cJson = jsonStr.toNativeUtf8();
    try {
      final handle = _nodeNew(cJson);
      if (handle == nullptr) {
        throw Exception('Failed to instantiate native node from configuration');
      }
      _nodeHandle = handle;
    } finally {
      calloc.free(cJson);
    }
  }

  /// Starts the Lightning node and sync processes.
  Future<void> startNode() async {
    if (!isInitialized) {
      throw StateError('Cannot start node: Node is not initialized');
    }
    final code = _nodeStart(_nodeHandle!);
    if (code != 0) {
      throw Exception('Native node_start returned error code $code');
    }
    _isRunning = true;
  }

  /// Gracefully stops the Lightning node.
  Future<void> stopNode() async {
    if (!isInitialized || !_isRunning) return;
    _nodeStop(_nodeHandle!);
    _isRunning = false;
  }

  /// Queries the current Lightning and BDK On-Chain balances in satoshis.
  WalletBalance getBalances() {
    if (!isInitialized) return WalletBalance.zero;
    final lightning = _spendableLightningBalance(_nodeHandle!);
    final onchain = _totalOnchainBalance(_nodeHandle!);
    return WalletBalance(
      lightningSats: lightning,
      onchainSats: onchain,
    );
  }

  /// Generates a fresh Native SegWit on-chain address via BDK.
  String getNewOnchainAddress() {
    if (!isInitialized) throw StateError('Node not initialized');
    final ptr = _newOnchainAddress(_nodeHandle!);
    if (ptr == nullptr) throw Exception('Failed to derive onchain address');
    try {
      return ptr.toDartString();
    } finally {
      _freeString(ptr);
    }
  }

  /// Creates a BOLT11 invoice for receiving payment.
  String createInvoice({
    required int amountSats,
    String? description,
    int expirySecs = 3600,
  }) {
    if (!isInitialized) throw StateError('Node not initialized');
    final cDesc = (description ?? 'Reliq Payment').toNativeUtf8();
    final amountMsat = amountSats * 1000;
    try {
      final ptr = _receivePayment(_nodeHandle!, amountMsat, cDesc, expirySecs);
      if (ptr == nullptr) throw Exception('Failed to generate BOLT11 invoice');
      try {
        return ptr.toDartString();
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(cDesc);
    }
  }

  /// Pays a BOLT11 invoice.
  Future<PaymentResult> sendPayment(String invoice) async {
    if (!isInitialized) throw StateError('Node not initialized');
    final cInvoice = invoice.toNativeUtf8();
    try {
      final ptr = _sendPayment(_nodeHandle!, cInvoice);
      if (ptr == nullptr) return PaymentResult.failed('Null native response');
      try {
        final jsonStr = ptr.toDartString();
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        return PaymentResult.fromJson(data);
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(cInvoice);
    }
  }

  /// Decodes and validates a BOLT11 invoice string.
  DecodedInvoice decodeInvoice(String invoice) {
    final cInvoice = invoice.trim().toNativeUtf8();
    try {
      final ptr = _decodePaymentRequest(cInvoice);
      if (ptr == nullptr) return DecodedInvoice.invalid('Null native response');
      try {
        final jsonStr = ptr.toDartString();
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        return DecodedInvoice.fromJson(data);
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(cInvoice);
    }
  }

  /// Frees all native handles and memory.
  void dispose() {
    if (isInitialized) {
      if (_isRunning) {
        _nodeStop(_nodeHandle!);
      }
      _nodeFree(_nodeHandle!);
      _nodeHandle = null;
      _isRunning = false;
    }
  }
}
