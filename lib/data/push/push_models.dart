/// Status of an in-flight payment claim triggered by push/intermittent delivery.
enum PaymentClaimStatus {
  idle,
  pending,
  claiming,
  succeeded,
  failed,
}

/// Payload received from an LSP webhook / push notification when an HTLC is held.
class PushPaymentPayload {
  final String paymentHash;
  final int amountSats;
  final String? description;
  final DateTime timestamp;
  final String? lspEndpoint;

  const PushPaymentPayload({
    required this.paymentHash,
    required this.amountSats,
    this.description,
    required this.timestamp,
    this.lspEndpoint,
  });

  Map<String, dynamic> toJson() => {
        'payment_hash': paymentHash,
        'amount_sats': amountSats,
        if (description != null) 'description': description,
        'timestamp': timestamp.toIso8601String(),
        if (lspEndpoint != null) 'lsp_endpoint': lspEndpoint,
      };

  factory PushPaymentPayload.fromJson(Map<String, dynamic> json) {
    return PushPaymentPayload(
      paymentHash: json['payment_hash'] as String? ??
          json['paymentHash'] as String? ??
          '',
      amountSats: json['amount_sats'] as int? ??
          json['amountSats'] as int? ??
          int.tryParse(json['amount']?.toString() ?? '0') ??
          0,
      description: json['description'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      lspEndpoint: json['lsp_endpoint'] as String? ?? json['lspEndpoint'] as String?,
    );
  }
}

/// Active claim state tracked in memory and surfaced to the UI.
class ActivePaymentClaim {
  final String paymentHash;
  final int amountSats;
  final String description;
  final DateTime receivedAt;
  final PaymentClaimStatus status;
  final String? error;

  const ActivePaymentClaim({
    required this.paymentHash,
    required this.amountSats,
    required this.description,
    required this.receivedAt,
    required this.status,
    this.error,
  });

  ActivePaymentClaim copyWith({
    PaymentClaimStatus? status,
    String? error,
  }) {
    return ActivePaymentClaim(
      paymentHash: paymentHash,
      amountSats: amountSats,
      description: description,
      receivedAt: receivedAt,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  bool get isPending => status == PaymentClaimStatus.pending;
  bool get isClaiming => status == PaymentClaimStatus.claiming;
  bool get isSucceeded => status == PaymentClaimStatus.succeeded;
  bool get isFailed => status == PaymentClaimStatus.failed;
}
