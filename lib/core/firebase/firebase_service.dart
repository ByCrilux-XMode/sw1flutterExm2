import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Handler de background: debe ser top-level (fuera de cualquier clase)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No necesita inicializar Firebase aquí si ya se hizo en main()
  debugPrint('🔔 [Background] ${message.notification?.title}');
  // El sistema operativo muestra la notificación automáticamente
}

class PushNotificationService {
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Callback que las pantallas pueden registrar para refrescarse
  /// en cuanto llega una notificación foreground.
  static VoidCallback? onNewMessage;

  static Future<void> init(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    // Registrar handler de mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Solicitar permisos (Android 13+ y iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // --- FOREGROUND: app abierta ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 [Foreground] ${message.notification?.title}');
      _showSnackbar(message);
      onNewMessage?.call(); // notifica a la pantalla activa
    });

    // --- OPENED APP: usuario toca notificación con app en background ---
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 [OpenedApp] ${message.notification?.title}');
      // TODO: navegar a la pantalla del trámite si el payload trae un tramiteId
      // final tramiteId = message.data['tramiteId'];
      // if (tramiteId != null) navigateTo(tramiteId);
    });

    // --- TERMINATED: app estaba cerrada y el usuario tocó la notificación ---
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 [InitialMessage] ${initialMessage.notification?.title}');
    }
  }

  static void _showSnackbar(RemoteMessage message) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? 'Notificación';
    final body = message.notification?.body ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  if (body.isNotEmpty)
                    Text(body,
                        style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
