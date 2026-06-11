import 'dart:convert';

import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';

/// Información resuelta de un nodo del diagrama GoJS.
class _NodeInfo {
  final String key;
  final String text;
  final String? group; // key del nodo-grupo (departamento)

  _NodeInfo({required this.key, required this.text, this.group});
}

/// Servicio para obtener metadata de políticas.
/// Incluye caché en memoria para evitar llamadas repetidas durante la sesión.
class PoliticaService {
  // ── Caché ─────────────────────────────────────────────────────────────────
  static final Map<String, String> _nombreCache = {};
  static final Map<String, Map<String, String>> _nodeNamesCache = {};

  // ─────────────────────────────────────────────────────────────────────────
  /// Retorna el nombre legible de la política (ej. "Proceso de Matrícula").
  static Future<String> getPoliticaNombre(String politicaId) async {
    if (_nombreCache.containsKey(politicaId)) return _nombreCache[politicaId]!;
    await _fetchAndCache(politicaId);
    return _nombreCache[politicaId] ?? politicaId;
  }

  /// Retorna un mapa { nodoKey → "Nombre Tarea • Departamento" }.
  static Future<Map<String, String>> getNodeNames(String politicaId) async {
    if (_nodeNamesCache.containsKey(politicaId)) {
      return _nodeNamesCache[politicaId]!;
    }
    await _fetchAndCache(politicaId);
    return _nodeNamesCache[politicaId] ?? {};
  }

  // ── Internos ──────────────────────────────────────────────────────────────
  static Future<void> _fetchAndCache(String politicaId) async {
    try {
      final response = await ApiClient.get(
          '${AppConstants.politicaEndpoint}/$politicaId');

      if (response.statusCode != 200) {
        _nombreCache.putIfAbsent(politicaId, () => politicaId);
        _nodeNamesCache.putIfAbsent(politicaId, () => {});
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Nombre de la política
      _nombreCache[politicaId] = data['nombre'] as String? ?? politicaId;

      // Parsear esquemaJson para resolver nombres de nodos
      final esquemaRaw = data['esquemaJson'];
      if (esquemaRaw == null) {
        _nodeNamesCache[politicaId] = {};
        return;
      }

      final Map<String, dynamic> schema =
          esquemaRaw is String ? json.decode(esquemaRaw) : esquemaRaw;

      final List<dynamic> nodeArray =
          schema['nodeDataArray'] as List<dynamic>? ?? [];

      // 1. Construir mapa key → NodeInfo
      final Map<String, _NodeInfo> nodeMap = {};
      for (final n in nodeArray) {
        final key = n['key']?.toString() ?? '';
        if (key.isEmpty) continue;
        nodeMap[key] = _NodeInfo(
          key: key,
          text: n['text'] as String? ?? key,
          group: n['group']?.toString(),
        );
      }

      // 2. Construir mapa key → display name con departamento
      final Map<String, String> names = {};
      for (final entry in nodeMap.entries) {
        final node = entry.value;
        final groupNode =
            node.group != null ? nodeMap[node.group!] : null;

        if (groupNode != null && groupNode.text.isNotEmpty) {
          names[entry.key] = '${node.text} • ${groupNode.text}';
        } else {
          names[entry.key] = node.text;
        }
      }

      _nodeNamesCache[politicaId] = names;
    } catch (_) {
      // Ante cualquier error, dejamos caché vacío; la UI mostrará el ID
      _nombreCache.putIfAbsent(politicaId, () => politicaId);
      _nodeNamesCache.putIfAbsent(politicaId, () => {});
    }
  }

  /// Limpia la caché (útil al hacer logout).
  static void clearCache() {
    _nombreCache.clear();
    _nodeNamesCache.clear();
  }
}
