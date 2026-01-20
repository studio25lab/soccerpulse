// lib/widgets/glassmorphic_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth; // ADDED
  final Color? borderColor;
  final double blur;
  final double opacity;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const GlassmorphicCard({
    Key? key,
    required this.child,
    this.borderRadius = 16.0,
    this.borderWidth = 1.0, // ADDED with default
    this.borderColor,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.backgroundColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ??
                (isDark
                    ? Colors.white.withOpacity(opacity)
                    : Colors.black.withOpacity(opacity * 0.5)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ??
                  (isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1)),
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );
  }
}
