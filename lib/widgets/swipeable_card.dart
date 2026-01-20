import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../services/haptic_service.dart';

class SwipeableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final String? leftActionLabel;
  final String? rightActionLabel;
  final IconData? leftActionIcon;
  final IconData? rightActionIcon;
  final Color? leftActionColor;
  final Color? rightActionColor;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftActionLabel,
    this.rightActionLabel,
    this.leftActionIcon,
    this.rightActionIcon,
    this.leftActionColor,
    this.rightActionColor,
  });

  @override
  Widget build(BuildContext context) {
    final haptic = HapticService();

    return Slidable(
      key: key,
      startActionPane: onSwipeRight != null
          ? ActionPane(
              motion: const StretchMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (context) {
                    haptic.medium();
                    onSwipeRight!();
                  },
                  backgroundColor: rightActionColor ?? Colors.green,
                  foregroundColor: Colors.white,
                  icon: rightActionIcon ?? Icons.check,
                  label: rightActionLabel ?? 'Confirm',
                ),
              ],
            )
          : null,
      endActionPane: onSwipeLeft != null
          ? ActionPane(
              motion: const StretchMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (context) {
                    haptic.medium();
                    onSwipeLeft!();
                  },
                  backgroundColor: leftActionColor ?? Colors.red,
                  foregroundColor: Colors.white,
                  icon: leftActionIcon ?? Icons.delete,
                  label: leftActionLabel ?? 'Delete',
                ),
              ],
            )
          : null,
      child: child,
    );
  }
}

// Card con gesture detector personalizzato
class GestureCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const GestureCard({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<GestureCard> createState() => _GestureCardState();
}

class _GestureCardState extends State<GestureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final haptic = HapticService();
  double _dragOffset = 0;

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          haptic.light();
          widget.onTap!();
        }
      },
      onDoubleTap: () {
        if (widget.onDoubleTap != null) {
          haptic.medium();
          widget.onDoubleTap!();
        }
      },
      onLongPress: () {
        if (widget.onLongPress != null) {
          haptic.heavy();
          widget.onLongPress!();
        }
      },
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset > 100 && widget.onSwipeRight != null) {
          haptic.medium();
          widget.onSwipeRight!();
        } else if (_dragOffset < -100 && widget.onSwipeLeft != null) {
          haptic.medium();
          widget.onSwipeLeft!();
        }
        setState(() {
          _dragOffset = 0;
        });
      },
      child: Transform.translate(
        offset: Offset(_dragOffset * 0.1, 0),
        child: widget.child,
      ),
    );
  }
}
