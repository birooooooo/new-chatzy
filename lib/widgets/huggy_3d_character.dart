import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'stable_huggy_character.dart';
import 'dart:io';

class Huggy3DCharacter extends StatefulWidget {
  final String mood;
  final double size;
  final bool isChatting;

  const Huggy3DCharacter({
    super.key,
    required this.mood,
    this.size = 300,
    this.isChatting = false,
  });

  @override
  State<Huggy3DCharacter> createState() => _Huggy3DCharacterState();
}

class _Huggy3DCharacterState extends State<Huggy3DCharacter> {
  late final O3DController _o3dController;
  bool _useFallback = false;
  bool _isInitialized = false;
  String? _lastAnimatedMood;

  @override
  void initState() {
    super.initState();
    _o3dController = O3DController();
    _checkHardwareAndInit();
  }

  Future<void> _checkHardwareAndInit() async {
    // Force 3D initialization on all devices as requested
    if (mounted) setState(() => _isInitialized = true);
  }

  @override
  void didUpdateWidget(covariant Huggy3DCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_useFallback && (oldWidget.mood != widget.mood || oldWidget.isChatting != widget.isChatting)) {
      _triggerAnimation();
    }
  }

  void _triggerAnimation() {
    final newAnim = _getAnimationName();
    
    // Check if this is a "Play Once" action mood
    final isActionOnce = ['waving', 'mad', 'angry', 'surprised', 'kiss'].contains(widget.mood.toLowerCase());
    
    if (isActionOnce) {
      if (_lastAnimatedMood != widget.mood) {
        _o3dController.animationName = newAnim;
        _o3dController.play();
        _lastAnimatedMood = widget.mood;
        
        // Return to idle after the animation duration
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) {
            setState(() {
              _lastAnimatedMood = 'idle';
              _o3dController.animationName = 'SK_Huggy|A_Huggy_Idle_SK_Huggy';
            });
          }
        });
      }
    } else {
      _o3dController.animationName = newAnim;
      _lastAnimatedMood = widget.mood;
    }
  }

  String _getAnimationName() {
    switch (widget.mood.toLowerCase()) {
      case 'happy':
      case 'smile':
        return 'SK_Huggy|A_Huggy_SelectScreenIntro_SK_Huggy';
      case 'waving':
      case 'hello':
        return 'SK_Huggy|A_Huggy_SelectScreenIntro_SK_Huggy';
      case 'sad':
      case 'sleeping':
        return 'SK_Huggy|A_Huggy_SitIdle_SK_Huggy';
      case 'angry':
      case 'mad':
        return 'SK_Huggy|A_SewerHuggy_Punch_SK_Huggy';
      case 'surprised':
        return 'SK_Huggy|A_Huggy_MiniAlert_SK_Huggy';
      case 'thinking':
        return 'SK_Huggy|A_Huggy_CrouchIdle_SK_Huggy';
      case 'kiss':
        return 'SK_Huggy|A_Huggy_Kiss_SK_Huggy';
      default:
        return 'SK_Huggy|A_Huggy_Idle_SK_Huggy';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback) {
      return StableHuggyCharacter(mood: widget.mood, size: widget.size * 0.8);
    }

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.5,
        child: O3D(
          controller: _o3dController,
          src: 'assets/models/huggy_wuggy.glb',
          autoPlay: true,
          animationName: _getAnimationName(),
          autoRotate: false,
          ar: false,
          cameraControls: false,
          shadowIntensity: 0.5,
        ),
      ),
    );
  }
}
