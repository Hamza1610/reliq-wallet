import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'ldk_models.dart';

// Native function typedefs for the LSPS2 inbound liquidity surface
typedef _LspCreateInboundInvoiceNative = Pointer<Utf8> Function(
    Pointer<Void>, Uint64, Pointer<Utf8>, Uint32, Uint64);
typedef _LspCreateInboundInvoiceDart = Pointer<Utf8> Function(
    Pointer<Void>, int, Pointer<Utf8>, int, int);

typedef _LspClaimInboundHtlcNative = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);
typedef _LspClaimInboundHtlcDart = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);

typedef _LspPendingInboundPaymentsNative = Pointer<Utf8> Function(Pointer<Void>);
typedef _LspPendingInboundPaymentsDart = Pointer<Utf8> Function(Pointer<Void>);

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

/// Client for LSPS2-style inbound liquidity operations and background claim handling.
///
/// Phase 3 — Intermittent Connectivity & Push Wake-Up:
/// - Creates BOLT11 invoices backed by provisioned inbound liquidity.
/// - Claims pending inbound HTLCs after wake-up / background settlement.
/// - Lists inbound payments pending claim.
class LspClient {
  late final DynamicLibrary _lib;
  late final _LspCreateInboundInvoiceDart _createInboundInvoice;
  late final _LspClaimInboundHtlcDart _claimInboundHtlc;
  late final _LspPendingInboundPaymentsDart _pendingInboundPayments;
  late final _FreeStringDart _freeString;

  Pointer<Void>? _nodeHandle;

  Pointer<Void>? get nodeHandle => _nodeHandle;
  set nodeHandle(Pointer<Void>? handle) => _nodeHandle = handle;

  LspClient({DynamicLibrary? customLib, Pointer<Void>? nodeHandle}) {
    _lib = customLib ?? _loadLibrary();
    _bindFunctions();
    _nodeHandle = nodeHandle;
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
    _createInboundInvoice = _lib
        .lookupFunction<_LspCreateInboundInvoiceNative, _LspCreateInboundInvoiceDart>(
            'lsp_create_inbound_invoice');
    _claimInboundHtlc = _lib
        .lookupFunction<_LspClaimInboundHtlcNative, _LspClaimInboundHtlcDart>(
            'lsp_claim_inbound_htlc');
    _pendingInboundPayments = _lib
        .lookupFunction<_LspPendingInboundPaymentsNative, _LspPendingInboundPaymentsDart>(
            'lsp_pending_inbound_payments');
    _freeString = _lib
        .lookupFunction<_FreeStringNative, _FreeStringDart>('free_string');
  }

  /// Creates a BOLT11 invoice backed by provisioned inbound liquidity.
  ///
  /// Mirrors `LdkNodeService.createInvoice` but targets the LSPS2 inbound
  /// liquidity surface (`lsp_create_inbound_invoice`).
  String createInboundInvoice({
    required int amountSats,
    String? description,
    int expirySecs = 3600,
    int inboundLiquiditySats = 0,
  }) {
    final nodeHandle = _nodeHandle;
    if (nodeHandle == null) {
      throw StateError('LSP client requires a native node handle');
    }
    final amountMsat = amountSats * 1000;
    final cDesc = (description ?? 'Reliq Payment').toNativeUtf8();
    try {
      final ptr = _createInboundInvoice(
          nodeHandle, amountMsat, cDesc, expirySecs, inboundLiquiditySats);
      if (ptr == nullptr) {
        throw Exception('Failed to create inbound liquidity invoice');
      }
      try {
        final raw = ptr.toDartString();
        if (raw.trim().startsWith('{')) {
          final Map<String, dynamic> data = jsonDecode(raw);
          final inv = data['invoice'] as String?;
          if (inv != null && inv.isNotEmpty) {
            return inv;
          }
        }
        return raw;
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(cDesc);
    }
  }

  /// Creates a BOLT11 invoice with inbound liquidity and returns full metadata details.
  Map<String, dynamic> createInboundInvoiceDetails({
    required int amountSats,
    String? description,
    int expirySecs = 3600,
    int inboundLiquiditySats = 0,
  }) {
    final nodeHandle = _nodeHandle;
    if (nodeHandle == null) {
      throw StateError('LSP client requires a native node handle');
    }
    final amountMsat = amountSats * 1000;
    final cDesc = (description ?? 'Reliq Payment').toNativeUtf8();
    try {
      final ptr = _createInboundInvoice(
          nodeHandle, amountMsat, cDesc, expirySecs, inboundLiquiditySats);
      if (ptr == nullptr) {
        throw Exception('Failed to create inbound liquidity invoice');
      }
      try {
        final raw = ptr.toDartString();
        if (raw.trim().startsWith('{')) {
          return jsonDecode(raw) as Map<String, dynamic>;
        }
        return {
          'status': 'created',
          'invoice': raw,
          'amount_sats': amountSats,
          'inbound_liquidity_sats': inboundLiquiditySats,
        };
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(cDesc);
    }
  }

  /// Claims a pending inbound HTLC via the LSP after wake-up (background settlement).
  Future<bool> claimInboundPayment(String paymentHash) async {
    final nodeHandle = _nodeHandle;
    if (nodeHandle == null) {
      throw StateError('LSP client requires a native node handle');
    }
    final cHash = paymentHash.toNativeUtf8();
    try {
      final ptr = _claimInboundHtlc(nodeHandle, cHash);
      if (ptr == nullptr) {
        return false;
      }
      try {
        final jsonStr = ptr.toDartString();
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        return data['status']?.toString() == 'claimed';
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(cHash);
    }
  }

  /// Returns inbound payments currently pending claim.
  Future<List<PendingInboundPayment>> getPendingInboundPayments() async {
    final nodeHandle = _nodeHandle;
    if (nodeHandle == null) {
      throw StateError('LSP client requires a native node handle');
    }
    final ptr = _pendingInboundPayments(nodeHandle);
    if (ptr == nullptr) {
      return [];
    }
    try {
      final jsonStr = ptr.toDartString();
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) =>
              PendingInboundPayment.fromJson((e as Map<String, dynamic>).cast<String, dynamic>()))
          .toList();
    } finally {
      _freeString(ptr);
    }
  }
}
