import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Screen spike mandiri untuk memvalidasi Google Nearby Connections di 2 device fisik.
/// Sesuai Phase 0 di update/planingUpdate2.md.
class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key});

  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _DiscoveredEndpoint {
  final String id;
  final String name;
  final String serviceId;

  _DiscoveredEndpoint({
    required this.id,
    required this.name,
    required this.serviceId,
  });
}

class _SpikeScreenState extends State<SpikeScreen> {
  static const String _serviceId = 'com.gyntec.spike';
  static const Strategy _strategy = Strategy.P2P_POINT_TO_POINT;

  late final String _localName;
  final Nearby _nearby = Nearby();

  bool _isAdvertising = false;
  bool _isDiscovering = false;
  String? _connectedEndpointId;
  String? _connectedEndpointName;
  String? _authPin;

  final Map<String, _DiscoveredEndpoint> _endpoints = {};
  final List<String> _logs = [];

  // Transfer state
  double _sendProgress = 0.0;
  double _recvProgress = 0.0;
  String? _lastReceivedFilePath;
  int? _lastReceivedFileSize;
  int? _activeSendPayloadId;

  @override
  void initState() {
    super.initState();
    final rand = Random().nextInt(9000) + 1000;
    _localName = 'Gyntec-$rand';
    _log('Nama device lokal: $_localName');
  }

  @override
  void dispose() {
    _nearby.stopAdvertising();
    _nearby.stopDiscovery();
    _nearby.stopAllEndpoints();
    super.dispose();
  }

