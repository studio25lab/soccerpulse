// lib/services/favorite_notification_coordinator.dart
// [FAV-C] coordinator pulito

import 'dart:async';
import '../models/soccer_match.dart';
import 'live_update_service.dart';
import 'match_notification_preferences_service.dart';
import 'team_notification_preferences_service.dart';

/// Firma del callback invocato quando un goal deve generare una notifica.
typedef FavoriteGoalCallback = void Function({
  required String homeTeam,
  required String awayTeam,
  required int homeScore,
  required int awayScore,
  required String scorer,
  required int minute,
  String? homeTeamLogo,
  String? awayTeamLogo,
});

/// Ascolta gli eventi goal di [LiveUpdateService] e invoca [onFavoriteGoal]
/// quando il goal riguarda un match o una squadra con le notifiche attive.
///
/// Filtro "match O squadra": la notifica scatta se
///  - il match ha notifiche goal attive (MatchNotificationPreferencesService)
///  oppure
///  - la squadra di casa o trasferta ha notifiche goal attive
///    (TeamNotificationPreferencesService).
class FavoriteNotificationCoordinator {
  FavoriteNotificationCoordinator({
    required this.liveUpdateService,
    required this.matchNotifService,
    required this.teamNotifService,
    required this.onFavoriteGoal,
  });

  final LiveUpdateService liveUpdateService;
  final MatchNotificationPreferencesService matchNotifService;
  final TeamNotificationPreferencesService teamNotifService;
  final FavoriteGoalCallback onFavoriteGoal;

  StreamSubscription<GoalEvent>? _goalSub;

  /// Chiavi degli eventi gia' notificati, per evitare doppioni.
  final Set<String> _notified = <String>{};

  /// Avvia l'ascolto degli eventi live. Idempotente.
  void start() {
    _goalSub ??= liveUpdateService.goalStream.listen(_handleGoalEvent);
  }

  /// Interrompe l'ascolto e libera le risorse.
  void dispose() {
    _goalSub?.cancel();
    _goalSub = null;
    _notified.clear();
  }

  /// True se il match ha notifiche goal attive.
  bool _matchWantsGoal(int matchId) {
    final s = matchNotifService.getSettingsForMatch(matchId);
    if (!s.enabled) return false;
    return s.notifyHomeGoals || s.notifyAwayGoals;
  }

  /// True se la squadra ha notifiche goal attive.
  /// (Opzione A: non distingue goal della squadra / degli avversari;
  /// basta che la squadra abbia le notifiche goal attive.)
  bool _teamWantsGoal(int teamId) {
    final s = teamNotifService.getSettingsForTeam(teamId);
    if (!s.enabled) return false;
    return s.notifyTeamGoals || s.notifyOpponentGoals;
  }

  void _handleGoalEvent(GoalEvent event) {
    // ignore: avoid_print
    print('[FAV-cdbg] A) GoalEvent ricevuto, matchId=' +
        event.matchId.toString());
    SoccerMatch? match;
    for (final m in liveUpdateService.currentMatches) {
      if (m.id == event.matchId) {
        match = m;
        break;
      }
    }
    if (match == null) {
      // ignore: avoid_print
      print('[FAV-cdbg] B) match NON trovato in currentMatches '
          '(tot=' + liveUpdateService.currentMatches.length.toString()
          + ') -> SCARTATO');
      return;
    }
    // ignore: avoid_print
    print('[FAV-cdbg] B) match trovato: ' + match.homeTeamName +
        ' vs ' + match.awayTeamName + ', isLive=' +
        match.isLive.toString());
    if (!match.isLive) {
      // ignore: avoid_print
      print('[FAV-cdbg] C) match non live -> SCARTATO');
      return;
    }

    // Filtro "match O squadra".
    final matchWants = _matchWantsGoal(match.id);
    final homeWants = _teamWantsGoal(match.homeTeamId);
    final awayWants = _teamWantsGoal(match.awayTeamId);
    // ignore: avoid_print
    print('[FAV-cdbg] D) filtro: matchWants=' + matchWants.toString() +
        ' homeWants=' + homeWants.toString() +
        ' awayWants=' + awayWants.toString() +
        ' (matchId=' + match.id.toString() +
        ' homeId=' + match.homeTeamId.toString() +
        ' awayId=' + match.awayTeamId.toString() + ')');
    if (!matchWants && !homeWants && !awayWants) {
      // ignore: avoid_print
      print('[FAV-cdbg] D) nessuna notifica attiva -> SCARTATO');
      return;
    }

    // Dedup per combinazione match + punteggio.
    final key = '${match.id}-${match.homeScore}-${match.awayScore}';
    if (!_notified.add(key)) return;

    final scorer = event.teamName.isNotEmpty
        ? event.teamName
        : match.homeTeamName;

    // ignore: avoid_print
    print('[FAV-cdbg] E) onFavoriteGoal INVOCATO');
    onFavoriteGoal(
      homeTeam: match.homeTeamName,
      awayTeam: match.awayTeamName,
      homeScore: match.homeScore,
      awayScore: match.awayScore,
      scorer: scorer,
      minute: match.elapsed ?? 0,
      homeTeamLogo: match.homeTeamLogo,
      awayTeamLogo: match.awayTeamLogo,
    );
  }
}
