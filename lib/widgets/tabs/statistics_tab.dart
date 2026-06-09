// lib/widgets/tabs/statistics_tab.dart
//
// Tab "Statistiche" della partita: 5 sezioni (Possesso, Tiri, Passaggi,
// Generali, Difesa) con confronto Home vs Away.
// Estratta da match_detail_screen.dart.
//
// I valori delle statistiche vengono ricevuti via costruttore.
// Quando l-API sara attiva, il wrapper nel match_detail_screen passera
// i valori dal repository invece dei mock attualmente hardcoded.
//
// // [FAV-statistics-tab]

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/l10n_helper.dart';
import '../../generated/l10n.dart';
import '../../widgets/Interactive_defensive_widget.dart';
import '../../painters/match_detail_painters.dart';

class StatisticsTab extends StatelessWidget {
  final String homeTeamName;
  final String awayTeamName;
  final int homePossession;
  final int awayPossession;
  final int homeShotsTotal;
  final int awayShotsTotal;
  final int homeShotsOnTarget;
  final int awayShotsOnTarget;
  final int homePassesTotal;
  final int awayPassesTotal;
  final int homePassesCompleted;
  final int awayPassesCompleted;
  final int homeKeyPasses;
  final int awayKeyPasses;
  final int homeCrossOk;
  final int awayCrossOk;
  final int homeLongBallsOk;
  final int awayLongBallsOk;
  final int homeCorners;
  final int awayCorners;
  final int homeThrowIns;
  final int awayThrowIns;
  final int homeOffsides;
  final int awayOffsides;
  final int homeFouls;
  final int awayFouls;
  final int homeYellowCards;
  final int awayYellowCards;
  final DefensiveStats homeDefensiveStats;
  final DefensiveStats awayDefensiveStats;

