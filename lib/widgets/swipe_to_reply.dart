import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0;
  final double _threshold = 70;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {
          _dragExtent = _animation.value * _dragExtent;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Only allow swiping to the right
    if (details.delta.dx > 0 || _dragExtent > 0) {
      setState(() {
        _dragExtent += details.delta.dx * 0.5; // Friction
        if (_dragExtent < 0) _dragExtent = 0;
        if (_dragExtent > _threshold * 1.5) _dragExtent = _threshold * 1.5;
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent >= _threshold) {
      widget.onReply();
      // Simple haptic feedback simulation
      Feedback.forLongPress(context);
    }
    _controller.reverse(from: _dragExtent / (_threshold * 1.5));
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (_dragExtent / _threshold).clamp(0.0, 1.0);
    final scale = (0.5 + 0.5 * opacity).clamp(0.5, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Reply Indicator
          Positioned(
            left: _dragExtent - 40,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.reply_rounded,
                    color: AppTheme.secondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Bubbles
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
