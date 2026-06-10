// lib/widgets/advanced_views/attack_view.dart
//
// Sotto-vista 'Attacco' di _buildAdvancedStatsTab. Mostra heatmap zonale
// + barre statistiche comparative offensive (tiri, gol, xG, occasioni).
// Estratta da match_detail_screen.dart.
//
// E' una StatelessWidget: il toggle Casa/Trasferta e il filtro periodo
// sono gestiti dal router padre (_buildAdvancedVisualization) e passati
// come param gia risolti.
//
// // [FAV-attack-view]

import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import '../../generated/l10n.dart';
import '../../models/local_match_models.dart';
import '../../painters/match_detail_painters.dart';

class AttackView extends StatelessWidget {
  final String homeTeamName;
  final String awayTeamName;

  /// Valore corrente del toggle Casa/Trasferta (gia risolto dal router).
  final bool showHome;

  /// Filtro periodo: 0=tutti, 1=1°T, 2=2°T.
  final int timeFilter;

  /// Dati momentum attacco (statici mock).
  final List<List<dynamic>> mockAttackMomentum;

  /// Callback per filtro temporale.
  final bool Function(int minute, int filter) inSelectedHalf;

  /// Callback per ottenere lista eventi mock.
  final List<LocalMatchEvent> Function() generateEvents;

  const AttackView({
    Key? key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.showHome,
    required this.timeFilter,
    required this.mockAttackMomentum,
    required this.inSelectedHalf,
    required this.generateEvents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _buildAttackView(context, isDark);
  }

  Widget _buildAttackView(BuildContext context, bool isDark) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF262626) : Colors.white;
    final fieldGreen = const Color(0xFF66BB6A);

    // ── Palette unificata Avanzate (= Difensiva) ──
    const homeColor = Color(0xFF4CAF50); // verde Material (Lazio)
    const awayColor = Color(0xFF1565C0); // blu scuro (Milan)
    final homeName = homeTeamName;
    final awayName = awayTeamName;

    // ══════ DERIVE ALL STATS FROM mockAttackMomentum (single source of truth) ══════
    // Filtro periodo: minute e' in d[0]. Quando arriveranno dati API reali,
    // questa where() basta a far funzionare il selettore 1°T/2°T.
    final data = mockAttackMomentum
        .where((d) => inSelectedHalf(d[0] as int, timeFilter))
        .toList();
    final hAttacks = data.where((d) => d[1] == true).length;
    final aAttacks = data.where((d) => d[1] == false).length;
    final hDangerous =
        data.where((d) => d[1] == true && (d[2] as double) >= 0.6).length;
    final aDangerous =
        data.where((d) => d[1] == false && (d[2] as double) >= 0.6).length;

    // Derive other stats from events (also single source of truth)
    final allEvents = generateEvents()
        .where((e) => inSelectedHalf(e.minute, timeFilter))
        .toList();
    final hGoals =
        allEvents.where((e) => e.type == 'goal' && e.isHomeTeam).length;
    final aGoals =
        allEvents.where((e) => e.type == 'goal' && !e.isHomeTeam).length;
    // "Grandi occasioni realizzate" = goals
    // "Grandi occasioni mancate" = on_target shots (saved) = high xG shots that didn't go in
    final hOnTarget = allEvents
        .where((e) =>
            e.type == 'shot' &&
            e.isHomeTeam &&
            e.detail != null &&
            e.detail!.toLowerCase().contains('parato'))
        .length;
    final aOnTarget = allEvents
        .where((e) =>
            e.type == 'shot' &&
            !e.isHomeTeam &&
            e.detail != null &&
            e.detail!.toLowerCase().contains('parato'))
        .length;
    // Tocchi in area = proportional to dangerous attacks * factor
    final hTouches = (hDangerous * 1.5).round();
    final aTouches = (aDangerous * 1.2).round();
    // Falli avversari nel terzo offensivo = subset of opponent fouls
    final hOffFouls =
        allEvents.where((e) => e.type == 'foul' && !e.isHomeTeam).length ~/ 3;
    final aOffFouls =
        allEvents.where((e) => e.type == 'foul' && e.isHomeTeam).length ~/ 3;
    // Fuorigioco
    final hOffsides =
        allEvents.where((e) => e.type == 'offside' && e.isHomeTeam).length;
    final aOffsides =
        allEvents.where((e) => e.type == 'offside' && !e.isHomeTeam).length;

    final stats = [
      AttackStat(S.of(context)!.grandiOccasioniRealizzate, hGoals, aGoals, true),
      AttackStat(S.of(context)!.grandiOccasioniMancate, hOnTarget, aOnTarget, false),
      AttackStat(localizeShotData(context, 'Tocchi area avversaria'), hTouches, aTouches, true),
      AttackStat(
          localizeShotData(context, 'Falli avversari nel terzo offensivo'), hOffFouls, aOffFouls, true),
      AttackStat(tr(context, 'Fuorigioco'), hOffsides, aOffsides, false),
      AttackStat(localizeShotData(context, 'Attacchi pericolosi'), hDangerous, aDangerous, true),
      AttackStat(localizeShotData(context, 'Attacchi'), hAttacks, aAttacks, true),
    ];

