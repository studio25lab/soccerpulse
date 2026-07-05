// lib/widgets/live_notification_overlay.dart

import 'package:flutter/material.dart';
import '../models/soccer_match.dart';
import '../pages/match_detail_screen.dart';
import '../services/haptic_service.dart';

class LiveNotificationOverlay extends StatefulWidget {
  static final GlobalKey<_LiveNotificationOverlayState> globalKey =
      GlobalKey<_LiveNotificationOverlayState>();

  final Widget child;

  const LiveNotificationOverlay({
    super.key,
    required this.child,
  });

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
      title: 'GOL',
      // [FAV-labelB] message = dettaglio + risultato; subtitle = etichetta
      message: '$scorer ($minute\') \u00b7 $homeTeam $homeScore-$awayScore $awayTeam',
      subtitle: 'GOL',
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
          ? 'Cartellino Giallo'
          : 'Cartellino Rosso',
      // [FAV-labelB]
      message: '$player ($minute\') \u00b7 $team',
      subtitle: cardType == CardType.yellow ? 'GIALLO' : 'ROSSO',
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
      title: 'Partita Iniziata',
      // [FAV-labelB]
      message: competition == null || competition.isEmpty
          ? '$homeTeam vs $awayTeam'
          : '$homeTeam vs $awayTeam \u00b7 $competition',
      subtitle: 'INIZIO',
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
      title: 'Partita Terminata',
      // [FAV-labelB]
      message: homeScore > awayScore
          ? '$homeTeam $homeScore-$awayScore $awayTeam \u00b7 Vittoria $homeTeam'
          : homeScore < awayScore
              ? '$homeTeam $homeScore-$awayScore $awayTeam \u00b7 Vittoria $awayTeam'
              : '$homeTeam $homeScore-$awayScore $awayTeam \u00b7 Pareggio',
      subtitle: 'FINE',
      timestamp: DateTime.now(),
    );

    _addNotification(notification);
    _haptic.lightImpact();
  }

  // [FAV-newtypes] --- nuovi banner ---------------------------------

  // Fallo - livello squadra
  // [FAV-count] Fallo con conteggio progressivo.
  void showFoulNotification({
    required String homeTeam,
    required String awayTeam,
    required int homeCount,
    required int awayCount,
    required bool isHomeTeam,
    required int minute,
  }) {
    final eventTeam = isHomeTeam ? homeTeam : awayTeam;
    final tally = isHomeTeam
        ? '$homeTeam-$awayTeam [$homeCount]-$awayCount'
        : '$homeTeam-$awayTeam $homeCount-[$awayCount]';
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.foul,
      title: 'Fallo \u00b7 $eventTeam',
      message: '$minute\' \u00b7 $tally',
      subtitle: 'FALLO',
      timestamp: DateTime.now(),
    );
    _addNotification(notification);
    _haptic.lightImpact();
  }

  // Fuori gioco - livello squadra
  // [FAV-offcount] Fuorigioco con conteggio progressivo.
  void showOffsideNotification({
    required String homeTeam,
    required String awayTeam,
    required int homeCount,
    required int awayCount,
    required bool isHomeTeam,
    required int minute,
  }) {
    final eventTeam = isHomeTeam ? homeTeam : awayTeam;
    final tally = isHomeTeam
        ? '$homeTeam-$awayTeam [$homeCount]-$awayCount'
        : '$homeTeam-$awayTeam $homeCount-[$awayCount]';
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.offside,
      title: 'Fuorigioco \u00b7 $eventTeam',
      message: '$minute\' \u00b7 $tally',
      subtitle: 'FUORIGIOCO',
      timestamp: DateTime.now(),
    );
    _addNotification(notification);
    _haptic.lightImpact();
  }

  // Calcio d-angolo - livello squadra
  // [FAV-count] Calcio d-angolo con conteggio progressivo.
  void showCornerNotification({
    required String homeTeam,
    required String awayTeam,
    required int homeCount,
    required int awayCount,
    required bool isHomeTeam,
    required int minute,
  }) {
    final eventTeam = isHomeTeam ? homeTeam : awayTeam;
    final tally = isHomeTeam
        ? '$homeTeam-$awayTeam [$homeCount]-$awayCount'
        : '$homeTeam-$awayTeam $homeCount-[$awayCount]';
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.corner,
      title: 'Calcio d\'angolo \u00b7 $eventTeam',
      message: '$minute\' \u00b7 $tally',
      subtitle: 'ANGOLO',
      timestamp: DateTime.now(),
    );
    _addNotification(notification);
    _haptic.lightImpact();
  }

  // Rigore assegnato - livello squadra
  void showPenaltyNotification({
    required String team,
    required int minute,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.penalty,
      title: 'Rigore assegnato',
      // [FAV-labelB]
      message: '$minute\' \u00b7 $team',
      subtitle: 'RIGORE',
      timestamp: DateTime.now(),
    );
    _addNotification(notification);
    _haptic.mediumImpact();
  }

  // Sostituzione - livello giocatore
  void showSubstitutionNotification({
    required String playerOut,
    required String playerIn,
    required String team,
    required int minute,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.substitution,
      title: 'Sostituzione',
      // [FAV-labelB]
      message: 'Esce $playerOut, entra $playerIn ($minute\') \u00b7 $team',
      subtitle: 'CAMBIO',
      timestamp: DateTime.now(),
    );
    _addNotification(notification);
    _haptic.lightImpact();
  }

  // Revisione VAR - l-esito viene passato dal chiamante
  // Esempi di outcome: 'Gol annullato per fuorigioco',
  // 'Gol annullato per fallo', 'Rigore annullato',
  // 'Rigore confermato', 'Gol convalidato'.
  void showVarNotification({
    required String outcome,
    required String team,
    required int minute,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.varReview,
      title: 'Revisione VAR',
      // [FAV-labelB]
      message: '$outcome ($minute\') \u00b7 $team',
      subtitle: 'VAR',
      timestamp: DateTime.now(),
    );
    _addNotification(notification);
    _haptic.mediumImpact();
  }

  void _addNotification(NotificationItem notification) {
    setState(() {
      _notifications.insert(0, notification);
    });

    // Auto rimuovi dopo 5 secondi
    // [FAV-tap7] 7s pieni + 400ms per l-uscita animata
    Future.delayed(const Duration(milliseconds: 7400), () {
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
              // [FAV-bannerkey] ValueKey -> i timer di ogni card
              // restano coordinati quando ne arrivano di nuove.
              return GoalNotificationCard(
                key: ValueKey(notification.id),
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

// [FAV-banner3] finto-vetro (no BackdropFilter, robusto su web)
class GoalNotificationCard extends StatefulWidget {
  final NotificationItem notification;
  final VoidCallback onDismiss;

  const GoalNotificationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

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
      duration: const Duration(milliseconds: 360),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // [FAV-tap7] uscita dopo 7s pieni
    Future.delayed(const Duration(milliseconds: 7000), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon => Icons.notifications_active_rounded;

  // [FAV-tap7] Apre la partita live al tap sul banner.
  // Coi mock l-unica live e Lazio-Milan; quando ci sara il
  // simulatore, ogni banner portera il proprio matchId.
  // [FAV-fetchx] Apre la partita live al tap.
  // L-acquisizione della partita e isolata in
  // _fetchLiveMatchForTap() per facilitare il passaggio alle
  // API: quando ci arriverai, modifica solo quel metodo.
  Future<void> _handleTap(BuildContext context) async {
    // 1) chiudo subito il banner (UI reattiva)
    widget.onDismiss();

    // 2) ottengo la partita (oggi mock, domani repo API)
    final liveMatch = await _fetchLiveMatchForTap();
    if (liveMatch == null) return;

    // 3) navigo al dettaglio (stesso pattern di home_screen)
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => MatchDetailScreen(match: liveMatch),
      ),
    );
  }

  // TODO API: rimpiazzare il corpo con
  //   final repo = RepositoryProvider.matchRepository;
  //   return repo.getMatchById(widget.notification.matchId);
  // (richiede prima di aggiungere `matchId` a NotificationItem)
  // Per ora torna la stessa SoccerMatch costruita inline dalla
  // home in _loadMockMatches (Lazio-Milan, id 9001).
  Future<SoccerMatch?> _fetchLiveMatchForTap() async {
    return SoccerMatch(
      id: 9001,
      homeTeamId: 487,
      awayTeamId: 489,
      homeTeamName: 'Lazio',
      awayTeamName: 'Milan',
      homeScore: 2,
      awayScore: 1,
      status: '1H',
      date: DateTime(2023, 5, 14),
      time: '20:45',
      venue: 'Stadio Olimpico',
      leagueId: 135,
      leagueName: 'Serie A',
      round: 'Giornata 35',
      elapsed: 45,
      homeTeamLogo:
          'https://media.api-sports.io/football/teams/487.png',
      awayTeamLogo:
          'https://media.api-sports.io/football/teams/489.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // "Finto vetro": niente BackdropFilter. Superficie a trasparenza
    // parziale. Su Flutter Web e robusto e non collassa.
    final Color glassFill = isDark
        ? const Color(0xFF1E1E1E).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.94);
    final Color glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.90);
    final Color textPrimary =
        isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : Colors.black.withValues(alpha: 0.55);
    final Color pillFill = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.05);

    final n = widget.notification;
    final hasSubtitle = n.subtitle != null && n.subtitle!.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Dismissible(
            key: Key(n.id),
            direction: DismissDirection.horizontal,
            onDismissed: (_) => widget.onDismiss(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: glassFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: glassBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                          alpha: isDark ? 0.40 : 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    // [FAV-tap7] tap = apri partita live + dismiss
                    onTap: () => _handleTap(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: pillFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_icon,
                                size: 22, color: textPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  n.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (n.message.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    n.message,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (hasSubtitle) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: pillFill,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                n.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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

// Modelli
enum NotificationType {
  goal,
  yellowCard,
  redCard,
  matchStart,
  matchEnd,
  // [FAV-newtypes] nuovi tipi
  foul,
  offside,
  corner,
  penalty,
  substitution,
  varReview,
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
