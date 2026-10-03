import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service singleton untuk memantau status koneksi jaringan secara real-time.
///
/// Menyediakan [isOfflineNotifier] (ValueNotifier) dan fallback polling otomatis
/// sehingga seluruh screen dalam aplikasi selalu sinkron tanpa duplikasi timer.
class ConnectivityService {
  ConnectivityService._() {
    _init();
  }
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isOfflineNotifier = ValueNotifier<bool>(false);
  Timer? _pollTimer;

  /// Status offline saat ini
  bool get isOffline => isOfflineNotifier.value;

  /// Stream yang emit `true` saat online, `false` saat offline (backward compatibility).
  Stream<bool> get onStatusChanged => _connectivity.onConnectivityChanged
      .map((results) => _isConnected(results));

  void _init() {
    // Cek koneksi awal
    isOnline();

    // Dengarkan perubahan koneksi
    _connectivity.onConnectivityChanged.listen((results) {
      final online = _isConnected(results);
      if (isOfflineNotifier.value != !online) {
        isOfflineNotifier.value = !online;
      }
    });

    // Polling fallback setiap 4 detik untuk perangkat yang tidak konsisten memicu stream
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      await isOnline();
    });
  }

  /// Cek status koneksi saat ini (satu kali) dan perbarui [isOfflineNotifier].
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final online = _isConnected(results);
      if (isOfflineNotifier.value != !online) {
        isOfflineNotifier.value = !online;
      }
      return online;
    } catch (_) {
      return !isOfflineNotifier.value;
    }
  }

  /// Kembalikan true jika setidaknya ada satu koneksi aktif selain `none`.
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _pollTimer?.cancel();
    isOfflineNotifier.dispose();
  }
}