    // ══════ CONCENTRATION ZONES from momentum (per team) ══════
    // 6 zones (2 rows x 3 cols): [defense, midfield, attack]
    // Zone intensity = proportion of attacks in that zone
    List<List<double>> _calcZones(bool isHome) {
      final teamData = data.where((d) => d[1] == isHome).toList();
      if (teamData.isEmpty)
        return [
          [0.2, 0.2, 0.2],
          [0.2, 0.2, 0.2]
        ];

      // Count attacks by intensity bucket
      int defCount = 0, midCount = 0, atkCount = 0;
      for (final d in teamData) {
        final intensity = d[2] as double;
        if (intensity < 0.4)
          defCount++;
        else if (intensity < 0.6)
          midCount++;
        else
          atkCount++;
      }
      final total = teamData.length.toDouble();
      final defR = defCount / total; // ~0.4
      final midR = midCount / total; // ~0.25
      final atkR = atkCount / total; // ~0.3

      // Wide range: defense=cold (0.05-0.25), midfield=warm (0.4-0.6), attack=hot (0.7-0.95)
      // Home attacks left→right: left=defense, center=midfield, right=attack
      if (isHome) {
        return [
          [0.05 + defR * 0.2, 0.35 + midR * 0.3, 0.70 + atkR * 0.25],
          [0.08 + defR * 0.15, 0.40 + midR * 0.25, 0.65 + atkR * 0.25],
        ];
      } else {
        // Away attacks right→left: right=defense, center=midfield, left=attack
        return [
          [0.70 + atkR * 0.25, 0.35 + midR * 0.3, 0.05 + defR * 0.2],
          [0.65 + atkR * 0.25, 0.40 + midR * 0.25, 0.08 + defR * 0.15],
        ];
      }
    }

    final selectedZones = _calcZones(showHome);
    final selectedColor = showHome ? homeColor : awayColor;
    final selectedName = showHome ? homeName : awayName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── TITOLO SEZIONE (centrato) ──
        Center(
          child: Text(tr(context, 'Concentrazione attacchi'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
        ),
        const SizedBox(height: 10),
        // ── PITCH HEATMAP ──
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
                aspectRatio: 1.85,
                child: CustomPaint(
                    painter: AttackHeatmapPainter(
                  zones: selectedZones,
                  isHome: showHome,
                  isDark: isDark,
                )),
              ),
          ),
        ),
        const SizedBox(height: 10),

        // ── LEGENDA GRADIENT 5 LIVELLI (stile SofaScore-pro) ──
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Barra gradient con tutti e 5 i colori della scala
            Container(
              width: 260,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFDCEDC8), // very light sage (bassa)
                    Color(0xFFC5E1A5), // light lime-green
                    Color(0xFFA5D6A7), // medium-light
                    Color(0xFF81C784), // medium green
                    Color(0xFF66BB6A), // bright medium (alta)
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Labels ai bordi
            SizedBox(
              width: 260,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(localizeShotData(context, 'Più bassa concentrazione'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: lb)),
                  Text(localizeShotData(context, 'Più alta concentrazione'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: lb)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // ── OFFENSIVE STATS ──
        ...stats.map((stat) => _buildAttackStatBar(
              stat.label,
              stat.homeVal,
              stat.awayVal,
              homeColor,
              awayColor,
              tx,
              lb,
              cardBg,
              isDark,
              isHigherBetter: stat.higherIsBetter,
            )),
      ]),
    );
  }

  Widget _buildAttackStatBar(
      String label,
      int homeVal,
      int awayVal,
      Color homeColor,
      Color awayColor,
      Color tx,
      Color lb,
      Color cardBg,
      bool isDark,
      {bool isHigherBetter = true}) {
    final maxVal = (homeVal > awayVal ? homeVal : awayVal).clamp(1, 999);
    final homeRatio = homeVal / maxVal;
    final awayRatio = awayVal / maxVal;
    // Il numero più alto ha SEMPRE la barra evidenziata (colore pieno)
    // Il numero più basso ha la barra sbiadita
    final homeHigher = homeVal >= awayVal;
    final awayHigher = awayVal > homeVal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(children: [
        // Values + label
        Row(children: [
          SizedBox(
              width: 36,
              child: Text('$homeVal',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: homeHigher ? homeColor : lb),
                  textAlign: TextAlign.left)),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: tx),
                  textAlign: TextAlign.center)),
          SizedBox(
              width: 36,
              child: Text('$awayVal',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: awayHigher ? awayColor : lb),
                  textAlign: TextAlign.right)),
        ]),
        const SizedBox(height: 6),
        // Bars
        Row(children: [
          // Home bar (right-aligned, grows left)
          Expanded(child: LayoutBuilder(builder: (ctx, constraints) {
            return Stack(clipBehavior: Clip.none, children: [
              Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(3))),
              Positioned(
                right: 0,
                child: Container(
                  height: 6,
                  width: constraints.maxWidth * homeRatio,
                  decoration: BoxDecoration(
                      color:
                          homeHigher ? homeColor : homeColor.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(3)),
                ),
              ),
            ]);
          })),
          const SizedBox(width: 4),
          // Away bar (left-aligned, grows right)
          Expanded(child: LayoutBuilder(builder: (ctx, constraints) {
            return Stack(clipBehavior: Clip.none, children: [
              Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(3))),
              Container(
                height: 6,
                width: constraints.maxWidth * awayRatio,
                decoration: BoxDecoration(
                    color: awayHigher ? awayColor : awayColor.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(3)),
              ),
            ]);
          })),
        ]),
      ]),
    );
  }
}
