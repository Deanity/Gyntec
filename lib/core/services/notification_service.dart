import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service lokal untuk mengelola notifikasi Android status bar
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _channelId = 'gyntec_p2p_channel';
  static const String _channelName = 'Transfer Modul Offline';
  static const String _channelDescription =
      'Notifikasi penyelesaian transfer modul pembelajaran P2P';

  Future<void> init() async {
    if (_isInitialized) return;
    if (!Platform.isAndroid) {
      _isInitialized = true;
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // Payload dapat berisi moduleId jika ingin auto-navigasi
          debugPrint('[NotificationService] Notification tapped: ${response.payload}');
        },
      );

      // Buat notification channel untuk Android 8.0+
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }

    _isInitialized = true;
  }

  Future<void> showModuleReceivedNotification({
    required String senderName,
    required int moduleCount,
    String? firstModuleTitle,
    String? firstModuleId,
  }) async {
    if (!Platform.isAndroid) return;
    await init();

    try {
      final String body;
      if (firstModuleTitle != null && moduleCount > 1) {
        body = '$firstModuleTitle dan ${moduleCount - 1} modul lainnya dari $senderName berhasil disimpan.';
      } else if (firstModuleTitle != null) {
        body = '$firstModuleTitle dari $senderName berhasil disimpan dan siap dipelajari offline.';
      } else {
        body = '$moduleCount modul dari $senderName berhasil disimpan dan siap dipelajari offline.';
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '📥 Modul Berhasil Diterima',
        body,
        notificationDetails,
        payload: firstModuleId,
      );
    } catch (e) {
      debugPrint('[NotificationService] Show notification error: $e');
    }
  }
}