  void _log(String msg) {
    debugPrint('[SPIKE] $msg');
    final time = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.insert(0, '[$time] $msg');
      if (_logs.length > 100) _logs.removeLast();
    });
  }

  Future<void> _requestPermissions() async {
    _log('Meminta izin Android...');
    // Request permission yang relevan untuk modern Android & legacy
    final permissionsToRequest = <Permission>[
      Permission.location,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ];

    final statuses = await permissionsToRequest.request();

    // Verifikasi: lokasi dan bluetooth permissions
    final locationOk = statuses[Permission.location]?.isGranted ?? false;
    final btScanOk = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final btAdvertiseOk = statuses[Permission.bluetoothAdvertise]?.isGranted ?? false;
    final btConnectOk = statuses[Permission.bluetoothConnect]?.isGranted ?? false;

    // Di Android 12+, butuh lokasi + bt scan/adv/connect
    // Di Android 11 ke bawah, bt legacy otomatis dari manifest
    final bool isReady = locationOk && (btScanOk && btAdvertiseOk && btConnectOk || statuses[Permission.bluetooth]?.isGranted == true);

    _log('Status detail: $statuses');
    _log(
      isReady
          ? 'Izin SIAP untuk Nearby Connections'
          : 'Catatan: Pastikan Lokasi & Nearby Devices diizinkan!',
    );
  }

  Future<void> _startAdvertising() async {
    try {
      _log('Memulai Advertising sebagai $_localName...');
      final ok = await _nearby.startAdvertising(
        _localName,
        _strategy,
        serviceId: _serviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      setState(() => _isAdvertising = ok);
      _log(ok ? 'Advertising AKTIF' : 'Advertising GAGAL');
    } catch (e) {
      _log('Error startAdvertising: $e');
    }
  }

  Future<void> _stopAdvertising() async {
    await _nearby.stopAdvertising();
    setState(() => _isAdvertising = false);
    _log('Advertising dihentikan');
  }

  Future<void> _startDiscovery() async {
    try {
      _log('Memulai Discovery...');
      final ok = await _nearby.startDiscovery(
        _localName,
        _strategy,
        serviceId: _serviceId,
        onEndpointFound: (id, name, serviceId) {
          _log('Device ditemukan: $name ($id)');
          setState(() {
            _endpoints[id] = _DiscoveredEndpoint(
              id: id,
              name: name,
              serviceId: serviceId,
            );
          });
        },
        onEndpointLost: (id) {
          _log('Device hilang: $id');
          setState(() => _endpoints.remove(id));
        },
      );
      setState(() => _isDiscovering = ok);
      _log(ok ? 'Discovery AKTIF' : 'Discovery GAGAL');
    } catch (e) {
      _log('Error startDiscovery: $e');
    }
  }

  Future<void> _stopDiscovery() async {
    await _nearby.stopDiscovery();
    setState(() {
      _isDiscovering = false;
      _endpoints.clear();
    });
    _log('Discovery dihentikan');
  }

  Future<void> _connectTo(_DiscoveredEndpoint ep) async {
    _log('Mengajukan koneksi ke ${ep.name} (${ep.id})...');
    try {
      await _nearby.requestConnection(
        _localName,
        ep.id,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      _log('Error requestConnection: $e');
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    _log('Koneksi diajukan oleh ${info.endpointName} (${info.authenticationToken})');
    setState(() {
      _authPin = info.authenticationToken;
    });

    // Otomatis accept di sisi spike untuk verifikasi konektivitas
    _nearby.acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) => _onPayloadReceived(endpointId, payload),
      onPayloadTransferUpdate: (endpointId, update) =>
          _onPayloadTransferUpdate(endpointId, update),
    );
    _log('acceptConnection dipanggil untuk $id');
  }

  void _onConnectionResult(String id, Status status) {
    _log('Status koneksi $id: ${status.name}');
    if (status == Status.CONNECTED) {
      setState(() {
        _connectedEndpointId = id;
        _connectedEndpointName = _endpoints[id]?.name ?? 'Peer';
      });
      // Sesuai rekomendasi, hentikan discovery saat sudah connect
      _stopDiscovery();
      _stopAdvertising();
    } else {
      setState(() {
        if (_connectedEndpointId == id) {
          _connectedEndpointId = null;
          _connectedEndpointName = null;
        }
      });
    }
  }

  void _onDisconnected(String id) {
    _log('Terputus dari $id');
    setState(() {
      if (_connectedEndpointId == id) {
        _connectedEndpointId = null;
        _connectedEndpointName = null;
        _authPin = null;
      }
    });
  }

  void _onPayloadReceived(String endpointId, Payload payload) async {
    _log('Payload masuk dari $endpointId: type=${payload.type}, id=${payload.id}');
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      final text = String.fromCharCodes(payload.bytes!);
      _log('Pesan teks diterima: "$text"');
    } else if (payload.type == PayloadType.FILE) {
      _log('File payload terdeteksi, uri: ${payload.uri}');
      // Simpan referensi uri untuk dicopy saat transfer selesai
      _lastReceivedFilePath = payload.uri;
    }
  }

  void _onPayloadTransferUpdate(String endpointId, PayloadTransferUpdate update) async {
    final total = update.totalBytes;
    final transferred = update.bytesTransferred;
    final progress = total > 0 ? transferred / total : 0.0;

    if (update.status == PayloadStatus.IN_PROGRESS) {
      setState(() {
        if (_activeSendPayloadId == update.id) {
          _sendProgress = progress;
        } else {
          _recvProgress = progress;
        }
      });
    } else if (update.status == PayloadStatus.SUCCESS) {
      _log('Transfer payload #${update.id} SUKSES ($transferred bytes)');
      setState(() {
        if (_activeSendPayloadId == update.id) {
          _sendProgress = 1.0;
        } else {
          _recvProgress = 1.0;
        }
      });

      // Jika ini file yang diterima, copy ke documents
      if (_lastReceivedFilePath != null && _activeSendPayloadId != update.id) {
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          final destPath = '${docsDir.path}/received_spike_${DateTime.now().millisecondsSinceEpoch}.bin';
          _log('Menyalin file dari uri: $_lastReceivedFilePath ke $destPath');
          final ok = await _nearby.copyFileAndDeleteOriginal(_lastReceivedFilePath!, destPath);
          if (ok) {
            final destFile = File(destPath);
            final size = await destFile.length();
            setState(() {
              _lastReceivedFilePath = destPath;
              _lastReceivedFileSize = size;
            });
            _log('File berhasil disalin! Ukuran: ${(size / (1024 * 1024)).toStringAsFixed(2)} MB');
          } else {
            _log('copyFileAndDeleteOriginal mengembalikan false');
          }
        } catch (e) {
          _log('Gagal menyalin file diterima: $e');
        }
      }
    } else if (update.status == PayloadStatus.FAILURE) {
      _log('Transfer payload #${update.id} GAGAL');
    } else if (update.status == PayloadStatus.CANCELED) {
      _log('Transfer payload #${update.id} DIBATALKAN');
    }
  }

  Future<void> _sendTestMessage() async {
    final target = _connectedEndpointId;
    if (target == null) return;
    final msg = 'Hello dari $_localName pada ${DateTime.now()}';
    final bytes = Uint8List.fromList(msg.codeUnits);
    await _nearby.sendBytesPayload(target, bytes);
    _log('Pesan teks terkirim: "$msg"');
  }

  Future<void> _sendDummy10MBFile() async {
    final target = _connectedEndpointId;
    if (target == null) return;

    setState(() => _sendProgress = 0.0);
    _log('Menyiapkan file dummy 10 MB...');

    final tempDir = await getTemporaryDirectory();
    final dummyFile = File('${tempDir.path}/dummy_10mb.bin');

    // Buat file 10 MB jika belum ada / ukuran berbeda
    const size = 10 * 1024 * 1024; // 10 MB
    if (!dummyFile.existsSync() || dummyFile.lengthSync() != size) {
      final sink = dummyFile.openWrite();
      final chunk = Uint8List(64 * 1024); // 64 KB chunk
      for (int i = 0; i < chunk.length; i++) {
        chunk[i] = i % 256;
      }
      final chunks = size ~/ chunk.length;
      for (int i = 0; i < chunks; i++) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      _log('File dummy 10 MB dibuat di ${dummyFile.path}');
    }

    _log('Mengirim file 10 MB ke $target...');
    final payloadId = await _nearby.sendFilePayload(target, dummyFile.path);
    setState(() => _activeSendPayloadId = payloadId);
    _log('sendFilePayload berjalan, payloadId: $payloadId');
  }

  Future<void> _disconnect() async {
    final target = _connectedEndpointId;
    if (target != null) {
      await _nearby.disconnectFromEndpoint(target);
      setState(() {
        _connectedEndpointId = null;
        _connectedEndpointName = null;
        _authPin = null;
      });
      _log('Disconnect dipanggil untuk $target');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _connectedEndpointId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spike: Nearby Connections'),
        backgroundColor: const Color(0xFF0066FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus log',
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header status
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF1F5F9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_android, size: 18, color: Color(0xFF0066FF)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Device: $_localName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isConnected ? 'TERHUBUNG' : 'IDLE',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                if (isConnected) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Terkoneksi ke: $_connectedEndpointName ($_connectedEndpointId)',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                  ),
                  if (_authPin != null)
                    Text(
                      'PIN Auth: $_authPin',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0066FF)),
                    ),
                ],
              ],
            ),
          ),

          // Tombol aksi utama
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _requestPermissions,
                  icon: const Icon(Icons.security, size: 16),
                  label: const Text('1. Izin'),
                ),
                ElevatedButton.icon(
                  onPressed: _isAdvertising ? _stopAdvertising : _startAdvertising,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAdvertising ? Colors.orange : null,
                    foregroundColor: _isAdvertising ? Colors.white : null,
                  ),
                  icon: Icon(_isAdvertising ? Icons.stop : Icons.sensors, size: 16),
                  label: Text(_isAdvertising ? 'Stop Adv' : '2. Terima (Adv)'),
                ),
                ElevatedButton.icon(
                  onPressed: _isDiscovering ? _stopDiscovery : _startDiscovery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDiscovering ? Colors.orange : null,
                    foregroundColor: _isDiscovering ? Colors.white : null,
                  ),
                  icon: Icon(_isDiscovering ? Icons.stop : Icons.search, size: 16),
                  label: Text(_isDiscovering ? 'Stop Disc' : '3. Kirim (Disc)'),
                ),
                if (isConnected) ...[
                  ElevatedButton.icon(
                    onPressed: _sendTestMessage,
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Kirim Text'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _sendDummy10MBFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Kirim 10 MB'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _disconnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.link_off, size: 16),
                    label: const Text('Disconnect'),
                  ),
                ],
              ],
            ),
          ),

          // Progress bar transfer
          if (_sendProgress > 0 || _recvProgress > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFEFF6FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_sendProgress > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Upload progress:', style: TextStyle(fontSize: 11)),
                        Text('${(_sendProgress * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(value: _sendProgress, color: const Color(0xFF0066FF)),
                    const SizedBox(height: 6),
                  ],
                  if (_recvProgress > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Download progress:', style: TextStyle(fontSize: 11)),
                        Text('${(_recvProgress * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(value: _recvProgress, color: Colors.green),
                  ],
                  if (_lastReceivedFileSize != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'File diterima: ${(_lastReceivedFileSize! / (1024 * 1024)).toStringAsFixed(2)} MB di $_lastReceivedFilePath',
                        style: const TextStyle(fontSize: 10, color: Colors.black87),
                      ),
                    ),
                ],
              ),
            ),

          // Daftar endpoint yang ditemukan (saat discovery)
          if (_endpoints.isNotEmpty)
            Container(
              constraints: const BoxBoxHeight(120),
              color: const Color(0xFFF8FAFC),
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  const Text('Endpoint Ditemukan (tap untuk connect):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ..._endpoints.values.map(
                    (ep) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        dense: true,
                        title: Text(ep.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(ep.id, style: const TextStyle(fontSize: 10)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => _connectTo(ep),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Log live
          Expanded(
            child: Container(
              color: const Color(0xFF0F172A),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) => Text(
                  _logs[index],
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: _logs[index].contains('Error') || _logs[index].contains('GAGAL')
                        ? Colors.redAccent
                        : _logs[index].contains('SUKSES') || _logs[index].contains('DIBERIKAN')
                            ? Colors.greenAccent
                            : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BoxBoxHeight extends BoxConstraints {
  const BoxBoxHeight(double height)
      : super(minHeight: 0, maxHeight: height, minWidth: double.infinity, maxWidth: double.infinity);
}
