import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';

class AuthService {
  /// Login + sync automático del token FCM si el login es exitoso.
  ///
  /// El backend espera: { "username": "...", "password": "..." }
  /// Devuelve:          { "token": "...", "username": "...", "rol": "...", "userId": "..." }
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await ApiClient.post(AppConstants.loginEndpoint, {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userId = data['userId'] as String;

        // Persistir sesión
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token'] as String);
        await prefs.setString('user_id', userId);
        await prefs.setString('username', data['username'] as String);
        await prefs.setString('rol', data['rol'] as String);

        // Sincronizar token FCM (no bloquea ni falla el login si hay error)
        _syncFcmToken(userId);

        return {'success': true, ...data};
      }

      if (response.statusCode == 401) {
        return {'success': false, 'message': 'Usuario o contraseña incorrectos'};
      }

      return {
        'success': false,
        'message': 'Error del servidor (${response.statusCode})',
      };
    } catch (e) {
      return {'success': false, 'message': 'Sin conexión con el servidor'};
    }
  }

  /// Obtiene el token FCM y lo envía al backend.
  /// Se llama en fire-and-forget: los errores se ignoran silenciosamente.
  static Future<void> _syncFcmToken(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      // PATCH /api/usuarios/{userId}/token-dispositivo?token=<fcmToken>
      final endpoint =
          '${AppConstants.usuariosEndpoint}/$userId/token-dispositivo'
          '?token=${Uri.encodeComponent(fcmToken)}';

      await ApiClient.patch(endpoint);
    } catch (_) {
      // Error de red o FCM no disponible → se ignora; el usuario ya hizo login
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<String?> getRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rol');
  }
}
