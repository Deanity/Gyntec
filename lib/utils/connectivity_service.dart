import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service singleton untuk memantau status koneksi jaringan secara real-time.
///
/// Cara pakai:
/// ```dart
/// // Cek status saat ini (untuk pull-to-refresh)
/// bool online = await ConnectivityService.instance.isOnline();
///
/// // Dengarkan perubahan otomatis
/// ConnectivityService.instance.onStatusChanged.listen((isOnline) { ... });
/// ```
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Stream yang emit `true` saat online, `false` saat offline.
  /// Catatan: tidak semua HP Android fire ini secara reliable.
  /// Gunakan kombinasi stream + polling/pull-to-refresh untuk hasil terbaik.
  Stream<bool> get onStatusChanged => _connectivity.onConnectivityChanged
      .map((results) => _isConnected(results));

  /// Cek status koneksi saat ini (satu kali). Dipakai untuk:
  /// - Cek awal saat screen dibuka
  /// - Pull-to-refresh manual oleh user
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  /// Kembalikan true jika setidaknya ada satu koneksi aktif selain `none`.
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
