import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../features/tramites/models/tramite_model.dart';

class TramiteService {
  /// GET /api/tramite/cliente/{clienteId}
  /// Devuelve los trámites del cliente autenticado.
  static Future<List<TramiteModel>> getTramites() async {
    final prefs = await SharedPreferences.getInstance();
    final clienteId = prefs.getString('user_id');

    if (clienteId == null) {
      throw Exception('No hay sesión activa');
    }

    final response = await ApiClient.get(
      '${AppConstants.tramitesClienteEndpoint}/$clienteId',
    );

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json
          .map((e) => TramiteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (response.statusCode == 403) {
      throw Exception('Sin permisos para ver estos trámites');
    }

    throw Exception('Error ${response.statusCode} al cargar trámites');
  }
}
