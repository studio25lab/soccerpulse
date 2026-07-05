// lib/widgets/tabs/lineups_tab.dart
//
// Tab "Formazioni" della partita: campo verticale con giocatori posizionati
// per modulo, panchina, profilo allenatore. Estratta da match_detail_screen.dart.
//
// StatefulWidget: gestisce internamente il toggle Campo/Lista (_lineupViewMode).
// Il toggle Casa/Trasferta (showHomeLineup) resta gestito dal padre via callback.
//
// // [FAV-lineups-tab]

import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import '../../models/local_match_models.dart';
import '../../models/match_data.dart';
import '../../painters/match_detail_painters.dart';
import '../../pages/match_player_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Modalita' di visualizzazione delle formazioni.
enum _LineupViewMode { field, list }

class LineupsTab extends StatefulWidget {
  final String homeTeamName;
  final String awayTeamName;
  final MatchData? matchData;
  final bool showHomeLineup;
  final String? homeLogoUrl;
  final String? awayLogoUrl;

  /// Callback per cambiare il toggle Casa/Trasferta.
  final ValueChanged<bool?> onToggleHome;

  /// Genera lineup mock per home/away.
  final List<LocalLineupPlayer> Function(bool isHome) generateLineup;

  /// Genera panchina mock per home/away.
  final List<LocalLineupPlayer> Function(bool isHome) generateBench;

  /// Widget del selettore Casa/Trasferta (condiviso col padre).
  final Widget Function(bool? selected, ValueChanged<bool?> onChanged,
      bool isDark, {bool showTutti}) buildTeamSelector;

  /// Apre il profilo dell-allenatore.
  final void Function(String coachName, bool isHome, Color teamColor, bool isDark) showCoachProfile;

  /// Apre la modale stats giocatore.
  final void Function(LocalLineupPlayer player, Color teamColor, bool isDark,
      {List<LocalLineupPlayer> allPlayers}) showPlayerMatchStats;

  const LineupsTab({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.matchData,
    required this.showHomeLineup,
    this.homeLogoUrl,
    this.awayLogoUrl,
    required this.onToggleHome,
    required this.generateLineup,
    required this.generateBench,
    required this.buildTeamSelector,
    required this.showCoachProfile,
    required this.showPlayerMatchStats,
  });

  @override
  State<LineupsTab> createState() => _LineupsTabState();
}

