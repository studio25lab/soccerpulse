import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/haptic_service.dart';

class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final ButtonStyle style;
  final Color? color;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.style = ButtonStyle.primary,
    this.color,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final haptic = HapticService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.isDisabled && !widget.isLoading;
    final buttonColor = widget.color ?? Theme.of(context).primaryColor;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _controller.forward() : null,
      onTapUp: isEnabled ? (_) => _controller.reverse() : null,
      onTapCancel: () => _controller.reverse(),
      onTap: isEnabled
          ? () {
              haptic.medium();
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_controller.value * 0.05),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? LinearGradient(
                    colors: _getGradientColors(buttonColor),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isEnabled ? null : Colors.grey[400],
            borderRadius: BorderRadius.circular(16),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: buttonColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getTextColor(),
                    ),
                  ),
                )
              else if (widget.icon != null)
                Icon(
                  widget.icon,
                  color: _getTextColor(),
                  size: 20,
                ),
              if ((widget.isLoading || widget.icon != null))
                const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: _getTextColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.2, end: 0, duration: 300.ms);
  }

  List<Color> _getGradientColors(Color baseColor) {
    switch (widget.style) {
      case ButtonStyle.primary:
        return [baseColor, baseColor.withOpacity(0.8)];
      case ButtonStyle.secondary:
        return [
          baseColor.withOpacity(0.2),
          baseColor.withOpacity(0.1),
        ];
      case ButtonStyle.danger:
        return [Colors.red, Colors.red.withOpacity(0.8)];
      case ButtonStyle.success:
        return [Colors.green, Colors.green.withOpacity(0.8)];
    }
  }

  Color _getTextColor() {
    if (widget.isDisabled) return Colors.white;

    switch (widget.style) {
      case ButtonStyle.primary:
      case ButtonStyle.danger:
      case ButtonStyle.success:
        return Colors.white;
      case ButtonStyle.secondary:
        return widget.color ?? Theme.of(context).primaryColor;
    }
  }
}

enum ButtonStyle {
  primary,
  secondary,
  danger,
  success,
}
