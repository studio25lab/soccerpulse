// lib/pages/match_player_comparison_screen.dart
//
// Schermata di confronto giocatori durante una specifica partita.
// Lavora su LocalLineupPlayer + dati partita (tiri, azioni difensive).
// Estratta da match_detail_screen.dart.
//
// Distinguere da PlayerComparisonScreen (in player_comparison_screen.dart)
// che e' il confronto generico su modello Player (per stats stagionali).
//
// // [FAV-comparison-extract]

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import '../generated/l10n.dart';
import 'package:soccerpulse/models/local_match_models.dart';
import '../widgets/interactive_shot_map_widget.dart';
import '../widgets/Interactive_defensive_widget.dart';
import 'package:soccerpulse/main.dart';
import '../widgets/player_match_visuals.dart';

class MatchPlayerComparisonScreen extends StatefulWidget {
  final List<LocalLineupPlayer> initialPlayers;
  final List<LocalLineupPlayer> allPlayers;
  final String homeTeamName;
  final String awayTeamName;
  final List<ShotData> homeShotsData;
  final List<ShotData> awayShotsData;
  final List<DefensiveActionData> homeDefensiveActions;
  final List<DefensiveActionData> awayDefensiveActions;

  const MatchPlayerComparisonScreen({
    required this.initialPlayers,
    required this.allPlayers,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeShotsData = const <ShotData>[],
    this.awayShotsData = const <ShotData>[],
    this.homeDefensiveActions = const <DefensiveActionData>[],
    this.awayDefensiveActions = const <DefensiveActionData>[],
  });

  @override
  State<MatchPlayerComparisonScreen> createState() => _MatchPlayerComparisonScreenState();
}

class _MatchPlayerComparisonScreenState extends State<MatchPlayerComparisonScreen> {
  late List<LocalLineupPlayer> _players;

  @override
  void initState() {
    super.initState();
    _players = List.from(widget.initialPlayers);
  }

  Color _teamColor(LocalLineupPlayer p) {
    // Determina colore in base alla squadra
    final homeNumbers = widget.allPlayers
        .take(widget.allPlayers.length ~/ 2)
        .map((pl) => pl.number)
        .toSet();
    return homeNumbers.contains(p.number)
        ? const Color(0xFF1565C0)
        : const Color(0xFFD32F2F);
  }

  String _teamName(LocalLineupPlayer p) {
    final homeNumbers = widget.allPlayers
        .take(widget.allPlayers.length ~/ 2)
        .map((pl) => pl.number)
        .toSet();
    return homeNumbers.contains(p.number)
        ? widget.homeTeamName
        : widget.awayTeamName;
  }

