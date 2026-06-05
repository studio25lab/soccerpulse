// lib/widgets/tabs/probable_lineups_tab.dart
//
// Tab "Probabili Formazioni" pre-match: mostra formazioni probabili
// delle due squadre su un campo verde + panchina con allenatore.
// Estratta da match_detail_screen.dart.
//
// Include i dati mock di:
//   - 12 formazioni squadre Serie A
//   - 11+ lineup base per squadra
//   - 5 panchine
//   - 12 nomi allenatori
//
// // [FAV-probable-lineups]

import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import '../../models/local_match_models.dart';
import '../../painters/match_detail_painters.dart';

/// Dati del giocatore tappato (utilizzato dal callback onPlayerTap).
class TappedPlayerInfo {
  final LocalLineupPlayer player;
  final String teamName;
  final Color teamColor;

  const TappedPlayerInfo({
    required this.player,
    required this.teamName,
    required this.teamColor,
  });
}

class ProbableLineupsTab extends StatelessWidget {
  final String homeName;
  final String awayName;
  final Color homeColor;
  final Color awayColor;

  /// Callback chiamato al tap su giocatore o allenatore.
  /// Il padre si occupa di aprire MatchPlayerProfileScreen via Navigator.
  final void Function(TappedPlayerInfo info) onPlayerTap;

