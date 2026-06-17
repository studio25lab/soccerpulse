// lib/widgets/dialogs/lineup_dialogs.dart
//
// Dialog modali per la tab Lineups della MatchDetailScreen.
// Estratti da match_detail_screen.dart come funzioni top-level
// per pulizia (~665 righe spostate dal monolite).
//
// Dialog:
//   showCoachProfile(): bottom sheet col profilo allenatore
//   showPlayerComparisonPicker(): bottom sheet per scegliere giocatore
//     da confrontare
//   showMatchPlayerNotifDialog(): dialog per configurare le notifiche
//     di un giocatore per la specifica partita
//
// // [FAV-lineup-dialogs]

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/l10n_helper.dart';
import '../../generated/l10n.dart';
import '../../models/local_match_models.dart';
import '../../services/player_notification_preferences_service.dart';
import '../../pages/coach_profile_screen.dart';
import '../../pages/match_player_comparison_screen.dart';
import '../../models/player_notification_settings.dart';
import '../../services/haptic_service.dart';
import '../interactive_shot_map_widget.dart';
import '../Interactive_defensive_widget.dart';

void showCoachProfile(BuildContext context, {required String coachName, required String teamName, required Color teamColor, required bool isDark}) {
  final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
  final tx = isDark ? Colors.white : Colors.black87;
  final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
  final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);
  final sectionBg = isDark ? const Color(0xFF16162A) : const Color(0xFFF8F9FA);

  // Dati coach (demo realistici 2022-23)
  final Map<String, Map<String, dynamic>> coachData = {
    'Maurizio Sarri': {
      'nationality': '🇮🇹 Italiano',
      'age': 64,
      'born': '10 gennaio 1959',
      'formation': '4-3-3',
      'teamFull': 'S.S. Lazio',
      'seasonW': 14, 'seasonD': 7, 'seasonL': 6,
      'seasonGoalsFor': 42, 'seasonGoalsAgainst': 28,
      'style': 'Possesso palla, pressing alto, gioco verticale rapido',
      'philosophy': 'Il "Sarrismo" si basa su un calcio offensivo e spettacolare, con movimenti sincronizzati e transizioni veloci.',
      'career': [
        {'team': 'Lazio', 'period': '2021-2023', 'trophy': ''},
        {'team': 'Juventus', 'period': '2019-2020', 'trophy': '🏆 Serie A'},
        {'team': 'Chelsea', 'period': '2018-2019', 'trophy': '🏆 Europa League'},
        {'team': 'Napoli', 'period': '2015-2018', 'trophy': ''},
        {'team': 'Empoli', 'period': '2012-2015', 'trophy': ''},
      ],
      'stats': {'matches': 27, 'winRate': 52, 'avgGoals': 1.56, 'cleanSheets': 8, 'avgPoints': 1.81},
    },
    'Stefano Pioli': {
      'nationality': '🇮🇹 Italiano',
      'age': 57,
      'born': '20 ottobre 1965',
      'formation': '4-2-3-1',
      'teamFull': 'A.C. Milan',
      'seasonW': 16, 'seasonD': 5, 'seasonL': 6,
      'seasonGoalsFor': 48, 'seasonGoalsAgainst': 26,
      'style': 'Transizioni rapide, pressing coordinato, gioco sulle fasce',
      'philosophy': 'Calcio pragmatico e moderno, con enfasi sulle ripartenze veloci e la solidità difensiva.',
      'career': [
        {'team': 'Milan', 'period': '2019-2024', 'trophy': '🏆 Scudetto 2022'},
        {'team': 'Fiorentina', 'period': '2017-2019', 'trophy': ''},
        {'team': 'Inter', 'period': '2016-2017', 'trophy': ''},
        {'team': 'Lazio', 'period': '2014-2016', 'trophy': ''},
        {'team': 'Bologna', 'period': '2011-2014', 'trophy': ''},
      ],
      'stats': {'matches': 27, 'winRate': 59, 'avgGoals': 1.78, 'cleanSheets': 10, 'avgPoints': 1.96},
    },
  };

  final data = coachData[coachName];
  if (data == null) return;

  final stats = data['stats'] as Map<String, dynamic>;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.zero,
          children: [
            // ── Handle ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header con iniziali + nome ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(children: [
                // Avatar con iniziali
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [teamColor, teamColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: teamColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      coachName.split(' ').map((w) => w[0]).take(2).join(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coachName,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: tx)),
                    const SizedBox(height: 4),
                    Text('${tr(context, 'Allenatore')} · ${data['teamFull']}',
                        style: TextStyle(fontSize: 13, color: lb)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text(tr(context, data['nationality'] as String? ?? ''), style: TextStyle(fontSize: 12, color: lb)),
                      const SizedBox(width: 12),
                      Text('${data['age']} ${tr(context, 'anni')}', style: TextStyle(fontSize: 12, color: lb)),
                    ]),
                  ],
                )),
              ]),
            ),

            // ── Modulo ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sectionBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(Icons.dashboard_rounded, size: 20, color: teamColor),
                const SizedBox(width: 12),
                Text(S.of(context)!.modulo, style: TextStyle(fontSize: 13, color: lb, fontWeight: FontWeight.w500)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: teamColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: teamColor.withOpacity(0.3)),
                  ),
                  child: Text('${data['formation']}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: teamColor)),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            // ── Record Stagionale ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: sectionBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(children: [
                    Icon(Icons.emoji_events_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey[500]),
                    const SizedBox(width: 8),
                    Text(tr(context, 'RECORD STAGIONALE'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white38 : Colors.grey[500], letterSpacing: 1.5)),
                  ]),
                ),
                // W / D / L row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    _coachStatBox('V', '${data['seasonW']}', const Color(0xFF4CAF50), isDark),
                    const SizedBox(width: 8),
                    _coachStatBox('P', '${data['seasonD']}', Colors.amber, isDark),
                    const SizedBox(width: 8),
                    _coachStatBox('S', '${data['seasonL']}', const Color(0xFFE53935), isDark),
                  ]),
                ),
                const SizedBox(height: 12),
                // Progress bar V/P/S
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Row(children: [
                        Expanded(flex: data['seasonW'], child: Container(color: const Color(0xFF4CAF50))),
                        Expanded(flex: data['seasonD'], child: Container(color: Colors.amber)),
                        Expanded(flex: data['seasonL'], child: Container(color: const Color(0xFFE53935))),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Gol fatti/subiti
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(children: [
                    Expanded(child: _coachInfoTile(localizeShotData(context, 'Gol Fatti'), '${data['seasonGoalsFor']}', tx, lb, isDark)),
                    Container(width: 1, height: 30, color: divider),
                    Expanded(child: _coachInfoTile(localizeShotData(context, 'Gol Subiti'), '${data['seasonGoalsAgainst']}', tx, lb, isDark)),
                    Container(width: 1, height: 30, color: divider),
                    Expanded(child: _coachInfoTile(localizeShotData(context, 'Clean Sheet'), '${stats['cleanSheets']}', tx, lb, isDark)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            // ── Statistiche Stagionali ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: sectionBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(children: [
                    Icon(Icons.bar_chart_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey[500]),
                    const SizedBox(width: 8),
                    Text(tr(context, 'STATISTICHE'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white38 : Colors.grey[500], letterSpacing: 1.5)),
                  ]),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(children: [
                    Expanded(child: _coachInfoTile(localizeShotData(context, 'Partite'), '${stats['matches']}', tx, lb, isDark)),
                    Container(width: 1, height: 30, color: divider),
                    Expanded(child: _coachInfoTile(localizeShotData(context, '% Vittorie'), '${stats['winRate']}%', tx, lb, isDark)),
                    Container(width: 1, height: 30, color: divider),
                    Expanded(child: _coachInfoTile(localizeShotData(context, 'Gol/Partita'), '${stats['avgGoals']}', tx, lb, isDark)),
                    Container(width: 1, height: 30, color: divider),
                    Expanded(child: _coachInfoTile(localizeShotData(context, 'Punti/Partita'), '${stats['avgPoints']}', tx, lb, isDark)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            // ── Vedi profilo completo ──
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Future.delayed(const Duration(milliseconds: 300), () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CoachProfileScreen(
                      coachName: coachName,
                      teamName: teamName,
                      teamColor: teamColor,
                      data: data,
                    ),
                  ));
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sectionBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: teamColor.withOpacity(0.15)),
                ),
                child: Row(children: [
                  Icon(Icons.person_search_rounded, size: 18, color: teamColor),
                  SizedBox(width: 12),
                  Text(localizeShotData(context, 'Vedi profilo completo'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: teamColor)),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, size: 20, color: teamColor.withOpacity(0.6)),
                ]),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );
}

