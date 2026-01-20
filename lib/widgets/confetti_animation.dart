// lib/widgets/confetti_animation.dart

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class ConfettiAnimation extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback? onComplete;

  const ConfettiAnimation({
    Key? key,
    required this.isPlaying,
    this.onComplete,
  }) : super(key: key);

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    if (widget.isPlaying) {
      _confettiController.play();
    }
  }

  @override
  void didUpdateWidget(ConfettiAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _confettiController.play();
      Future.delayed(const Duration(seconds: 3), () {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _confettiController.stop();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiWidget(
      confettiController: _confettiController,
      blastDirection: -pi / 2, // Verso l'alto (90 gradi)
      blastDirectionality: BlastDirectionality.explosive,
      maxBlastForce: 20,
      minBlastForce: 8,
      emissionFrequency: 0.05,
      numberOfParticles: 50,
      gravity: 0.2,
      shouldLoop: false,
      colors: const [
        Colors.green,
        Colors.blue,
        Colors.pink,
        Colors.orange,
        Colors.purple,
        Colors.yellow,
        Colors.red,
      ],
      // RIMOSSI strokeWidth e strokeColor che non esistono!
    );
  }
}
