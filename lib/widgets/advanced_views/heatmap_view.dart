// lib/widgets/advanced_views/heatmap_view.dart
//
// Sotto-vista 'Heatmap' di _buildAdvancedStatsTab. Mostra heatmap di
// possesso/territorio sul campo + stats comparative dettagliate.
// Estratta da match_detail_screen.dart.
//
// StatefulWidget: gestisce state interno _heatmapSelectedTeam (toggle)
// e _heatmapTimeFilter (Tutti/1°T/2°T).
//
// // [FAV-heatmap-view]

import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import '../../utils/period_factor.dart';
import '../../generated/l10n.dart';
import '../../services/haptic_service.dart';
import '../../painters/match_detail_painters.dart';

class HeatmapView extends StatefulWidget {
  final String homeTeamName;
  final String awayTeamName;

  // Stats home
  final int homeCorners;
  final int homeFinalThirdEntries;
  final List<int> homeHeatZones;
  final int homePassesCompleted;
  final int homePassesTotal;
  final int homePossAttack;
  final int homePossDefense;
  final int homePossMidfield;
  final int homePossession;
  final int homeShotsOnTarget;
  final int homeShotsTotal;
  final int homeTerritory;

  // Stats away
  final int awayCorners;
  final int awayFinalThirdEntries;
  final List<int> awayHeatZones;
  final int awayPassesCompleted;
  final int awayPassesTotal;
  final int awayPossAttack;
  final int awayPossDefense;
  final int awayPossMidfield;
  final int awayPossession;
  final int awayShotsOnTarget;
  final int awayShotsTotal;
  final int awayTerritory;

  // Heat grid
  final int heatGridCols;
  final int heatGridRows;

  // Animation controller (gestito dal padre)
  final AnimationController animationController;

  // Callback per circular progress widget (sub-widget di Passes condiviso)
  final Widget Function(double progress, String label, Color color, double size) circularProgress;

  // Callback per filtro zone heatmap per periodo
  final List<int> Function(List<int> baseZones, bool isHome, int filter) heatZonesForPeriod;

  /// Widget selettore squadra (Tutti / Casa / Trasferta).
  final Widget Function(bool? selected, ValueChanged<bool?> onChanged,
      bool isDark, {bool showTutti}) buildTeamSelector;

  const HeatmapView({
    Key? key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeCorners,
    required this.homeFinalThirdEntries,
    required this.homeHeatZones,
    required this.homePassesCompleted,
    required this.homePassesTotal,
    required this.homePossAttack,
    required this.homePossDefense,
    required this.homePossMidfield,
    required this.homePossession,
    required this.homeShotsOnTarget,
    required this.homeShotsTotal,
    required this.homeTerritory,
    required this.awayCorners,
    required this.awayFinalThirdEntries,
    required this.awayHeatZones,
    required this.awayPassesCompleted,
    required this.awayPassesTotal,
    required this.awayPossAttack,
    required this.awayPossDefense,
    required this.awayPossMidfield,
    required this.awayPossession,
    required this.awayShotsOnTarget,
    required this.awayShotsTotal,
    required this.awayTerritory,
    required this.heatGridCols,
    required this.heatGridRows,
    required this.animationController,
    required this.circularProgress,
    required this.heatZonesForPeriod,
    required this.buildTeamSelector,
  }) : super(key: key);

  @override
  State<HeatmapView> createState() => _HeatmapViewState();
}

