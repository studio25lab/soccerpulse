// lib/widgets/notification_badge.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final Color? color;
  final bool pulse;

  const NotificationBadge({
    Key? key,
    required this.count,
    this.color,
    this.pulse = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );

    if (pulse) {
      badge = badge
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .scale(
            duration: const Duration(seconds: 2),
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
          )
          .then()
          .scale(
            duration: const Duration(seconds: 2),
            begin: const Offset(1.1, 1.1),
            end: const Offset(1, 1),
          );
    }

    return badge;
  }
}

// Widget per mostrare notifiche in-app
class InAppNotification extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Duration duration;

  const InAppNotification({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.notifications,
    this.color = Colors.blue,
    this.onTap,
    this.duration = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  State<InAppNotification> createState() => _InAppNotificationState();
}

class _InAppNotificationState extends State<InAppNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: isDark ? Colors.grey[900] : Colors.white,
              child: InkWell(
                onTap: () {
                  _controller.reverse();
                  widget.onTap?.call();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
