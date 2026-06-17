import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/soccer_match.dart';

class H2HTab extends StatelessWidget {
  final List<SoccerMatch> matches;
  final String homeTeamName;
  final String awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final int homeTeamId;
  final int awayTeamId;

  const H2HTab({
    Key? key,
    required this.matches,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
    required this.homeTeamId,
    required this.awayTeamId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey.withOpacity(0.3),
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .fadeIn(duration: 1500.ms)
                .scale(
                    begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
            const SizedBox(height: 24),
            Text(
              tr(context, 'Nessuno scontro diretto disponibile'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      );
    }

    // Calcola statistiche generali
    final stats = _calculateStats();

    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // Summary Card
          _buildSummaryCard(context, stats, isDark, theme),
          const SizedBox(height: 24),

          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  theme.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: theme.primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Ultimi Incontri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${matches.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0),

          const SizedBox(height: 16),

          // Match Cards
          ...matches.asMap().entries.map((entry) {
            final index = entry.key;
            final match = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMatchCard(context, match, isDark, theme, index),
            );
          }).toList(),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStats() {
    int homeWins = 0;
    int awayWins = 0;
    int draws = 0;
    int totalGoalsHome = 0;
    int totalGoalsAway = 0;

    for (var match in matches) {
      // Determina quale squadra è "home" nella partita storica
      final isHomeTeamHome = match.homeTeamId == homeTeamId;
      final homeScore = match.homeScore;
      final awayScore = match.awayScore;

      if (isHomeTeamHome) {
        // La squadra home attuale era home anche nella partita storica
        totalGoalsHome += homeScore;
        totalGoalsAway += awayScore;
        if (homeScore > awayScore) {
          homeWins++;
        } else if (awayScore > homeScore) {
          awayWins++;
        } else {
          draws++;
        }
      } else {
        // La squadra home attuale era away nella partita storica
        totalGoalsHome += awayScore;
        totalGoalsAway += homeScore;
        if (awayScore > homeScore) {
          homeWins++;
        } else if (homeScore > awayScore) {
          awayWins++;
        } else {
          draws++;
        }
      }
    }

    return {
      'homeWins': homeWins,
      'awayWins': awayWins,
      'draws': draws,
      'totalGoalsHome': totalGoalsHome,
      'totalGoalsAway': totalGoalsAway,
      'avgGoalsHome': totalGoalsHome / matches.length,
      'avgGoalsAway': totalGoalsAway / matches.length,
    };
  }

  Widget _buildSummaryCard(
    BuildContext context,
    Map<String, dynamic> stats,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[800]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Teams Header
          Row(
            children: [
              // Home Team
              Expanded(
                child: Column(
                  children: [
                    if (homeTeamLogo != null)
                      CachedNetworkImage(
                        imageUrl: homeTeamLogo!,
                        width: 48,
                        height: 48,
                        errorWidget: (_, __, ___) => Icon(
                          Icons.shield,
                          size: 48,
                          color: theme.primaryColor,
                        ),
                      )
                    else
                      Icon(Icons.shield, size: 48, color: theme.primaryColor),
                    const SizedBox(height: 12),
                    Text(
                      homeTeamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .scale(begin: const Offset(0.8, 0.8)),

              // VS Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .scale(begin: const Offset(0.5, 0.5)),

              // Away Team
              Expanded(
                child: Column(
                  children: [
                    if (awayTeamLogo != null)
                      CachedNetworkImage(
                        imageUrl: awayTeamLogo!,
                        width: 48,
                        height: 48,
                        errorWidget: (_, __, ___) => Icon(
                          Icons.shield,
                          size: 48,
                          color: theme.primaryColor,
                        ),
                      )
                    else
                      Icon(Icons.shield, size: 48, color: theme.primaryColor),
                    const SizedBox(height: 12),
                    Text(
                      awayTeamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 150.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
            ],
          ),

          const SizedBox(height: 32),

          // Win/Draw/Loss Stats
          Row(
            children: [
              // Home Wins
              Expanded(
                child: _buildStatColumn(
                  tr(context, 'Vittorie'),
                  '${stats['homeWins']}',
                  const Color(0xFF2196F3),
                  isDark,
                  0,
                ),
              ),

              // Draws
              Expanded(
                child: _buildStatColumn(
                  tr(context, 'Pareggi'),
                  '${stats['draws']}',
                  Colors.grey,
                  isDark,
                  1,
                ),
              ),

              // Away Wins
              Expanded(
                child: _buildStatColumn(
                  tr(context, 'Vittorie'),
                  '${stats['awayWins']}',
                  const Color(0xFFE53935),
                  isDark,
                  2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Divider
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  theme.primaryColor.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Goals Stats
          Row(
            children: [
              Expanded(
                child: _buildGoalsStat(
                  tr(context, 'Gol Totali'),
                  '${stats['totalGoalsHome']}',
                  const Color(0xFF2196F3),
                  isDark,
                ),
              ),
              Container(
                width: 2,
                height: 50,
                color: theme.primaryColor.withOpacity(0.2),
              ),
              Expanded(
                child: _buildGoalsStat(
                  tr(context, 'Gol Totali'),
                  '${stats['totalGoalsAway']}',
                  const Color(0xFFE53935),
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Match Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_soccer, size: 18, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '${tr(context, "Totale")}: ${matches.length} ${tr(context, "partite")}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatColumn(
    String label,
    String value,
    Color color,
    bool isDark,
    int index,
  ) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.7)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: 300 + (index * 100)))
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsStat(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    SoccerMatch match,
    bool isDark,
    ThemeData theme,
    int index,
  ) {
    // Determina se homeTeam attuale era home o away in questa partita
    final isHomeTeamHome = match.homeTeamId == homeTeamId;
    final homeScore = match.homeScore;
    final awayScore = match.awayScore;

    // Calcola il risultato dal punto di vista della squadra home attuale
    String result = 'D';
    Color resultColor = Colors.grey;
    if (isHomeTeamHome) {
      if (homeScore > awayScore) {
        result = 'V';
        resultColor = Colors.green;
      } else if (awayScore > homeScore) {
        result = 'S';
        resultColor = Colors.red;
      }
    } else {
      if (awayScore > homeScore) {
        result = 'V';
        resultColor = Colors.green;
      } else if (homeScore > awayScore) {
        result = 'S';
        resultColor = Colors.red;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[800]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: resultColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: resultColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: League + Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, size: 16, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.leagueName ?? 'Serie A',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDate(match.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Match Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Result Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [resultColor, resultColor.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: resultColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      result,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Teams and Score
                Expanded(
                  child: Column(
                    children: [
                      // Home Team Row
                      Row(
                        children: [
                          if (match.homeTeamLogo != null)
                            CachedNetworkImage(
                              imageUrl: match.homeTeamLogo!,
                              width: 20,
                              height: 20,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.shield,
                                size: 20,
                              ),
                            )
                          else
                            const Icon(Icons.shield, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              match.homeTeamName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isHomeTeamHome
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$homeScore',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Away Team Row
                      Row(
                        children: [
                          if (match.awayTeamLogo != null)
                            CachedNetworkImage(
                              imageUrl: match.awayTeamLogo!,
                              width: 20,
                              height: 20,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.shield,
                                size: 20,
                              ),
                            )
                          else
                            const Icon(Icons.shield, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              match.awayTeamName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: !isHomeTeamHome
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$awayScore',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(match.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(match.status).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _getStatusText(match.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(match.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 + (index * 80)))
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.2, end: 0, curve: Curves.easeOut);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final months = [
      'Gen',
      'Feb',
      'Mar',
      'Apr',
      'Mag',
      'Giu',
      'Lug',
      'Ago',
      'Set',
      'Ott',
      'Nov',
      'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ft':
      case 'finished':
        return Colors.green;
      case 'live':
      case '1h':
      case '2h':
        return Colors.red;
      case 'ns':
      case 'scheduled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'ft':
      case 'finished':
        return 'FT';
      case 'live':
        return 'LIVE';
      case '1h':
        return '1T';
      case '2h':
        return '2T';
      case 'ns':
      case 'scheduled':
        return 'PROG';
      default:
        return status.toUpperCase();
    }
  }
}