class _LineupsTabState extends State<LineupsTab> {
  _LineupViewMode _viewMode = _LineupViewMode.field;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _buildLineupsTab(context, theme, isDark);
  }

  Widget _buildLineupsTab(BuildContext context, ThemeData theme, bool isDark) {
    List<LocalLineupPlayer> homeLineup = [];
    List<LocalLineupPlayer> awayLineup = [];
    if (widget.matchData != null) {
      homeLineup = widget.matchData!.homeLineup
          .map((p) => LocalLineupPlayer(
              number: p.number,
              name: p.name,
              position: p.position,
              rating: p.rating,
              goals: p.goals,
              assists: p.assists,
              shots: p.shots,
              shotsOnTarget: p.shotsOnTarget,
              passes: p.passes,
              passesCompleted: p.passesCompleted,
              tackles: p.tackles,
              interceptions: p.interceptions,
              fouls: p.fouls,
              yellowCards: p.yellowCards,
              redCards: p.redCards))
          .toList();
      awayLineup = widget.matchData!.awayLineup
          .map((p) => LocalLineupPlayer(
              number: p.number,
              name: p.name,
              position: p.position,
              rating: p.rating,
              goals: p.goals,
              assists: p.assists,
              shots: p.shots,
              shotsOnTarget: p.shotsOnTarget,
              passes: p.passes,
              passesCompleted: p.passesCompleted,
              tackles: p.tackles,
              interceptions: p.interceptions,
              fouls: p.fouls,
              yellowCards: p.yellowCards,
              redCards: p.redCards))
          .toList();
    }
    if (homeLineup.isEmpty) homeLineup = widget.generateLineup(true);
    if (awayLineup.isEmpty) awayLineup = widget.generateLineup(false);

    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    const homeFormation = '4-3-3';
    const awayFormation = '4-2-3-1';
    final homeBench = widget.generateBench(true);
    final awayBench = widget.generateBench(false);
    const homeCoach = 'Maurizio Sarri';
    const awayCoach = 'Stefano Pioli';

    final lineup = widget.showHomeLineup ? homeLineup : awayLineup;
    final formation = widget.showHomeLineup ? homeFormation : awayFormation;
    final bench = widget.showHomeLineup ? homeBench : awayBench;
    final coach = widget.showHomeLineup ? homeCoach : awayCoach;
    final teamColor =
        widget.showHomeLineup ? const Color(0xFF1565C0) : const Color(0xFFD32F2F);
    final allPlayers = [...lineup, ...bench];

    // Average rating
    final avgRating = lineup
            .where((p) => p.rating > 0)
            .fold(0.0, (sum, p) => sum + p.rating) /
        lineup.where((p) => p.rating > 0).length;
    Color avgRatingBg;
    if (avgRating >= 8.0) {
      avgRatingBg = const Color(0xFF1B5E20);
    } else if (avgRating >= 7.0)
      avgRatingBg = const Color(0xFF388E3C);
    else if (avgRating >= 6.5)
      avgRatingBg = const Color(0xFFF9A825);
    else if (avgRating >= 6.0)
      avgRatingBg = const Color(0xFFEF6C00);
    else
      avgRatingBg = const Color(0xFFD32F2F);

    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA),
      child: Column(children: [
        // Team selector — same style as other sections
        widget.buildTeamSelector(widget.showHomeLineup,
            widget.onToggleHome, isDark,
            showTutti: false),

        // Toggle Campo / Lista
        _buildViewModeToggle(isDark, tx, lb),

        // Contenuto: campo (con bench/coach) oppure lista
        Expanded(
          child: _viewMode == _LineupViewMode.field
              ? _buildFieldView(context, isDark, tx, lb, cardBg, lineup, bench,
                  formation, coach, teamColor, avgRating, avgRatingBg,
                  allPlayers)
              : _buildListView(context, isDark, tx, lb, cardBg, homeLineup,
                  awayLineup, homeBench, awayBench),
        ),
      ]),
    );
  }

  // ── Toggle Campo / Lista ──
  Widget _buildViewModeToggle(bool isDark, Color tx, Color lb) {
    final selBg = isDark ? const Color(0xFF1565C0) : const Color(0xFF1565C0);
    final trackBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    Widget seg(String label, Widget icon, _LineupViewMode mode) {
      final selected = _viewMode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _viewMode = mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? selBg : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              icon,
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : lb)),
            ]),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Row(children: [
        seg(
            localizeShotData(context, 'Campo'),
            SizedBox(
              width: 17,
              height: 17,
              child: CustomPaint(
                painter: _SoccerFieldIcon(
                    color: _viewMode == _LineupViewMode.field
                        ? Colors.white
                        : lb),
              ),
            ),
            _LineupViewMode.field),
        seg(
            localizeShotData(context, 'Lista'),
            Icon(Icons.format_list_bulleted,
                size: 16,
                color: _viewMode == _LineupViewMode.list
                    ? Colors.white
                    : lb),
            _LineupViewMode.list),
      ]),
    );
  }

  // ── VISTA LISTA (due colonne stile diretta.it) ──
  Widget _buildListView(
      BuildContext context,
      bool isDark,
      Color tx,
      Color lb,
      Color cardBg,
      List<LocalLineupPlayer> homeLineup,
      List<LocalLineupPlayer> awayLineup,
      List<LocalLineupPlayer> homeBench,
      List<LocalLineupPlayer> awayBench) {
    const homeColor = Color(0xFF1565C0);
    const awayColor = Color(0xFFD32F2F);
    final homeAll = [...homeLineup, ...homeBench];
    final awayAll = [...awayLineup, ...awayBench];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colonna CASA
          Expanded(
            child: _buildListColumn(
              context, isDark, tx, lb, cardBg,
              widget.homeTeamName, widget.homeLogoUrl, homeColor, true,
              homeLineup, homeBench, homeAll),
          ),
          const SizedBox(width: 8),
          // Colonna OSPITE
          Expanded(
            child: _buildListColumn(
              context, isDark, tx, lb, cardBg,
              widget.awayTeamName, widget.awayLogoUrl, awayColor, false,
              awayLineup, awayBench, awayAll),
          ),
        ],
      ),
    );
  }

  Widget _buildListColumn(
      BuildContext context,
      bool isDark,
      Color tx,
      Color lb,
      Color cardBg,
      String teamName,
      String? logoUrl,
      Color teamColor,
      bool isHome,
      List<LocalLineupPlayer> lineup,
      List<LocalLineupPlayer> bench,
      List<LocalLineupPlayer> allPlayers) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header squadra con LOGO reale
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: teamColor.withValues(alpha: isDark ? 0.18 : 0.10),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
          ),
          child: Row(children: [
            _teamLogoSmall(logoUrl, teamColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(teamName,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: tx),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
        // Titolari (zebra via index)
        ...lineup.asMap().entries.map((e) => _buildListPlayerRow(
            context, e.value, teamColor, isHome, isDark, tx, lb, allPlayers,
            e.key.isOdd)),
        // Separatore panchina
        if (bench.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.06),
            child: Text(localizeShotData(context, 'Panchina'),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: lb,
                    letterSpacing: 0.5)),
          ),
          ...bench.asMap().entries.map((e) => _buildListPlayerRow(
              context, e.value, teamColor, isHome, isDark, tx, lb, allPlayers,
              e.key.isOdd)),
        ],
      ]),
    );
  }

  // Logo squadra piccolo con fallback a scudo
  Widget _teamLogoSmall(String? logoUrl, Color teamColor) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          width: 22, height: 22, fit: BoxFit.contain,
          errorWidget: (_, __, ___) => Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
                color: teamColor.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(Icons.shield, color: teamColor, size: 13),
          ),
        ),
      );
    }
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
          color: teamColor.withValues(alpha: 0.18), shape: BoxShape.circle),
      child: Icon(Icons.shield, color: teamColor, size: 13),
    );
  }

  Widget _buildListPlayerRow(
      BuildContext context,
      LocalLineupPlayer player,
      Color teamColor,
      bool isHome,
      bool isDark,
      Color tx,
      Color lb,
      List<LocalLineupPlayer> allPlayers,
      bool zebra) {
    final hasYellow = player.yellowCards > 0;
    final hasRed = player.redCards > 0;
    final hasGoal = player.goals > 0;
    final wasSubbed = player.minutesPlayed < 90 && player.minutesPlayed > 0;
    final didNotPlay = player.minutesPlayed == 0;

    // Rating badge color per fascia
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

    final zebraBg = zebra
        ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.04))
        : Colors.transparent;

    return InkWell(
      onTap: () {
        if (didNotPlay) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MatchPlayerProfileScreen(
                  player: player,
                  teamName: isHome ? widget.homeTeamName : widget.awayTeamName,
                  teamColor: teamColor)));
        } else {
          widget.showPlayerMatchStats(player, teamColor, isDark,
              allPlayers: allPlayers);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        color: zebraBg,
        child: Row(children: [
          // Numero in cerchietto
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: didNotPlay
                  ? (isDark ? Colors.grey[800] : Colors.grey[200])
                  : teamColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('${player.number}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: didNotPlay ? lb : teamColor)),
            ),
          ),
          const SizedBox(width: 8),
          // Nome
          Expanded(
            child: Text(_shortName(player.name),
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: didNotPlay ? lb : tx),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          // Icone evento
          if (hasGoal) ...[
            const SizedBox(width: 3),
            Icon(Icons.sports_soccer, size: 13, color: tx),
            if (player.goals > 1)
              Padding(
                padding: const EdgeInsets.only(left: 1),
                child: Text('${player.goals}',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: tx)),
              ),
          ],
          if (wasSubbed) ...[
            const SizedBox(width: 3),
            const Icon(Icons.swap_horiz_rounded,
                size: 14, color: Color(0xFFEF5350)),
          ],
          if (hasYellow || hasRed) ...[
            const SizedBox(width: 3),
            Container(
              width: 8,
              height: 11,
              decoration: BoxDecoration(
                color: hasRed
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFFF9A825),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
          // Rating badge a destra
          if (!didNotPlay && player.rating > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: ratingBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(player.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ],
        ]),
      ),
    );
  }

  // ── VISTA CAMPO (identica all'originale) ──
  Widget _buildFieldView(
      BuildContext context,
      bool isDark,
      Color tx,
      Color lb,
      Color cardBg,
      List<LocalLineupPlayer> lineup,
      List<LocalLineupPlayer> bench,
      String formation,
      String coach,
      Color teamColor,
      double avgRating,
      Color avgRatingBg,
      List<LocalLineupPlayer> allPlayers) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        // ── VISUAL PITCH ──
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(children: [
              // Team header bar
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: const Color(0xFF1B5E20),
                child: Row(children: [
                  // Team shield
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: teamColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                    child: Icon(Icons.shield, color: teamColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                      widget.showHomeLineup
                          ? widget.homeTeamName
                          : widget.awayTeamName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(width: 10),
                  // Avg rating badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: avgRatingBg,
                        borderRadius: BorderRadius.circular(5)),
                    child: Text(avgRating.toStringAsFixed(2),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const Spacer(),
                  // Formation label
                  Text(formation,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                          letterSpacing: 1)),
                ]),
              ),
              // Pitch — responsive: max 420px height, wider on desktop
              LayoutBuilder(builder: (context, outerConstraints) {
                const maxH = 460.0;
                // On narrow screens (mobile) use 0.75, on wide (desktop) use 0.85
                final ratio = outerConstraints.maxWidth > 600 ? 0.85 : 0.75;
                final calcH = outerConstraints.maxWidth / ratio;
                final pitchH = calcH > maxH ? maxH : calcH;
                return SizedBox(
                  height: pitchH,
                  child: CustomPaint(
                    painter: FormationPitchPainter(isDark: isDark),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      final positions = _getFormationPositions(formation);

                      return Stack(clipBehavior: Clip.none, children: [
                        for (int i = 0;
                            i < lineup.length && i < positions.length;
                            i++)
                          _buildPitchPlayer(
                            lineup[i],
                            positions[i],
                            w,
                            h,
                            teamColor,
                            isDark,
                            allPlayers: allPlayers,
                          ),
                      ]);
                    }),
                  ),
                );
              }),
            ]),
          ),
        ),
        const SizedBox(height: 20),

        // ── COACH ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: GestureDetector(
            onTap: () => widget.showCoachProfile(
                coach, widget.showHomeLineup, teamColor, isDark),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: teamColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_outline_rounded,
                    color: teamColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(localizeShotData(context, localizeShotData(context, 'Allenatore')),
                      style: TextStyle(
                          fontSize: 11,
                          color: lb,
                          fontWeight: FontWeight.w500)),
                  Text(coach,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tx)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: lb, size: 20),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── PANCHINA ──
        Align(
          alignment: Alignment.centerLeft,
          child: Text(localizeShotData(context, 'Panchina'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: tx)),
        ),
        const SizedBox(height: 10),
        ...bench.map((p) => _buildBenchPlayerItem(context,
            p, teamColor, isDark, tx, lb, cardBg,
            allPlayers: allPlayers)),
        const SizedBox(height: 20),
      ]),
    );
  }

  List<Offset> _getFormationPositions(String formation) {
    switch (formation) {
      case '4-3-3':
        return const [
          Offset(0.50, 0.12), // GK
          Offset(0.12, 0.28), Offset(0.37, 0.28), Offset(0.63, 0.28),
          Offset(0.88, 0.28), // DEF
          Offset(0.28, 0.48), Offset(0.72, 0.48), Offset(0.50, 0.56), // MID
          Offset(0.15, 0.76), Offset(0.50, 0.85), Offset(0.85, 0.76), // ATK
        ];
      case '4-2-3-1':
        return const [
          Offset(0.50, 0.12), // GK
          Offset(0.12, 0.28), Offset(0.37, 0.28), Offset(0.63, 0.28),
          Offset(0.88, 0.28), // DEF
          Offset(0.33, 0.46), Offset(0.67, 0.46), // DM
          Offset(0.15, 0.64), Offset(0.50, 0.64), Offset(0.85, 0.64), // AM
          Offset(0.50, 0.84), // ST
        ];
      default:
        return const [
          Offset(0.50, 0.12),
          Offset(0.12, 0.28), Offset(0.37, 0.28), Offset(0.63, 0.28),
          Offset(0.88, 0.28),
          Offset(0.25, 0.48), Offset(0.50, 0.48), Offset(0.75, 0.48),
          Offset(0.18, 0.72), Offset(0.50, 0.82), Offset(0.82, 0.72),
        ];
    }
  }

  Widget _buildPitchPlayer(LocalLineupPlayer player, Offset pos, double pitchW,
      double pitchH, Color teamColor, bool isDark,
      {List<LocalLineupPlayer> allPlayers = const []}) {
    final x = pos.dx * pitchW;
    // [FAV-fix-gk-name] padding bottom 35px per nome portiere visibile
    final y = (1.0 - pos.dy) * (pitchH - 35);
    // Responsive dot size: BIG — min 46, max 58
    final dotSize = (pitchH * 0.12).clamp(46.0, 58.0);

    // Rating color
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

    // Event badges
    final hasYellow = player.yellowCards > 0;
    final hasRed = player.redCards > 0;
    // Substituted = starter who played less than 90 minutes
    final wasSubbed = player.minutesPlayed < 90 && player.minutesPlayed > 0;

    final fontSize = (dotSize * 0.36).clamp(14.0, 20.0);
    final nameFontSize = (dotSize * 0.20).clamp(9.0, 11.0);
    final ratingFontSize = (dotSize * 0.22).clamp(10.0, 13.0);
    final badgeSize = dotSize * 0.38;

    return Positioned(
      left: x - dotSize / 2 - 16,
      top: y - dotSize / 2 - 4,
      child: GestureDetector(
        onTap: () => widget.showPlayerMatchStats(player, teamColor, isDark,
            allPlayers: allPlayers),
        child: SizedBox(
          width: dotSize + 32,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Player circle with event badges
            SizedBox(
              width: dotSize + 12,
              height: dotSize + 12,
              child: Stack(clipBehavior: Clip.none, children: [
                // Main circle — white with team color border
                Center(
                    child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: teamColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Center(
                      child: Text(
                    '${player.number}',
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                        height: 1),
                  )),
                )),
                // Yellow/Red card badge — top right
                if (hasYellow || hasRed)
                  Positioned(
                    top: -2,
                    right: 2,
                    child: Container(
                      width: dotSize * 0.28,
                      height: dotSize * 0.38,
                      decoration: BoxDecoration(
                        color: hasRed
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFFF9A825),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 3)
                        ],
                      ),
                    ),
                  ),
                // Substitution badge — top left (red arrow out)
                if (wasSubbed)
                  Positioned(
                    top: -3,
                    left: 0,
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 3)
                        ],
                      ),
                      child: Icon(Icons.swap_horiz_rounded,
                          size: badgeSize * 0.65,
                          color: const Color(0xFFEF5350)),
                    ),
                  ),
              ]),
            ),
            // Rating badge — overlaps circle bottom
            Transform.translate(
              offset: const Offset(0, -8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: ratingBg,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5), blurRadius: 4)
                  ],
                ),
                child: Text(
                  player.rating.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: ratingFontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2),
                ),
              ),
            ),
            // Player name: "27 N. Semedo"
            Transform.translate(
              offset: const Offset(0, -4),
              child: Text(
                '${player.number} ${_shortName(player.name)}',
                style: TextStyle(
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 4)
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildBenchPlayerItem(BuildContext context, LocalLineupPlayer player, Color teamColor,
      bool isDark, Color tx, Color lb, Color cardBg,
      {List<LocalLineupPlayer> allPlayers = const []}) {
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

    return GestureDetector(
        onTap: () {
          if (player.minutesPlayed > 0) {
            widget.showPlayerMatchStats(player, teamColor, isDark, allPlayers: allPlayers);
          } else {
            final teamName = widget.showHomeLineup ? widget.homeTeamName : widget.awayTeamName;
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchPlayerProfileScreen(player: player, teamName: teamName, teamColor: teamColor)));
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: teamColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                  child: Text('${player.number}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: teamColor))),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(player.name,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tx)),
                  Text(player.position,
                      style: TextStyle(fontSize: 11, color: lb)),
                ])),
            if (player.rating > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: ratingBg, borderRadius: BorderRadius.circular(6)),
                child: Text(player.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('-',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ),
          ]),
        ));
  }

  String _shortName(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) return name;
    if (name.length <= 10) return name;
    // "Luis Alberto" → "L. Alberto", "Theo Hernandez" → "T. Hernandez"
    return '${parts.first[0]}. ${parts.last}';
  }
}


// Mini campo da calcio per il toggle: perimetro + meta' campo + cerchio.
class _SoccerFieldIcon extends CustomPainter {
  final Color color;
  _SoccerFieldIcon({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(0.7, 0.7, w - 1.4, h - 1.4), const Radius.circular(1.5));
    // Perimetro
    canvas.drawRRect(r, p);
    // Linea di meta' campo (verticale)
    canvas.drawLine(Offset(w / 2, 0.7), Offset(w / 2, h - 0.7), p);
    // Cerchio di centrocampo
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.15, p);
    // Aree di rigore (rettangolini ai lati corti)
    final boxH = h * 0.44;
    final boxW = w * 0.18;
    final boxTop = (h - boxH) / 2;
    canvas.drawRect(Rect.fromLTWH(0.7, boxTop, boxW, boxH), p);
    canvas.drawRect(Rect.fromLTWH(w - 0.7 - boxW, boxTop, boxW, boxH), p);
  }

  @override
  bool shouldRepaint(_SoccerFieldIcon old) => old.color != color;
}
