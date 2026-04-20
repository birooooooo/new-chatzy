import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'stable_huggy_character.dart';

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

class _Huggy3DCharacterState extends State<Huggy3DCharacter>
    with SingleTickerProviderStateMixin {
  late final O3DController _o3dController;
  bool _useFallback = false;
  bool _isInitialized = false;
  String? _lastAnimatedMood;
  Timer? _autoCycleTimer;
  Timer? _returnToIdleTimer;
  bool _isPlayingAction = false;

  // ── All known animations in the GLB ──────────────────────────────────────
  static const String _idle        = 'SK_Huggy|A_Huggy_Idle_SK_Huggy';
  static const String _sitIdle     = 'SK_Huggy|A_Huggy_SitIdle_SK_Huggy';
  static const String _crouchIdle  = 'SK_Huggy|A_Huggy_CrouchIdle_SK_Huggy';
  static const String _intro       = 'SK_Huggy|A_Huggy_SelectScreenIntro_SK_Huggy';
  // Dedicated right-hand wave — stands still, loops the greeting wave
  static const String _wave        = 'SK_Huggy|A_Huggy_Wave_SK_Huggy';
  static const String _kiss        = 'SK_Huggy|A_Huggy_Kiss_SK_Huggy';
  static const String _alert       = 'SK_Huggy|A_Huggy_MiniAlert_SK_Huggy';
  static const String _punch       = 'SK_Huggy|A_SewerHuggy_Punch_SK_Huggy';
  static const String _walk        = 'SK_Huggy|A_Huggy_Walk_SK_Huggy';
  static const String _run         = 'SK_Huggy|A_Huggy_Run_SK_Huggy';
  static const String _jump        = 'SK_Huggy|A_Huggy_Jump_SK_Huggy';
  static const String _dance       = 'SK_Huggy|A_Huggy_Dance_SK_Huggy';
  static const String _celebrate   = 'SK_Huggy|A_Huggy_Celebrate_SK_Huggy';
  static const String _laugh       = 'SK_Huggy|A_Huggy_Laugh_SK_Huggy';
  static const String _grab        = 'SK_Huggy|A_SewerHuggy_Grab_SK_Huggy';
  static const String _sneak       = 'SK_Huggy|A_Huggy_Sneak_SK_Huggy';
  static const String _roar        = 'SK_Huggy|A_Huggy_Roar_SK_Huggy';
  static const String _lookAround  = 'SK_Huggy|A_Huggy_LookAround_SK_Huggy';
  static const String _taunt       = 'SK_Huggy|A_Huggy_Taunt_SK_Huggy';

  // Random idle pool — cycles automatically
  static const _idlePool = [_idle, _sitIdle, _crouchIdle, _lookAround];

  // Random action pool — triggered on tap
  static const _actionPool = [
    _intro, _kiss, _alert, _dance, _celebrate,
    _laugh, _jump, _taunt, _roar,
  ];

  @override
  void initState() {
    super.initState();
    _o3dController = O3DController();
    _isInitialized = true;
  }

  @override
  void dispose() {
    _autoCycleTimer?.cancel();
    _returnToIdleTimer?.cancel();
    super.dispose();
  }

  bool get _isWaving {
    final m = widget.mood.toLowerCase();
    return m == 'hi' || m == 'wave' || m == 'waving' || m == 'hello';
  }

  // ── Tap → random action, then return to idle ──────────────────────────────
  void _onTap() {
    if (_isPlayingAction) return;
    final action = _actionPool[Random().nextInt(_actionPool.length)];
    _playAction(action);
  }

  void _playAction(String anim, {int durationMs = 2500}) {
    _isPlayingAction = true;
    _playAnim(anim, loop: false);
    _returnToIdleTimer?.cancel();
    _returnToIdleTimer = Timer(Duration(milliseconds: durationMs), () {
      if (mounted) {
        _isPlayingAction = false;
        _playAnim(_idle, loop: true);
      }
    });
  }

  void _playAnim(String name, {bool loop = true}) {
    if (!mounted || !_isInitialized) return;
    setState(() {
      _o3dController.animationName = name;
    });
    // Defer play() to next frame so the O3D widget JS bridge is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _o3dController.play();
      } catch (_) {}
    });
  }

  // ── Mood → animation ──────────────────────────────────────────────────────
  @override
  void didUpdateWidget(covariant Huggy3DCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_useFallback &&
        (oldWidget.mood != widget.mood ||
            oldWidget.isChatting != widget.isChatting)) {
      _applyMood();
    }
  }

  void _applyMood() {
    final mood = widget.mood.toLowerCase();
    final isAction = _actionMoods.contains(mood);

    if (mood == 'neutral') {
      // Reset so the same mood can re-trigger next time
      _lastAnimatedMood = null;
      _isPlayingAction = false;
      _playAnim(_idle, loop: true);
      return;
    }

    if (isAction) {
      _lastAnimatedMood = mood;
      _playAction(_moodToAnim(mood), durationMs: _moodDuration(mood));
    } else {
      _isPlayingAction = false;
      _lastAnimatedMood = mood;
      _playAnim(_moodToAnim(mood), loop: true);
    }
  }

  static const _actionMoods = {
    'angry', 'mad', 'surprised', 'kiss',
    'dance', 'celebrate', 'laugh', 'jump', 'grab', 'roar', 'taunt',
    // 'hi', 'waving', 'hello' are NOT action moods — they loop continuously
    // 'recording'/'talking' are NOT here — they loop while mic is active
  };

  String _moodToAnim(String mood) {
    switch (mood) {
      // ── Positive ──
      case 'happy':
      case 'smile':       return _intro;
      case 'hi':
      case 'wave':
      case 'waving':
      case 'hello':       return _wave;
      case 'kiss':        return _kiss;
      case 'laugh':       return _laugh;
      case 'celebrate':   return _celebrate;
      case 'dance':       return _dance;

      // ── Negative ──
      case 'sad':
      case 'sleeping':    return _sitIdle;
      case 'angry':
      case 'mad':         return _punch;
      case 'roar':        return _roar;
      case 'recording':
      case 'talking':     return _roar;
      case 'grab':        return _grab;

      // ── Neutral ──
      case 'surprised':   return _alert;
      case 'thinking':    return _crouchIdle;
      case 'sneak':       return _sneak;
      case 'taunt':       return _taunt;

      // ── Movement ──
      case 'walk':
      case 'walking':     return _walk;
      case 'run':
      case 'running':     return _run;
      case 'jump':        return _jump;

      default:            return _idle;
    }
  }

  int _moodDuration(String mood) {
    switch (mood) {
      case 'dance':       return 5000;
      case 'celebrate':   return 3500;
      case 'roar':        return 3000;
      case 'grab':        return 3000;
      case 'laugh':       return 3000;
      default:            return 2500;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback) {
      return StableHuggyCharacter(mood: widget.mood, size: widget.size * 0.8);
    }

    return GestureDetector(
      onTap: _onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size * 1.5,
            child: O3D(
              controller: _o3dController,
              src: 'assets/models/huggy_wuggy.glb',
              autoPlay: true,
              animationName: _moodToAnim(widget.mood.toLowerCase()),
              autoRotate: false,
              ar: false,
              cameraControls: false,
              shadowIntensity: 0.5,
            ),
          ),

          // Tap hint — fades in briefly then hides
          Positioned(
            bottom: 8,
            child: _TapHint(),
          ),
        ],
      ),
    );
  }
}

// Small "tap me" hint that fades out after 3 seconds
class _TapHint extends StatefulWidget {
  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // Show for 3s then fade out
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.0).animate(_ctrl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, color: Colors.white70, size: 14),
            SizedBox(width: 4),
            Text('Tap for moves',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
