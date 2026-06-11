import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/consulta_service.dart';
import 'models/recomendacion_model.dart';

/// Módulo de Recomendación Inteligente de Trámites (frontend Flutter).
///
/// Equivalente a `ConsultaPoliticaComponent` de Angular:
///  - Botón de grabación (flutter_sound, análogo a MediaRecorder).
///  - Área de texto manual.
///  - Al recibir el JSON, "patchValue" → puebla los campos del formulario.
///  - Card con la política recomendada y botones para las subOpciones.
///  - Spinner de carga mientras la IA procesa.
class ConsultaPoliticaScreen extends StatefulWidget {
  const ConsultaPoliticaScreen({super.key});

  @override
  State<ConsultaPoliticaScreen> createState() => _ConsultaPoliticaScreenState();
}

class _ConsultaPoliticaScreenState extends State<ConsultaPoliticaScreen>
    with SingleTickerProviderStateMixin {
  static const _azul = Color(0xFF1565C0);

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  // "Formulario": estos controladores se pueblan con patchValue() (_patchValue).
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _transcripcionCtrl = TextEditingController();
  final TextEditingController _politicaCtrl = TextEditingController();
  final TextEditingController _razonCtrl = TextEditingController();

  bool _recorderReady = false;
  bool _isRecording = false;
  bool _isLoading = false;
  String? _audioPath;

  RecomendacionResponse? _resultado;
  String? _subOpcionSeleccionada;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;
    await _recorder.openRecorder();
    if (mounted) setState(() => _recorderReady = true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _recorder.closeRecorder();
    _textController.dispose();
    _transcripcionCtrl.dispose();
    _politicaCtrl.dispose();
    _razonCtrl.dispose();
    super.dispose();
  }

  // ── patchValue(): puebla los campos del formulario con el JSON ────────────
  void _patchValue(RecomendacionResponse r) {
    setState(() {
      _resultado = r;
      _subOpcionSeleccionada = null;
      _transcripcionCtrl.text = r.transcripcion;
      _politicaCtrl.text = r.politicaRecomendada;
      _razonCtrl.text = r.razon;
      if (_textController.text.trim().isEmpty) {
        _textController.text = r.transcripcion;
      }
    });
  }

  // ── Grabación (MediaRecorder API equivalente) ─────────────────────────────
  Future<void> _startRecording() async {
    if (!_recorderReady) {
      _snack('Permiso de micrófono denegado', Colors.red);
      return;
    }
    final dir = await getTemporaryDirectory();
    _audioPath =
        '${dir.path}/consulta_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.startRecorder(toFile: _audioPath, codec: Codec.pcm16WAV);
    setState(() => _isRecording = true);
    _pulseCtrl.repeat(reverse: true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    setState(() => _isRecording = false);
    if (_audioPath != null) {
      await _enviar(audio: File(_audioPath!));
    }
  }

  // ── Envío al backend ──────────────────────────────────────────────────────
  Future<void> _enviarTexto() async {
    final texto = _textController.text.trim();
    if (texto.isEmpty) {
      _snack('Escribe tu consulta o graba un audio', Colors.orange);
      return;
    }
    await _enviar(texto: texto);
  }

  Future<void> _enviar({File? audio, String? texto}) async {
    setState(() {
      _isLoading = true;
      _resultado = null;
    });
    try {
      final r = audio != null
          ? await ConsultaService.recomendarPorAudio(audio)
          : await ConsultaService.recomendarPorTexto(texto!);
      _patchValue(r);
    } catch (e) {
      if (mounted) _snack(e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Recomendación de Trámites'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isRecording
                  ? '🎙 Grabando... describe tu trámite'
                  : 'Describe tu necesidad por voz o texto y la IA te recomendará el trámite adecuado.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildMicButton(),
            const SizedBox(height: 24),
            _buildTextInput(),
            const SizedBox(height: 16),
            if (_isLoading) _buildSpinner() else _buildResultado(),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _isRecording ? _pulseAnim.value : 1.0,
            child: GestureDetector(
              onTap: _isLoading
                  ? null
                  : (_isRecording ? _stopRecording : _startRecording),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : _azul,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : _azul)
                          .withOpacity(0.35),
                      blurRadius: 22,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic,
                  size: 46,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isRecording ? 'Toca para detener y enviar' : 'Toca para grabar',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _textController,
          maxLines: 4,
          minLines: 3,
          decoration: InputDecoration(
            hintText: 'O escribe aquí tu consulta...',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _enviarTexto,
          icon: const Icon(Icons.send),
          label: const Text('Consultar por texto'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            backgroundColor: _azul,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSpinner() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircularProgressIndicator(color: _azul),
          SizedBox(height: 12),
          Text('La IA está procesando tu consulta…',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    final r = _resultado;
    if (r == null) return const SizedBox.shrink();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.recommend, color: _azul),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.politicaRecomendada.isEmpty
                        ? 'Sin recomendación'
                        : r.politicaRecomendada,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _azul,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (r.razon.isNotEmpty)
              Text(r.razon,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800])),
            const Divider(height: 24),
            if (r.transcripcion.isNotEmpty) ...[
              const Text('Transcripción:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Text(r.transcripcion,
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey[700])),
              const SizedBox(height: 14),
            ],
            if (r.subOpciones.isNotEmpty) ...[
              const Text('Sub-opciones / pasos sugeridos:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: r.subOpciones.map(_buildSubOpcionBtn).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (_subOpcionSeleccionada != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Seleccionaste: $_subOpcionSeleccionada',
                    style: const TextStyle(color: _azul)),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Modelo: ${r.modeloUtilizado}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubOpcionBtn(String texto) {
    final seleccionada = _subOpcionSeleccionada == texto;
    return OutlinedButton(
      onPressed: () => setState(() => _subOpcionSeleccionada = texto),
      style: OutlinedButton.styleFrom(
        backgroundColor: seleccionada ? _azul : Colors.white,
        foregroundColor: seleccionada ? Colors.white : _azul,
        side: const BorderSide(color: _azul),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(texto),
    );
  }
}
