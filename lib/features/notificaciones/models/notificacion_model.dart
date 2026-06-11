class NotificacionModel {
  final String id;
  final String clienteId;
  final String tramiteId;
  final String titulo;
  final String mensaje;
  final bool leida;
  final DateTime fechaCreacion;

  const NotificacionModel({
    required this.id,
    required this.clienteId,
    required this.tramiteId,
    required this.titulo,
    required this.mensaje,
    required this.leida,
    required this.fechaCreacion,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: json['id'] as String? ?? '',
      clienteId: json['clienteId'] as String? ?? '',
      tramiteId: json['tramiteId'] as String? ?? '',
      titulo: json['titulo'] as String? ?? 'Sin título',
      mensaje: json['mensaje'] as String? ?? '',
      leida: json['leida'] as bool? ?? false,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.now(),
    );
  }
}
