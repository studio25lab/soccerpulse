import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;
  final Widget? customIllustration;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color,
    this.customIllustration,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).primaryColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icona o illustrazione personalizzata
            if (customIllustration != null)
              customIllustration!
            else
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 60,
                  color: themeColor.withOpacity(0.6),
                ),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .then()
                  .shake(duration: 500.ms, hz: 2),

            const SizedBox(height: 32),

            // Titolo
            Text(
              title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(
                  begin: 0.3,
                  end: 0,
                ),

            const SizedBox(height: 12),

            // Messaggio
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(
                  begin: 0.3,
                  end: 0,
                ),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms)
                  .slideY(begin: 0.3, end: 0)
                  .then()
                  .shimmer(duration: 2000.ms, delay: 1000.ms),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget per empty state con animazione Lottie
class LottieEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LottieEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.sports_soccer,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      customIllustration: _buildSoccerBallAnimation(),
    );
  }

  Widget _buildSoccerBallAnimation() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.2),
            Colors.blue.withOpacity(0.2),
          ],
        ),
      ),
      child: const Center(
        child: Text(
          '⚽',
          style: TextStyle(fontSize: 80),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .rotate(duration: 3000.ms)
        .then()
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: 1000.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.1, 1.1),
          end: const Offset(1, 1),
          duration: 1000.ms,
        );
  }
}