Widget _coachStatBox(String label, String value, Color color, bool isDark) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
      ]),
    ),
  );
}

Widget _coachInfoTile(String label, String value, Color tx, Color lb, bool isDark) {
  return Column(children: [
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tx)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 10, color: lb, fontWeight: FontWeight.w500)),
  ]);
}

void showPlayerComparisonPicker(BuildContext context, {required LocalLineupPlayer player1, required Color teamColor, required bool isDark, required List<LocalLineupPlayer> allPlayers, required String homeTeamName, required String awayTeamName, required List<ShotData> homeShotsData, required List<ShotData> awayShotsData, required List<DefensiveActionData> homeDefensiveActions, required List<DefensiveActionData> awayDefensiveActions}) {
  final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
  final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
  final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
  final others = allPlayers.where((p) => p.number != player1.number).toList();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('${tr(context, 'Confronta')} ${player1.name} ${tr(context, 'con...')}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tx)),
        ),
        Expanded(child: ListView.builder(
          itemCount: others.length,
          itemBuilder: (ctx, i) {
            final p2 = others[i];
            final pColor = i < allPlayers.length ~/ 2
                ? const Color(0xFF1565C0) : const Color(0xFFD32F2F);
            return ListTile(
              leading: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: pColor.withOpacity(0.12), shape: BoxShape.circle,
                  border: Border.all(color: pColor.withOpacity(0.3)),
                ),
                child: Center(child: Text('${p2.number}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: pColor))),
              ),
              title: Text(p2.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tx)),
              subtitle: Text('${p2.position} · ${p2.rating.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 12, color: lb)),
              trailing: Icon(Icons.chevron_right_rounded, color: lb, size: 20),
              onTap: () {
                Navigator.pop(ctx);
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MatchPlayerComparisonScreen(
                      initialPlayers: [player1, p2],
                      allPlayers: allPlayers,
                      homeTeamName: homeTeamName,
                      awayTeamName: awayTeamName,
                      homeShotsData: homeShotsData,
                      awayShotsData: awayShotsData,
                      homeDefensiveActions: homeDefensiveActions,
                      awayDefensiveActions: awayDefensiveActions,
                    ),
                  ));
                });
              },
            );
          },
        )),
      ]),
    ),
  );
}

