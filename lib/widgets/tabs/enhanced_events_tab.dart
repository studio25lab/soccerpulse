// lib/widgets/tabs/enhanced_events_tab.dart
//
// Tab "Eventi" della partita: timeline centrale con goal, cartellini,
// sostituzioni, momentum bar e filtri. Estratta da match_detail_screen.dart.
//
// Implementata come StatefulWidget perche gestisce state mutabile
// (toggle cronologico, set di filtri attivi).
//
// // [FAV-events-tab]

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/l10n_helper.dart';
import '../../generated/l10n.dart';
import '../../models/local_match_models.dart';

class EnhancedEventsTab extends StatefulWidget {
  final String homeTeamName;
  final String awayTeamName;
  final int homeShotsTotal;
  final int awayShotsTotal;
  final List<List<dynamic>> mockAttackMomentum;

  /// Callback per ottenere la lista di eventi della partita.
  final List<LocalMatchEvent> Function() getEvents;

  /// Callback per generare la lineup (necessaria per cliccare giocatori).
  final List<LocalLineupPlayer> Function(bool isHome) generateLineup;

  /// Callback per generare la panchina.
  final List<LocalLineupPlayer> Function(bool isHome) generateBench;

  /// Callback per ottenere l'icona di un tipo di evento.
  final IconData Function(String type) getEventIcon;

  /// Callback per localizzare dettagli evento.
  final String Function(BuildContext context, String? detail) localizeEventDetail;

  /// Callback per aprire stats giocatore dato un evento.
  final void Function(String playerName, bool isHome, bool isDark) openPlayerStatsFromEvent;

  /// Callback per aprire la modale stats giocatore.
  final void Function(LocalLineupPlayer player, Color teamColor, bool isDark, {List<LocalLineupPlayer> allPlayers}) showPlayerMatchStats;

  const EnhancedEventsTab({
    Key? key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeShotsTotal,
    required this.awayShotsTotal,
    required this.mockAttackMomentum,
    required this.getEvents,
    required this.generateLineup,
    required this.generateBench,
    required this.getEventIcon,
    required this.localizeEventDetail,
    required this.openPlayerStatsFromEvent,
    required this.showPlayerMatchStats,
  }) : super(key: key);

  @override
  State<EnhancedEventsTab> createState() => _EnhancedEventsTabState();
}

class _EnhancedEventsTabState extends State<EnhancedEventsTab> {
  // ── State locali (precedentemente nel padre) ──
  bool _eventsChronologicalOrder = true;

  Set<String> _activeEventFilters = {
    'goal',
    'yellowCard',
    'redCard',
    'substitution'
  };

  static const _keyEventTypes = {
    'goal',
    'yellowCard',
    'redCard',
    'substitution'
  };

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _eventKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToMinute(int minute) {
    final key = _eventKeys[minute];
    final ctx = key?.currentContext;
    if (ctx != null) {
      // Percorso principale: singola animazione fluida.
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0.25,
      );
    } else {
      // Fallback raro (item molto lontano non ancora montato nonostante
      // il cacheExtent). In Crono 0' in cima, 90' in fondo; in Recenti invertito.
      final max = _scrollController.position.maxScrollExtent;
      var frac = (minute / 90).clamp(0.0, 1.0);
      if (!_eventsChronologicalOrder) frac = 1.0 - frac;
      final target = frac * max;
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _buildEnhancedEventsTab(theme, isDark);
  }

