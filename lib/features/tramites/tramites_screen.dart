import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/firebase/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/notificacion_service.dart';
import '../../services/politica_service.dart';
import '../../services/tramite_service.dart';
import '../auth/login_screen.dart';
import '../consulta_politica/consulta_politica_screen.dart';
import '../ia_voz/voz_a_texto_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import 'models/tramite_model.dart';

// ── DTO interno con nombres resueltos ─────────────────────────────────────────
class _TramiteDisplay {
  final TramiteModel tramite;
  final String politicaNombre;
  final List<String> nodosNombres; // nombres legibles de nodos actuales

  _TramiteDisplay({
    required this.tramite,
    required this.politicaNombre,
    required this.nodosNombres,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────
class TramitesScreen extends StatefulWidget {
  const TramitesScreen({super.key});

  @override
  State<TramitesScreen> createState() => _TramitesScreenState();
}

class _TramitesScreenState extends State<TramitesScreen> {
  List<_TramiteDisplay> _tramites = [];
  bool _loading = true;
  String? _error;
  int _noLeidas = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Polling cada 10 segundos
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadData(silent: true),
    );

    // Refresh inmediato al recibir push foreground
    PushNotificationService.onNewMessage = () {
      if (mounted) _loadData(silent: true);
    };
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    // Limpiar callback solo si sigue siendo el nuestro
    PushNotificationService.onNewMessage = null;
    super.dispose();
  }

  // ── Carga de datos ─────────────────────────────────────────────────────────
  Future<void> _loadData({bool silent = false}) async {
    if (!silent && mounted) setState(() { _loading = true; _error = null; });

    try {
      final tramites = await TramiteService.getTramites();
      final List<_TramiteDisplay> displays = [];

      for (final t in tramites) {
        final politicaNombre =
            await PoliticaService.getPoliticaNombre(t.politicaId);
        final nodeNames = await PoliticaService.getNodeNames(t.politicaId);
        final nodosNombres = t.nodosActualesKeys
            .map((k) => nodeNames[k] ?? k)
            .toList();
        displays.add(_TramiteDisplay(
          tramite: t,
          politicaNombre: politicaNombre,
          nodosNombres: nodosNombres,
        ));
      }

      // Badge de notificaciones no leídas
      int noLeidas = 0;
      try {
        final notifs = await NotificacionService.getNotificaciones();
        noLeidas = notifs.where((n) => !n.leida).length;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _tramites = displays;
          _noLeidas = noLeidas;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() { _loading = false; _error = e.toString(); });
      }
    }
  }

  Future<void> _logout() async {
    _refreshTimer?.cancel();
    PushNotificationService.onNewMessage = null;
    PoliticaService.clearCache();
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mis Trámites'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bell con badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Notificaciones',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificacionesScreen()),
                  );
                  _loadData(silent: true); // refrescar badge al volver
                },
              ),
              if (_noLeidas > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _noLeidas > 9 ? '9+' : '$_noLeidas',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Recomendación de trámites (IA)',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ConsultaPoliticaScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mic_none),
            tooltip: 'Grabar nota de voz',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VozATextoScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VozATextoScreen()),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mic),
        label: const Text('Nota de Voz'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1565C0)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tramites.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF1565C0),
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No tienes trámites registrados.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF1565C0),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _tramites.length,
        itemBuilder: (context, index) =>
            _TramiteCard(display: _tramites[index]),
      ),
    );
  }
}

// ── Tarjeta individual ────────────────────────────────────────────────────────
class _TramiteCard extends StatelessWidget {
  final _TramiteDisplay display;
  const _TramiteCard({required this.display});

  TramiteModel get t => display.tramite;

  Color get _color {
    switch (t.estadoActual.toUpperCase()) {
      case 'FINALIZADO':
        return Colors.green.shade600;
      case 'EN_PROCESO':
        return Colors.blue.shade600;
      case 'INICIADO':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData get _icon {
    switch (t.estadoActual.toUpperCase()) {
      case 'FINALIZADO':
        return Icons.check_circle_outline;
      case 'EN_PROCESO':
        return Icons.autorenew;
      case 'INICIADO':
        return Icons.play_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  String get _estadoLabel {
    switch (t.estadoActual.toUpperCase()) {
      case 'FINALIZADO':
        return 'Finalizado';
      case 'EN_PROCESO':
        return 'En proceso';
      case 'INICIADO':
        return 'Iniciado';
      default:
        return t.estadoActual;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaInicio =
        '${t.fechaInicio.day.toString().padLeft(2, '0')}/'
        '${t.fechaInicio.month.toString().padLeft(2, '0')}/'
        '${t.fechaInicio.year}';

    // Nombre de nodos activos (o "Sin asignar")
    final nodosText = display.nodosNombres.isNotEmpty
        ? display.nodosNombres.join(' • ')
        : 'Sin asignar';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado: nombre política + badge estado ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        display.politicaNombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${t.id.length > 8 ? t.id.substring(0, 8) : t.id}…',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Badge de estado
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _color),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_icon, size: 13, color: _color),
                      const SizedBox(width: 4),
                      Text(
                        _estadoLabel,
                        style: TextStyle(
                          color: _color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Nodo(s) actual(es) + fecha inicio ──────────────────────────
            Row(
              children: [
                const Icon(Icons.business_outlined,
                    size: 15, color: Color(0xFF1565C0)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    nodosText,
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  fechaInicio,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),

            // ── Fecha fin (si finalizado) ───────────────────────────────────
            if (t.fechaFin != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 13, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Finalizado: ${t.fechaFin!.day}/${t.fechaFin!.month}/${t.fechaFin!.year}',
                    style:
                        TextStyle(color: Colors.green.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
