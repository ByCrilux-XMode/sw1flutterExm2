import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/hugging_face_service.dart';

class VozATextoScreen extends StatefulWidget {
  const VozATextoScreen({super.key});

  @override
  State<VozATextoScreen> createState() => _VozATextoScreenState();
}

class _VozATextoScreenState extends State<VozATextoScreen>
    with SingleTickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final TextEditingController _textController = TextEditingController();

  bool _recorderReady = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _audioPath;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
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
    super.dispose();
  }

  // ── Grabación ─────────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    if (!_recorderReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de micrófono denegado')),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    _audioPath =
        '${dir.path}/nota_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.startRecorder(
      toFile: _audioPath,
      codec: Codec.pcm16WAV,
    );

    setState(() => _isRecording = true);
    _pulseCtrl.repeat(reverse: true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    setState(() => _isRecording = false);

    if (_audioPath != null) {
      await _transcribe(File(_audioPath!));
    }
  }

  Future<void> _transcribe(File audio) async {
    setState(() {
      _isTranscribing = true;
      _textController.clear();
    });
    try {
      final texto = await HuggingFaceService.transcribirAudio(audio);
      setState(() => _textController.text = texto);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTranscribing = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nota de Voz'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(
              _isRecording
                  ? '🎙 Grabando... habla ahora'
                  : _isTranscribing
                      ? 'Procesando con IA...'
                      : 'Toca el micrófono para grabar tu queja o nota',
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // Botón animado
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _isRecording ? _pulseAnim.value : 1.0,
                child: GestureDetector(
                  onTap: _isTranscribing
                      ? null
                      : (_isRecording ? _stopRecording : _startRecording),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.red
                          : const Color(0xFF1565C0),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording
                                  ? Colors.red
                                  : const Color(0xFF1565C0))
                              .withOpacity(0.35),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isRecording ? 'Toca para detener' : 'Toca para grabar',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Resultado / transcripción
            if (_isTranscribing) ...[
              const CircularProgressIndicator(color: Color(0xFF1565C0)),
              const SizedBox(height: 12),
              const Text('Transcribiendo audio con IA…',
                  style: TextStyle(color: Colors.grey)),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Texto transcrito (editable):',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.grey[800]),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText:
                        'El texto aparecerá aquí después de grabar...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_textController.text.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: enviar nota al backend
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('✅ Nota enviada'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar Nota'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
