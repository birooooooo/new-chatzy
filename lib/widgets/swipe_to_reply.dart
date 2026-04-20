import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    this.onDelete,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  final double _threshold = 70;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx * 0.5;
      // Clamp: positive = right (reply), negative = left (delete)
      if (_dragExtent > _threshold * 1.5) _dragExtent = _threshold * 1.5;
      if (_dragExtent < -_threshold * 1.5) _dragExtent = -_threshold * 1.5;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent >= _threshold) {
      widget.onReply();
      Feedback.forLongPress(context);
    } else if (_dragExtent <= -_threshold && widget.onDelete != null) {
      widget.onDelete!();
      Feedback.forLongPress(context);
    }
    // Snap back
    final startValue = _dragExtent;
    _controller.reset();
    _controller.addListener(() {
      if (mounted) setState(() => _dragExtent = startValue * (1 - _controller.value));
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Right swipe (reply)
    final replyOpacity = (_dragExtent / _threshold).clamp(0.0, 1.0);
    final replyScale = (0.5 + 0.5 * replyOpacity).clamp(0.5, 1.0);

    // Left swipe (delete)
    final deleteProgress = (-_dragExtent / _threshold).clamp(0.0, 1.0);
    final deleteScale = (0.5 + 0.5 * deleteProgress).clamp(0.5, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Reply indicator (left side, shown on swipe right)
          if (_dragExtent > 0)
            Positioned(
              left: _dragExtent - 40,
              child: Opacity(
                opacity: replyOpacity,
                child: Transform.scale(
                  scale: replyScale,
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

          // Delete indicator (right side, shown on swipe left)
          if (_dragExtent < 0)
            Positioned(
              right: -_dragExtent - 40,
              child: Opacity(
                opacity: deleteProgress,
                child: Transform.scale(
                  scale: deleteScale,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

          // Message bubble
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
