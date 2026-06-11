import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/firebase/firebase_service.dart';
import '../../services/notificacion_service.dart';
import 'models/notificacion_model.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<NotificacionModel> _notifs = [];
  bool _loading = true;
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
    PushNotificationService.onNewMessage = null;
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final notifs = await NotificacionService.getNotificaciones();
      if (mounted) setState(() { _notifs = notifs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _marcarLeida(NotificacionModel n) async {
    if (n.leida) return;
    try {
      await NotificacionService.marcarComoLeida(n.id);
      _loadData(silent: true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _notifs.isEmpty
              ? RefreshIndicator(
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
                            Icon(Icons.notifications_none,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Sin notificaciones',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF1565C0),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = _notifs[index];
                      final fecha =
                          '${n.fechaCreacion.day.toString().padLeft(2, '0')}/'
                          '${n.fechaCreacion.month.toString().padLeft(2, '0')}/'
                          '${n.fechaCreacion.year}  '
                          '${n.fechaCreacion.hour.toString().padLeft(2, '0')}:'
                          '${n.fechaCreacion.minute.toString().padLeft(2, '0')}';

                      return Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.startToEnd,
                        background: Container(
                          padding: const EdgeInsets.only(left: 20),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.done, color: Colors.green.shade700),
                        ),
                        onDismissed: (_) => _marcarLeida(n),
                        child: Card(
                          elevation: n.leida ? 1 : 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          color: n.leida
                              ? Colors.white
                              : const Color(0xFFE3F2FD),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: n.leida
                                  ? Colors.grey.shade200
                                  : const Color(0xFF1565C0),
                              child: Icon(
                                n.leida
                                    ? Icons.notifications_none
                                    : Icons.notifications_active,
                                color: n.leida ? Colors.grey : Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              n.titulo,
                              style: TextStyle(
                                fontWeight: n.leida
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(n.mensaje,
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  fecha,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                            trailing: n.leida
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.done,
                                        color: Color(0xFF1565C0)),
                                    tooltip: 'Marcar como leída',
                                    onPressed: () => _marcarLeida(n),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
