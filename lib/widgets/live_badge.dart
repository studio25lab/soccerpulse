import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LiveBadge extends StatelessWidget {
  final bool isLive;
  final bool pulseEffect;

  const LiveBadge({
    super.key,
    required this.isLive,
    this.pulseEffect = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLive) return const SizedBox.shrink();

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .fadeOut(
                duration: 1000.ms,
              )
              .then()
              .fadeIn(
                duration: 1000.ms,
              ),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (pulseEffect) {
      return badge
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .scale(
            duration: 1500.ms,
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.1, 1.1),
          )
          .then()
          .scale(
            duration: 1500.ms,
            begin: const Offset(1.1, 1.1),
            end: const Offset(1.0, 1.0),
          );
    }

    return badge;
  }
}
