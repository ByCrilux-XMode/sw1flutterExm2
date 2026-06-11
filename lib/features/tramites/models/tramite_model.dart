class TramiteModel {
  final String id;
  final String clienteId;
  final String politicaId;

  /// INICIADO | EN_PROCESO | FINALIZADO
  final String estadoActual;

  /// Nodos (departamentos) en los que está actualmente el trámite
  final List<String> nodosActualesKeys;

  final DateTime fechaInicio;
  final DateTime? fechaFin;

  const TramiteModel({
    required this.id,
    required this.clienteId,
    required this.politicaId,
    required this.estadoActual,
    required this.nodosActualesKeys,
    required this.fechaInicio,
    this.fechaFin,
  });

  factory TramiteModel.fromJson(Map<String, dynamic> json) {
    return TramiteModel(
      id: json['id'] as String? ?? '',
      clienteId: json['clienteId'] as String? ?? '',
      politicaId: json['politicaId'] as String? ?? '',
      estadoActual: json['estadoActual'] as String? ?? 'INICIADO',
      nodosActualesKeys: (json['nodosActualesKeys'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fechaInicio: json['fechaInicio'] != null
          ? DateTime.parse(json['fechaInicio'] as String)
          : DateTime.now(),
      fechaFin: json['fechaFin'] != null
          ? DateTime.parse(json['fechaFin'] as String)
          : null,
    );
  }

  /// Nombre para mostrar: primer nodo actual o "Sin asignar"
  String get departamentoActual =>
      nodosActualesKeys.isNotEmpty ? nodosActualesKeys.first : 'Sin asignar';

  /// Todos los nodos activos separados por coma (para flujos paralelos)
  String get departamentosDisplay => nodosActualesKeys.isNotEmpty
      ? nodosActualesKeys.join(' • ')
      : 'Sin asignar';
}
