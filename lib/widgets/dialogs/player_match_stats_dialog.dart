// lib/widgets/dialogs/player_match_stats_dialog.dart
//
// Modale stats giocatore: mostra tutte le statistiche di un giocatore
// nella partita (rating, gol, assist, passaggi, dribbling, difensiva).
// Estratta da match_detail_screen.dart.
//
// Implementata come funzione top-level perche e' un dialog modale
// auto-contenuto chiamato da Events tab, Lineups tab, Advanced sub-views.
// State _visualTab gestito via StatefulBuilder interno.
// La funzione e' ricorsiva (puo aprire stats di un giocatore collegato).
//
// // [FAV-player-match-stats-dialog]

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/favorites_service.dart';
import '../../services/player_notification_preferences_service.dart';
import '../../models/player_notification_settings.dart';
import '../../pages/match_player_profile_screen.dart';
import '../player_match_visuals.dart';
import '../../utils/l10n_helper.dart';
import '../../generated/l10n.dart';
import '../../models/local_match_models.dart';
import '../interactive_shot_map_widget.dart';
import '../Interactive_defensive_widget.dart';
import '../../services/haptic_service.dart';
import 'lineup_dialogs.dart';

void showPlayerMatchStats(
  BuildContext context, {
  required LocalLineupPlayer player,
  required Color teamColor,
  required bool isDark,
  List<LocalLineupPlayer> allPlayers = const [],
  required int matchId,
  required int homeTeamId,
  required int awayTeamId,
  required String homeTeamName,
  required String awayTeamName,
  required List<ShotData> homeShotsData,
  required List<ShotData> awayShotsData,
  required List<DefensiveActionData> homeDefensiveActions,
  required List<DefensiveActionData> awayDefensiveActions,
  required bool showHomeLineup,
  required List<LocalMatchEvent> Function() generateEvents,
  required Map<String, dynamic>? Function(String name) getPlayerSeasonData,
}) {
  final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
  int visualTab = -1;
  final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
  final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
  final divider = isDark ? Colors.grey[800]! : Colors.grey[200]!;
  final sectionBg =
      isDark ? const Color(0xFF222222) : const Color(0xFFF8F8F8);

  Color ratingBg;
  if (player.rating >= 8.0) {
    ratingBg = const Color(0xFF1B5E20);
  } else if (player.rating >= 7.0)
    ratingBg = const Color(0xFF388E3C);
  else if (player.rating >= 6.5)
    ratingBg = const Color(0xFFF9A825);
  else if (player.rating >= 6.0)
    ratingBg = const Color(0xFFEF6C00);
  else
    ratingBg = const Color(0xFFD32F2F);

  final passAcc = player.passes > 0
      ? ((player.passesCompleted / player.passes) * 100).round()
      : 0;

  // Find substitution info from events
  final events = generateEvents();
  LocalMatchEvent? subEvent;
  LocalLineupPlayer? linkedPlayer;
  bool wasSubbedOut = false;

  // Check if this player was subbed OUT (starter replaced)
  for (final e in events) {
    if (e.type == 'substitution' && e.playerName == player.name) {
      subEvent = e;
      wasSubbedOut = true;
      // Find the player who came IN (detail = incoming player name)
      if (e.detail != null) {
        final matches = allPlayers.where((p) => p.name == e.detail);
        if (matches.isNotEmpty) linkedPlayer = matches.first;
      }
      break;
    }
  }
  // Check if this player was subbed IN (substitute entering)
  if (!wasSubbedOut) {
    for (final e in events) {
      if (e.type == 'substitution' && e.detail == player.name) {
        subEvent = e;
        // Find the player who went OUT (playerName = outgoing player)
        final matches = allPlayers.where((p) => p.name == e.playerName);
        if (matches.isNotEmpty) linkedPlayer = matches.first;
        break;
      }
    }
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: bg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => Column(children: [
        // Handle + Close button row
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6, right: 12),
          child: Row(
            children: [
              const Spacer(),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: isDark ? Colors.white70 : Colors.grey[600]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Player header — fixed
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: teamColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: teamColor, width: 2.5),
              ),
              child: Center(
                  child: Text('${player.number}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: teamColor))),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(player.name,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: tx)),
                  Row(children: [
                    Text(player.position,
                        style: TextStyle(fontSize: 13, color: lb)),
                    const SizedBox(width: 8),
                    Text('${player.minutesPlayed}\'',
                        style: TextStyle(
                            fontSize: 13,
                            color: lb,
                            fontWeight: FontWeight.w600)),
                  ]),
                ])),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                  color: ratingBg, borderRadius: BorderRadius.circular(10)),
              child: Text(player.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
            const SizedBox(width: 10),
            // Cuore + Campanella (Builder unificato)
            StatefulBuilder(builder: (ctx, setSheetState) {
              final favSvc = ctx.read<FavoritesService>();
              final notifSvc = ctx.read<PlayerNotificationPreferencesService>();
              final playerId = player.name.hashCode.abs();
              final isFav = favSvc.isPlayerFavorite(playerId);
              final mSet = notifSvc.getSettingsForPlayer(
                player.number, player.name, matchId: matchId,
              );
              final mOn = mSet.hasActiveNotifications;
              return Row(mainAxisSize: MainAxisSize.min, children: [
                // Cuore preferiti
                GestureDetector(
                  onTap: () async {
                    HapticService().lightImpact();
                    final seasonData = getPlayerSeasonData(player.name);
                    final teamName = showHomeLineup ? homeTeamName : awayTeamName;
                    favSvc.togglePlayerFavorite(playerId);
                    if (!isFav) {
                      favSvc.storePlayerMeta(playerId, {
                        'name': player.name,
                        'position': player.position,
                        'number': player.number,
                        'rating': seasonData?['avgRating'] ?? player.rating,
                        'goals': seasonData?['goals'] ?? 0,
                        'assists': seasonData?['assists'] ?? 0,
                        'appearances': seasonData?['appearances'] ?? 0,
                        'yellowCards': seasonData?['yellowCards'] ?? 0,
                        'redCards': seasonData?['redCards'] ?? 0,
                        'nationality': seasonData?['nationality'] ?? '',
                        'age': seasonData?['age'] ?? 0,
                        'team': teamName,
                        'teamId': showHomeLineup ? homeTeamId : awayTeamId,
                      });
                      // [CC-DIALOG-LIVE] regola: accendi default SOLO se spente
                      final existingNotif = notifSvc.getSettingsByPlayerName(player.name);
                      if (existingNotif == null || !existingNotif.hasActiveNotifications) {
                        final preset = PlayerNotificationSettings.essentialOnly(player.number, player.name);
                        await notifSvc.saveSettingsForPlayer(preset);
                        final matchPreset = PlayerNotificationSettings.essentialOnly(
                          player.number, player.name, matchId: matchId,
                        );
                        await notifSvc.saveSettingsForPlayer(matchPreset);
                        await notifSvc.updateAllSettingsForPlayerByName(player.name, preset);
                      }
                    }
                    // [CC-DIALOG-LIVE] cuore rimosso: NON tocca le notifiche
                    setSheetState(() {});
                  },
                  child: Container(
                    width: 38, height: 38,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isFav
                          ? Colors.red.withValues(alpha: 0.15)
                          : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFav
                            ? Colors.red.withValues(alpha: 0.4)
                            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
                      ),
                    ),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 20,
                      color: isFav ? Colors.red : lb,
                    ),
                  ),
                ),
                // Campanella notifiche
                GestureDetector(
                  onTap: () async {
                    if (!mOn) {
                      final preset = PlayerNotificationSettings.essentialOnly(
                        player.number, player.name, matchId: matchId,
                      );
                      await notifSvc.saveSettingsForPlayer(preset);
                      final global = PlayerNotificationSettings.essentialOnly(
                        player.number, player.name,
                      );
                      await notifSvc.saveSettingsForPlayer(global);
                    }
                    // Navigator.pop(context); // Keep sheet open
                    {
                      await showMatchPlayerNotifDialog(
                        context,
                        player: player,
                        teamColor: teamColor,
                        isDark: isDark,
                        matchId: matchId,
                        onShowPlayerStats: (p) => showPlayerMatchStats(
                          context,
                          player: p,
                          teamColor: teamColor,
                          isDark: isDark,
                          allPlayers: allPlayers,
                          matchId: matchId,
                          homeTeamId: homeTeamId,
                          awayTeamId: awayTeamId,
                          homeTeamName: homeTeamName,
                          awayTeamName: awayTeamName,
                          homeShotsData: homeShotsData,
                          awayShotsData: awayShotsData,
                          homeDefensiveActions: homeDefensiveActions,
                          awayDefensiveActions: awayDefensiveActions,
                          showHomeLineup: showHomeLineup,
                          generateEvents: generateEvents,
                          getPlayerSeasonData: getPlayerSeasonData,
                        ),
                      );
                      setSheetState(() {});
                    }
                  },
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: mOn
                          ? teamColor.withValues(alpha: 0.15)
                          : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: mOn
                            ? teamColor.withValues(alpha: 0.4)
                            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
                      ),
                    ),
                    child: Icon(
                      mOn ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                      size: 20,
                      color: mOn ? teamColor : lb,
                    ),
                  ),
                ),
              ]);
            }),
          ]),
        ),
        Container(height: 1, color: divider),

        // "Vedi profilo completo" + "Confronta giocatore"
        Row(children: [
          // Profilo completo
          Expanded(child: GestureDetector(
            onTap: () {
              final nav = Navigator.of(context); nav.pop(); Future.delayed(const Duration(milliseconds: 300), () { nav.push(MaterialPageRoute(builder: (_) => MatchPlayerProfileScreen(player: player, teamName: showHomeLineup ? homeTeamName : awayTeamName, teamColor: teamColor))); });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: divider))),
              child: Row(children: [
                Icon(Icons.person_outline_rounded, color: teamColor, size: 18),
                const SizedBox(width: 8),
                Text(S.of(context)!.profile,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: teamColor)),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: teamColor, size: 20),
              ]),
            ),
          )),
          Container(width: 1, height: 40, color: divider),
          // Confronta
          Expanded(child: GestureDetector(
            onTap: () {
              // [FAV-confronta-fix] cattura context valido prima del pop
              final rootContext = Navigator.of(context, rootNavigator: true).context;
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 300), () {
                showPlayerComparisonPicker(
                  rootContext,
                  player1: player,
                  teamColor: teamColor,
                  isDark: isDark,
                  allPlayers: allPlayers,
                  homeTeamName: homeTeamName,
                  awayTeamName: awayTeamName,
                  homeShotsData: homeShotsData,
                  awayShotsData: awayShotsData,
                  homeDefensiveActions: homeDefensiveActions,
                  awayDefensiveActions: awayDefensiveActions,
                );
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: divider))),
              child: Row(children: [
                Icon(Icons.compare_arrows_rounded, color: lb, size: 18),
                const SizedBox(width: 8),
                Text(S.of(context)!.compare,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: lb, size: 20),
              ]),
            ),
          )),
        ]),

        // Substitution info (if applicable)
        if (subEvent != null) ...[
          GestureDetector(
            onTap: linkedPlayer != null
                ? () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 250), () {
                      showPlayerMatchStats(
                          context,
                          player: linkedPlayer!,
                          teamColor: teamColor,
                          isDark: isDark,
                          matchId: matchId,
                          homeTeamId: homeTeamId,
                          awayTeamId: awayTeamId,
                          homeTeamName: homeTeamName,
                          awayTeamName: awayTeamName,
                          homeShotsData: homeShotsData,
                          awayShotsData: awayShotsData,
                          homeDefensiveActions: homeDefensiveActions,
                          awayDefensiveActions: awayDefensiveActions,
                          showHomeLineup: showHomeLineup,
                          generateEvents: generateEvents,
                          getPlayerSeasonData: getPlayerSeasonData,
                          allPlayers: allPlayers);
                    });
                  }
                : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: divider))),
              child: Row(children: [
                // Sub icon
                Icon(
                  wasSubbedOut
                      ? Icons.subdirectory_arrow_right_rounded
                      : Icons.subdirectory_arrow_left_rounded,
                  color: wasSubbedOut
                      ? const Color(0xFFEF5350)
                      : const Color(0xFF66BB6A),
                  size: 22,
                ),
                const SizedBox(width: 10),
                // Minute
                Text('${subEvent.minute}\'',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: wasSubbedOut
                            ? const Color(0xFFEF5350)
                            : const Color(0xFF66BB6A))),
                const SizedBox(width: 12),
                // Label + player name
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          wasSubbedOut ? tr(context, 'Sostituito da:') : tr(context, 'Sostituito per:'),
                          style: TextStyle(fontSize: 11, color: lb)),
                      Text(
                          linkedPlayer?.name ??
                              (wasSubbedOut
                                  ? subEvent.detail ?? ''
                                  : subEvent.playerName),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tx)),
                    ])),
                // Linked player badge
                if (linkedPlayer != null) ...[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: teamColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: teamColor.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Center(
                        child: Text('${linkedPlayer.number}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: teamColor))),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: lb, size: 20),
                ],
              ]),
            ),
          ),
        ],

        // Minutes played row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: divider))),
          child: Row(children: [
            Icon(Icons.access_time_rounded, color: lb, size: 18),
            const SizedBox(width: 10),
            Text(S.of(context)!.minutesPlayedLabel, style: TextStyle(fontSize: 14, color: lb)),
            const Spacer(),
            Text('${player.minutesPlayed}\'',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
          ]),
        ),

        // Scrollable stats with visual mini-menu
        Expanded(
          child: StatefulBuilder(
            builder: (context, setTabState) {
              return Column(children: [
                // ── MINI-MENU TABS ──
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    _visualTabBtn(S.of(context)!.tiriSection, Icons.gps_fixed_rounded, visualTab == 0, () {
                      setTabState(() => visualTab = visualTab == 0 ? -1 : 0);
                    }, isDark),
                    _visualTabBtn(S.of(context)!.passaggiRLabel, Icons.swap_calls_rounded, visualTab == 1, () {
                      setTabState(() => visualTab = visualTab == 1 ? -1 : 1);
                    }, isDark),
                    _visualTabBtn(S.of(context)!.dribLabel, Icons.directions_run_rounded, visualTab == 2, () {
                      setTabState(() => visualTab = visualTab == 2 ? -1 : 2);
                    }, isDark),
                    _visualTabBtn(S.of(context)!.difLabel, Icons.shield_outlined, visualTab == 3, () {
                      setTabState(() => visualTab = visualTab == 3 ? -1 : 3);
                    }, isDark),
                  ]),
                ),

                // ── CONTENT BASED ON TAB ──
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      // ── HEATMAP (solo in home, nessuna tab selezionata) ──
                      if (visualTab == -1)
                        PlayerHeatmapCard(
                          playerName: player.name,
                          position: player.position,
                          touches: player.touches,
                          teamColor: teamColor,
                          isDark: isDark,
                        ),
                      // ════════════════════════════
                      //  TAB 0: TIRI
                      // ════════════════════════════
                      if (visualTab == 0) ...[
                        PlayerShotMapCard(
                          shots: (showHomeLineup ? homeShotsData : awayShotsData)
                              .where((s) => s.playerName == player.name)
                              .toList(),
                          teamColor: teamColor,
                          isDark: isDark,
                        ),
                        _statSectionHeader(S.of(context)!.attaccoSection, Icons.sports_soccer,
                            const Color(0xFF2E7D32), sectionBg),
                        if (player.goals > 0)
                          _statRow(S.of(context)!.gol, '${player.goals}', tx, lb, divider,
                              highlight: true),
                        if (player.xG > 0)
                          _statRow(tr(context, 'Goal attesi (xG)'),
                              player.xG.toStringAsFixed(2), tx, lb, divider),
                        if (player.assists > 0)
                          _statRow(tr(context, 'Assist'), '${player.assists}', tx, lb, divider,
                              highlight: true),
                        if (player.xA > 0)
                          _statRow(tr(context, 'Assist previsti (xA)'),
                              player.xA.toStringAsFixed(2), tx, lb, divider),
                        _statRow(
                            localizeShotData(context, 'Tiri totali'), '${player.shots}', tx, lb, divider),
                        _statRow(localizeShotData(context, 'Tiri in porta'), '${player.shotsOnTarget}', tx,
                            lb, divider),
                        if (player.keyPasses > 0)
                          _statRow(S.of(context)!.passaggiChiave, '${player.keyPasses}', tx,
                              lb, divider),
                        if (player.offsides > 0)
                          _statRow(
                              localizeShotData(context, 'Fuorigioco'), '${player.offsides}', tx, lb, divider),
                      ],

                      // ════════════════════════════
                      //  TAB 1: PASSAGGI
                      // ════════════════════════════
                      if (visualTab == 1) ...[
                        PlayerPassMapCard(
                          playerName: player.name,
                          position: player.position,
                          passes: player.passes,
                          passesCompleted: player.passesCompleted,
                          keyPasses: player.keyPasses,
                          crosses: player.crosses,
                          crossesCompleted: player.crossesCompleted,
                          teamColor: teamColor,
                          isDark: isDark,
                        ),
                        _statSectionHeader(
                            S.of(context)!.possessoSection,
                            Icons.compare_arrows_rounded,
                            const Color(0xFF1565C0),
                            sectionBg),
                        _statRow(S.of(context)!.tocchi, '${player.touches}', tx, lb, divider),
                        _statRow(
                            S.of(context)!.passaggiPrecisilabel,
                            '${player.passesCompleted}/${player.passes} ($passAcc%)',
                            tx, lb, divider),
                        if (player.crosses > 0)
                          _statRow(
                              localizeShotData(context, 'Cross (precisi)'),
                              '${player.crosses} (${player.crossesCompleted})',
                              tx, lb, divider),
                        if (player.keyPasses > 0)
                          _statRow(S.of(context)!.passaggiChiave, '${player.keyPasses}', tx,
                              lb, divider),
                        if (player.ballsLost > 0)
                          _statRow(
                              localizeShotData(context, 'Palla persa'), '${player.ballsLost}', tx, lb, divider),
                      ],

                      // ════════════════════════════
                      //  TAB 2: DRIBBLING
                      // ════════════════════════════
                      if (visualTab == 2) ...[
                        _statSectionHeader(
                            S.of(context)!.dribblingLabel,
                            Icons.directions_run_rounded,
                            const Color(0xFF7B1FA2),
                            sectionBg),
                        if (player.dribbles > 0)
                          _statRow(
                              localizeShotData(context, 'Dribbling (riusciti)'),
                              '${player.dribbles} (${player.dribblesSuccessful})',
                              tx, lb, divider),
                        _statRow(S.of(context)!.tocchi, '${player.touches}', tx, lb, divider),
                        if (player.foulsWon > 0)
                          _statRow(
                              localizeShotData(context, 'Falli subiti'), '${player.foulsWon}', tx, lb, divider),
                        if (player.ballsLost > 0)
                          _statRow(
                              localizeShotData(context, 'Palla persa'), '${player.ballsLost}', tx, lb, divider),
                        if (player.offsides > 0)
                          _statRow(
                              localizeShotData(context, 'Fuorigioco'), '${player.offsides}', tx, lb, divider),
                      ],

                      // ════════════════════════════
                      //  TAB 3: DIFESA + DISCIPLINA
                      // ════════════════════════════
                      if (visualTab == 3) ...[
                        PlayerDefensiveMapCard(
                          actions: (showHomeLineup ? homeDefensiveActions : awayDefensiveActions)
                              .where((a) => a.playerName == player.name)
                              .toList(),
                          teamColor: teamColor,
                          isDark: isDark,
                        ),
                        _statSectionHeader(S.of(context)!.difesaSection, Icons.shield_outlined,
                            const Color(0xFFE65100), sectionBg),
                        if (player.tackles > 0)
                          _statRow(
                              localizeShotData(context, 'Contrasti vinti'),
                              '${player.tackles} (${player.tacklesWon})',
                              tx, lb, divider),
                        if (player.interceptions > 0)
                          _statRow(
                              localizeShotData(context, 'Intercetti'), '${player.interceptions}', tx, lb, divider),
                        if (player.clearances > 0)
                          _statRow(localizeShotData(context, 'Chiusure difensive'), '${player.clearances}',
                              tx, lb, divider),
                        if (player.recoveries > 0)
                          _statRow(
                              localizeShotData(context, 'Recuperi'), '${player.recoveries}', tx, lb, divider),
                        if (player.duelsTotal > 0)
                          _statRow(
                              'Duelli a terra (vinti)',
                              '${player.duelsTotal} (${player.duelsWon})',
                              tx, lb, divider),
                        if (player.aerialTotal > 0)
                          _statRow(
                              'Duelli aerei (vinti)',
                              '${player.aerialTotal} (${player.aerialWon})',
                              tx, lb, divider),
                        _statSectionHeader(S.of(context)!.disciplinaLabel, Icons.style_rounded,
                            const Color(0xFFF9A825), sectionBg),
                        if (player.fouls > 0)
                          _statRow(
                              tr(context, 'Falli commessi'), '${player.fouls}', tx, lb, divider),
                        if (player.foulsWon > 0)
                          _statRow(
                              localizeShotData(context, 'Falli subiti'), '${player.foulsWon}', tx, lb, divider),
                        if (player.yellowCards > 0)
                          _statRow(
                              S.of(context)!.ammonizioni, '${player.yellowCards}', tx, lb, divider,
                              valueColor: const Color(0xFFF9A825)),
                        if (player.redCards > 0)
                          _statRow(
                              'Espulsioni', '${player.redCards}', tx, lb, divider,
                              valueColor: const Color(0xFFD32F2F)),
                      ],
                    ],
                  ),
                ),
              ]);
            },
          ),
        ),

      ]),
    ),
  );

}

Widget _visualTabBtn(String label, IconData icon, bool isSelected, VoidCallback onTap, bool isDark) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
                  : null,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                  : (isDark ? Colors.grey[500] : Colors.grey[400])),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                      : (isDark ? Colors.grey[500] : Colors.grey[400]))),
            ]),
          ),
          if (isSelected)
            Positioned(
              top: 2, right: 4,
              child: Icon(Icons.close_rounded, size: 12,
                  color: isDark ? Colors.white30 : Colors.grey[400]),
            ),
        ],
      ),
    ),
  );
}

Widget _statSectionHeader(
    String title, IconData icon, Color color, Color sectionBg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    margin: const EdgeInsets.only(top: 4),
    color: sectionBg,
    child: Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, color: color)),
    ]),
  );
}

Widget _statRow(
    String label, String value, Color tx, Color lb, Color divider,
    {bool highlight = false, Color? valueColor}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
    decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: divider, width: 0.5))),
    child: Row(children: [
      Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: highlight ? tx : lb,
                  fontWeight:
                      highlight ? FontWeight.w700 : FontWeight.w400))),
      Text(value,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? tx)),
    ]),
  );
}