  void _addPlayer() {
    final used = _players.map((p) => p.number).toSet();
    final available = widget.allPlayers.where((p) => !used.contains(p.number)).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = isDark ? Colors.white : Colors.black87;
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(tr(context, 'Aggiungi giocatore'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tx)),
        ),
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: available.length,
            itemBuilder: (ctx, i) {
              final p = available[i];
              final c = _teamColor(p);
              return ListTile(
                dense: true,
                leading: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: c.withOpacity(0.12), shape: BoxShape.circle,
                      border: Border.all(color: c.withOpacity(0.3))),
                  child: Center(child: Text('${p.number}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c))),
                ),
                title: Text(p.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tx)),
                subtitle: Text('${p.position} · ${p.rating.toStringAsFixed(1)}', style: TextStyle(fontSize: 11, color: lb)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() { _players.add(p); });
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  void _removePlayer(int index) {
    if (_players.length <= 2) return;
    setState(() { _players.removeAt(index); });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF0F2F5);
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0D0D1A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: tx),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(tr(context, 'Confronto Giocatori'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tx)),
        centerTitle: true,
        actions: [
              IconButton(
                icon: const Icon(Icons.home_rounded, size: 22),
                tooltip: 'Home',
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                },
              ),
          if (_players.length < 4)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_add_rounded, size: 18, color: Color(0xFF1565C0)),
              ),
              onPressed: _addPlayer,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Row(
        children: _players.asMap().entries.map((entry) {
          final idx = entry.key;
          final p = entry.value;
          final c = _teamColor(p);
          final team = _teamName(p);
          final isLast = idx == _players.length - 1;

          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: isLast ? null : Border(right: BorderSide(color: divider, width: 1)),
              ),
              child: MatchPlayerComparisonColumn(
                key: ValueKey('comparison_${p.number}'),
                player: p,
                teamColor: c,
                teamName: team,
                isDark: isDark,
                canRemove: _players.length > 2,
                onRemove: () => _removePlayer(idx),
                shotsData: c == const Color(0xFF1565C0)
                    ? widget.homeShotsData : widget.awayShotsData,
                defensiveActions: c == const Color(0xFF1565C0)
                    ? widget.homeDefensiveActions : widget.awayDefensiveActions,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
class MatchPlayerComparisonColumn extends StatefulWidget {
  final LocalLineupPlayer player;
  final Color teamColor;
  final String teamName;
  final bool isDark;
  final bool canRemove;
  final VoidCallback onRemove;
  final List<ShotData> shotsData;
  final List<DefensiveActionData> defensiveActions;

  const MatchPlayerComparisonColumn({
    super.key,
    required this.player,
    required this.teamColor,
    required this.teamName,
    required this.isDark,
    required this.canRemove,
    required this.onRemove,
    this.shotsData = const <ShotData>[],
    this.defensiveActions = const <DefensiveActionData>[],
  });

  @override
  State<MatchPlayerComparisonColumn> createState() => _MatchPlayerComparisonColumnState();
}

class _MatchPlayerComparisonColumnState extends State<MatchPlayerComparisonColumn> {
  int _tab = -1; // 0=Tiri, 1=Pass, 2=Drib, 3=Dif

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final p = widget.player;
    final teamColor = widget.teamColor;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);
    final sectionBg = isDark ? const Color(0xFF222222) : const Color(0xFFF8F8F8);

    Color ratingColor;
    if (p.rating >= 7.5) ratingColor = const Color(0xFF1B5E20);
    else if (p.rating >= 7.0) ratingColor = const Color(0xFF388E3C);
    else if (p.rating >= 6.5) ratingColor = const Color(0xFFF9A825);
    else ratingColor = const Color(0xFFEF6C00);

    final passAcc = p.passes > 0 ? (p.passesCompleted / p.passes * 100).round() : 0;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(),
          child: Column(children: [
            if (widget.canRemove)
              Align(alignment: Alignment.topRight, child: GestureDetector(
                onTap: widget.onRemove,
                child: Padding(padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.close_rounded, size: 16, color: lb)),
              )),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: teamColor.withOpacity(0.15), shape: BoxShape.circle,
                border: Border.all(color: teamColor, width: 2),
              ),
              child: Center(child: Text('${p.number}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: teamColor))),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(p.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tx),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Text('${p.position} · ${widget.teamName}', style: TextStyle(fontSize: 9, color: lb)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: ratingColor, borderRadius: BorderRadius.circular(6)),
                child: Text(p.rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(width: 6),
              Text("${p.minutesPlayed}'", style: TextStyle(fontSize: 10, color: lb)),
            ]),
          ]),
        ),

        // ── Visual Tabs ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            _tabBtn(S.of(context)!.tiriSection, Icons.gps_fixed_rounded, 0),
            _tabBtn(S.of(context)!.passaggiRLabel, Icons.swap_calls_rounded, 1),
            _tabBtn(S.of(context)!.dribLabel, Icons.directions_run_rounded, 2),
            _tabBtn(S.of(context)!.difLabel, Icons.shield_outlined, 3),

          ]),
        ),

        // ── Heatmap (solo in home, nessuna tab selezionata) ──
        if (_tab == -1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: PlayerHeatmapCard(
              playerName: p.name,
              position: p.position,
              touches: p.touches,
              teamColor: teamColor,
              isDark: isDark,
            ),
          ),

        // ── TAB 0: TIRI / ATTACCO ──
        if (_tab == 0) ...[
          // Shot map
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: PlayerShotMapCard(
              shots: widget.shotsData
                  .where((s) => s.playerName == p.name)
                  .toList(),
              teamColor: teamColor,
              isDark: isDark,
            ),
          ),
          _header(S.of(context)!.attaccoSection, Icons.sports_soccer, const Color(0xFF2E7D32), sectionBg),
          _row(S.of(context)!.gol, '${p.goals}', tx, lb, divider, highlight: p.goals > 0),
          _row('xG', p.xG.toStringAsFixed(2), tx, lb, divider),
          _row(tr(context, 'Assist'), '${p.assists}', tx, lb, divider, highlight: p.assists > 0),
          _row('xA', p.xA.toStringAsFixed(2), tx, lb, divider),
          _row(localizeShotData(context, 'Tiri totali'), '${p.shots}', tx, lb, divider),
          _row(localizeShotData(context, 'Tiri in porta'), '${p.shotsOnTarget}', tx, lb, divider),
          _row(tr(context, 'Pass. chiave'), '${p.keyPasses}', tx, lb, divider),
          if (p.offsides > 0) _row(localizeShotData(context, 'Fuorigioco'), '${p.offsides}', tx, lb, divider),
        ],

        // ── TAB 1: PASSAGGI ──
        if (_tab == 1) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: PlayerPassMapCard(
              playerName: p.name,
              position: p.position,
              passes: p.passes,
              passesCompleted: p.passesCompleted,
              keyPasses: p.keyPasses,
              crosses: p.crosses,
              crossesCompleted: p.crossesCompleted,
              teamColor: teamColor,
              isDark: isDark,
            ),
          ),
          _header(S.of(context)!.possessoSection, Icons.compare_arrows_rounded, const Color(0xFF1565C0), sectionBg),
          _row(S.of(context)!.tocchi, '${p.touches}', tx, lb, divider),
          _row(S.of(context)!.passaggiSection, '${p.passesCompleted}/${p.passes}', tx, lb, divider),
          _row(S.of(context)!.precisione, '$passAcc%', tx, lb, divider),
          if (p.keyPasses > 0) _row(tr(context, 'Pass. chiave'), '${p.keyPasses}', tx, lb, divider),
          if (p.crosses > 0) _row(tr(context, 'Cross'), '${p.crossesCompleted}/${p.crosses}', tx, lb, divider),
          if (p.ballsLost > 0) _row(tr(context, 'Palle perse'), '${p.ballsLost}', tx, lb, divider),
        ],

        // ── TAB 2: DRIBBLING ──
        if (_tab == 2) ...[
          _header(S.of(context)!.dribblingLabel, Icons.directions_run_rounded, Color(0xFF7B1FA2), sectionBg),
          if (p.dribbles > 0) _row(S.of(context)!.dribblingLabel, '${p.dribblesSuccessful}/${p.dribbles}', tx, lb, divider),
          _row(S.of(context)!.tocchi, '${p.touches}', tx, lb, divider),
          if (p.foulsWon > 0) _row(localizeShotData(context, 'Falli subiti'), '${p.foulsWon}', tx, lb, divider),
          if (p.ballsLost > 0) _row(tr(context, 'Palle perse'), '${p.ballsLost}', tx, lb, divider),
          if (p.offsides > 0) _row(localizeShotData(context, 'Fuorigioco'), '${p.offsides}', tx, lb, divider),
        ],

        // ── TAB 3: DIFESA + DISCIPLINA ──
        if (_tab == 3) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: PlayerDefensiveMapCard(
              actions: widget.defensiveActions
                  .where((a) => a.playerName == p.name)
                  .toList(),
              teamColor: teamColor,
              isDark: isDark,
            ),
          ),
          _header(S.of(context)!.difesaSection, Icons.shield_outlined, Color(0xFFE65100), sectionBg),
          if (p.tackles > 0) _row(localizeShotData(context, 'Contrasti'), '${p.tacklesWon}/${p.tackles}', tx, lb, divider),
          if (p.interceptions > 0) _row(localizeShotData(context, 'Intercetti'), '${p.interceptions}', tx, lb, divider),
          if (p.clearances > 0) _row(tr(context, 'Chiusure'), '${p.clearances}', tx, lb, divider),
          if (p.recoveries > 0) _row(tr(context, 'Recuperi'), '${p.recoveries}', tx, lb, divider),
          if (p.duelsTotal > 0) _row(S.of(context)!.duelliLabel, '${p.duelsWon}/${p.duelsTotal}', tx, lb, divider),
          if (p.aerialTotal > 0) _row(tr(context, 'Aerei'), '${p.aerialWon}/${p.aerialTotal}', tx, lb, divider),
          SizedBox(height: 6),
          _header(S.of(context)!.disciplinaLabel, Icons.style_rounded, Color(0xFFC62828), sectionBg),
          _row(S.of(context)!.falliLabel, '${p.fouls}', tx, lb, divider),
          _row(localizeShotData(context, 'Falli subiti'), '${p.foulsWon}', tx, lb, divider),
          _row(tr(context, 'Gialli'), '${p.yellowCards}', tx, lb, divider,
              valueColor: p.yellowCards > 0 ? const Color(0xFFFDD835) : null),
          _row(tr(context, 'Rossi'), '${p.redCards}', tx, lb, divider,
              valueColor: p.redCards > 0 ? const Color(0xFFE53935) : null),
        ],

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _tabBtn(String label, IconData icon, int idx) {
    final isOn = _tab == idx;
    final tc = widget.teamColor;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() { _tab = _tab == idx ? -1 : idx; }),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isOn ? tc.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14, color: isOn ? tc : (widget.isDark ? Colors.white38 : Colors.grey)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 8, fontWeight: isOn ? FontWeight.w700 : FontWeight.w400,
                  color: isOn ? tc : (widget.isDark ? Colors.white38 : Colors.grey))),
            ]),
          ),
          if (isOn)
            Positioned(
              top: 2, right: 4,
              child: Icon(Icons.close_rounded, size: 10,
                  color: widget.isDark ? Colors.white30 : Colors.grey[400]),
            ),
        ],
      ),
    ));
  }



  Widget _header(String title, IconData icon, Color color, Color bg) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: bg,
      child: Row(children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  Widget _row(String label, String value, Color tx, Color lb, Color divider,
      {bool highlight = false, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: divider))),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 10, color: lb))),
        Text(value, style: TextStyle(
          fontSize: 12,
          fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
          color: valueColor ?? (highlight ? widget.teamColor : tx),
        )),
      ]),
    );
  }
}
