class AppConstants {
  // Base URL del backend Spring Boot
  // Emulador Android → 10.0.2.2 apunta al localhost del PC
  // Dispositivo físico → usa tu IP local, ej: 192.168.1.X
  static const String baseUrl = 'https://sw1backendexm2-614166022463.southamerica-east1.run.app';

  // ── Auth ──────────────────────────────────────────────────────────────────
  // POST  body: { "username": "...", "password": "..." }
  // resp: { "token": "...", "username": "...", "rol": "...", "userId": "..." }
  static const String loginEndpoint = '/api/auth/login';

  // ── Trámites ──────────────────────────────────────────────────────────────
  // GET /api/tramite/cliente/{clienteId}  →  List<Tramite>
  static const String tramitesClienteEndpoint = '/api/tramite/cliente';

  // ── Notificaciones ────────────────────────────────────────────────────────
  // GET /api/notificaciones/cliente/{clienteId}
  static const String notificacionesClienteEndpoint =
      '/api/notificaciones/cliente';
  // PUT /api/notificaciones/{id}/leer
  static const String notificacionLeerEndpoint = '/api/notificaciones';

  // ── Usuarios ──────────────────────────────────────────────────────────────
  // PATCH /api/usuarios/{userId}/token-dispositivo?token=<fcmToken>
  static const String usuariosEndpoint = '/api/usuarios';

  // ── Políticas ─────────────────────────────────────────────────────────────
  // GET /api/politica/{id}  →  { id, nombre, objetivo, esquemaJson, ... }
  static const String politicaEndpoint = '/api/politica';

  // ── HuggingFace / Gradio ─────────────────────────────────────────────────
  static const String huggingFaceUrl =
      'https://alexsolizduran-ia-voztotext.hf.space/api/predict';

  // ── Recomendación Inteligente de Trámites ────────────────────────────────
  // POST multipart (audio y/o texto) → JSON con la política recomendada.
  static const String recomendarConsultaEndpoint = '/api/consultas/recomendar';
}
