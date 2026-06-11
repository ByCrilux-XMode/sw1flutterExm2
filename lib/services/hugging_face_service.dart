import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class HuggingFaceService {
  /// Envía un archivo WAV al modelo de Gradio y devuelve el texto transcrito.
  static Future<String> transcribirAudio(File audioFile) async {
    try {
      // Gradio espera el audio como base64 en el campo "data"
      final bytes = await audioFile.readAsBytes();
      final base64Audio = base64Encode(bytes);

      final response = await http
          .post(
            Uri.parse(AppConstants.huggingFaceUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'data': [
                {
                  'name': 'audio.wav',
                  'data': 'data:audio/wav;base64,$base64Audio',
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        // Gradio retorna: { "data": ["texto transcrito"], "duration": ... }
        final data = json['data'];
        if (data is List && data.isNotEmpty) {
          return data[0]?.toString() ?? 'Sin respuesta del modelo';
        }
        return 'El modelo no retornó texto';
      } else {
        throw Exception(
            'Error HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión a internet');
    } catch (e) {
      throw Exception('Error en transcripción: $e');
    }
  }
}
