// lib/widgets/advanced_views/passes_view.dart
//
// Sotto-vista 'Passaggi' di _buildAdvancedStatsTab. Mostra statistiche
// di passaggio: comparativa generale, vista per squadra (tutti i tipi
// di passaggi), zone, lateralita, lunghezza, cross, calci d'angolo.
// Estratta da match_detail_screen.dart.
//
// StatefulWidget: state interno _passesSelectedTeam (toggle squadra)
// e _passesTimeFilter (Tutti/1°T/2°T).
//
// // [FAV-passes-view]

import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import '../../utils/period_factor.dart';
import '../../generated/l10n.dart';
import '../../services/haptic_service.dart';
import '../../painters/match_detail_painters.dart';

class PassesView extends StatefulWidget {
  final int homeCrossOk;
  final int homeCrossTotal;
  final int homeFTPasses;
  final int homeFTTotal;
  final int homeFinalThirdEntries;
  final int homeKeyPasses;
  final int homeLongBallsOk;
  final int homeLongBallsTotal;
  final int homeLongPasses;
  final int homeMediumPasses;
  final int homePassCenter;
  final int homePassCenterOk;
  final int homePassCenterTotal;
  final int homePassLeft;
  final int homePassLeftOk;
  final int homePassLeftTotal;
  final int homePassRight;
  final int homePassRightOk;
  final int homePassRightTotal;
  final int homePassesCompleted;
  final int homePassesTotal;
  final int homeProgressivePasses;
  final int homeShortPasses;
  final int homeThrowIns;
  final int awayCrossOk;
  final int awayCrossTotal;
  final int awayFTPasses;
  final int awayFTTotal;
  final int awayFinalThirdEntries;
  final int awayKeyPasses;
  final int awayLongBallsOk;
  final int awayLongBallsTotal;
  final int awayLongPasses;
  final int awayMediumPasses;
  final int awayPassCenter;
  final int awayPassCenterOk;
  final int awayPassCenterTotal;
  final int awayPassLeft;
  final int awayPassLeftOk;
  final int awayPassLeftTotal;
  final int awayPassRight;
  final int awayPassRightOk;
  final int awayPassRightTotal;
  final int awayPassesCompleted;
  final int awayPassesTotal;
  final int awayProgressivePasses;
  final int awayShortPasses;
  final int awayThrowIns;
  final int generalZoneLeft;
  final int generalZoneCenter;
  final int generalZoneRight;
  final int generalZoneTotal;

  /// Widget selettore squadra (Tutti / Casa / Trasferta).
  final Widget Function(bool? selected, ValueChanged<bool?> onChanged,
      bool isDark, {bool showTutti}) buildTeamSelector;

  /// Widget selettore periodo (Tutti / 1°T / 2°T).
  final Widget Function(int selected, ValueChanged<int> onChanged,
      bool isDark) buildPeriodSelector;

  /// Helper filtro temporale.
  final bool Function(int minute, int filter) inSelectedHalf;

  const PassesView({
    Key? key,
    required this.homeCrossOk,
    required this.homeCrossTotal,
    required this.homeFTPasses,
    required this.homeFTTotal,
    required this.homeFinalThirdEntries,
    required this.homeKeyPasses,
    required this.homeLongBallsOk,
    required this.homeLongBallsTotal,
    required this.homeLongPasses,
    required this.homeMediumPasses,
    required this.homePassCenter,
    required this.homePassCenterOk,
    required this.homePassCenterTotal,
    required this.homePassLeft,
    required this.homePassLeftOk,
    required this.homePassLeftTotal,
    required this.homePassRight,
    required this.homePassRightOk,
    required this.homePassRightTotal,
    required this.homePassesCompleted,
    required this.homePassesTotal,
    required this.homeProgressivePasses,
    required this.homeShortPasses,
    required this.homeThrowIns,
    required this.awayCrossOk,
    required this.awayCrossTotal,
    required this.awayFTPasses,
    required this.awayFTTotal,
    required this.awayFinalThirdEntries,
    required this.awayKeyPasses,
    required this.awayLongBallsOk,
    required this.awayLongBallsTotal,
    required this.awayLongPasses,
    required this.awayMediumPasses,
    required this.awayPassCenter,
    required this.awayPassCenterOk,
    required this.awayPassCenterTotal,
    required this.awayPassLeft,
    required this.awayPassLeftOk,
    required this.awayPassLeftTotal,
    required this.awayPassRight,
    required this.awayPassRightOk,
    required this.awayPassRightTotal,
    required this.awayPassesCompleted,
    required this.awayPassesTotal,
    required this.awayProgressivePasses,
    required this.awayShortPasses,
    required this.awayThrowIns,
    required this.generalZoneLeft,
    required this.generalZoneCenter,
    required this.generalZoneRight,
    required this.generalZoneTotal,
    required this.buildTeamSelector,
    required this.buildPeriodSelector,
    required this.inSelectedHalf,
  }) : super(key: key);

