/// Respuesta del endpoint POST /api/consultas/recomendar.
class RecomendacionResponse {
  final String transcripcion;
  final String politicaRecomendada;
  final String razon;
  final List<String> subOpciones;
  final String modeloUtilizado;

  RecomendacionResponse({
    required this.transcripcion,
    required this.politicaRecomendada,
    required this.razon,
    required this.subOpciones,
    required this.modeloUtilizado,
  });

  factory RecomendacionResponse.fromJson(Map<String, dynamic> json) {
    final subs = json['subOpciones'];
    return RecomendacionResponse(
      transcripcion: json['transcripcion']?.toString() ?? '',
      politicaRecomendada: json['politicaRecomendada']?.toString() ?? '',
      razon: json['razon']?.toString() ?? '',
      subOpciones: subs is List
          ? subs.map((e) => e.toString()).toList()
          : <String>[],
      modeloUtilizado: json['modeloUtilizado']?.toString() ??
          json['modeloAudioUtilizado']?.toString() ??
          'desconocido',
    );
  }
}