  const ProbableLineupsTab({
    Key? key,
    required this.homeName,
    required this.awayName,
    required this.homeColor,
    required this.awayColor,
    required this.onPlayerTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? Colors.grey[900]! : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final divider = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.grey.withOpacity(0.1);

    final homeFormation = _getPreMatchFormation(homeName);
    final awayFormation = _getPreMatchFormation(awayName);
    final homePlayers = _getPreMatchLineup(homeName);
    final awayPlayers = _getPreMatchLineup(awayName);
    final homeBench = _getPreMatchBench(homeName);
    final awayBench = _getPreMatchBench(awayName);

    return Container(
      color: bg,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Formation header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: divider),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(tr(context, 'Probabili Formazioni'),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryColor,
                      letterSpacing: 0.5)),
            ),
            Row(children: [
              Expanded(
                  child: Column(children: [
                Text(homeName,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: homeColor)),
                const SizedBox(height: 2),
                Text(homeFormation,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: tx)),
              ])),
              Container(
                  width: 1,
                  height: 40,
                  color: isDark
                      ? Colors.white12
                      : Colors.grey.withOpacity(0.15)),
              Expanded(
                  child: Column(children: [
                Text(awayName,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: awayColor)),
                const SizedBox(height: 2),
                Text(awayFormation,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: tx)),
              ])),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Field with players
        Container(
          height: 800,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2E7D32),
                Color(0xFF388E3C),
                Color(0xFF43A047),
                Color(0xFF388E3C),
                Color(0xFF2E7D32)
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            final fw = constraints.maxWidth;
            const fh = 800.0;
            const dotW = 82.0;
            return Stack(clipBehavior: Clip.none, children: [
              CustomPaint(size: Size(fw, fh), painter: PreMatchFieldPainter()),
              ...homePlayers.asMap().entries.map((e) {
                final p = e.value;
                final ppx = (p['px'] as double?) ??
                    ((p['x'] as double?) ?? 155.0) / 310.0;
                final ppy = (p['py'] as double?) ??
                    (((p['y'] as double?) ?? 100.0) - 15.0) / 175.0;
                return Positioned(
                  left: (6 + ppx * (fw - dotW - 12)).clamp(0.0, fw - dotW),
                  top: 10 + ppy * (fh * 0.49 - 70),
                  child: _preMatchPlayerDot(
                      context,
                      p['name'] as String,
                      p['number'] as int,
                      homeColor,
                      homeName),
                );
              }),
              ...awayPlayers.asMap().entries.map((e) {
                final p = e.value;
                final ppx = (p['px'] as double?) ??
                    ((p['x'] as double?) ?? 155.0) / 310.0;
                final ppy = (p['py'] as double?) ??
                    (((p['y'] as double?) ?? 300.0) - 210.0) / 175.0;
                return Positioned(
                  left: (6 + ppx * (fw - dotW - 12)).clamp(0.0, fw - dotW),
                  top: fh * 0.51 + (1.0 - ppy) * (fh * 0.49 - 70),
                  child: _preMatchPlayerDot(
                      context,
                      p['name'] as String,
                      p['number'] as int,
                      awayColor,
                      awayName),
                );
              }),
            ]);
          }),
        ),
        const SizedBox(height: 16),

        // Bench sections
        _buildPreMatchBenchSection(context, homeName, homeBench, homeColor,
            cardBg, tx, lb, divider),
        const SizedBox(height: 12),
        _buildPreMatchBenchSection(context, awayName, awayBench, awayColor,
            cardBg, tx, lb, divider),
      ]),
    );
  }

  Widget _preMatchPlayerDot(BuildContext context, String name, int number,
      Color color, String teamName) {
    final shortName = name.split(' ').last;
    return GestureDetector(
      onTap: () {
        onPlayerTap(TappedPlayerInfo(
          player: LocalLineupPlayer(
              name: name, number: number, position: ''),
          teamName: teamName,
          teamColor: color,
        ));
      },
      child: SizedBox(
        width: 82,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1),
                const BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: Center(
                child: Text('$number',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white))),
          ),
          const SizedBox(height: 3),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(shortName,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }

  Widget _buildPreMatchBenchSection(
      BuildContext context,
      String teamName,
      List<Map<String, dynamic>> bench,
      Color color,
      Color cardBg,
      Color tx,
      Color lb,
      Color divider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.event_seat_rounded, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(teamName,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(width: 6),
          Text('— ${tr(context, "Panchina")}',
              style: TextStyle(fontSize: 13, color: lb)),
        ]),
        const SizedBox(height: 12),
        // Coach
        GestureDetector(
          onTap: () {
            final coachName = _getCoachName(teamName);
            onPlayerTap(TappedPlayerInfo(
              player: LocalLineupPlayer(
                  name: coachName, number: 0, position: 'ALL'),
              teamName: teamName,
              teamColor: color,
            ));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: divider)),
            ),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: color.withOpacity(0.3), width: 1.5),
                ),
                child: Icon(Icons.person, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(_getCoachName(teamName),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tx))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(tr(context, 'Allenatore'),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: lb),
            ]),
          ),
        ),
        ...bench.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final isLast = i == bench.length - 1;
          return GestureDetector(
            onTap: () {
              final playerName = p['name'] as String;
              onPlayerTap(TappedPlayerInfo(
                player: LocalLineupPlayer(
                    name: playerName,
                    number: p['number'] as int,
                    position: ''),
                teamName: teamName,
                teamColor: color,
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(color: divider)),
              ),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color.withOpacity(0.3), width: 1.5),
                  ),
                  child: Center(
                      child: Text('${p["number"]}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color))),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(tr(context, p['name'] as String),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: tx))),
                Icon(Icons.chevron_right, size: 18, color: lb),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  String _getPreMatchFormation(String teamName) {
    const formations = {
      'Inter': '3-5-2', 'Milan': '4-2-3-1', 'Juventus': '3-5-2',
      'Napoli': '4-3-3', 'Roma': '3-4-2-1', 'Lazio': '4-3-3',
      'Atalanta': '3-4-1-2', 'Bologna': '4-2-3-1', 'Fiorentina': '4-3-3',
      'Torino': '3-4-2-1', 'Verona': '4-2-3-1', 'Monza': '3-4-2-1',
    };
    return formations[teamName] ?? '4-4-2';
  }

  List<Map<String, dynamic>> _getPreMatchLineup(String teamName) {
    // px: 0.0=left, 1.0=right | py: 0.0=goal, 1.0=midfield
    final lineups = <String, List<Map<String, dynamic>>>{
      'Inter': [ // 3-5-2
        {'name': 'Sommer', 'number': 1, 'px': 0.50, 'py': 0.05},
        {'name': 'Pavard', 'number': 87, 'px': 0.22, 'py': 0.30},
        {'name': 'Acerbi', 'number': 15, 'px': 0.50, 'py': 0.30},
        {'name': 'Bastoni', 'number': 95, 'px': 0.78, 'py': 0.30},
        {'name': 'Darmian', 'number': 36, 'px': 0.05, 'py': 0.55},
        {'name': 'Barella', 'number': 23, 'px': 0.28, 'py': 0.57},
        {'name': 'Calhanoglu', 'number': 20, 'px': 0.50, 'py': 0.53},
        {'name': 'Mkhitaryan', 'number': 22, 'px': 0.72, 'py': 0.57},
        {'name': 'Dumfries', 'number': 2, 'px': 0.95, 'py': 0.55},
        {'name': 'Lautaro', 'number': 10, 'px': 0.35, 'py': 0.88},
        {'name': 'Thuram', 'number': 9, 'px': 0.65, 'py': 0.88},
      ],
      'Milan': [ // 4-2-3-1
        {'name': 'Maignan', 'number': 16, 'px': 0.50, 'py': 0.05},
        {'name': 'Calabria', 'number': 2, 'px': 0.08, 'py': 0.30},
        {'name': 'Tomori', 'number': 23, 'px': 0.35, 'py': 0.30},
        {'name': 'Thiaw', 'number': 28, 'px': 0.65, 'py': 0.30},
        {'name': 'Hernandez', 'number': 19, 'px': 0.92, 'py': 0.30},
        {'name': 'Bennacer', 'number': 4, 'px': 0.35, 'py': 0.53},
        {'name': 'Reijnders', 'number': 14, 'px': 0.65, 'py': 0.53},
        {'name': 'Pulisic', 'number': 11, 'px': 0.12, 'py': 0.72},
        {'name': 'Diaz', 'number': 10, 'px': 0.50, 'py': 0.70},
        {'name': 'Leao', 'number': 17, 'px': 0.88, 'py': 0.72},
        {'name': 'Giroud', 'number': 9, 'px': 0.50, 'py': 0.96},
      ],
      'Napoli': [ // 4-3-3
        {'name': 'Meret', 'number': 1, 'px': 0.50, 'py': 0.05},
        {'name': 'Di Lorenzo', 'number': 22, 'px': 0.08, 'py': 0.30},
        {'name': 'Rrahmani', 'number': 13, 'px': 0.35, 'py': 0.30},
        {'name': 'Kim', 'number': 3, 'px': 0.65, 'py': 0.30},
        {'name': 'Mario Rui', 'number': 6, 'px': 0.92, 'py': 0.30},
        {'name': 'Anguissa', 'number': 99, 'px': 0.28, 'py': 0.55},
        {'name': 'Lobotka', 'number': 68, 'px': 0.50, 'py': 0.53},
        {'name': 'Zielinski', 'number': 20, 'px': 0.72, 'py': 0.55},
        {'name': 'Politano', 'number': 21, 'px': 0.12, 'py': 0.82},
        {'name': 'Osimhen', 'number': 9, 'px': 0.50, 'py': 0.96},
        {'name': 'Kvara', 'number': 77, 'px': 0.88, 'py': 0.82},
      ],
      'Roma': [ // 3-4-2-1
        {'name': 'Rui Patricio', 'number': 1, 'px': 0.50, 'py': 0.05},
        {'name': 'Mancini', 'number': 23, 'px': 0.22, 'py': 0.30},
        {'name': 'Smalling', 'number': 6, 'px': 0.50, 'py': 0.30},
        {'name': 'Ibanez', 'number': 3, 'px': 0.78, 'py': 0.30},
        {'name': 'Karsdorp', 'number': 2, 'px': 0.05, 'py': 0.55},
        {'name': 'Cristante', 'number': 4, 'px': 0.33, 'py': 0.55},
        {'name': 'Matic', 'number': 8, 'px': 0.67, 'py': 0.55},
        {'name': 'Spinazzola', 'number': 37, 'px': 0.95, 'py': 0.55},
        {'name': 'Dybala', 'number': 21, 'px': 0.30, 'py': 0.80},
        {'name': 'Pellegrini', 'number': 7, 'px': 0.70, 'py': 0.80},
        {'name': 'Abraham', 'number': 9, 'px': 0.50, 'py': 0.96},
      ],
      'Juventus': [ // 3-5-2
        {'name': 'Szczesny', 'number': 1, 'px': 0.50, 'py': 0.05},
        {'name': 'Danilo', 'number': 6, 'px': 0.22, 'py': 0.30},
        {'name': 'Bremer', 'number': 3, 'px': 0.50, 'py': 0.30},
        {'name': 'Gatti', 'number': 4, 'px': 0.78, 'py': 0.30},
        {'name': 'Kostic', 'number': 17, 'px': 0.05, 'py': 0.55},
        {'name': 'Locatelli', 'number': 5, 'px': 0.28, 'py': 0.57},
        {'name': 'Rabiot', 'number': 25, 'px': 0.50, 'py': 0.53},
        {'name': 'Fagioli', 'number': 21, 'px': 0.72, 'py': 0.57},
        {'name': 'Cambiaso', 'number': 27, 'px': 0.95, 'py': 0.55},
        {'name': 'Vlahovic', 'number': 9, 'px': 0.35, 'py': 0.88},
        {'name': 'Chiesa', 'number': 7, 'px': 0.65, 'py': 0.88},
      ],
      'Lazio': [ // 4-3-3
        {'name': 'Provedel', 'number': 94, 'px': 0.50, 'py': 0.05},
        {'name': 'Lazzari', 'number': 29, 'px': 0.08, 'py': 0.30},
        {'name': 'Casale', 'number': 15, 'px': 0.35, 'py': 0.30},
        {'name': 'Romagnoli', 'number': 13, 'px': 0.65, 'py': 0.30},
        {'name': 'Marusic', 'number': 77, 'px': 0.92, 'py': 0.30},
        {'name': 'Milinkovic', 'number': 21, 'px': 0.28, 'py': 0.55},
        {'name': 'Cataldi', 'number': 32, 'px': 0.50, 'py': 0.53},
        {'name': 'Luis Alberto', 'number': 10, 'px': 0.72, 'py': 0.55},
        {'name': 'Felipe A.', 'number': 7, 'px': 0.12, 'py': 0.82},
        {'name': 'Immobile', 'number': 17, 'px': 0.50, 'py': 0.96},
        {'name': 'Zaccagni', 'number': 20, 'px': 0.88, 'py': 0.82},
      ],
      'Atalanta': [ // 3-4-1-2
        {'name': 'Musso', 'number': 1, 'px': 0.50, 'py': 0.05},
        {'name': 'Toloi', 'number': 2, 'px': 0.22, 'py': 0.30},
        {'name': 'Demiral', 'number': 28, 'px': 0.50, 'py': 0.30},
        {'name': 'Scalvini', 'number': 42, 'px': 0.78, 'py': 0.30},
        {'name': 'Hateboer', 'number': 33, 'px': 0.05, 'py': 0.53},
        {'name': 'De Roon', 'number': 15, 'px': 0.35, 'py': 0.53},
        {'name': 'Koopmeiners', 'number': 7, 'px': 0.65, 'py': 0.53},
        {'name': 'Gosens', 'number': 8, 'px': 0.95, 'py': 0.53},
        {'name': 'Ederson', 'number': 13, 'px': 0.50, 'py': 0.72},
        {'name': 'Lookman', 'number': 11, 'px': 0.35, 'py': 0.90},
        {'name': 'Scamacca', 'number': 90, 'px': 0.65, 'py': 0.90},
      ],
      'Bologna': [ // 4-2-3-1
        {'name': 'Skorupski', 'number': 28, 'px': 0.50, 'py': 0.05},
        {'name': 'Posch', 'number': 22, 'px': 0.08, 'py': 0.30},
        {'name': 'Beukema', 'number': 5, 'px': 0.35, 'py': 0.30},
        {'name': 'Lucumi', 'number': 26, 'px': 0.65, 'py': 0.30},
        {'name': 'Kristiansen', 'number': 3, 'px': 0.92, 'py': 0.30},
        {'name': 'Freuler', 'number': 8, 'px': 0.35, 'py': 0.55},
        {'name': 'Ferguson', 'number': 99, 'px': 0.65, 'py': 0.55},
        {'name': 'Orsolini', 'number': 7, 'px': 0.12, 'py': 0.70},
        {'name': 'Fabbian', 'number': 30, 'px': 0.50, 'py': 0.68},
        {'name': 'Ndoye', 'number': 11, 'px': 0.88, 'py': 0.70},
        {'name': 'Zirkzee', 'number': 9, 'px': 0.50, 'py': 0.96},
      ],
      'Fiorentina': [ // 4-3-3
        {'name': 'Terracciano', 'number': 1, 'px': 0.50, 'py': 0.05},
        {'name': 'Dodo', 'number': 2, 'px': 0.08, 'py': 0.30},
        {'name': 'Milenkovic', 'number': 4, 'px': 0.35, 'py': 0.30},
        {'name': 'Martinez Q.', 'number': 28, 'px': 0.65, 'py': 0.30},
        {'name': 'Biraghi', 'number': 3, 'px': 0.92, 'py': 0.30},
        {'name': 'Bonaventura', 'number': 5, 'px': 0.28, 'py': 0.55},
        {'name': 'Amrabat', 'number': 34, 'px': 0.50, 'py': 0.53},
        {'name': 'Castrovilli', 'number': 10, 'px': 0.72, 'py': 0.55},
        {'name': 'Gonzalez', 'number': 33, 'px': 0.12, 'py': 0.82},
        {'name': 'Jovic', 'number': 9, 'px': 0.50, 'py': 0.96},
        {'name': 'Sottil', 'number': 7, 'px': 0.88, 'py': 0.82},
      ],
      'Torino': [ // 3-4-2-1
        {'name': 'Milinkovic V.', 'number': 32, 'px': 0.50, 'py': 0.05},
        {'name': 'Djidji', 'number': 26, 'px': 0.22, 'py': 0.30},
        {'name': 'Buongiorno', 'number': 4, 'px': 0.50, 'py': 0.30},
        {'name': 'Rodriguez', 'number': 13, 'px': 0.78, 'py': 0.30},
        {'name': 'Bellanova', 'number': 19, 'px': 0.05, 'py': 0.55},
        {'name': 'Ricci', 'number': 28, 'px': 0.33, 'py': 0.55},
        {'name': 'Ilic', 'number': 8, 'px': 0.67, 'py': 0.55},
        {'name': 'Lazaro', 'number': 22, 'px': 0.95, 'py': 0.55},
        {'name': 'Vlasic', 'number': 10, 'px': 0.33, 'py': 0.77},
        {'name': 'Radonjic', 'number': 49, 'px': 0.67, 'py': 0.77},
        {'name': 'Sanabria', 'number': 9, 'px': 0.50, 'py': 0.96},
      ],
      'Verona': [ // 4-2-3-1
        {'name': 'Montipo', 'number': 1, 'px': 0.50, 'py': 0.05},
        {'name': 'Faraoni', 'number': 5, 'px': 0.08, 'py': 0.30},
        {'name': 'Hien', 'number': 4, 'px': 0.35, 'py': 0.30},
        {'name': 'Magnani', 'number': 15, 'px': 0.65, 'py': 0.30},
        {'name': 'Doig', 'number': 3, 'px': 0.92, 'py': 0.30},
        {'name': 'Hongla', 'number': 6, 'px': 0.35, 'py': 0.53},
        {'name': 'Serdar', 'number': 21, 'px': 0.65, 'py': 0.53},
        {'name': 'Lazovic', 'number': 8, 'px': 0.12, 'py': 0.72},
        {'name': 'Barak', 'number': 72, 'px': 0.50, 'py': 0.70},
        {'name': 'Ngonge', 'number': 11, 'px': 0.88, 'py': 0.72},
        {'name': 'Djuric', 'number': 9, 'px': 0.50, 'py': 0.96},
      ],
    };
    final defaultLineup = [
      {'name': 'GK', 'number': 1, 'px': 0.50, 'py': 0.05},
      {'name': 'RB', 'number': 2, 'px': 0.08, 'py': 0.30},
      {'name': 'CB', 'number': 4, 'px': 0.35, 'py': 0.30},
      {'name': 'CB', 'number': 5, 'px': 0.65, 'py': 0.30},
      {'name': 'LB', 'number': 3, 'px': 0.92, 'py': 0.30},
      {'name': 'CM', 'number': 6, 'px': 0.28, 'py': 0.55},
      {'name': 'CM', 'number': 8, 'px': 0.50, 'py': 0.53},
      {'name': 'CM', 'number': 10, 'px': 0.72, 'py': 0.55},
      {'name': 'RW', 'number': 7, 'px': 0.12, 'py': 0.82},
      {'name': 'ST', 'number': 9, 'px': 0.50, 'py': 0.92},
      {'name': 'LW', 'number': 11, 'px': 0.88, 'py': 0.82},
    ];
    return lineups[teamName] ?? defaultLineup;
  }

  List<Map<String, dynamic>> _getPreMatchBench(String teamName) {
    final benches = <String, List<Map<String, dynamic>>>{
      'Inter': [
        {'name': 'Di Gennaro', 'number': 21}, {'name': 'Dimarco', 'number': 32},
        {'name': 'de Vrij', 'number': 6}, {'name': 'Frattesi', 'number': 16},
        {'name': 'Asllani', 'number': 21}, {'name': 'Arnautovic', 'number': 8},
      ],
      'Milan': [
        {'name': 'Sportiello', 'number': 57}, {'name': 'Kjaer', 'number': 24},
        {'name': 'Krunic', 'number': 33}, {'name': 'Musah', 'number': 80},
        {'name': 'Chukwueze', 'number': 21}, {'name': 'Jovic', 'number': 9},
      ],
      'Roma': [
        {'name': 'Svilar', 'number': 99}, {'name': 'Llorente', 'number': 18},
        {'name': 'Zalewski', 'number': 59}, {'name': 'Bove', 'number': 52},
        {'name': 'Belotti', 'number': 11}, {'name': 'El Shaarawy', 'number': 92},
      ],
      'Napoli': [
        {'name': 'Gollini', 'number': 12}, {'name': 'Juan Jesus', 'number': 5},
        {'name': 'Olivera', 'number': 17}, {'name': 'Elmas', 'number': 7},
        {'name': 'Raspadori', 'number': 81}, {'name': 'Simeone', 'number': 18},
      ],
      'Bologna': [
        {'name': 'Ravaglia', 'number': 36}, {'name': 'Calafiori', 'number': 33},
        {'name': 'Aebischer', 'number': 20}, {'name': 'Saelemaekers', 'number': 14},
        {'name': 'Karlsson', 'number': 17}, {'name': 'Odgaard', 'number': 21},
      ],
    };
    return benches[teamName] ?? [
      {'name': 'Sub 1', 'number': 12}, {'name': 'Sub 2', 'number': 13},
      {'name': 'Sub 3', 'number': 14}, {'name': 'Sub 4', 'number': 15},
      {'name': 'Sub 5', 'number': 16},
    ];
  }

  String _getCoachName(String teamName) {
    const coaches = {
      'Inter': 'Simone Inzaghi',
      'Milan': 'Stefano Pioli',
      'Juventus': 'Massimiliano Allegri',
      'Napoli': 'Luciano Spalletti',
      'Roma': 'José Mourinho',
      'Lazio': 'Maurizio Sarri',
      'Atalanta': 'Gian Piero Gasperini',
      'Bologna': 'Thiago Motta',
      'Fiorentina': 'Vincenzo Italiano',
      'Torino': 'Ivan Juric',
      'Verona': 'Marco Baroni',
      'Monza': 'Raffaele Palladino',
    };
    return coaches[teamName] ?? 'Allenatore';
  }
}
