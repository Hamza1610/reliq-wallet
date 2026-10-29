import 'dart:convert';

/// Supported Bitcoin / Lightning network types
enum NetworkType {
  signet,
  mutinynet,
  regtest,
  mainnet;

  String get name => toString().split('.').last;

  static NetworkType fromString(String val) {
    return NetworkType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => NetworkType.regtest,
    );
  }
}

/// Node configuration parameters
class NodeConfig {
  final NetworkType network;
  final String esploraUrl;
  final String? rgsUrl;
  final String storageDir;
  final String? mnemonic;
  final int? listeningPort;

  const NodeConfig({
    required this.network,
    required this.esploraUrl,
    this.rgsUrl,
    required this.storageDir,
    this.mnemonic,
    this.listeningPort,
  });

  Map<String, dynamic> toJson() => {
        'network': network.name,
        'esplora_url': esploraUrl,
        if (rgsUrl != null) 'rgs_url': rgsUrl,
        'storage_dir': storageDir,
        if (mnemonic != null) 'mnemonic': mnemonic,
        if (listeningPort != null) 'listening_port': listeningPort,
      };

  String toJsonString() => jsonEncode(toJson());
}

/// Balance representation combining Layer-2 (Lightning) and Layer-1 (BDK On-Chain)
class WalletBalance {
  final int lightningSats;
  final int onchainSats;

  const WalletBalance({
    required this.lightningSats,
    required this.onchainSats,
  });

  int get totalSats => lightningSats + onchainSats;

  static const zero = WalletBalance(lightningSats: 0, onchainSats: 0);

  @override
  String toString() =>
      'WalletBalance(lightning: $lightningSats sats, onchain: $onchainSats sats, total: $totalSats sats)';
}

/// Result of a payment dispatch
class PaymentResult {
  final String status;
  final String? paymentHash;
  final int? feeSats;
  final String? error;

  const PaymentResult({
    required this.status,
    this.paymentHash,
    this.feeSats,
    this.error,
  });

  bool get isSuccess => status.toLowerCase() == 'succeeded' || status.toLowerCase() == 'pending';

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      status: json['status'] as String? ?? 'unknown',
      paymentHash: json['payment_hash'] as String?,
      feeSats: json['fee_sats'] as int?,
      error: json['error'] as String?,
    );
  }

  factory PaymentResult.failed(String errorMessage) {
    return PaymentResult(status: 'failed', error: errorMessage);
  }
}

/// Decoded representation of a BOLT11 Lightning Invoice
class DecodedInvoice {
  final bool isValid;
  final int amountSats;
  final String description;
  final String? paymentHash;
  final int expirySecs;
  final String network;
  final String? error;

  const DecodedInvoice({
    required this.isValid,
    required this.amountSats,
    required this.description,
    this.paymentHash,
    this.expirySecs = 3600,
    required this.network,
    this.error,
  });

  factory DecodedInvoice.fromJson(Map<String, dynamic> json) {
    return DecodedInvoice(
      isValid: json['is_valid'] as bool? ?? false,
      amountSats: json['amount_sats'] as int? ?? 0,
      description: json['description'] as String? ?? 'Reliq Payment',
      paymentHash: json['payment_hash'] as String?,
      expirySecs: json['expiry_secs'] as int? ?? 3600,
      network: json['network'] as String? ?? 'regtest',
      error: json['error'] as String?,
    );
  }

  factory DecodedInvoice.invalid(String error) {
    return DecodedInvoice(
      isValid: false,
      amountSats: 0,
      description: '',
      network: 'unknown',
      error: error,
    );
  }
}

/// Activity entry for sent or received payment
enum PaymentType { receive, send }
enum ActivityStatus { pending, succeeded, failed }

class PaymentActivity {
  final String id;
  final PaymentType type;
  final int amountSats;
  final int feeSats;
  final String description;
  final DateTime timestamp;
  final ActivityStatus status;
  final String? paymentHash;

  const PaymentActivity({
    required this.id,
    required this.type,
    required this.amountSats,
    this.feeSats = 0,
    required this.description,
    required this.timestamp,
    required this.status,
    this.paymentHash,
  });

  bool get isReceived => type == PaymentType.receive;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount_sats': amountSats,
        'fee_sats': feeSats,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'payment_hash': paymentHash,
      };

  factory PaymentActivity.fromJson(Map<String, dynamic> json) {
    return PaymentActivity(
      id: json['id'] as String,
      type: json['type'] == 'receive' ? PaymentType.receive : PaymentType.send,
      amountSats: json['amount_sats'] as int,
      feeSats: json['fee_sats'] as int? ?? 0,
      description: json['description'] as String? ?? 'Payment',
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: ActivityStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ActivityStatus.succeeded,
      ),
      paymentHash: json['payment_hash'] as String?,
    );
  }
}

/// An inbound Lightning payment pending LSP liquidity / claim processing.
///
/// Used during Phase 3 (Intermittent Connectivity & Push Wake-Up) to track
/// received payments that are awaiting inbound liquidity provisioning and
/// HTLC claim after wake-up / background settlement.
class PendingInboundPayment {
  final String paymentHash;
  final int amountSats;
  final String description;
  final DateTime createdAt;
  final bool isClaimed;

  const PendingInboundPayment({
    required this.paymentHash,
    required this.amountSats,
    required this.description,
    required this.createdAt,
    required this.isClaimed,
  });

  Map<String, dynamic> toJson() => {
        'payment_hash': paymentHash,
        'amount_sats': amountSats,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'is_claimed': isClaimed,
      };

  factory PendingInboundPayment.fromJson(Map<String, dynamic> json) {
    return PendingInboundPayment(
      paymentHash: json['payment_hash'] as String? ?? '',
      amountSats: json['amount_sats'] as int? ?? 0,
      description: json['description'] as String? ?? 'Payment',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      isClaimed: json['is_claimed'] as bool? ?? false,
    );
  }
}
