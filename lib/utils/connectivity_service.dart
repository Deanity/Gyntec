import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service singleton untuk memantau status koneksi jaringan secara real-time.
///
/// Cara pakai:
/// ```dart
/// // Cek status saat ini
/// bool online = await ConnectivityService.instance.isOnline();
///
/// // Dengarkan perubahan
/// ConnectivityService.instance.onStatusChanged.listen((isOnline) { ... });
/// ```
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Stream yang emit `true` saat online, `false` saat offline.
  Stream<bool> get onStatusChanged => _connectivity.onConnectivityChanged
      .map((results) => _isConnected(results));

  /// Cek status koneksi saat ini (satu kali).
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  /// Kembalikan true jika setidaknya ada satu koneksi aktif selain `none`.
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
