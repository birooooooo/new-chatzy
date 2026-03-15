import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'glass_container.dart';

class VoiceRecorder extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(String path, Duration duration) onSend;

  const VoiceRecorder({
    super.key,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> with TickerProviderStateMixin {
  late AnimationController _waveController;
  final List<double> _amplitudes = List.generate(30, (index) => 0.2);
  final math.Random _random = math.Random();
  
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _timer;
  int _seconds = 0;
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(() {
      setState(() {
        _amplitudes.removeAt(0);
        _amplitudes.add(0.2 + _random.nextDouble() * 0.8);
      });
    });
    _waveController.repeat();
    
    _startRecording();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = p.join(directory.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');
        _currentPath = path;

        const config = RecordConfig(); // Default values are fine

        await _audioRecorder.start(config, path: path);
        debugPrint("Recording started at: $path");
      } else {
        debugPrint("Microphone permission denied");
        widget.onCancel();
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
      widget.onCancel();
    }
  }

  Future<void> _stopAndSend() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        widget.onSend(path, Duration(seconds: _seconds));
      } else {
        widget.onCancel();
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
      widget.onCancel();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(30),
      blur: 20,
      gradient: LinearGradient(
        colors: [AppTheme.secondary.withOpacity(0.2), Colors.black.withOpacity(0.8)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () async {
              await _audioRecorder.stop();
              widget.onCancel();
            },
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(_seconds),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _amplitudes.map((amp) {
                  return Container(
                    width: 3,
                    height: 40 * amp,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(amp),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _stopAndSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 24),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 500.ms),
        ],
      ),
    );
  }
}
