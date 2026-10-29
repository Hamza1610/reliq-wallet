import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'nearby_models.dart';

enum NearbyState { idle, advertising, discovering, connected }

/// Manages Bluetooth / Google Nearby Connections discovery, connection,
/// payload exchange, signature verification, and 60s session timeout.
/// Conforms to Section 2.1 of the Reliq Nearby Confirm Technical Specification.
class NearbyConfirmService {
  static const String serviceId = 'com.reliq.nearby.confirm';
  static const Strategy strategy = Strategy.P2P_STAR;

  final Nearby _nearby = Nearby();
  final _confirmationsController = StreamController<NearbyPayload>.broadcast();
  Stream<NearbyPayload> get incomingConfirmations => _confirmationsController.stream;

  final Map<String, String> _connectedEndpoints = {};
  NearbyState _state = NearbyState.idle;
  Timer? _sessionTimeoutTimer;

  NearbyState get state => _state;
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Starts advertising as a Receiver to accept nearby confirmation payloads
  Future<bool> startAdvertising({required String displayName}) async {
    if (!isSupported) {
      debugPrint('[NearbyConfirmService] Platform does not support Nearby Connections');
      return false;
    }

    try {
      await stopAll();

      final success = await _nearby.startAdvertising(
        displayName,
        strategy,
        onConnectionInitiated: (endpointId, connectionInfo) async {
          debugPrint('[NearbyConfirmService] Connection initiated with $endpointId');
          // Auto-accept connection for rapid marketplace checkout
          await _nearby.acceptConnection(
            endpointId,
            onPayLoadRecieved: (endpointId, payload) {
              if (payload.type == PayloadType.BYTES && payload.bytes != null) {
                _handleIncomingBytes(payload.bytes!);
              }
            },
          );
        },
        onConnectionResult: (endpointId, status) {
          if (status == Status.CONNECTED) {
            _connectedEndpoints[endpointId] = displayName;
            _state = NearbyState.connected;
          } else {
            _connectedEndpoints.remove(endpointId);
          }
        },
        onDisconnected: (endpointId) {
          _connectedEndpoints.remove(endpointId);
        },
        serviceId: serviceId,
      );

      if (success) {
        _state = NearbyState.advertising;
        _startTimeoutTimer();
      }
      return success;
    } catch (e) {
      debugPrint('[NearbyConfirmService] Start advertising failed: $e');
      return false;
    }
  }

  /// Starts discovery as a Sender to find nearby Reliq receiver stalls
  Future<bool> startDiscovery({required String userName, required Function(String endpointId, String name) onDeviceFound}) async {
    if (!isSupported) {
      return false;
    }

    try {
      await stopAll();

      final success = await _nearby.startDiscovery(
        userName,
        strategy,
        onEndpointFound: (endpointId, endpointName, serviceId) {
          debugPrint('[NearbyConfirmService] Discovered nearby peer: $endpointName ($endpointId)');
          onDeviceFound(endpointId, endpointName);
        },
        onEndpointLost: (endpointId) {
          debugPrint('[NearbyConfirmService] Lost peer: $endpointId');
        },
        serviceId: serviceId,
      );

      if (success) {
        _state = NearbyState.discovering;
        _startTimeoutTimer();
      }
      return success;
    } catch (e) {
      debugPrint('[NearbyConfirmService] Start discovery failed: $e');
      return false;
    }
  }

  /// Connects to a discovered nearby peer
  Future<bool> connectToPeer({required String endpointId, required String userName}) async {
    if (!isSupported) return false;
    try {
      final success = await _nearby.requestConnection(
        userName,
        endpointId,
        onConnectionInitiated: (endpointId, connectionInfo) async {
          await _nearby.acceptConnection(
            endpointId,
            onPayLoadRecieved: (id, payload) {
              if (payload.type == PayloadType.BYTES && payload.bytes != null) {
                _handleIncomingBytes(payload.bytes!);
              }
            },
          );
        },
        onConnectionResult: (endpointId, status) {
          if (status == Status.CONNECTED) {
            _connectedEndpoints[endpointId] = userName;
            _state = NearbyState.connected;
          }
        },
        onDisconnected: (endpointId) {
          _connectedEndpoints.remove(endpointId);
        },
      );
      return success;
    } catch (e) {
      debugPrint('[NearbyConfirmService] Connect peer failed: $e');
      return false;
    }
  }

  /// Sends a signed confirmation payload to all connected peers
  Future<void> sendConfirmation(NearbyPayload payload) async {
    final bytes = payload.toBytes();
    for (final endpoint in _connectedEndpoints.keys) {
      try {
        await _nearby.sendBytesPayload(endpoint, bytes);
      } catch (e) {
        debugPrint('[NearbyConfirmService] Send payload error to $endpoint: $e');
      }
    }
  }

  void _handleIncomingBytes(Uint8List bytes) {
    try {
      final payload = NearbyPayload.fromBytes(bytes);
      // Validate signature and freshness per spec section 4.2
      if (payload.isFresh() && payload.verifySignature()) {
        _confirmationsController.add(payload);
      } else {
        debugPrint('[NearbyConfirmService] Rejected payload: failed freshness or signature');
      }
    } catch (e) {
      debugPrint('[NearbyConfirmService] Error deserializing payload: $e');
    }
  }

  void _startTimeoutTimer({Duration timeout = const Duration(seconds: 60)}) {
    _sessionTimeoutTimer?.cancel();
    _sessionTimeoutTimer = Timer(timeout, () async {
      debugPrint('[NearbyConfirmService] Session timeout reached (60s). Cleaning up.');
      await stopAll();
    });
  }

  /// Manually deliver a confirmed payload (useful for testing or direct simulation)
  void deliverPayloadForTesting(NearbyPayload payload) {
    _confirmationsController.add(payload);
  }

  /// Stops all discovery, advertising, and disconnects all endpoints
  Future<void> stopAll() async {
    _sessionTimeoutTimer?.cancel();
    _sessionTimeoutTimer = null;
    if (isSupported) {
      try {
        await _nearby.stopAdvertising();
        await _nearby.stopDiscovery();
        await _nearby.stopAllEndpoints();
      } catch (_) {}
    }
    _connectedEndpoints.clear();
    _state = NearbyState.idle;
  }

  void dispose() {
    stopAll();
    _confirmationsController.close();
  }
}