class _HeatmapViewState extends State<HeatmapView> {
  // State interno (precedentemente nel padre)
  bool? _heatmapSelectedTeam;
  int _heatmapTimeFilter = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _buildHeatmapView(isDark);
  }

  Widget _buildHeatmapView(bool isDark) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F0);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    const homeColor = Color(0xFF1B5E20);
    const awayColor = Color(0xFF1565C0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // [FAV-uniform-selector] sostituito con buildTeamSelector callback condivisa
        widget.buildTeamSelector(
          _heatmapSelectedTeam,
          (val) => setState(() {
            _heatmapSelectedTeam = val;
            _heatmapTimeFilter = 0;
          }),
          isDark,
        ),
        const SizedBox(height: 10),

        // ═══ FILTRO TEMPO ═══
        Row(children: [
          _heatmapTimeChip(localizeShotData(context, 'Tutti'), 0, isDark, tx, lb),
          const SizedBox(width: 8),
          _heatmapTimeChip(tr(context, '1° Tempo'), 1, isDark, tx, lb),
          const SizedBox(width: 8),
          _heatmapTimeChip(tr(context, '2° Tempo'), 2, isDark, tx, lb),
        ]),
        const SizedBox(height: 14),

        // ── TITOLO SEZIONE (centrato) ──
        Center(
          child: Text(tr(context, 'Mappa di calore - Possesso'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
        ),
        const SizedBox(height: 10),
        // ═══ CAMPO HEATMAP ═══
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: AnimatedBuilder(
                animation: widget.animationController,
                builder: (context, child) {
                  final animVal = widget.animationController.value;
                  if (_heatmapSelectedTeam == null) {
                    // Vista combinata — entrambe le squadre sovrapposte
                    return CustomPaint(
                      painter: CombinedHeatmapPainter(
                        homeZones: widget.heatZonesForPeriod(
                            widget.homeHeatZones, true, _heatmapTimeFilter),
                        awayZones: widget.heatZonesForPeriod(
                            widget.awayHeatZones, false, _heatmapTimeFilter),
                        gridCols: widget.heatGridCols,
                        gridRows: widget.heatGridRows,
                        isDark: isDark,
                        animationValue: animVal,
                      ),
                      child: Container(),
                    );
                  } else {
                    // Patch 7: zone filtrate per periodo (1°T / 2°T / tutti)
                    final homeZonesFiltered = widget.heatZonesForPeriod(
                        widget.homeHeatZones, true, _heatmapTimeFilter);
                    final awayZonesFiltered = widget.heatZonesForPeriod(
                        widget.awayHeatZones, false, _heatmapTimeFilter);
                    final zones = _heatmapSelectedTeam!
                        ? homeZonesFiltered
                        : awayZonesFiltered;
                    final isHome = _heatmapSelectedTeam!;
                    // Riferimento globale: il max tra TUTTE le zone di ENTRAMBE le squadre (filtrate)
                    // → la squadra con meno possesso avrà colori più freddi
                    final allZones = [...homeZonesFiltered, ...awayZonesFiltered];
                    final globalMax = allZones.reduce((a, b) => a > b ? a : b);
                    return CustomPaint(
                      painter: SingleTeamHeatmapPainter(
                        zones: zones,
                        isHome: isHome,
                        gridCols: widget.heatGridCols,
                        gridRows: widget.heatGridRows,
                        isDark: isDark,
                        animationValue: animVal,
                        globalRefMax: globalMax,
                      ),
                      child: Container(),
                    );
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ═══ LEGENDA GRADIENTE ═══
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(tr(context, 'Bassa'), style: TextStyle(fontSize: 11, color: lb)),
            const SizedBox(width: 8),
            Container(
              width: 160,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(colors: [
                  Color(0xFF81C784),
                  Color(0xFFD4E157),
                  Color(0xFFFFEE58),
                  Color(0xFFFFB300),
                  Color(0xFFFF9800),
                  Color(0xFFFF5722),
                  Color(0xFFF44336),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Text(tr(context, 'Alta'), style: TextStyle(fontSize: 11, color: lb)),
          ]),
        ),
        const SizedBox(height: 8),

        // ═══ STATS ═══
        if (_heatmapSelectedTeam == null)
          _heatmapComparativeStats(
              isDark, tx, lb, cardBg, cardBorder, homeColor, awayColor)
        else
          _heatmapTeamStats(
              _heatmapSelectedTeam!, isDark, tx, lb, cardBg, cardBorder),
      ]),
    );
  }

  Widget _heatmapTimeChip(
      String label, int value, bool isDark, Color tx, Color lb) {
    final active = _heatmapTimeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _heatmapTimeFilter = value);
        HapticService().lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFF424242).withValues(alpha: 0.08))
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : const Color(0xFF424242).withValues(alpha: 0.3))
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active
                  ? (isDark ? Colors.white : const Color(0xFF424242))
                  : lb,
            )),
      ),
    );
  }

  Widget _heatmapComparativeStats(bool isDark, Color tx, Color lb, Color cardBg,
      Color cardBorder, Color homeColor, Color awayColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Possesso palla
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(S.of(context)!.possessoPalla,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 16),
          // Barra grande possesso — font uniforme
          Row(children: [
            Text('${widget.homePossession}%',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: homeColor)),
            const SizedBox(width: 10),
            Expanded(
                child: SizedBox(
                    height: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(children: [
                        Expanded(
                            flex: widget.homePossession,
                            child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                              homeColor,
                              homeColor.withValues(alpha: 0.75)
                            ])))),
                        Container(
                            width: 2,
                            color: isDark
                                ? const Color(0xFF1A1A1A)
                                : Colors.white),
                        Expanded(
                            flex: widget.awayPossession,
                            child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                              awayColor.withValues(alpha: 0.4),
                              awayColor.withValues(alpha: 0.3)
                            ])))),
                      ]),
                    ))),
            const SizedBox(width: 10),
            Text('${widget.awayPossession}%',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: awayColor)),
          ]),
          const SizedBox(height: 18),
          _heatmapCompBar(S.of(context)!.difesaSection, widget.homePossDefense, widget.awayPossDefense,
              homeColor, awayColor, tx, lb, isDark),
          SizedBox(height: 14),
          _heatmapCompBar(tr(context, 'Centrocampo'), widget.homePossMidfield, widget.awayPossMidfield,
              homeColor, awayColor, tx, lb, isDark),
          const SizedBox(height: 14),
          _heatmapCompBar(S.of(context)!.attaccoSection, widget.homePossAttack, widget.awayPossAttack,
              homeColor, awayColor, tx, lb, isDark),
        ]),
      ),
      const SizedBox(height: 14),

      // Territorio
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(localizeShotData(context, 'Dominio Territoriale'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 4),
          Text(localizeShotData(context, '% azioni nella metà campo avversaria'),
              style: TextStyle(fontSize: 11, color: lb)),
          const SizedBox(height: 14),
          _heatmapCompBar(tr(context, 'Territorio'), widget.homeTerritory, widget.awayTerritory,
              homeColor, awayColor, tx, lb, isDark),
        ]),
      ),
      const SizedBox(height: 14),
    ]);
  }

  Widget _heatmapCompBar(String label, int value, int oppValue, Color color,
      Color oppColor, Color tx, Color lb, bool isDark) {
    final total = value + oppValue;
    final pct = total > 0 ? value / total : 0.5;
    return Column(children: [
      Text(label,
          style:
              TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
      const SizedBox(height: 8),
      Row(children: [
        SizedBox(
            width: 36,
            child: Text('$value',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: tx))),
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
                                  gradient: LinearGradient(colors: [
                            color,
                            color.withValues(alpha: 0.75)
                          ])))),
                      Container(
                          width: 2,
                          color:
                              isDark ? const Color(0xFF1A1A1A) : Colors.white),
                      Expanded(
                          flex: ((1 - pct) * 1000).round(),
                          child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                            oppColor.withValues(alpha: 0.35),
                            oppColor.withValues(alpha: 0.25)
                          ])))),
                    ])))),
        const SizedBox(width: 8),
        SizedBox(
            width: 36,
            child: Text('$oppValue',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: tx),
                textAlign: TextAlign.right)),
      ]),
    ]);
  }

  Widget _heatmapTeamStats(bool isHome, bool isDark, Color tx, Color lb,
      Color cardBg, Color cardBorder) {
    const homeColor = Color(0xFF1B5E20);
    const awayColor = Color(0xFF1565C0);
    final teamColor = isHome ? homeColor : awayColor;
    final oppColor = isHome ? awayColor : homeColor;
    final possession = isHome ? widget.homePossession : widget.awayPossession;
    final oppPossession = isHome ? widget.awayPossession : widget.homePossession;
    final territory = isHome ? widget.homeTerritory : widget.awayTerritory;
    final oppTerritory = isHome ? widget.awayTerritory : widget.homeTerritory;
    final possDefense = isHome ? widget.homePossDefense : widget.awayPossDefense;
    final possMidfield = isHome ? widget.homePossMidfield : widget.awayPossMidfield;
    final possAttack = isHome ? widget.homePossAttack : widget.awayPossAttack;
    final zones = isHome ? widget.homeHeatZones : widget.awayHeatZones;
    // Dati aggiuntivi centralizzati
    final totalPasses = isHome ? periodScale(widget.homePassesTotal, _heatmapTimeFilter) : periodScale(widget.awayPassesTotal, _heatmapTimeFilter);
    final accPasses = isHome ? periodScale(widget.homePassesCompleted, _heatmapTimeFilter) : periodScale(widget.awayPassesCompleted, _heatmapTimeFilter);
    final accPct =
        totalPasses > 0 ? (accPasses / totalPasses * 100).round() : 0;
    final corners = isHome ? periodScale(widget.homeCorners, _heatmapTimeFilter) : periodScale(widget.awayCorners, _heatmapTimeFilter);
    final oppCorners = isHome ? periodScale(widget.awayCorners, _heatmapTimeFilter) : periodScale(widget.homeCorners, _heatmapTimeFilter);
    final ftEntries = isHome ? periodScale(widget.homeFinalThirdEntries, _heatmapTimeFilter) : periodScale(widget.awayFinalThirdEntries, _heatmapTimeFilter);
    final oppFtEntries =
        isHome ? periodScale(widget.awayFinalThirdEntries, _heatmapTimeFilter) : periodScale(widget.homeFinalThirdEntries, _heatmapTimeFilter);
    final shots = isHome ? periodScale(widget.homeShotsTotal, _heatmapTimeFilter) : periodScale(widget.awayShotsTotal, _heatmapTimeFilter);
    final oppShots = isHome ? periodScale(widget.awayShotsTotal, _heatmapTimeFilter) : periodScale(widget.homeShotsTotal, _heatmapTimeFilter);
    final shotsOnTarget = isHome ? periodScale(widget.homeShotsOnTarget, _heatmapTimeFilter) : periodScale(widget.awayShotsOnTarget, _heatmapTimeFilter);
    final oppShotsOnTarget = isHome ? periodScale(widget.awayShotsOnTarget, _heatmapTimeFilter) : periodScale(widget.homeShotsOnTarget, _heatmapTimeFilter);
    // Zona più attiva
    final maxZone = zones.reduce((a, b) => a > b ? a : b);
    final maxIdx = zones.indexOf(maxZone).clamp(0, 19);
    const zoneNames = [
      'Difesa SX',
      'Difesa CSX',
      'Difesa CDX',
      'Difesa DX',
      'Centrodif. SX',
      'Centrodif. Centro-SX',
      'Centrodif. Centro-DX',
      'Centrodif. DX',
      'Centrocampo SX',
      'Centrocampo CSX',
      'Centrocampo CDX',
      'Centrocampo DX',
      'Centroatt. SX',
      'Centroatt. CSX',
      'Centroatt. CDX',
      'Centroatt. DX',
      'Attacco SX',
      'Attacco CSX',
      'Attacco CDX',
      'Attacco DX',
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ─── Card principale: possesso + territorio ───
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          // Due cerchi grandi: possesso e territorio
          Row(children: [
            Expanded(
                child: Column(children: [
              Text(S.of(context)!.possessoSection,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
              const SizedBox(height: 10),
              widget.circularProgress(
                  possession / 100, '$possession%', teamColor, 62),
              const SizedBox(height: 6),
              Text('vs $oppPossession%',
                  style: TextStyle(fontSize: 12, color: lb)),
            ])),
            Container(
                width: 1,
                height: 80,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
            Expanded(
                child: Column(children: [
              Text(localizeShotData(context, 'Territorio'),
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
              const SizedBox(height: 10),
              widget.circularProgress(territory / 100, '$territory%', teamColor, 62),
              const SizedBox(height: 6),
              Text('vs $oppTerritory%',
                  style: TextStyle(fontSize: 12, color: lb)),
            ])),
          ]),
          const SizedBox(height: 20),
          // Possesso per terzo
          Text(tr(context, 'Possesso per zona'),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
          const SizedBox(height: 12),
          _heatmapZoneBar(S.of(context)!.difesaSection, possDefense, 50, teamColor, tx, lb, isDark),
          SizedBox(height: 10),
          _heatmapZoneBar(
              'Centrocampo', possMidfield, 50, teamColor, tx, lb, isDark),
          const SizedBox(height: 10),
          _heatmapZoneBar(S.of(context)!.attaccoSection, possAttack, 50, teamColor, tx, lb, isDark),
        ]),
      ),
      const SizedBox(height: 14),

      // ─── Zona più attiva ───
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: teamColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.whatshot, color: teamColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(tr(context, 'Zona più attiva'),
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
                const SizedBox(height: 4),
                Text(zoneNames[maxIdx],
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
                Text('$maxZone ${tr(context, 'tocchi')}',
                    style: TextStyle(
                        fontSize: 12,
                        color: teamColor,
                        fontWeight: FontWeight.w600)),
              ])),
        ]),
      ),
      const SizedBox(height: 14),

      // ─── Metriche comparative vs avversario ───
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(localizeShotData(context, 'Confronto con avversario'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          SizedBox(height: 18),
          _heatmapMetricVs(Icons.sports_soccer, localizeShotData(context, 'Tiri totali'), shots, oppShots,
              teamColor, oppColor, tx, lb),
          SizedBox(height: 16),
          _heatmapMetricVs(Icons.gps_fixed, localizeShotData(context, 'Tiri in porta'), shotsOnTarget,
              oppShotsOnTarget, teamColor, oppColor, tx, lb),
          const SizedBox(height: 16),
          _heatmapMetricVs(Icons.swap_calls, '${S.of(context)!.passaggiSection} ($accPct%)', accPasses,
              totalPasses - accPasses, teamColor, Colors.grey, tx, lb,
              showOppAsLabel: true, oppLabel: 'errati'),
          const SizedBox(height: 16),
          _heatmapMetricVs(Icons.flag, tr(context, 'Corner'), corners, oppCorners, teamColor,
              oppColor, tx, lb),
          const SizedBox(height: 16),
          _heatmapMetricVs(Icons.arrow_upward, 'Ingressi terzo off.', ftEntries,
              oppFtEntries, teamColor, oppColor, tx, lb),
        ]),
      ),
      const SizedBox(height: 14),
    ]);
  }

  Widget _heatmapMetricVs(IconData icon, String label, int value, int oppValue,
      Color color, Color oppColor, Color tx, Color lb,
      {bool showOppAsLabel = false, String oppLabel = ''}) {
    final isWinning = value > oppValue;
    final isDraw = value == oppValue;
    return Row(children: [
      Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
      const SizedBox(width: 10),
      Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: tx))),
      Text(value.toString(),
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      if (!isDraw) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
              color: (isWinning
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4)),
          child: Icon(isWinning ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 16,
              color: isWinning
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44336)),
        ),
      ],
      const SizedBox(width: 6),
      Text(showOppAsLabel ? oppLabel : 'vs ${oppValue.toString()}',
          style: TextStyle(fontSize: 12, color: lb)),
    ]);
  }

  Widget _heatmapZoneBar(String label, int value, int max, Color color,
      Color tx, Color lb, bool isDark) {
    return Row(children: [
      SizedBox(
          width: 90,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: lb))),
      Expanded(
          child: SizedBox(
              height: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(children: [
                  Container(
                      color: Colors.grey.withValues(alpha: isDark ? 0.15 : 0.12)),
                  FractionallySizedBox(
                      widthFactor: (value / max).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.7)]),
                            borderRadius: BorderRadius.circular(5)),
                      )),
                ]),
              ))),
      const SizedBox(width: 10),
      Text('$value%',
          style:
              TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tx)),
    ]);
  }
}
