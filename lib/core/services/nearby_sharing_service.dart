import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/module/models/module_model.dart';
import '../../features/sharing/widgets/device_select_card.dart';
import 'module_repository.dart';

enum SharingReadiness {
  ready,
  permissionDenied,
  bluetoothOff,
  locationOff,
  unsupported,
}

class IncomingOffer {
  final String endpointId;
  final String senderName;
  final List<ModuleModel> modules;
  final int sizeBytes;
  final String? authPin;

  IncomingOffer({
    required this.endpointId,
    required this.senderName,
    required this.modules,
    required this.sizeBytes,
    this.authPin,
  });
}

class SendResult {
  final bool success;
  final String? errorMessage;

  SendResult.ok() : success = true, errorMessage = null;
  SendResult.fail(this.errorMessage) : success = false;
}

/// Service singleton pengelola konektivitas Nearby Connections untuk sharing modul.
class NearbySharingService {
  static final NearbySharingService instance = NearbySharingService._();
  NearbySharingService._();

  static const String _serviceId = 'com.gyntec.share';
  static const Strategy _strategy = Strategy.P2P_POINT_TO_POINT;

  final Nearby _nearby = Nearby();
  String _localDisplayName = 'Gyntec User';

  // Streams
  final _offersController = StreamController<IncomingOffer>.broadcast();
  final _devicesController = StreamController<List<TargetDeviceModel>>.broadcast();
  final _progressController = StreamController<double>.broadcast();
  final _receivedController = StreamController<List<String>>.broadcast();

  Stream<IncomingOffer> get offers => _offersController.stream;
  Stream<List<TargetDeviceModel>> get devices => _devicesController.stream;
  Stream<double> get progress => _progressController.stream;
  Stream<List<String>> get received => _receivedController.stream;

  final Map<String, TargetDeviceModel> _discoveredDevices = {};

  // Active Connection State
  String? _connectedEndpointId;
  String? _authPin;
  String? _lastIncomingFileUri;
  Completer<SendResult>? _sendCompleter;
  IncomingOffer? _currentOffer;
  List<ModuleModel>? _pendingModulesToSend;

  bool _isAdvertising = false;
  bool _isDiscovering = false;

  void setLocalDisplayName(String name) {
    final rand = Random().nextInt(9000) + 1000;
    _localDisplayName = '$name · $rand';
  }

  Future<SharingReadiness> checkReadiness() async {
    final locationStatus = await Permission.location.status;
    final nearbyWifiStatus = await Permission.nearbyWifiDevices.status;

    if (!locationStatus.isGranted || !nearbyWifiStatus.isGranted) {
      return SharingReadiness.permissionDenied;
    }

    final locationServiceEnabled = await Permission.location.serviceStatus.isEnabled;
    if (!locationServiceEnabled) {
      return SharingReadiness.locationOff;
    }

    return SharingReadiness.ready;
  }