  Widget _buildEnhancedEventsTab(ThemeData theme, bool isDark) {
    final allEvents = widget.getEvents();
    allEvents.sort((a, b) => a.minute.compareTo(b.minute));

    // Le GlobalKey vengono rigenerate a ogni build: l'ordine (Crono/Recenti)
    // cambia le posizioni, quindi le key vecchie non sono piu' valide.
    _eventKeys.clear();

    // Filter by active event types
    final filteredEvents =
        allEvents.where((e) => _activeEventFilters.contains(e.type)).toList();

    if (!_eventsChronologicalOrder)
      filteredEvents.sort((a, b) => b.minute.compareTo(a.minute));

    // Running score for goal events
    final scoreAtMinute = <int, List<int>>{};
    int hGoals = 0, aGoals = 0;
    final sortedAll = List<LocalMatchEvent>.from(allEvents)
      ..sort((a, b) => a.minute.compareTo(b.minute));
    for (final e in sortedAll) {
      if (e.type == 'goal') {
        if (e.isHomeTeam)
          hGoals++;
        else
          aGoals++;
      }
      scoreAtMinute[e.minute] = [hGoals, aGoals];
    }

    final bg = isDark ? Colors.grey[900]! : const Color(0xFFF5F6FA);
    final homeColor = const Color(0xFF1565C0);
    final awayColor = const Color(0xFFD32F2F);

    return Container(
      color: bg,
      child: Column(children: [
        _buildEventsControls(theme, isDark, allEvents),
        Expanded(
          child: filteredEvents.isEmpty
              ? Center(
                  child: Text(tr(context, 'Nessun evento trovato'),
                      style: TextStyle(fontSize: 16, color: Colors.grey[500])))
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  cacheExtent: 3000,
                  itemCount: filteredEvents.length + 3,
                  itemBuilder: (context, index) {
                    final isChrono = _eventsChronologicalOrder;
                    // First item: scrollable momentum chart
                    if (index == 0)
                      return _buildMomentumBar(allEvents, isDark, homeColor, awayColor);
                    // Second item: KO if chrono, FT if reverse
                    if (index == 1)
                      return _buildMatchMarker(
                          isChrono ? S.of(context)!.calcioInizio : S.of(context)!.finePartita,
                          isChrono ? 0 : 90,
                          isDark);
                    // Last item: FT if chrono, KO if reverse
                    if (index == filteredEvents.length + 2)
                      return _buildMatchMarker(
                          isChrono ? S.of(context)!.finePartita : S.of(context)!.calcioInizio,
                          isChrono ? 90 : 0,
                          isDark);
                    final event = filteredEvents[index - 2];
                    final score = scoreAtMinute[event.minute] ?? [0, 0];
                    // HT separator: detect crossing between 1st and 2nd half
                    bool needsHT = false;
                    if (index > 2) {
                      final prevEvent = filteredEvents[index - 3];
                      if (isChrono) {
                        needsHT = prevEvent.minute <= 45 && event.minute > 45;
                      } else {
                        needsHT = prevEvent.minute > 45 && event.minute <= 45;
                      }
                    }
                    final eventKey =
                        _eventKeys.putIfAbsent(event.minute, () => GlobalKey());
                    return Column(key: eventKey, children: [
                      if (needsHT) _buildMatchMarker(S.of(context)!.intervallo, 45, isDark),
                      _buildCentralTimelineEvent(
                          event, score, isDark, homeColor, awayColor),
                    ]);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _buildMomentumBar(List<LocalMatchEvent> allEvents, bool isDark,
      Color homeColor, Color awayColor) {
    final tx = isDark ? Colors.white : Colors.black87;
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final dividerColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.12);
    final data = widget.mockAttackMomentum;
    final segCount = data.length;

    // Eventi per i marker
    final goalEvents = allEvents.where((e) => e.type == 'goal').toList();
    final cardEvents = allEvents.where((e) => e.type == 'yellowCard' || e.type == 'redCard').toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.show_chart_rounded, size: 14, color: lb),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(S.of(context)!.faseOffensiva,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: tx, letterSpacing: 0.2)),
                const SizedBox(height: 2),
                Text(tr(context, 'Pressione offensiva minuto per minuto'),
                    style: TextStyle(
                        fontSize: 10, color: lb, fontWeight: FontWeight.w400, height: 1.2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _momentumLegendDot(homeColor, widget.homeTeamName, lb),
          const SizedBox(width: 12),
          _momentumLegendDot(awayColor, widget.awayTeamName, lb),
        ]),
        const SizedBox(height: 16),

        // ── Sismografo a barre ──
        SizedBox(
          height: 100,
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final barWidth = w / segCount;
            final halfH = 100.0 / 2;
            return Stack(clipBehavior: Clip.none, children: [
              // Subtle grid
              Positioned(
                top: halfH * 0.5,
                left: 0, right: 0,
                child: Container(height: 0.5, color: dividerColor),
              ),
              Positioned(
                top: halfH,
                left: 0, right: 0,
                child: Container(
                  height: 1,
                  color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.withOpacity(0.18),
                ),
              ),
              Positioned(
                top: halfH * 1.5,
                left: 0, right: 0,
                child: Container(height: 0.5, color: dividerColor),
              ),

              // Bars
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(segCount, (i) {
                  final isHome = data[i][1] as bool;
                  final intensity = (data[i][2] as double).clamp(0.0, 1.0);
                  final barH = intensity * (halfH - 4);
                  final color = isHome ? homeColor : awayColor;
                  final isHighIntensity = intensity > 0.7;

                  return SizedBox(
                    width: barWidth,
                    height: 100,
                    child: Stack(children: [
                      if (isHome && barH > 0)
                        Positioned(
                          bottom: halfH + 1,
                          left: barWidth * 0.12,
                          right: barWidth * 0.12,
                          height: barH,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  color.withOpacity(0.3 + intensity * 0.4),
                                  color.withOpacity(0.5 + intensity * 0.45),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1.5),
                              boxShadow: isHighIntensity
                                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, -1))]
                                  : null,
                            ),
                          ),
                        ),
                      if (!isHome && barH > 0)
                        Positioned(
                          top: halfH + 1,
                          left: barWidth * 0.12,
                          right: barWidth * 0.12,
                          height: barH,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  color.withOpacity(0.3 + intensity * 0.4),
                                  color.withOpacity(0.5 + intensity * 0.45),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1.5),
                              boxShadow: isHighIntensity
                                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 1))]
                                  : null,
                            ),
                          ),
                        ),
                    ]),
                  );
                }),
              ),

              // HT divider
              Positioned(
                left: 45 * barWidth,
                top: 0, bottom: 0,
                child: Container(
                  width: 1,
                  color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.25),
                ),
              ),

              // ── Event markers: Goals ──
              ...goalEvents.map((e) {
                final xPos = (e.minute / 90).clamp(0.0, 1.0) * w;
                return Positioned(
                  left: xPos - 8,
                  top: e.isHomeTeam ? 0 : null,
                  bottom: e.isHomeTeam ? null : 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _scrollToMinute(e.minute),
                      child: Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: e.isHomeTeam ? homeColor : awayColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBg, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: (e.isHomeTeam ? homeColor : awayColor).withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.sports_soccer, size: 8, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // ── Event markers: Cards ──
              ...cardEvents.map((e) {
                final xPos = (e.minute / 90).clamp(0.0, 1.0) * w;
                final isRed = e.type == 'redCard';
                return Positioned(
                  left: xPos - 4,
                  top: e.isHomeTeam ? 4 : null,
                  bottom: e.isHomeTeam ? null : 4,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _scrollToMinute(e.minute),
                      // area di tap leggermente piu' ampia del marker
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        color: Colors.transparent,
                        child: Container(
                          width: 8, height: 11,
                          decoration: BoxDecoration(
                            color: isRed ? Colors.red : Colors.amber,
                            borderRadius: BorderRadius.circular(1.5),
                            boxShadow: [
                              BoxShadow(
                                color: (isRed ? Colors.red : Colors.amber).withOpacity(0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ]);
          }),
        ),
        const SizedBox(height: 8),

        // ── Time labels ──
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _momentumTimeLabel("0'", lb, false),
          _momentumTimeLabel("15'", lb, false),
          _momentumTimeLabel("30'", lb, false),
          _momentumTimeLabel("45' · HT", lb, true),
          _momentumTimeLabel("60'", lb, false),
          _momentumTimeLabel("75'", lb, false),
          _momentumTimeLabel("90' · FT", lb, true),
        ]),
        const SizedBox(height: 10),
        // ── Mini-legend: marker types ──
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: lb.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.sports_soccer, size: 6, color: cardBg),
            ),
          ),
          const SizedBox(width: 5),
          Text(S.of(context)!.gol,
              style: TextStyle(fontSize: 9.5, color: lb, fontWeight: FontWeight.w500)),
          const SizedBox(width: 14),
          Container(
            width: 5, height: 8,
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 5, height: 8,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 5),
          Text(tr(context, 'Cartellini'),
              style: TextStyle(fontSize: 9.5, color: lb, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }

  Widget _momentumLegendDot(Color color, String label, Color textColor) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _momentumTimeLabel(String text, Color color, bool bold) {
    return Text(text, style: TextStyle(
      fontSize: 9,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color,
      letterSpacing: bold ? 0.5 : 0,
    ));
  }

  Widget _buildEventsControls(
      ThemeData theme, bool isDark, List<LocalMatchEvent> allEvents) {
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final cardBg = isDark ? Colors.grey[850]! : Colors.white;
    final accent = theme.primaryColor;
    final isAllKey = _activeEventFilters.length == _keyEventTypes.length &&
        _keyEventTypes.every((t) => _activeEventFilters.contains(t));
    final filterLabel = isAllKey
        ? S.of(context)!.eventiChiave
        : '${_activeEventFilters.length} filtri attivi';
    final filteredCount =
        allEvents.where((e) => _activeEventFilters.contains(e.type)).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        // Filter button
        Expanded(
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showEventFilterSheet(isDark),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(children: [
                    Icon(Icons.filter_list_rounded, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Text(filterLabel,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accent)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('$filteredCount',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accent)),
                    ),
                    const Spacer(),
                    Icon(Icons.expand_more_rounded, size: 18, color: lb),
                  ]),
                ),
              )),
        ),
        // Divider
        Container(
            width: 1,
            height: 28,
            color: isDark ? Colors.grey[700] : Colors.grey[200]),
        // Sort button
        Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() =>
                    _eventsChronologicalOrder = !_eventsChronologicalOrder);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      _eventsChronologicalOrder
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 16,
                      color: lb),
                  const SizedBox(width: 4),
                  Text(_eventsChronologicalOrder ? S.of(context)!.chrono : S.of(context)!.recenti,
                      style: TextStyle(
                          fontSize: 12,
                          color: lb,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            )),
      ]),
    );
  }

  void _showEventFilterSheet(bool isDark) {
    final tx = isDark ? Colors.white : Colors.black87;
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? Colors.grey[900]! : Colors.white;
    final allTypes = [
      ('goal', '⚽', S.of(context)!.gol),
      ('yellowCard', '🟨', tr(context, 'Cartellini gialli')),
      ('redCard', '🟥', tr(context, 'Cartellini rossi')),
      ('substitution', '🔄', tr(context, 'Sostituzioni')),
      ('shot', '🎯', S.of(context)!.tiriSection),
      ('foul', '⚠️', S.of(context)!.falliLabel),
      ('corner', '🚩', tr(context, 'Corner')),
      ('offside', '🏳️', tr(context, 'Fuorigioco')),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              // Title + quick actions
              Row(children: [
                Text(tr(context, 'Filtra eventi'),
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: tx)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setSheetState(() {});
                    setState(() => _activeEventFilters = {
                          'goal',
                          'yellowCard',
                          'redCard',
                          'substitution'
                        });
                    setSheetState(() {});
                  },
                  child: Text(tr(context, 'Solo chiave'),
                      style: TextStyle(fontSize: 12, color: lb)),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () {
                    setSheetState(() {});
                    setState(() => _activeEventFilters = {
                          'goal',
                          'yellowCard',
                          'redCard',
                          'substitution',
                          'shot',
                          'foul',
                          'corner',
                          'offside'
                        });
                    setSheetState(() {});
                  },
                  child:
                      Text(localizeShotData(context, 'Tutti'), style: TextStyle(fontSize: 12, color: lb)),
                ),
              ]),
              const SizedBox(height: 8),
              // Filter chips
              Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: allTypes.map((t) {
                    final type = t.$1;
                    final emoji = t.$2;
                    final label = t.$3;
                    final isActive = _activeEventFilters.contains(type);
                    final color = _getEventColor(type);

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (isActive)
                            _activeEventFilters.remove(type);
                          else
                            _activeEventFilters.add(type);
                        });
                        setSheetState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? color.withOpacity(0.15)
                              : (isDark ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isActive ? color : Colors.transparent,
                              width: 2),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isActive ? color : lb,
                              )),
                          if (isActive) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle_rounded,
                                size: 16, color: color),
                          ],
                        ]),
                      ),
                    );
                  }).toList()),
              const SizedBox(height: 16),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildMatchMarker(String label, int minute, bool isDark) {
    final lb = isDark ? Colors.grey[500]! : Colors.grey[500]!;
    final tx = isDark ? Colors.white : Colors.black87;

    // Icon + accent based on match phase
    IconData icon;
    Color accent;
    if (minute == 0) {
      icon = Icons.play_arrow_rounded;
      accent = const Color(0xFF26A69A); // teal-green: kickoff
    } else if (minute == 45) {
      icon = Icons.pause_circle_outline_rounded;
      accent = const Color(0xFFFFA726); // orange: halftime
    } else {
      icon = Icons.flag_rounded;
      accent = const Color(0xFFEF5350); // red: fulltime
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lb.withOpacity(0.0), lb.withOpacity(0.3)],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(isDark ? 0.18 : 0.12),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: tx,
                    letterSpacing: 0.9)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text("${minute}\'",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.3)),
            ),
          ]),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lb.withOpacity(0.3), lb.withOpacity(0.0)],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCentralTimelineEvent(LocalMatchEvent event, List<int> score,
      bool isDark, Color homeColor, Color awayColor) {
    final isHome = event.isHomeTeam;
    final isGoal = event.type == 'goal';
    final isKey = _keyEventTypes.contains(event.type);
    final teamColor = isHome ? homeColor : awayColor;
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final timelineColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    Widget minuteBadge = Container(
      width: isGoal ? 44 : (isKey ? 36 : 28),
      height: isGoal ? 44 : (isKey ? 36 : 28),
      decoration: BoxDecoration(
        color: isGoal
            ? teamColor
            : (isKey ? teamColor.withOpacity(0.15) : Colors.transparent),
        shape: BoxShape.circle,
        border: Border.all(
            color: isGoal
                ? teamColor
                : (isKey ? teamColor.withOpacity(0.5) : timelineColor),
            width: isGoal ? 2.5 : 1.5),
        boxShadow: isGoal
            ? [
                BoxShadow(
                    color: teamColor.withOpacity(0.35),
                    blurRadius: 10,
                    spreadRadius: 1)
              ]
            : null,
      ),
      child: Center(
          child: Text('${event.minute}\'',
              style: TextStyle(
                fontSize: isGoal ? 14 : (isKey ? 12 : 10),
                fontWeight: FontWeight.w800,
                color: isGoal ? Colors.white : (isKey ? teamColor : lb),
              ))),
    );

    Widget eventContent =
        GestureDetector(
        onTap: () => widget.openPlayerStatsFromEvent(event.playerName, isHome, isDark),
        child: _buildEventContent(event, isHome, isDark, teamColor, score));

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: isGoal ? 6 : (isKey ? 3 : 1), horizontal: 12),
      child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
            flex: 5, child: isHome ? eventContent : const SizedBox.shrink()),
        SizedBox(
            width: 52,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [minuteBadge])),
        Expanded(
            flex: 5, child: isHome ? const SizedBox.shrink() : eventContent),
      ])),
    );
  }

  Widget _buildEventContent(LocalMatchEvent event, bool isHome, bool isDark,
      Color teamColor, List<int> score) {
    final tx = isDark ? Colors.white : Colors.black87;
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final cardBg = isDark ? Colors.grey[850]! : Colors.white;

    if (event.type == 'goal')
      return _buildGoalEvent(
          event, isHome, isDark, teamColor, cardBg, tx, lb, score);
    if (event.type == 'yellowCard' || event.type == 'redCard')
      return _buildCardEvent(event, isHome, isDark, teamColor, cardBg, tx, lb);
    if (event.type == 'substitution')
      return _buildSubEvent(event, isHome, isDark, teamColor, cardBg, tx, lb);
    return _buildMinorEvent(event, isHome, isDark, teamColor, tx, lb);
  }

  Widget _buildGoalEvent(LocalMatchEvent event, bool isHome, bool isDark,
      Color teamColor, Color cardBg, Color tx, Color lb, List<int> score) {
    final textAlign = isHome ? TextAlign.right : TextAlign.left;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: teamColor.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: teamColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: teamColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
          crossAxisAlignment:
              isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: teamColor, borderRadius: BorderRadius.circular(8)),
              child: Text('${score[0]} - ${score[1]}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1)),
            ),
            const SizedBox(height: 6),
            Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isHome)
                    Icon(Icons.sports_soccer, size: 18, color: teamColor),
                  if (!isHome) const SizedBox(width: 6),
                  Flexible(
                      child: Text(event.playerName,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: tx),
                          textAlign: textAlign)),
                  if (isHome) const SizedBox(width: 6),
                  if (isHome)
                    Icon(Icons.sports_soccer, size: 18, color: teamColor),
                ]),
            if (event.detail != null && event.detail!.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(widget.localizeEventDetail(context, event.detail!),
                      style: TextStyle(
                          fontSize: 11, color: lb, fontStyle: FontStyle.italic),
                      textAlign: textAlign)),
          ]),
    );
  }

  Widget _buildCardEvent(LocalMatchEvent event, bool isHome, bool isDark,
      Color teamColor, Color cardBg, Color tx, Color lb) {
    final isRed = event.type == 'redCard';
    final cardColor = isRed ? const Color(0xFFD32F2F) : const Color(0xFFF9A825);
    final textAlign = isHome ? TextAlign.right : TextAlign.left;

    // ── Enhanced card icon: larger, bordered, with shadow ──
    Widget enhancedCardIcon() => Container(
          width: 16,
          height: 22,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(2.5),
            border: Border.all(
              color: cardColor.withOpacity(0.5),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardColor.withOpacity(0.18), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ]),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isHome) enhancedCardIcon(),
            if (!isHome) const SizedBox(width: 10),
            Flexible(
                child: Column(
                    crossAxisAlignment: isHome
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                  Text(event.playerName,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: tx),
                      textAlign: textAlign),
                  if (event.detail != null)
                    Text(widget.localizeEventDetail(context, event.detail!),
                        style: TextStyle(fontSize: 10, color: lb),
                        textAlign: textAlign),
                ])),
            if (isHome) const SizedBox(width: 10),
            if (isHome) enhancedCardIcon(),
          ]),
    );
  }

  Widget _buildSubEvent(LocalMatchEvent event, bool isHome, bool isDark,
      Color teamColor, Color cardBg, Color tx, Color lb) {
    final greenIn = isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
    final redOut = isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);

    // ── Swap icon: prominent, circular badge ──
    Widget swapBadge() => Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: teamColor.withOpacity(isDark ? 0.18 : 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: teamColor.withOpacity(0.35), width: 1),
          ),
          child: Icon(Icons.swap_vert_rounded,
              size: 16, color: teamColor),
        );

    // ── In/Out rows ──
    Widget inRow() => Row(mainAxisSize: MainAxisSize.min, children: [
          if (isHome)
            Flexible(
                child: Text(widget.localizeEventDetail(context, event.detail),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: greenIn))),
          if (isHome) const SizedBox(width: 4),
          Icon(Icons.arrow_downward_rounded, size: 12, color: greenIn),
          if (!isHome) const SizedBox(width: 4),
          if (!isHome)
            Flexible(
                child: Text(widget.localizeEventDetail(context, event.detail),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: greenIn))),
        ]);

    Widget outRow() => Row(mainAxisSize: MainAxisSize.min, children: [
          if (isHome)
            Flexible(
                child: Text(event.playerName,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: redOut))),
          if (isHome) const SizedBox(width: 4),
          Icon(Icons.arrow_upward_rounded, size: 12, color: redOut),
          if (!isHome) const SizedBox(width: 4),
          if (!isHome)
            Flexible(
                child: Text(event.playerName,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: redOut))),
        ]);

    final hasSubDetail = event.subDetail != null && event.subDetail!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: teamColor.withOpacity(0.18), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ]),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isHome) swapBadge(),
            if (!isHome) const SizedBox(width: 10),
            Flexible(
                child: Column(
                    crossAxisAlignment: isHome
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                  inRow(),
                  outRow(),
                  if (hasSubDetail)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        widget.localizeEventDetail(context, event.subDetail),
                        style: TextStyle(
                            fontSize: 10,
                            color: lb,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                ])),
            if (isHome) const SizedBox(width: 10),
            if (isHome) swapBadge(),
          ]),
    );
  }

  Widget _buildMinorEvent(LocalMatchEvent event, bool isHome, bool isDark,
      Color teamColor, Color tx, Color lb) {
    final icon = widget.getEventIcon(event.type);
    final color = _getEventColor(event.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isHome) Icon(icon, size: 13, color: color.withOpacity(0.7)),
            if (!isHome) const SizedBox(width: 5),
            Flexible(
                child: Text(
              '${event.playerName}${event.detail != null ? " · ${widget.localizeEventDetail(context, event.detail!)}" : ""}',
              style: TextStyle(
                  fontSize: 11, color: lb, fontWeight: FontWeight.w400),
              textAlign: isHome ? TextAlign.right : TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            if (isHome) const SizedBox(width: 5),
            if (isHome) Icon(icon, size: 13, color: color.withOpacity(0.7)),
          ]),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'goal':
        return const Color(0xFF4CAF50);
      case 'yellowCard':
        return const Color(0xFFF9A825);
      case 'redCard':
        return const Color(0xFFF44336);
      case 'substitution':
        return const Color(0xFF2E7D32);
      case 'foul':
        return const Color(0xFFFF9800);
      case 'offside':
        return const Color(0xFF2196F3);
      case 'shot':
        return const Color(0xFF9C27B0);
      case 'corner':
        return const Color(0xFF00BCD4);
      default:
        return Colors.grey;
    }
  }
}