  const StatisticsTab({
    Key? key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homePossession,
    required this.awayPossession,
    required this.homeShotsTotal,
    required this.awayShotsTotal,
    required this.homeShotsOnTarget,
    required this.awayShotsOnTarget,
    required this.homePassesTotal,
    required this.awayPassesTotal,
    required this.homePassesCompleted,
    required this.awayPassesCompleted,
    required this.homeKeyPasses,
    required this.awayKeyPasses,
    required this.homeCrossOk,
    required this.awayCrossOk,
    required this.homeLongBallsOk,
    required this.awayLongBallsOk,
    required this.homeCorners,
    required this.awayCorners,
    required this.homeThrowIns,
    required this.awayThrowIns,
    required this.homeOffsides,
    required this.awayOffsides,
    required this.homeFouls,
    required this.awayFouls,
    required this.homeYellowCards,
    required this.awayYellowCards,
    required this.homeDefensiveStats,
    required this.awayDefensiveStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _buildStatisticsTab(context, theme, isDark);
  }

  Widget _buildStatisticsTab(BuildContext context, ThemeData theme, bool isDark) {
    final homeColor = const Color(0xFF2196F3);
    final awayColor = const Color(0xFFE53935);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final sectionBg = isDark ? const Color(0xFF16162A) : const Color(0xFFF8F9FA);
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);
    final tx = isDark ? Colors.white : Colors.black87;
    final txSub = isDark ? Colors.white54 : Colors.grey[600]!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF0F2F5),
            isDark ? const Color(0xFF121228) : const Color(0xFFE8EAF0),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        children: [
          // ── Header con nomi squadre ──
          _statsTeamHeader(context, isDark, homeColor, awayColor),
          const SizedBox(height: 14),

          // ── Possesso Palla (widget speciale) ──
          _statsPossessionWidget(context, isDark, homeColor, awayColor, cardBg),
          const SizedBox(height: 14),

          // ── Sezione: Tiri ──
          _statsSection(
            title: S.of(context)!.tiriSection,
            icon: Icons.sports_soccer,
            isDark: isDark,
            cardBg: cardBg,
            sectionBg: sectionBg,
            divider: divider,
            tx: tx,
            txSub: txSub,
            homeColor: homeColor,
            awayColor: awayColor,
            stats: [
              StatItem(S.of(context)!.tiriTotali, homeShotsTotal, awayShotsTotal),
              StatItem(S.of(context)!.tiriInPorta, homeShotsOnTarget, awayShotsOnTarget),
              StatItem(S.of(context)!.tiriFuori, homeShotsTotal - homeShotsOnTarget, awayShotsTotal - awayShotsOnTarget),
            ],
          ),
          const SizedBox(height: 14),

          // ── Sezione: Passaggi ──
          _statsSection(
            title: S.of(context)!.passaggiSection,
            icon: Icons.swap_calls,
            isDark: isDark,
            cardBg: cardBg,
            sectionBg: sectionBg,
            divider: divider,
            tx: tx,
            txSub: txSub,
            homeColor: homeColor,
            awayColor: awayColor,
            stats: [
              StatItem(S.of(context)!.passaggiTotali, homePassesTotal, awayPassesTotal),
              StatItem(S.of(context)!.passaggiPrecisi, homePassesCompleted, awayPassesCompleted),
              StatItem(S.of(context)!.passaggiChiave, homeKeyPasses, awayKeyPasses),
              StatItem(S.of(context)!.crossRiusciti, homeCrossOk, awayCrossOk),
              StatItem(S.of(context)!.palleLunghe, homeLongBallsOk, awayLongBallsOk),
            ],
          ),
          const SizedBox(height: 14),

          // ── Sezione: Generali ──
          _statsSection(
            title: 'Generali',
            icon: Icons.bar_chart_rounded,
            isDark: isDark,
            cardBg: cardBg,
            sectionBg: sectionBg,
            divider: divider,
            tx: tx,
            txSub: txSub,
            homeColor: homeColor,
            awayColor: awayColor,
            stats: [
              StatItem(S.of(context)!.calciAngolo, homeCorners, awayCorners),
              StatItem(S.of(context)!.rimesseLaterali, homeThrowIns, awayThrowIns),
              StatItem(tr(context, 'Fuorigioco'), homeOffsides, awayOffsides),
            ],
          ),
          const SizedBox(height: 14),

          // ── Sezione: Difesa ──
          _statsSection(
            title: S.of(context)!.difesaSection,
            icon: Icons.security_rounded,
            isDark: isDark,
            cardBg: cardBg,
            sectionBg: sectionBg,
            divider: divider,
            tx: tx,
            txSub: txSub,
            homeColor: homeColor,
            awayColor: awayColor,
            stats: [
              StatItem(S.of(context)!.contrastiTotali, homeDefensiveStats.tacklesTotal, awayDefensiveStats.tacklesTotal),
              StatItem(localizeShotData(context, 'Contrasti vinti'), homeDefensiveStats.tacklesWon, awayDefensiveStats.tacklesWon),
              StatItem(S.of(context)!.intercetti, homeDefensiveStats.interceptions, awayDefensiveStats.interceptions),
              StatItem(localizeShotData(context, 'Rinvii'), homeDefensiveStats.rinvii, awayDefensiveStats.rinvii),
            ],
          ),
          const SizedBox(height: 14),

          // ── Sezione: Disciplina ──
          _statsSection(
            title: S.of(context)!.disciplinaLabel,
            icon: Icons.shield_outlined,
            isDark: isDark,
            cardBg: cardBg,
            sectionBg: sectionBg,
            divider: divider,
            tx: tx,
            txSub: txSub,
            homeColor: homeColor,
            awayColor: awayColor,
            stats: [
              StatItem(S.of(context)!.falliLabel, homeFouls, awayFouls),
              StatItem(S.of(context)!.cartelliniGialli, homeYellowCards, awayYellowCards),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
    );
  }

  Widget _statsTeamHeader(BuildContext context, bool isDark, Color homeColor, Color awayColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: homeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    homeTeamName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Text(
            tr(context, 'STATISTICHE'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white24 : Colors.grey[400],
              letterSpacing: 2.0,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    awayTeamName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: awayColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsPossessionWidget(BuildContext context, bool isDark, Color homeColor, Color awayColor, Color cardBg) {
    final homeP = homePossession;
    final awayP = awayPossession;
    final homeWins = homeP > awayP;
    final awayWins = awayP > homeP;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            S.of(context)!.possessoPalla,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Home percentage
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$homeP%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: homeWins ? homeColor : (isDark ? Colors.white38 : Colors.grey[400]),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              // Center possession bar
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: CustomPaint(
                    painter: PossessionBarPainter(
                      homePercent: homeP / 100,
                      homeColor: homeColor,
                      awayColor: awayColor,
                      isDark: isDark,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
              // Away percentage
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$awayP%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: awayWins ? awayColor : (isDark ? Colors.white38 : Colors.grey[400]),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0, duration: 400.ms);
  }

  Widget _statsSection({
    required String title,
    required IconData icon,
    required bool isDark,
    required Color cardBg,
    required Color sectionBg,
    required Color divider,
    required Color tx,
    required Color txSub,
    required Color homeColor,
    required Color awayColor,
    required List<StatItem> stats,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: sectionBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: isDark ? Colors.white38 : Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Stat rows
          ...stats.asMap().entries.map((entry) {
            final i = entry.key;
            final stat = entry.value;
            final isLast = i == stats.length - 1;
            return _premiumStatRow(
              label: stat.label,
              homeValue: stat.home,
              awayValue: stat.away,
              homeColor: homeColor,
              awayColor: awayColor,
              isDark: isDark,
              tx: tx,
              txSub: txSub,
              showDivider: !isLast,
              dividerColor: divider,
              animDelay: i * 80,
            );
          }),
        ],
      ),
    ).animate()
        .fadeIn(duration: 500.ms, delay: 100.ms)
        .slideY(begin: 0.05, end: 0, duration: 400.ms, delay: 100.ms);
  }

  Widget _premiumStatRow({
    required String label,
    required int homeValue,
    required int awayValue,
    required Color homeColor,
    required Color awayColor,
    required bool isDark,
    required Color tx,
    required Color txSub,
    required bool showDivider,
    required Color dividerColor,
    int animDelay = 0,
  }) {
    final total = homeValue + awayValue;
    final homePercent = total > 0 ? homeValue / total : 0.5;
    final awayPercent = total > 0 ? awayValue / total : 0.5;
    final homeWins = homeValue > awayValue;
    final awayWins = awayValue > homeValue;
    final isDraw = homeValue == awayValue;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              // Label + values row
              Row(
                children: [
                  // Home value
                  SizedBox(
                    width: 42,
                    child: Text(
                      homeValue.toString(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: homeWins ? FontWeight.w900 : FontWeight.w500,
                        color: homeWins ? homeColor : (isDark ? Colors.white60 : Colors.grey[500]),
                      ),
                    ),
                  ),
                  // Center label
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ),
                  // Away value
                  SizedBox(
                    width: 42,
                    child: Text(
                      awayValue.toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: awayWins ? FontWeight.w900 : FontWeight.w500,
                        color: awayWins ? awayColor : (isDark ? Colors.white60 : Colors.grey[500]),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Dual bar
              SizedBox(
                height: 6,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final gap = 3.0;
                    final availableWidth = (totalWidth - gap) / 2;
                    final homeBarWidth = availableWidth * (isDraw ? 1.0 : (homePercent * 2).clamp(0.0, 1.0));
                    final awayBarWidth = availableWidth * (isDraw ? 1.0 : (awayPercent * 2).clamp(0.0, 1.0));

                    return Row(
                      children: [
                        // Home bar (right-aligned, grows from center to left)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 800 + animDelay),
                                  curve: Curves.easeOutCubic,
                                  width: homeBarWidth,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: LinearGradient(
                                      colors: homeWins || isDraw
                                          ? [homeColor.withOpacity(0.5), homeColor]
                                          : [
                                              isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15),
                                              isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.25),
                                            ],
                                    ),
                                    boxShadow: homeWins
                                        ? [BoxShadow(color: homeColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 1))]
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: gap),
                        // Away bar (left-aligned, grows from center to right)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Flexible(
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 800 + animDelay),
                                  curve: Curves.easeOutCubic,
                                  width: awayBarWidth,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: LinearGradient(
                                      colors: awayWins || isDraw
                                          ? [awayColor, awayColor.withOpacity(0.5)]
                                          : [
                                              isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.25),
                                              isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15),
                                            ],
                                    ),
                                    boxShadow: awayWins
                                        ? [BoxShadow(color: awayColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 1))]
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 0.5, color: dividerColor, indent: 18, endIndent: 18),
      ],
    );
  }
}
