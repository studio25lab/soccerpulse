// lib/widgets/match_event_overlay.dart
//
// Sistema notifiche LIVE interno alla schermata partita.
// Quando il simulatore manda eventi (gol/cartellini/falli ecc) durante
// una partita in corso, questo overlay mostra una notifica toast in alto.
//
// IMPORTANTE: NON confondere con LiveNotificationOverlay (banner globale
// dell-app, gestito da main.dart). Quello mostra notifiche di squadre
// preferite ovunque, questo solo dentro la schermata partita aperta.
//
// Estratte da match_detail_screen.dart.
// Rinominate (rimosso underscore + prefisso Match) per chiarezza.
//
// // [FAV-eventoverlay]

import 'package:flutter/material.dart';

class MatchEventNotification {
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int minute;

  MatchEventNotification({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.minute,
  });
}

class MatchEventOverlay extends StatefulWidget {
  final MatchEventNotification notification;
  final VoidCallback onDismissed;

  const MatchEventOverlay({
    required this.notification,
    required this.onDismissed,
  });

  @override
  State<MatchEventOverlay> createState() =>
      _MatchEventOverlayState();
}

class _MatchEventOverlayState extends State<MatchEventOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();

    // Auto-dismiss dopo 4 secondi
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _animController.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notif = widget.notification;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -5) {
                _dismiss();
              }
            },
            onTap: _dismiss,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E30)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: notif.color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: notif.color.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ── Icona con glow ──
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: notif.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: notif.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        notif.icon,
                        color: notif.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ── Testo ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notif.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey[600],
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Minuto badge ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: notif.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${notif.minute}'",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: notif.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// STATS TAB — Helper Classes
// ═══════════════════════════════════════════════════════════════════════════



// ═══════════════════════════════════════════════════════════════════════════
// MOMENTUM CHART — Custom Painters
// ═══════════════════════════════════════════════════════════════════════════



// ═══════════════════════════════════════════════════════════════════════════
// COACH PROFILE SCREEN — Pagina fullscreen profilo allenatore
// ═══════════════════════════════════════════════════════════════════════════
