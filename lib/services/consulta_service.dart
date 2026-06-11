import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../features/consulta_politica/models/recomendacion_model.dart';

/// Servicio del módulo de Recomendación Inteligente de Trámites.
///
/// Envía un audio y/o texto al backend mediante multipart/form-data y recibe
/// la recomendación de política. El backend consulta MongoDB dinámicamente en
/// cada petición, por lo que cualquier política nueva se reconoce al instante.
class ConsultaService {
  /// Envía una consulta por AUDIO (archivo WAV).
  static Future<RecomendacionResponse> recomendarPorAudio(File audio) {
    return _enviar(audio: audio);
  }

  /// Envía una consulta por TEXTO manual.
  static Future<RecomendacionResponse> recomendarPorTexto(String texto) {
    return _enviar(texto: texto);
  }

  // ── Núcleo multipart ─────────────────────────────────────────────────────
  static Future<RecomendacionResponse> _enviar({File? audio, String? texto}) async {
    final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.recomendarConsultaEndpoint}');

    final request = http.MultipartRequest('POST', uri);

    // El endpoint es libre, pero adjuntamos el token si existe (no estorba).
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (audio != null) {
      request.files.add(
        await http.MultipartFile.fromPath('audio', audio.path),
      );
    }
    if (texto != null && texto.trim().isNotEmpty) {
      request.fields['texto'] = texto.trim();
    }

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RecomendacionResponse.fromJson(json);
      } else {
        String msg = 'Error ${response.statusCode}';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['error'] != null) msg = body['error'].toString();
        } catch (_) {}
        throw Exception(msg);
      }
    } on SocketException {
      throw Exception('Sin conexión con el servidor');
    }
  }
}