  @override
  State<PassesView> createState() => _PassesViewState();
}

class _PassesViewState extends State<PassesView> {
  bool? _passesSelectedTeam;
  int _passesTimeFilter = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _buildPassesView(isDark);
  }

  Widget _buildPassesView(bool isDark) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F0);
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);

    const homeColor = Color(0xFF1B5E20);
    const awayColor = Color(0xFF1565C0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        widget.buildPeriodSelector(_passesTimeFilter,
            (val) => setState(() => _passesTimeFilter = val), isDark),
        const SizedBox(height: 8),
        // Selettore squadra (refactored Patch 8: usa widget.buildTeamSelector
        // riusabile per coerenza con tutte le altre tab)
        widget.buildTeamSelector(_passesSelectedTeam,
            (val) => setState(() => _passesSelectedTeam = val), isDark),
        const SizedBox(height: 14),

        // Mostra vista comparativa o vista singola squadra
        if (_passesSelectedTeam == null)
          _passesComparativeView(
              isDark, tx, lb, cardBg, cardBorder, homeColor, awayColor)
        else
          _passesTeamView(
              _passesSelectedTeam!, isDark, tx, lb, cardBg, cardBorder),
      ]),
    );
  }

  Widget _passesComparativeView(bool isDark, Color tx, Color lb, Color cardBg,
      Color cardBorder, Color homeColor, Color awayColor) {
    // Percentuali generali (entrambe le squadre combinate)
    final genLeftPct = (widget.generalZoneLeft / widget.generalZoneTotal * 100).round();
    final genCenterPct = (widget.generalZoneCenter / widget.generalZoneTotal * 100).round();
    final genRightPct = (widget.generalZoneRight / widget.generalZoneTotal * 100).round();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Campo generale — distribuzione passaggi partita
      Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(tr(context, 'Distribuzione Passaggi'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 4),
          Text('${widget.generalZoneTotal} ${tr(context, 'passaggi totali nella partita')}',
              style: TextStyle(fontSize: 11, color: lb)),
          const SizedBox(height: 12),
          // ── TITOLO SEZIONE (centrato) ──
          Center(
            child: Text(tr(context, 'Distribuzione passaggi per zona'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          ),
          const SizedBox(height: 10),
          _generalFieldHeatmap(genLeftPct, genCenterPct, genRightPct, isDark),
        ]),
      ),
      const SizedBox(height: 14),

      // Header con totali entrambe le squadre
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(tr(context, 'Precisione Passaggi'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _miniAccuracyBlock(
                    periodScale(widget.homePassesCompleted, _passesTimeFilter), periodScale(widget.homePassesTotal, _passesTimeFilter), homeColor, tx, lb)),
            Container(width: 1, height: 70, color: cardBorder),
            Expanded(
                child: _miniAccuracyBlock(
                    periodScale(widget.awayPassesCompleted, _passesTimeFilter), periodScale(widget.awayPassesTotal, _passesTimeFilter), awayColor, tx, lb)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),

      // Barre comparative
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          _passComparisonBarPremium(S.of(context)!.passaggiPrecisilabel, periodScale(widget.homePassesCompleted, _passesTimeFilter),
              periodScale(widget.awayPassesCompleted, _passesTimeFilter), homeColor, awayColor, tx, lb, isDark),
          const SizedBox(height: 22),
          _passComparisonBarPremium(tr(context, 'Rimesse laterali'), periodScale(widget.homeThrowIns, _passesTimeFilter),
              periodScale(widget.awayThrowIns, _passesTimeFilter), homeColor, awayColor, tx, lb, isDark),
          SizedBox(height: 22),
          _passComparisonBarPremium(
              tr(context, 'Ingressi terzo offensivo'),
              periodScale(widget.homeFinalThirdEntries, _passesTimeFilter),
              periodScale(widget.awayFinalThirdEntries, _passesTimeFilter),
              homeColor,
              awayColor,
              tx,
              lb,
              isDark),
          const SizedBox(height: 22),
          _passComparisonBarPremium(S.of(context)!.passaggiChiave, periodScale(widget.homeKeyPasses, _passesTimeFilter),
              periodScale(widget.awayKeyPasses, _passesTimeFilter), homeColor, awayColor, tx, lb, isDark),
          const SizedBox(height: 22),
          _passComparisonBarPremium(
              S.of(context)!.passaggiProgressivi,
              periodScale(widget.homeProgressivePasses, _passesTimeFilter),
              periodScale(widget.awayProgressivePasses, _passesTimeFilter),
              homeColor,
              awayColor,
              tx,
              lb,
              isDark),
        ]),
      ),
      const SizedBox(height: 14),

      // Cerchi accuratezza per tipo
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(tr(context, 'Accuratezza per Tipo'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 20),
          _passCircularRow(
              S.of(context)!.passaggiTerzoOffensivo,
              periodScale(widget.homeFTPasses, _passesTimeFilter),
              periodScale(widget.homeFTTotal, _passesTimeFilter),
              periodScale(widget.awayFTPasses, _passesTimeFilter),
              periodScale(widget.awayFTTotal, _passesTimeFilter),
              homeColor,
              awayColor,
              tx,
              lb),
          const SizedBox(height: 24),
          _passCircularRow(
              localizeShotData(context, 'Palle lunghe'),
              periodScale(widget.homeLongBallsOk, _passesTimeFilter),
              periodScale(widget.homeLongBallsTotal, _passesTimeFilter),
              periodScale(widget.awayLongBallsOk, _passesTimeFilter),
              periodScale(widget.awayLongBallsTotal, _passesTimeFilter),
              homeColor,
              awayColor,
              tx,
              lb),
          const SizedBox(height: 24),
          _passCircularRow(localizeShotData(context, 'Cross'), periodScale(widget.homeCrossOk, _passesTimeFilter), periodScale(widget.homeCrossTotal, _passesTimeFilter), periodScale(widget.awayCrossOk, _passesTimeFilter),
              periodScale(widget.awayCrossTotal, _passesTimeFilter), homeColor, awayColor, tx, lb),
        ]),
      ),
      const SizedBox(height: 14),
    ]);
  }

  Widget _generalFieldHeatmap(
      int leftPct, int centerPct, int rightPct, bool isDark) {
    final maxPct =
        [leftPct, centerPct, rightPct].reduce((a, b) => a > b ? a : b);
    double zoneOpacity(int val) => 0.40 + (val / maxPct) * 0.55;

    return AspectRatio(
      aspectRatio: 1.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(children: [
          // Zone sfumate VERDI (palette unificata Avanzate)
          Row(children: [
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFC8E6C9).withOpacity(zoneOpacity(leftPct)),
                const Color(0xFF66BB6A).withOpacity(zoneOpacity(leftPct) - 0.10)
              ],
            )))),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF66BB6A).withOpacity(zoneOpacity(centerPct)),
                const Color(0xFF2E7D32)
                    .withOpacity(zoneOpacity(centerPct) + 0.05)
              ],
            )))),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFC8E6C9).withOpacity(zoneOpacity(rightPct)),
                const Color(0xFF66BB6A)
                    .withOpacity(zoneOpacity(rightPct) - 0.10)
              ],
            )))),
          ]),
          // Linee campo
          CustomPaint(
              painter: PassFieldLinePainter(isDark: isDark),
              size: Size.infinite),
          // Badge percentuali (non tappabili in vista generale)
          Row(children: [
            Expanded(child: Center(child: _generalZoneBadge('$leftPct%'))),
            Expanded(child: Center(child: _generalZoneBadge('$centerPct%'))),
            Expanded(child: Center(child: _generalZoneBadge('$rightPct%'))),
          ]),
        ]),
      ),
    );
  }

  Widget _generalZoneBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2),
        ],
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A))),
    );
  }

  Widget _miniAccuracyBlock(
      int completed, int total, Color color, Color tx, Color lb) {
    final pct = total > 0 ? (completed / total * 100).round() : 0;
    return Column(children: [
      SizedBox(
          width: 64,
          height: 64,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey.withOpacity(0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                )),
            Text('$pct%',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          ])),
      const SizedBox(height: 10),
      RichText(
          text: TextSpan(children: [
        TextSpan(
            text: '$completed',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        TextSpan(
            text: ' / $total',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: lb)),
      ])),
    ]);
  }

  Widget _passesTeamView(bool isHome, bool isDark, Color tx, Color lb,
      Color cardBg, Color cardBorder) {
    const homeColor = Color(0xFF1B5E20);
    const awayColor = Color(0xFF1565C0);
    final teamColor = isHome ? homeColor : awayColor;
    final oppColor = isHome ? awayColor : homeColor;

    final totalPasses = isHome ? periodScale(widget.homePassesTotal, _passesTimeFilter) : periodScale(widget.awayPassesTotal, _passesTimeFilter);
    final accPasses = isHome ? periodScale(widget.homePassesCompleted, _passesTimeFilter) : periodScale(widget.awayPassesCompleted, _passesTimeFilter);
    final accPct =
        totalPasses > 0 ? (accPasses / totalPasses * 100).round() : 0;
    final passLeft = isHome ? periodScale(widget.homePassLeft, _passesTimeFilter) : periodScale(widget.awayPassLeft, _passesTimeFilter);
    final passCenter = isHome ? periodScale(widget.homePassCenter, _passesTimeFilter) : periodScale(widget.awayPassCenter, _passesTimeFilter);
    final passRight = isHome ? periodScale(widget.homePassRight, _passesTimeFilter) : periodScale(widget.awayPassRight, _passesTimeFilter);
    final keyPasses = isHome ? periodScale(widget.homeKeyPasses, _passesTimeFilter) : periodScale(widget.awayKeyPasses, _passesTimeFilter);
    final oppKeyPasses = isHome ? periodScale(widget.awayKeyPasses, _passesTimeFilter) : periodScale(widget.homeKeyPasses, _passesTimeFilter);
    final progressivePasses =
        isHome ? periodScale(widget.homeProgressivePasses, _passesTimeFilter) : periodScale(widget.awayProgressivePasses, _passesTimeFilter);
    final oppProgressivePasses =
        isHome ? periodScale(widget.awayProgressivePasses, _passesTimeFilter) : periodScale(widget.homeProgressivePasses, _passesTimeFilter);
    final shortP = isHome ? periodScale(widget.homeShortPasses, _passesTimeFilter) : periodScale(widget.awayShortPasses, _passesTimeFilter);
    final mediumP = isHome ? periodScale(widget.homeMediumPasses, _passesTimeFilter) : periodScale(widget.awayMediumPasses, _passesTimeFilter);
    final longP = isHome ? periodScale(widget.homeLongPasses, _passesTimeFilter) : periodScale(widget.awayLongPasses, _passesTimeFilter);
    final ftP = isHome ? periodScale(widget.homeFTPasses, _passesTimeFilter) : periodScale(widget.awayFTPasses, _passesTimeFilter);
    final ftT = isHome ? periodScale(widget.homeFTTotal, _passesTimeFilter) : periodScale(widget.awayFTTotal, _passesTimeFilter);
    final oppFtP = isHome ? periodScale(widget.awayFTPasses, _passesTimeFilter) : periodScale(widget.homeFTPasses, _passesTimeFilter);
    final oppFtT = isHome ? periodScale(widget.awayFTTotal, _passesTimeFilter) : periodScale(widget.homeFTTotal, _passesTimeFilter);
    final lbOk = isHome ? periodScale(widget.homeLongBallsOk, _passesTimeFilter) : periodScale(widget.awayLongBallsOk, _passesTimeFilter);
    final lbTot = isHome ? periodScale(widget.homeLongBallsTotal, _passesTimeFilter) : periodScale(widget.awayLongBallsTotal, _passesTimeFilter);
    final oppLbOk = isHome ? periodScale(widget.awayLongBallsOk, _passesTimeFilter) : periodScale(widget.homeLongBallsOk, _passesTimeFilter);
    final oppLbTot = isHome ? periodScale(widget.awayLongBallsTotal, _passesTimeFilter) : periodScale(widget.homeLongBallsTotal, _passesTimeFilter);
    final crOk = isHome ? periodScale(widget.homeCrossOk, _passesTimeFilter) : periodScale(widget.awayCrossOk, _passesTimeFilter);
    final crTot = isHome ? periodScale(widget.homeCrossTotal, _passesTimeFilter) : periodScale(widget.awayCrossTotal, _passesTimeFilter);
    final oppCrOk = isHome ? periodScale(widget.awayCrossOk, _passesTimeFilter) : periodScale(widget.homeCrossOk, _passesTimeFilter);
    final oppCrTot = isHome ? periodScale(widget.awayCrossTotal, _passesTimeFilter) : periodScale(widget.homeCrossTotal, _passesTimeFilter);
    final zLeftOk = isHome ? periodScale(widget.homePassLeftOk, _passesTimeFilter) : periodScale(widget.awayPassLeftOk, _passesTimeFilter);
    final zLeftTot = isHome ? periodScale(widget.homePassLeftTotal, _passesTimeFilter) : periodScale(widget.awayPassLeftTotal, _passesTimeFilter);
    final zCenterOk = isHome ? periodScale(widget.homePassCenterOk, _passesTimeFilter) : periodScale(widget.awayPassCenterOk, _passesTimeFilter);
    final zCenterTot = isHome ? periodScale(widget.homePassCenterTotal, _passesTimeFilter) : periodScale(widget.awayPassCenterTotal, _passesTimeFilter);
    final zRightOk = isHome ? periodScale(widget.homePassRightOk, _passesTimeFilter) : periodScale(widget.awayPassRightOk, _passesTimeFilter);
    final zRightTot = isHome ? periodScale(widget.homePassRightTotal, _passesTimeFilter) : periodScale(widget.awayPassRightTotal, _passesTimeFilter);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Header accuratezza grande
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Row(children: [
          SizedBox(
              width: 72,
              height: 72,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: accPct / 100,
                      strokeWidth: 6,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.25),
                      valueColor: AlwaysStoppedAnimation<Color>(teamColor),
                      strokeCap: StrokeCap.round,
                    )),
                Text('$accPct%',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: teamColor)),
              ])),
          const SizedBox(width: 20),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(tr(context, 'Precisione Passaggi'),
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
                const SizedBox(height: 4),
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: '$accPasses',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: teamColor)),
                  TextSpan(
                      text: ' / $totalPasses',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: lb)),
                ])),
                const SizedBox(height: 2),
                Text(tr(context, 'passaggi completati'),
                    style: TextStyle(fontSize: 12, color: lb)),
              ])),
        ]),
      ),
      const SizedBox(height: 14),

      // Titolo zone (allineato alla vista Tutti)
      Center(
        child: Text(tr(context, 'Distribuzione passaggi per zona'),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
      ),
      const SizedBox(height: 12),
      // Campo minimal con zone + freccia orientamento
      Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: _passFieldMinimal(
            passLeft,
            passCenter,
            passRight,
            zLeftOk,
            zLeftTot,
            zCenterOk,
            zCenterTot,
            zRightOk,
            zRightTot,
            isHome,
            teamColor,
            isDark),
      ),
      const SizedBox(height: 14),

      // Passaggi chiave + progressivi
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          _passMetricRow(Icons.key, S.of(context)!.passaggiChiave, keyPasses, oppKeyPasses,
              teamColor, oppColor, tx, lb, isDark,
              tooltip: "Passaggi che creano un'occasione da gol"),
          const SizedBox(height: 20),
          _passMetricRow(
              Icons.trending_up,
              S.of(context)!.passaggiProgressivi,
              progressivePasses,
              oppProgressivePasses,
              teamColor,
              oppColor,
              tx,
              lb,
              isDark,
              tooltip:
                  S.of(context)!.passaggiAvanzano),
        ]),
      ),
      const SizedBox(height: 14),

      // Donut chart distribuzione lunghezza
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(tr(context, 'Distribuzione Lunghezza'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 20),
          _passDonutChart(
              shortP, mediumP, longP, totalPasses, teamColor, isDark, tx, lb),
        ]),
      ),
      const SizedBox(height: 14),

      // Cerchi accuratezza per tipo
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(tr(context, 'Accuratezza per Tipo'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 20),
          _passCircularRow(S.of(context)!.passaggiTerzoOffensivo, ftP, ftT, oppFtP,
              oppFtT, teamColor, oppColor, tx, lb),
          const SizedBox(height: 24),
          _passCircularRow(localizeShotData(context, 'Palle lunghe'), lbOk, lbTot, oppLbOk, oppLbTot,
              teamColor, oppColor, tx, lb),
          const SizedBox(height: 24),
          _passCircularRow(localizeShotData(context, 'Cross'), crOk, crTot, oppCrOk, oppCrTot, teamColor,
              oppColor, tx, lb),
        ]),
      ),
      const SizedBox(height: 14),
    ]);
  }

  Widget _passFieldMinimal(
    int left,
    int center,
    int right,
    int zLOk,
    int zLTot,
    int zCOk,
    int zCTot,
    int zROk,
    int zRTot,
    bool isHome,
    Color teamColor,
    bool isDark,
  ) {
    final maxPct = [left, center, right].reduce((a, b) => a > b ? a : b);
    double zoneOpacity(int val) => 0.40 + (val / maxPct) * 0.55;

    return AspectRatio(
      aspectRatio: 1.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(children: [
          // Zone sfumate
          // Zone sfumate VERDI (palette unificata Avanzate)
          Row(children: [
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFC8E6C9).withOpacity(zoneOpacity(left)),
                const Color(0xFF66BB6A).withOpacity(zoneOpacity(left) - 0.10)
              ],
            )))),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF66BB6A).withOpacity(zoneOpacity(center)),
                const Color(0xFF2E7D32).withOpacity(zoneOpacity(center) + 0.05)
              ],
            )))),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFC8E6C9).withOpacity(zoneOpacity(right)),
                const Color(0xFF66BB6A).withOpacity(zoneOpacity(right) - 0.10)
              ],
            )))),
          ]),
          // Linee campo
          CustomPaint(
              painter: PassFieldLinePainter(isDark: isDark),
              size: Size.infinite),
          // Orientamento offensivo (in basso)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (!isHome)
                Icon(Icons.arrow_back_rounded,
                    size: 14, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                  isHome
                      ? 'Attacca verso destra →'
                      : '← Attacca verso sinistra',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.7)),
                ),
              ),
              const SizedBox(width: 4),
              if (isHome)
                Icon(Icons.arrow_forward_rounded,
                    size: 14, color: Colors.white.withOpacity(0.5)),
            ]),
          ),
          // Badge percentuali tappabili
          Row(children: [
            Expanded(
                child: _tappableZone(
                    'Sinistra', left, zLOk, zLTot, teamColor, isDark)),
            Expanded(
                child: _tappableZone(
                    'Centro', center, zCOk, zCTot, teamColor, isDark)),
            Expanded(
                child: _tappableZone(
                    'Destra', right, zROk, zRTot, teamColor, isDark)),
          ]),
        ]),
      ),
    );
  }

  Widget _tappableZone(String zoneName, int pct, int ok, int total,
      Color teamColor, bool isDark) {
    final acc = total > 0 ? (ok / total * 100).round() : 0;
    return GestureDetector(
      onTap: () {
        HapticService().lightImpact();
        _showZoneDetailPopup(zoneName, pct, ok, total, acc, teamColor, isDark);
      },
      child: Container(
          color: Colors.transparent,
          child: Center(
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 2)
                ]),
            child: Text('$pct%',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A))),
          ))),
    );
  }

  void _showZoneDetailPopup(String zoneName, int pct, int ok, int total,
      int acc, Color teamColor, bool isDark) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: teamColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.location_on, color: teamColor, size: 22)),
                const SizedBox(width: 12),
                Text('${tr(context, 'Zona')} $zoneName',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                _zoneDetailRow(tr(context, 'Distribuzione'), '$pct%',
                    Icons.pie_chart_outline, teamColor, isDark),
                const SizedBox(height: 14),
                _zoneDetailRow(S.of(context)!.passaggiTotaliLabel, '$total', Icons.swap_calls,
                    teamColor, isDark),
                const SizedBox(height: 14),
                _zoneDetailRow(tr(context, 'Completati'), '$ok', Icons.check_circle_outline,
                    const Color(0xFF4CAF50), isDark),
                const SizedBox(height: 14),
                _zoneDetailRow(
                    'Accuratezza',
                    '$acc%',
                    Icons.gps_fixed,
                    const Color(0xFF4CAF50), // [FAV-pallino-verde] sempre verde per uniformita visiva
                    isDark),
                const SizedBox(height: 16),
                ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                        height: 10,
                        child: Stack(children: [
                          Container(color: Colors.grey.withOpacity(0.12)),
                          FractionallySizedBox(
                              widthFactor: acc / 100,
                              child: Container(
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        teamColor,
                                        teamColor.withOpacity(0.7)
                                      ]),
                                      borderRadius: BorderRadius.circular(6)))),
                        ]))),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(tr(context, 'Chiudi'),
                        style: TextStyle(
                            color: teamColor, fontWeight: FontWeight.w700)))
              ],
            ));
  }

  Widget _zoneDetailRow(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600])),
      const Spacer(),
      Text(value,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
    ]);
  }

  Widget _passMetricRow(IconData icon, String label, int value, int oppValue,
      Color color, Color oppColor, Color tx, Color lb, bool isDark,
      {String? tooltip}) {
    final isWinning = value > oppValue;
    final isDraw = value == oppValue;
    return Row(children: [
      Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color)),
      const SizedBox(width: 12),
      Expanded(
          child: Row(children: [
        Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: tx))),
        if (tooltip != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
              onTap: () => _showTooltip(label, tooltip, isDark),
              child: Icon(Icons.info_outline, size: 14, color: lb))
        ],
      ])),
      const SizedBox(width: 8),
      Text(value.toString(),
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      const SizedBox(width: 6),
      if (!isDraw)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
              color: (isWinning
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336))
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(4)),
          child: Icon(isWinning ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 16,
              color: isWinning
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44336)),
        ),
      const SizedBox(width: 4),
      Text('vs ${oppValue.toString()}',
          style: TextStyle(fontSize: 12, color: lb)),
    ]);
  }

  void _showTooltip(String title, String description, bool isDark) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              content: Text(description,
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'))
              ],
            ));
  }

  Widget _passComparisonBarPremium(String label, int value, int oppValue,
      Color color, Color oppColor, Color tx, Color lb, bool isDark) {
    final total = value + oppValue;
    final pct = total > 0 ? value / total : 0.5;
    final isWinning = value > oppValue;
    final isDraw = value == oppValue;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        SizedBox(
            width: 44,
            child: Text(value.toString(),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isWinning || isDraw ? tx : lb))),
        const SizedBox(width: 8),
        Expanded(
            child: SizedBox(
                height: 10,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Row(children: [
                      Expanded(
                          flex: (pct * 1000).round(),
                          child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [color, color.withOpacity(0.75)]),
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(5),
                                      bottomLeft: Radius.circular(5))))),
                      Container(
                          width: 2,
                          color:
                              isDark ? const Color(0xFF1A1A1A) : Colors.white),
                      Expanded(
                          flex: ((1 - pct) * 1000).round(),
                          child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    oppColor.withOpacity(0.35),
                                    oppColor.withOpacity(0.25)
                                  ]),
                                  borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(5),
                                      bottomRight: Radius.circular(5))))),
                    ])))),
        const SizedBox(width: 8),
        SizedBox(
            width: 44,
            child: Text(oppValue.toString(),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: !isWinning && !isDraw ? tx : lb),
                textAlign: TextAlign.right)),
      ]),
    ]);
  }

  Widget _passDonutChart(int shortP, int mediumP, int longP, int total,
      Color teamColor, bool isDark, Color tx, Color lb) {
    final shortPct = total > 0 ? (shortP / total * 100).round() : 0;
    final mediumPct = total > 0 ? (mediumP / total * 100).round() : 0;
    final longPct = total > 0 ? (longP / total * 100).round() : 0;
    const shortColor = Color(0xFF4CAF50);
    const mediumColor = Color(0xFFFF9800);
    const longColor = Color(0xFFE53935);
    return Row(children: [
      SizedBox(
          width: 120,
          height: 120,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                    painter: DonutChartPainter(segments: [
                  DonutSegment(value: shortP.toDouble(), color: shortColor),
                  DonutSegment(value: mediumP.toDouble(), color: mediumColor),
                  DonutSegment(value: longP.toDouble(), color: longColor)
                ], strokeWidth: 14, isDark: isDark))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$total',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: tx)),
              Text(tr(context, 'totali'), style: TextStyle(fontSize: 10, color: lb)),
            ]),
          ])),
      const SizedBox(width: 24),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _donutLegendItem(tr(context, 'Corti (<15m)'), shortP, shortPct, shortColor, tx, lb),
        const SizedBox(height: 14),
        _donutLegendItem(
            tr(context, 'Medi (15-30m)'), mediumP, mediumPct, mediumColor, tx, lb),
        const SizedBox(height: 14),
        _donutLegendItem(tr(context, 'Lunghi (>30m)'), longP, longPct, longColor, tx, lb),
      ])),
    ]);
  }

  Widget _donutLegendItem(
      String label, int count, int pct, Color color, Color tx, Color lb) {
    return Row(children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: lb)),
        const SizedBox(height: 2),
        RichText(
            text: TextSpan(children: [
          TextSpan(
              text: '$count',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: tx)),
          TextSpan(
              text: '  $pct%',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ])),
      ])),
    ]);
  }

  Widget _passCircularRow(String label, int ok, int total, int oppOk,
      int oppTotal, Color color, Color oppColor, Color tx, Color lb) {
    final pct = total > 0 ? (ok / total * 100).round() : 0;
    final oppPct = oppTotal > 0 ? (oppOk / oppTotal * 100).round() : 0;
    return Row(children: [
      SizedBox(
          width: 52,
          child: Text('$ok/$total',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: tx))),
      _circularProgress(pct / 100, '$pct%', color, 62),
      const SizedBox(width: 10),
      Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: lb),
              textAlign: TextAlign.center)),
      const SizedBox(width: 10),
      _circularProgress(oppPct / 100, '$oppPct%', oppColor, 62),
      SizedBox(
          width: 52,
          child: Text('$oppOk/$oppTotal',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: tx),
              textAlign: TextAlign.right)),
    ]);
  }

  Widget _circularProgress(
      double progress, String label, Color color, double size) {
    return SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5.5,
                  backgroundColor: Colors.grey.withOpacity(0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round)),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ]));
  }
}
