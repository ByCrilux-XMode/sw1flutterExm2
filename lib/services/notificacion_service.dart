import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../features/notificaciones/models/notificacion_model.dart';

class NotificacionService {
  /// GET /api/notificaciones/cliente/{clienteId}
  static Future<List<NotificacionModel>> getNotificaciones() async {
    final prefs = await SharedPreferences.getInstance();
    final clienteId = prefs.getString('user_id');

    if (clienteId == null) throw Exception('No hay sesión activa');

    final response = await ApiClient.get(
      '${AppConstants.notificacionesClienteEndpoint}/$clienteId',
    );

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json
          .map((e) => NotificacionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Error ${response.statusCode} al cargar notificaciones');
  }

  /// PUT /api/notificaciones/{id}/leer
  static Future<void> marcarComoLeida(String id) async {
    await ApiClient.put('${AppConstants.notificacionLeerEndpoint}/$id/leer');
  }
}