  Future<bool> requestPermissions() async {
    try {
      final statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
      ].request();

      final locationOk = statuses[Permission.location]?.isGranted ?? false;
      return locationOk;
    } catch (e) {
      debugPrint('[NearbyService] requestPermissions error: $e');
      return false;
    }
  }

  Future<void> startReceiving() async {
    await stop();
    await requestPermissions();
    _isAdvertising = true;

    try {
      await _nearby.startAdvertising(
        _localDisplayName,
        _strategy,
        serviceId: _serviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      debugPrint('[NearbyService] startAdvertising error: $e');
      _isAdvertising = false;
    }
  }

  Future<void> startDiscovery() async {
    await stop();
    await requestPermissions();
    _isDiscovering = true;
    _discoveredDevices.clear();
    _devicesController.add([]);

    try {
      await _nearby.startDiscovery(
        _localDisplayName,
        _strategy,
        serviceId: _serviceId,
        onEndpointFound: (id, name, serviceId) {
          _discoveredDevices[id] = TargetDeviceModel(id: id, name: name);
          _devicesController.add(_discoveredDevices.values.toList());
        },
        onEndpointLost: (id) {
          _discoveredDevices.remove(id);
          _devicesController.add(_discoveredDevices.values.toList());
        },
      );
    } catch (e) {
      debugPrint('[NearbyService] startDiscovery error: $e');
      _isDiscovering = false;
    }
  }

  Future<SendResult> send(TargetDeviceModel target, List<ModuleModel> modules) async {
    _sendCompleter = Completer<SendResult>();
    _pendingModulesToSend = modules;

    try {
      // 1. Hentikan discovery saat mulai connect
      await _nearby.stopDiscovery();
      _isDiscovering = false;

      // 2. Ajukan koneksi
      await _nearby.requestConnection(
        _localDisplayName,
        target.id,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) async {
          _onConnectionResult(id, status);
          if (status == Status.CONNECTED) {
            // Begitu connected, susun & kirim payload OFFER
            _sendOffer(id, modules);
          } else {
            if (_sendCompleter != null && !_sendCompleter!.isCompleted) {
              _sendCompleter!.complete(SendResult.fail('Gagal terhubung ke ${target.name}'));
            }
          }
        },
        onDisconnected: _onDisconnected,
      );

      return await _sendCompleter!.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () => SendResult.fail('Waktu pengiriman habis (timeout).'),
      );
    } catch (e) {
      return SendResult.fail(e.toString());
    }
  }

  Future<void> _sendOffer(String endpointId, List<ModuleModel> modules) async {
    try {
      final payloadFile = await ModuleRepository.instance.buildPayloadFile(modules);
      final size = await payloadFile.length();

      final offerMsg = {
        'type': 'offer',
        'v': 1,
        'sender': _localDisplayName,
        'modules': modules.map((m) => m.toJson()).toList(),
        'sizeBytes': size,
      };

      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(offerMsg)));
      await _nearby.sendBytesPayload(endpointId, bytes);
    } catch (e) {
      if (_sendCompleter != null && !_sendCompleter!.isCompleted) {
        _sendCompleter!.complete(SendResult.fail('Gagal menyiapkan modul: $e'));
      }
    }
  }

  Future<void> acceptOffer(IncomingOffer offer) async {
    final acceptMsg = {'type': 'accept', 'v': 1};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(acceptMsg)));
    await _nearby.sendBytesPayload(offer.endpointId, bytes);
  }

  Future<void> rejectOffer(IncomingOffer offer) async {
    final rejectMsg = {'type': 'reject', 'v': 1};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(rejectMsg)));
    await _nearby.sendBytesPayload(offer.endpointId, bytes);
    await _nearby.disconnectFromEndpoint(offer.endpointId);
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    _authPin = info.authenticationToken;
    _nearby.acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) => _onPayloadReceived(endpointId, payload),
      onPayloadTransferUpdate: (endpointId, update) => _onPayloadTransferUpdate(endpointId, update),
    );
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      _connectedEndpointId = id;
    } else {
      if (_connectedEndpointId == id) _connectedEndpointId = null;
    }
  }

  void _onDisconnected(String id) {
    if (_connectedEndpointId == id) {
      _connectedEndpointId = null;
      _authPin = null;
    }
  }

  void _onPayloadReceived(String endpointId, Payload payload) async {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      try {
        final text = utf8.decode(payload.bytes!);
        final json = jsonDecode(text) as Map<String, dynamic>;
        final type = json['type'] as String?;

        if (type == 'offer') {
          final sender = json['sender'] as String? ?? 'Perangkat Lain';
          final size = json['sizeBytes'] as int? ?? 0;
          final modulesList = (json['modules'] as List? ?? [])
              .map((e) => ModuleModel.fromJson(e as Map<String, dynamic>))
              .toList();

          _currentOffer = IncomingOffer(
            endpointId: endpointId,
            senderName: sender,
            modules: modulesList,
            sizeBytes: size,
            authPin: _authPin,
          );
          _offersController.add(_currentOffer!);
        } else if (type == 'accept') {
          // Penerima setuju, kirim payload file sekarang
          _executeSendFile(endpointId);
        } else if (type == 'reject') {
          if (_sendCompleter != null && !_sendCompleter!.isCompleted) {
            _sendCompleter!.complete(SendResult.fail('Pengiriman ditolak oleh penerima.'));
          }
        } else if (type == 'file_meta') {
          // Metadata file diterima
        } else if (type == 'done') {
          if (_sendCompleter != null && !_sendCompleter!.isCompleted) {
            _sendCompleter!.complete(SendResult.ok());
          }
        }
      } catch (e) {
        debugPrint('[NearbyService] Parse bytes error: $e');
      }
    } else if (payload.type == PayloadType.FILE) {
      _lastIncomingFileUri = payload.uri;
    }
  }

  Future<void> _executeSendFile(String endpointId) async {
    try {
      final modules = _pendingModulesToSend ?? [];
      final payloadFile = await ModuleRepository.instance.buildPayloadFile(modules);
      final payloadId = await _nearby.sendFilePayload(endpointId, payloadFile.path);

      final metaMsg = {
        'type': 'file_meta',
        'v': 1,
        'payloadId': payloadId,
      };
      await _nearby.sendBytesPayload(endpointId, Uint8List.fromList(utf8.encode(jsonEncode(metaMsg))));
    } catch (e) {
      if (_sendCompleter != null && !_sendCompleter!.isCompleted) {
        _sendCompleter!.complete(SendResult.fail('Gagal mengirim file payload: $e'));
      }
    }
  }

  void _onPayloadTransferUpdate(String endpointId, PayloadTransferUpdate update) async {
    final total = update.totalBytes;
    final transferred = update.bytesTransferred;
    final prog = total > 0 ? (transferred / total) : 0.0;

    if (update.status == PayloadStatus.IN_PROGRESS) {
      _progressController.add(prog);
    } else if (update.status == PayloadStatus.SUCCESS) {
      _progressController.add(1.0);

      // Jika di sisi penerima
      if (_lastIncomingFileUri != null) {
        try {
          final tempDir = Directory.systemTemp;
          final destPath = '${tempDir.path}/incoming_p2p_${DateTime.now().millisecondsSinceEpoch}.json';
          final ok = await _nearby.copyFileAndDeleteOriginal(_lastIncomingFileUri!, destPath);

          if (ok) {
            final savedIds = await ModuleRepository.instance.saveReceived(File(destPath));
            _receivedController.add(savedIds);

            // Beri tahu pengirim bahwa proses simpan selesai
            final doneMsg = {'type': 'done', 'v': 1, 'savedIds': savedIds};
            await _nearby.sendBytesPayload(
              endpointId,
              Uint8List.fromList(utf8.encode(jsonEncode(doneMsg))),
            );
          }
        } catch (e) {
          debugPrint('[NearbyService] Simpan file gagal: $e');
        }
      }
    } else if (update.status == PayloadStatus.FAILURE) {
      if (_sendCompleter != null && !_sendCompleter!.isCompleted) {
        _sendCompleter!.complete(SendResult.fail('Transfer file terputus / gagal.'));
      }
    }
  }

  Future<void> stop() async {
    try {
      if (_isAdvertising) {
        await _nearby.stopAdvertising();
        _isAdvertising = false;
      }
      if (_isDiscovering) {
        await _nearby.stopDiscovery();
        _isDiscovering = false;
      }
      await _nearby.stopAllEndpoints();
      _connectedEndpointId = null;
      _authPin = null;
      _discoveredDevices.clear();
    } catch (_) {}
  }
}
