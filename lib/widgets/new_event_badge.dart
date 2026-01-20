import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NewEventBadge extends StatelessWidget {
  final bool show;

  const NewEventBadge({
    super.key,
    this.show = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .shimmer(
          duration: 1500.ms,
          color: Colors.white.withOpacity(0.5),
        );
  }
}