Future<void> showMatchPlayerNotifDialog(BuildContext context, {required LocalLineupPlayer player, required Color teamColor, required bool isDark, required int matchId, required void Function(LocalLineupPlayer player) onShowPlayerStats}) async {
  final svc = context.read<PlayerNotificationPreferencesService>();
  await svc.loadSettings();
  var settings = svc.getSettingsForPlayer(player.number, player.name, matchId: matchId);
  // Se nessuna notifica attiva, attiva preset essential
  if (!settings.hasActiveNotifications) {
    settings = PlayerNotificationSettings.essentialOnly(
      player.number, player.name, matchId: matchId,
    );
    await svc.saveSettingsForPlayer(settings);
    // Sync globale
    final global = PlayerNotificationSettings.essentialOnly(
      player.number, player.name,
    );
    await svc.saveSettingsForPlayer(global);
    // Sync per nome
    await svc.updateAllSettingsForPlayerByName(player.name, global);
  }
  final tx = isDark ? Colors.white : Colors.black87;
  final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;

  // Notification types for match context
  final categories = {
    'Gol & Tiri': {
      'goals': [S.of(context)!.gol, 'Notifica quando segna', Icons.sports_soccer],
      'shotsOnTarget': [localizeShotData(context, 'Tiri in porta'), tr(context, 'Notifica tiri in porta'), Icons.gps_fixed],
      'shotsOffTarget': [localizeShotData(context, 'Tiri totali'), tr(context, 'Notifica tutti i tiri'), Icons.gps_not_fixed],
    },
    S.of(context)!.disciplinaLabel: {
      'yellowCard': ['Cartellino giallo', 'Notifica ammonizione', Icons.square],
      'redCard': ['Cartellino rosso', 'Notifica espulsione', Icons.square],
      'foulCommitted': ['Fallo commesso', 'Notifica falli commessi', Icons.front_hand],
      'foulSuffered': ['Fallo subito', 'Notifica falli subiti', Icons.personal_injury],
    },
    'Gioco': {
      'keyPasses': [S.of(context)!.passaggiChiave, 'Notifica passaggi decisivi', Icons.swap_calls],
      'dribblesSuccessful': [tr(context, 'Dribbling riusciti'), tr(context, 'Notifica dribbling'), Icons.directions_run],
      'offsides': [tr(context, 'Fuorigioco'), 'Notifica fuorigioco', Icons.flag],
    },
  };

  Map<String, bool> getPrefs() => {
    'goals': settings.notifyGoals,
    'assists': settings.notifyAssists,
    'shotsOnTarget': settings.notifyShotsOnTarget,
    'keyPasses': settings.notifyKeyPasses,
    'dribblesSuccessful': settings.notifyDribblesSuccessful,
    'offsides': settings.notifyOffsides,
    'yellowCard': settings.notifyYellowCard,
    'redCard': settings.notifyRedCard,
    'foulCommitted': settings.notifyFoulCommitted,
    'foulSuffered': settings.notifyFoulSuffered,
    'substitutionOn': settings.notifySubstitutionOn,
  };

  void updatePref(String key, bool val) {
    switch (key) {
      case 'goals': settings = settings.copyWith(notifyGoals: val, enabled: true); break;
      case 'assists': settings = settings.copyWith(notifyAssists: val, enabled: true); break;
      case 'shotsOnTarget': settings = settings.copyWith(notifyShotsOnTarget: val, enabled: true); break;
      case 'keyPasses': settings = settings.copyWith(notifyKeyPasses: val, enabled: true); break;
      case 'dribblesSuccessful': settings = settings.copyWith(notifyDribblesSuccessful: val, enabled: true); break;
      case 'offsides': settings = settings.copyWith(notifyOffsides: val, enabled: true); break;
      case 'yellowCard': settings = settings.copyWith(notifyYellowCard: val, enabled: true); break;
      case 'redCard': settings = settings.copyWith(notifyRedCard: val, enabled: true); break;
      case 'foulCommitted': settings = settings.copyWith(notifyFoulCommitted: val, enabled: true); break;
      case 'foulSuffered': settings = settings.copyWith(notifyFoulSuffered: val, enabled: true); break;
      case 'substitutionOn': settings = settings.copyWith(notifySubstitutionOn: val, enabled: true); break;
    }
    svc.saveSettingsForPlayer(settings);
    // Sync to global (no matchId) so favorites screen sees it
    final globalSettings = PlayerNotificationSettings(
      playerId: settings.playerId,
      playerName: settings.playerName,
      enabled: settings.enabled,
      notifyGoals: settings.notifyGoals,
      notifyAssists: settings.notifyAssists,
      notifyShotsOnTarget: settings.notifyShotsOnTarget,
      notifyShotsOffTarget: settings.notifyShotsOffTarget,
      notifyYellowCard: settings.notifyYellowCard,
      notifyRedCard: settings.notifyRedCard,
      notifyFoulCommitted: settings.notifyFoulCommitted,
      notifyFoulSuffered: settings.notifyFoulSuffered,
      notifyKeyPasses: settings.notifyKeyPasses,
      notifyDribblesSuccessful: settings.notifyDribblesSuccessful,
      notifyOffsides: settings.notifyOffsides,
    );
    svc.saveSettingsForPlayer(globalSettings);
    svc.updateAllSettingsForPlayerByName(settings.playerName, globalSettings);
  }

  void setAll(bool val) {
    settings = settings.copyWith(
      enabled: val,
      notifyGoals: val, notifyAssists: val, notifyShotsOnTarget: val,
      notifyKeyPasses: val, notifyDribblesSuccessful: val, notifyOffsides: val,
      notifyYellowCard: val, notifyRedCard: val, notifyFoulCommitted: val,
      notifyFoulSuffered: val, notifySubstitutionOn: val,
    );
    svc.saveSettingsForPlayer(settings);
    // Sync to global
    final globalAll = PlayerNotificationSettings(
      playerId: settings.playerId,
      playerName: settings.playerName,
      enabled: settings.enabled,
      notifyGoals: settings.notifyGoals,
      notifyAssists: settings.notifyAssists,
      notifyShotsOnTarget: settings.notifyShotsOnTarget,
      notifyShotsOffTarget: settings.notifyShotsOffTarget,
      notifyYellowCard: settings.notifyYellowCard,
      notifyRedCard: settings.notifyRedCard,
      notifyFoulCommitted: settings.notifyFoulCommitted,
      notifyFoulSuffered: settings.notifyFoulSuffered,
      notifyKeyPasses: settings.notifyKeyPasses,
      notifyDribblesSuccessful: settings.notifyDribblesSuccessful,
      notifyOffsides: settings.notifyOffsides,
    );
    svc.saveSettingsForPlayer(globalAll);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(builder: (context, setSheetState) {
        final prefs = getPrefs();
        final allOn = prefs.values.every((v) => v);
        final anyOn = prefs.values.any((v) => v);
        final activeCount = prefs.values.where((v) => v).length;

        // Color per category
        Color _catColor(String key) {
          switch(key) {
            case 'goals': return const Color(0xFF4CAF50);
            case 'assists': return const Color(0xFF2196F3);
            case 'shotsOnTarget': return const Color(0xFFFF7043);
            case 'keyPasses': return const Color(0xFF26A69A);
            case 'dribblesSuccessful': return const Color(0xFF66BB6A);
            case 'offsides': return const Color(0xFF7E57C2);
            case 'yellowCard': return const Color(0xFFFFCA28);
            case 'redCard': return const Color(0xFFE53935);
            case 'foulCommitted': return const Color(0xFF8D6E63);
            case 'foulSuffered': return const Color(0xFF5C6BC0);
            case 'substitutionOn': return const Color(0xFF42A5F5);
            default: return teamColor;
          }
        }

        Widget _tile(String key, IconData icon, String label, String desc, bool isOn) {
          final color = _catColor(key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(color: Colors.transparent, child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () { HapticService().lightImpact(); setSheetState(() { updatePref(key, !isOn); }); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isOn ? color.withOpacity(isDark ? 0.12 : 0.06) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isOn ? color.withOpacity(isDark ? 0.3 : 0.2) : isDark ? Colors.white10 : Colors.grey[200]!, width: isOn ? 1.5 : 1)),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(
                      color: color.withOpacity(isOn ? 0.15 : 0.08), borderRadius: BorderRadius.circular(10)),
                    child: key == 'yellowCard'
                      ? Center(child: Container(width: 14, height: 18, decoration: BoxDecoration(
                          color: const Color(0xFFFDD835), borderRadius: BorderRadius.circular(2),
                          boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 4)])))
                      : key == 'redCard'
                        ? Center(child: Container(width: 14, height: 18, decoration: BoxDecoration(
                            color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4)])))
                        : Icon(icon, size: 20, color: isOn ? color : isDark ? Colors.white30 : Colors.grey[400])),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: isOn ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white54 : Colors.grey[500]))),
                    const SizedBox(height: 2),
                    Text(desc, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.grey[400])),
                  ])),
                  AnimatedContainer(duration: const Duration(milliseconds: 200), width: 44, height: 26,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(13),
                        color: isOn ? color : isDark ? Colors.white12 : Colors.grey[300]),
                    child: AnimatedAlign(duration: const Duration(milliseconds: 200),
                      alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(margin: const EdgeInsets.all(3), width: 20, height: 20,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)])))),
                ]),
              ),
            )),
          );
        }

        Widget _header(String t, IconData ic) => Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(children: [
            Icon(ic, size: 16, color: isDark ? Colors.white38 : Colors.grey[500]),
            const SizedBox(width: 8),
            Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                color: isDark ? Colors.white38 : Colors.grey[500])),
          ]),
        );

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle + Back + Close
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 0, left: 12, right: 12),
              child: Row(children: [
                GestureDetector(
                  onTap: () { Navigator.of(context).pop(); onShowPlayerStats(player); },
                  child: Container(width: 32, height: 32,
                    decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], shape: BoxShape.circle),
                    child: Icon(Icons.arrow_back_rounded, size: 18, color: isDark ? Colors.white70 : Colors.grey[600]))),
                const Spacer(),
                Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(width: 32, height: 32,
                    decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white70 : Colors.grey[600]))),
              ])),
            // Header
            Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(color: teamColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: teamColor.withOpacity(0.3))),
                child: Center(child: Text('${player.number}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: teamColor)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(player.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tx)),
                const SizedBox(height: 2),
                Text(anyOn ? '$activeCount/${prefs.length} ${tr(context, 'notifiche attive')}' : tr(context, 'Nessuna notifica attiva'),
                    style: TextStyle(fontSize: 13, color: lb)),
              ])),
              GestureDetector(onTap: () { HapticService().lightImpact(); setSheetState(() { setAll(!allOn); }); },
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: allOn ? teamColor : isDark ? Colors.white10 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: allOn ? teamColor : isDark ? Colors.white24 : Colors.grey[300]!)),
                  child: Text(allOn ? S.of(context)!.deactivate : S.of(context)!.activateAll,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: allOn ? Colors.white : isDark ? Colors.white70 : Colors.grey[700])))),
            ])),
            // Badge scope
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.timer_outlined, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Text(S.of(context)!.onlyForThisMatch,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange[700])),
                ]))),
            Divider(color: isDark ? Colors.white12 : Colors.grey[200], height: 1),
            // Notification tiles
            Flexible(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _header(S.of(context)!.offensive, Icons.sports_soccer),
                _tile('goals', Icons.sports_soccer, S.of(context)!.goalNotif, S.of(context)!.goalDesc, prefs['goals'] ?? false),
                _tile('assists', Icons.assistant_rounded, S.of(context)!.assistNotif, S.of(context)!.assistDesc, prefs['assists'] ?? false),
                _tile('shotsOnTarget', Icons.gps_not_fixed, S.of(context)!.shotsOnTargetNotif, S.of(context)!.shotsOnTargetDesc, prefs['shotsOnTarget'] ?? false),
                _tile('keyPasses', Icons.trending_up, S.of(context)!.keyPassesNotif, S.of(context)!.keyPassesDesc, prefs['keyPasses'] ?? false),
                _tile('dribblesSuccessful', Icons.directions_run, S.of(context)!.dribblesNotif, S.of(context)!.dribblesDesc, prefs['dribblesSuccessful'] ?? false),
                _tile('offsides', Icons.front_hand, S.of(context)!.offsidesNotif, S.of(context)!.offsidesDesc, prefs['offsides'] ?? false),
                const SizedBox(height: 16),
                _header(S.of(context)!.discipline, Icons.style),
                _tile('yellowCard', Icons.square_rounded, S.of(context)!.yellowCardNotif, S.of(context)!.yellowCardDesc, prefs['yellowCard'] ?? false),
                _tile('redCard', Icons.square_rounded, S.of(context)!.redCardNotif, S.of(context)!.redCardDesc, prefs['redCard'] ?? false),
                _tile('foulCommitted', Icons.warning_amber, S.of(context)!.foulsCommittedNotif, S.of(context)!.foulsCommittedDesc, prefs['foulCommitted'] ?? false),
                _tile('foulSuffered', Icons.personal_injury, S.of(context)!.foulsSufferedNotif, S.of(context)!.foulsSufferedDesc, prefs['foulSuffered'] ?? false),
                const SizedBox(height: 16),
                _header(tr(context, 'Altro'), Icons.swap_horiz),
                _tile('substitutionOn', Icons.swap_horiz, S.of(context)!.substitutionNotif, S.of(context)!.substitutionDesc, prefs['substitutionOn'] ?? false),
              ]),
            )),
          ]),
        );
      });
    },
  );
}
