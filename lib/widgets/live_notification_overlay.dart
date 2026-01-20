// lib/widgets/live_notification_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/haptic_service.dart';

class LiveNotificationOverlay extends StatefulWidget {
  final Widget child;

  const LiveNotificationOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  static _LiveNotificationOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<_LiveNotificationOverlayState>();
  }

  @override
  State<LiveNotificationOverlay> createState() =>
      _LiveNotificationOverlayState();
}

class _LiveNotificationOverlayState extends State<LiveNotificationOverlay>
    with TickerProviderStateMixin {
  final List<NotificationItem> _notifications = [];
  final HapticService _haptic = HapticService();

  void showGoalNotification({
    required String homeTeam,
    required String awayTeam,
    required int homeScore,
    required int awayScore,
    required String scorer,
    required int minute,
    String? homeTeamLogo,
    String? awayTeamLogo,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.goal,
      title: 'GOOOOOL! ⚽',
      message: '$scorer ($minute\')',
      subtitle: '$homeTeam $homeScore - $awayScore $awayTeam',
      homeTeamLogo: homeTeamLogo,
      awayTeamLogo: awayTeamLogo,
      timestamp: DateTime.now(),
    );

    _addNotification(notification);
    _haptic.heavyImpact();
  }

  void showCardNotification({
    required String player,
    required String team,
    required CardType cardType,
    required int minute,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: cardType == CardType.yellow
          ? NotificationType.yellowCard
          : NotificationType.redCard,
      title: cardType == CardType.yellow
          ? '🟨 Cartellino Giallo'
          : '🟥 Cartellino Rosso',
      message: '$player ($minute\')',
      subtitle: team,
      timestamp: DateTime.now(),
    );

    _addNotification(notification);
    _haptic.mediumImpact();
  }

  void showMatchStartNotification({
    required String homeTeam,
    required String awayTeam,
    String? competition,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.matchStart,
      title: '🏁 Partita Iniziata!',
      message: '$homeTeam vs $awayTeam',
      subtitle: competition,
      timestamp: DateTime.now(),
    );

    _addNotification(notification);
    _haptic.lightImpact();
  }

  void showMatchEndNotification({
    required String homeTeam,
    required String awayTeam,
    required int homeScore,
    required int awayScore,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.matchEnd,
      title: '⏱️ Partita Terminata',
      message: '$homeTeam $homeScore - $awayScore $awayTeam',
      subtitle: homeScore > awayScore
          ? '🏆 Vittoria $homeTeam'
          : homeScore < awayScore
              ? '🏆 Vittoria $awayTeam'
              : '🤝 Pareggio',
      timestamp: DateTime.now(),
    );

    _addNotification(notification);
    _haptic.lightImpact();
  }

  void _addNotification(NotificationItem notification) {
    setState(() {
      _notifications.insert(0, notification);
    });

    // Auto rimuovi dopo 5 secondi
    Future.delayed(const Duration(seconds: 5), () {
      _removeNotification(notification.id);
    });
  }

  void _removeNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: Column(
            children: _notifications.map((notification) {
              return GoalNotificationCard(
                notification: notification,
                onDismiss: () => _removeNotification(notification.id),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class GoalNotificationCard extends StatefulWidget {
  final NotificationItem notification;
  final VoidCallback onDismiss;

  const GoalNotificationCard({
    Key? key,
    required this.notification,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<GoalNotificationCard> createState() => _GoalNotificationCardState();
}

class _GoalNotificationCardState extends State<GoalNotificationCard>
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
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getNotificationColor() {
    switch (widget.notification.type) {
      case NotificationType.goal:
        return Colors.green;
      case NotificationType.yellowCard:
        return Colors.amber;
      case NotificationType.redCard:
        return Colors.red;
      case NotificationType.matchStart:
        return Colors.blue;
      case NotificationType.matchEnd:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon() {
    switch (widget.notification.type) {
      case NotificationType.goal:
        return Icons.sports_soccer;
      case NotificationType.yellowCard:
      case NotificationType.redCard:
        return Icons.square;
      case NotificationType.matchStart:
        return Icons.play_arrow;
      case NotificationType.matchEnd:
        return Icons.stop;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _getNotificationColor();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dismissible(
          key: Key(widget.notification.id),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => widget.onDismiss(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.9),
                  color.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  widget.onDismiss();
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Icona animata
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(),
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                          .animate(
                            onPlay: (controller) => controller.repeat(),
                          )
                          .scale(
                            duration: const Duration(seconds: 1),
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                          )
                          .then()
                          .scale(
                            duration: const Duration(seconds: 1),
                            begin: const Offset(1.2, 1.2),
                            end: const Offset(1, 1),
                          ),
                      const SizedBox(width: 12),

                      // Contenuto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.notification.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (widget.notification.message.isNotEmpty)
                              Text(
                                widget.notification.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            if (widget.notification.subtitle != null)
                              Text(
                                widget.notification.subtitle!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Logo squadre (per goal)
                      if (widget.notification.type ==
                          NotificationType.goal) ...[
                        if (widget.notification.homeTeamLogo != null)
                          CachedNetworkImage(
                            imageUrl: widget.notification.homeTeamLogo!,
                            width: 24,
                            height: 24,
                            errorWidget: (context, url, error) => const Icon(
                                Icons.sports_soccer,
                                size: 24,
                                color: Colors.white),
                          ),
                        const SizedBox(width: 4),
                        if (widget.notification.awayTeamLogo != null)
                          CachedNetworkImage(
                            imageUrl: widget.notification.awayTeamLogo!,
                            width: 24,
                            height: 24,
                            errorWidget: (context, url, error) => const Icon(
                                Icons.sports_soccer,
                                size: 24,
                                color: Colors.white),
                          ),
                      ],

                      // Close button
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: widget.onDismiss,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().shimmer(
                duration: const Duration(seconds: 2),
                color: Colors.white.withOpacity(0.2),
              ),
        ),
      ),
    );
  }
}

// Modelli
enum NotificationType {
  goal,
  yellowCard,
  redCard,
  matchStart,
  matchEnd,
  generic,
}

enum CardType {
  yellow,
  red,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? subtitle;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final DateTime timestamp;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.subtitle,
    this.homeTeamLogo,
    this.awayTeamLogo,
    required this.timestamp,
  });
}
