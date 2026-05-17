// lib/pages/coach_detail_screen.dart
import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import '../generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/haptic_service.dart';
import '../models/coach_season_stats.dart'; // ✅ IMPORT CORRETTO

class CoachDetailScreen extends StatefulWidget {
  final String coachName;
  final String teamName;
  final Color teamColor;
  final String? teamLogo;
  final List<CoachSeasonStats> coachHistory;
  final String nationality;
  final String countryFlag;
  final int age;
  final int yearsOfExperience;

  const CoachDetailScreen({
    super.key,
    required this.coachName,
    required this.teamName,
    required this.teamColor,
    this.teamLogo,
    required this.coachHistory,
    required this.nationality,
    required this.countryFlag,
    required this.age,
    required this.yearsOfExperience,
  });

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen> {
  final HapticService _haptic = HapticService();
  bool _showAllSeasons = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSeason = widget.coachHistory.first;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: widget.teamColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.teamColor,
                      widget.teamColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(60, 20, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (widget.teamLogo != null)
                          CachedNetworkImage(
                            imageUrl: widget.teamLogo!,
                            width: 45,
                            height: 45,
                            errorWidget: (context, url, error) => Icon(
                                Icons.shield,
                                size: 45,
                                color: Colors.white.withOpacity(0.5)),
                          )
                        else
                          Icon(Icons.shield,
                              size: 45, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.coachName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.countryFlag} ${widget.nationality} • ${widget.age} anni',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),

              // Stagione Corrente
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  tr(context, 'Stagione in Corso'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildSeasonCard(currentSeason, widget.teamColor, isDark,
                  isCurrentSeason: true),

              const SizedBox(height: 24),

              // Storico Stagioni
              if (widget.coachHistory.length > 1) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr(context, 'Storico Carriera'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (widget.coachHistory.length > 4)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showAllSeasons = !_showAllSeasons;
                            });
                            _haptic.lightImpact();
                          },
                          child: Text(
                            _showAllSeasons ? 'Mostra meno' : 'Mostra tutto',
                            style: TextStyle(color: widget.teamColor),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...(_showAllSeasons
                        ? widget.coachHistory.skip(1)
                        : widget.coachHistory.skip(1).take(3))
                    .map((season) {
                  final isBestSeason = _isBestSeason(season);
                  return _buildSeasonCard(season, widget.teamColor, isDark,
                      isBestSeason: isBestSeason);
                }),
                const SizedBox(height: 24),
              ],

              // Statistiche Totali Carriera
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  S.of(context)!.totaliCarriera,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildCareerTotals(isDark),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  bool _isBestSeason(CoachSeasonStats season) {
    double bestScore = 0;
    CoachSeasonStats? bestSeason;

    for (var s in widget.coachHistory) {
      double score = s.winPercentage +
          (s.trophies != null ? 20 : 0) +
          ((s.goalsScored - s.goalsConceded) * 0.1);
      if (score > bestScore) {
        bestScore = score;
        bestSeason = s;
      }
    }

    return season == bestSeason;
  }

  Widget _buildSeasonCard(CoachSeasonStats season, Color teamColor, bool isDark,
      {bool isCurrentSeason = false, bool isBestSeason = false}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isCurrentSeason
            ? LinearGradient(
                colors: [
                  teamColor.withOpacity(0.15),
                  teamColor.withOpacity(0.05)
                ],
              )
            : isBestSeason
                ? LinearGradient(
                    colors: [
                      Colors.amber.withOpacity(0.15),
                      Colors.amber.withOpacity(0.05)
                    ],
                  )
                : null,
        color: isCurrentSeason || isBestSeason
            ? null
            : (isDark ? Colors.grey[850] : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentSeason
              ? teamColor.withOpacity(0.4)
              : isBestSeason
                  ? Colors.amber.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.2),
          width: isCurrentSeason || isBestSeason ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (season.teamLogo != null)
                CachedNetworkImage(
                  imageUrl: season.teamLogo!,
                  width: 32,
                  height: 32,
                  errorWidget: (context, url, error) =>
                      Icon(Icons.shield, size: 32, color: Colors.grey[400]),
                )
              else
                Icon(Icons.shield, size: 32, color: Colors.grey[400]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            season.teamName ?? widget.teamName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isCurrentSeason ? teamColor : null,
                            ),
                          ),
                        ),
                        if (season.trophies != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.emoji_events,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  season.trophies!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${tr(context, "Stagione")} ${season.season}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (isBestSeason) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.white, size: 11),
                                SizedBox(width: 3),
                                Text(
                                  'MIGLIORE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Statistiche
          Row(
            children: [
              Expanded(
                child: _buildStatBox(S.of(context)!.partite, season.matchesPlayed.toString(),
                    teamColor, isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox(
                    S.of(context)!.vittorie, season.wins.toString(), Colors.green, isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox(
                    S.of(context)!.pareggi, season.draws.toString(), Colors.grey, isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox(
                    S.of(context)!.sconfitte, season.losses.toString(), Colors.red, isDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                    'Goal Fatti',
                    season.goalsScored.toString(),
                    teamColor.withOpacity(0.7),
                    isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox('Goal Subiti',
                    season.goalsConceded.toString(), Colors.red, isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox(
                    'Win%',
                    '${season.winPercentage.toStringAsFixed(1)}%',
                    Colors.green,
                    isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerTotals(bool isDark) {
    final totalMatches =
        widget.coachHistory.fold<int>(0, (sum, s) => sum + s.matchesPlayed);
    final totalWins =
        widget.coachHistory.fold<int>(0, (sum, s) => sum + s.wins);
    final totalDraws =
        widget.coachHistory.fold<int>(0, (sum, s) => sum + s.draws);
    final totalLosses =
        widget.coachHistory.fold<int>(0, (sum, s) => sum + s.losses);
    final totalGoalsScored =
        widget.coachHistory.fold<int>(0, (sum, s) => sum + s.goalsScored);
    final totalGoalsConceded =
        widget.coachHistory.fold<int>(0, (sum, s) => sum + s.goalsConceded);
    final totalTrophies =
        widget.coachHistory.where((s) => s.trophies != null).length;
    final winPercentage =
        totalMatches > 0 ? (totalWins / totalMatches * 100) : 0.0;
    final avgGoalsScored =
        totalMatches > 0 ? (totalGoalsScored / totalMatches) : 0.0;
    final avgGoalsConceded =
        totalMatches > 0 ? (totalGoalsConceded / totalMatches) : 0.0;
    final goalDifference = totalGoalsScored - totalGoalsConceded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Statistiche Base
          Row(
            children: [
              Expanded(
                  child: _buildTotalStatItem(
                      S.of(context)!.partite, totalMatches, widget.teamColor, isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildTotalStatItem(
                      S.of(context)!.vittorie, totalWins, Colors.green, isDark)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildTotalStatItem(
                      S.of(context)!.pareggi, totalDraws, Colors.grey, isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildTotalStatItem(
                      S.of(context)!.sconfitte, totalLosses, Colors.red, isDark)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildTotalStatItem(
                      'Win%',
                      '${winPercentage.toStringAsFixed(1)}%',
                      Colors.green,
                      isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildTotalStatItem(
                      'Trofei', totalTrophies, Colors.amber, isDark)),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 20),

          // Statistiche Avanzate
          Text(
            S.of(context)!.statisticheAvanzate,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildAdvancedStatItem(tr(context, 'Media Goal Fatti'),
              avgGoalsScored.toStringAsFixed(2), widget.teamColor, isDark),
          const SizedBox(height: 12),
          _buildAdvancedStatItem(tr(context, 'Media Goal Subiti'),
              avgGoalsConceded.toStringAsFixed(2), Colors.red, isDark),
          const SizedBox(height: 12),
          _buildAdvancedStatItem(
              tr(context, 'Differenza Reti'),
              '${goalDifference >= 0 ? '+' : ''}$goalDifference',
              goalDifference >= 0 ? Colors.green : Colors.red,
              isDark),
        ],
      ),
    );
  }

  Widget _buildTotalStatItem(
      String label, dynamic value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedStatItem(
      String label, String value, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
