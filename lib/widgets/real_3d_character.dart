import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';

class Real3DCharacter extends StatefulWidget {
  final String mood;
  final double? size;

  const Real3DCharacter({
    super.key,
    required this.mood,
    this.size,
  });

  @override
  State<Real3DCharacter> createState() => _Real3DCharacterState();
}

class _Real3DCharacterState extends State<Real3DCharacter> with TickerProviderStateMixin {
  Object? _character;
  bool _isLoading = true;
  String? _error;
  
  late AnimationController _idleController;
  late AnimationController _fadeController;
  late AnimationController _moodController;
  
  late Animation<double> _breatheAnimation;
  late Animation<double> _swayAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _greetAnimation; // For nodding/waving
  late Animation<double> _kissAnimation;  // For scale pulse
  late Animation<double> _danceAnimation; // For bounce

  @override
  void initState() {
    super.initState();
    
    _idleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );
    
    _swayAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _moodController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
    );
    
    _greetAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween<double>(begin: 0, end: 15).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
        TweenSequenceItem(tween: Tween<double>(begin: 15, end: 0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_moodController);

    _kissAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
        TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_moodController);

    _danceAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween<double>(begin: 0, end: -40).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
        TweenSequenceItem(tween: Tween<double>(begin: -40, end: 0).chain(CurveTween(curve: Curves.bounceOut)), weight: 50),
    ]).animate(_moodController);
    
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use character.obj as discovered in the models directory
      final obj = Object(fileName: 'assets/models/character.obj');
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (mounted) {
        setState(() {
          _character = obj;
          _character!.scale.setValues(5.5, 5.5, 5.5);
          _character!.rotation.setValues(0, 0, 0);
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _fadeController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Real3DCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood && _character != null) {
      _moodController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idleController, _fadeController, _moodController]),
      builder: (context, child) {
        double verticalOffset = 0;
        
        if (_character != null) {
          // Default Breathing Scale
          double currentScale = 5.5 * _breatheAnimation.value;
          
          // Apply Kiss Pulse
          if (widget.mood == 'kiss') {
             currentScale *= _kissAnimation.value;
          }
          
          _character!.scale.setValues(currentScale, currentScale, currentScale);
          
          // Handle Rotation and Movement
          switch (widget.mood) {
            case 'happy':
              _character!.rotation.y = _swayAnimation.value * 5 + (_moodController.value * 360);
              verticalOffset = _danceAnimation.value;
              break;
            case 'waving':
            case 'greeting':
              _character!.rotation.x = _greetAnimation.value; // Nodding
              _character!.rotation.y = _swayAnimation.value;
              break;
            case 'kiss':
              _character!.rotation.x = -_greetAnimation.value; // Leaning forward
              break;
            default:
              _character!.rotation.y = _swayAnimation.value;
          }
        }

        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, verticalOffset), // Applied vertical bounce
            child: SizedBox(
              width: widget.size ?? MediaQuery.of(context).size.width * 0.8,
              height: widget.size ?? MediaQuery.of(context).size.width * 0.8,
              child: Stack(
                children: [
                   if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.white))
                  else if (_error != null)
                    Center(child: Icon(Icons.error, color: Colors.white.withOpacity(0.5)))
                  else if (_character != null)
                    Cube(
                      onSceneCreated: (Scene scene) {
                        scene.world.add(_character!);
                        scene.camera.zoom = 5;
                        scene.camera.position.setValues(0, 0, 15);
                        scene.light.position.setValues(0, 10, 10);
                      },
                      interactive: false,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
