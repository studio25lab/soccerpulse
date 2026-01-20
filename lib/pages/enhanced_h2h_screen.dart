// lib/pages/enhanced_h2h_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/soccer_match.dart';
import '../models/team_standing.dart';
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/stats_chart_widget.dart';
import '../generated/l10n.dart';

class EnhancedH2HScreen extends StatefulWidget {
  final TeamStanding? team1;
  final TeamStanding? team2;

  const EnhancedH2HScreen({
    Key? key,
    this.team1,
    this.team2,
  }) : super(key: key);

  @override
  State<EnhancedH2HScreen> createState() => _EnhancedH2HScreenState();
}

class _EnhancedH2HScreenState extends State<EnhancedH2HScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();

  late AnimationController _animationController;

  TeamStanding? _team1;
  TeamStanding? _team2;

  List<SoccerMatch> _h2hMatches = [];
  bool _isLoading = false;

  // Statistiche confronto
  Map<String, int> _h2hStats = {
    'team1Wins': 0,
    'draws': 0,
    'team2Wins': 0,
    'team1Goals': 0,
    'team2Goals': 0,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _team1 = widget.team1;
    _team2 = widget.team2;

    if (_team1 != null && _team2 != null) {
      _loadH2HData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadH2HData() async {
    if (_team1 == null || _team2 == null) return;

    setState(() => _isLoading = true);

    try {
      final matches = await _apiService.fetchHeadToHead(
        _team1!.teamId,
        _team2!.teamId,
      );

      // Calcola statistiche
      for (var match in matches) {
        if (match.homeTeamId == _team1!.teamId) {
          if (match.homeScore > match.awayScore) {
            _h2hStats['team1Wins'] = _h2hStats['team1Wins']! + 1;
          } else if (match.homeScore < match.awayScore) {
            _h2hStats['team2Wins'] = _h2hStats['team2Wins']! + 1;
          } else {
            _h2hStats['draws'] = _h2hStats['draws']! + 1;
          }
          _h2hStats['team1Goals'] = _h2hStats['team1Goals']! + match.homeScore;
          _h2hStats['team2Goals'] = _h2hStats['team2Goals']! + match.awayScore;
        } else {
          if (match.awayScore > match.homeScore) {
            _h2hStats['team1Wins'] = _h2hStats['team1Wins']! + 1;
          } else if (match.awayScore < match.homeScore) {
            _h2hStats['team2Wins'] = _h2hStats['team2Wins']! + 1;
          } else {
            _h2hStats['draws'] = _h2hStats['draws']! + 1;
          }
          _h2hStats['team1Goals'] = _h2hStats['team1Goals']! + match.awayScore;
          _h2hStats['team2Goals'] = _h2hStats['team2Goals']! + match.homeScore;
        }
      }

      setState(() {
        _h2hMatches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Confronto Testa a Testa'),
        backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
        elevation: 0,
      ),
      body: _team1 == null || _team2 == null
          ? _buildTeamSelector(theme, isDark, s)
          : _buildComparison(theme, isDark, s),
    );
  }

  Widget _buildTeamSelector(ThemeData theme, bool isDark, S s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 80,
              color: theme.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'Seleziona due squadre per il confronto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child:
                      _buildTeamCard(_team1, 'Squadra 1', theme, isDark, true),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child:
                      _buildTeamCard(_team2, 'Squadra 2', theme, isDark, false),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_team1 != null && _team2 != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.compare),
                label: const Text('Confronta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: _loadH2HData,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(TeamStanding? team, String label, ThemeData theme,
      bool isDark, bool isTeam1) {
    return GlassmorphicCard(
      borderRadius: 16,
      child: InkWell(
        onTap: () {
          _haptic.lightImpact();
          // Apri selezione squadra
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          child: team == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: theme.primaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (team.teamLogo != null)
                      CachedNetworkImage(
                        imageUrl: team.teamLogo!,
                        width: 50,
                        height: 50,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.sports_soccer, size: 50),
                      )
                    else
                      const Icon(Icons.sports_soccer, size: 50),
                    const SizedBox(height: 12),
                    Text(
                      team.teamName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${team.position}° • ${team.points} pts',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildComparison(ThemeData theme, bool isDark, S s) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con loghi squadre
          _buildComparisonHeader(theme, isDark),

          // Statistiche generali H2H
          _buildH2HStats(theme, isDark),

          // Grafico radar confronto
          if (!_isLoading && _team1 != null && _team2 != null)
            _buildRadarComparison(theme, isDark),

          // Confronto dettagliato statistiche
          if (_team1 != null && _team2 != null)
            _buildDetailedComparison(theme, isDark),

          // Ultime partite H2H
          if (_h2hMatches.isNotEmpty) _buildRecentMatches(theme, isDark, s),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildComparisonHeader(ThemeData theme, bool isDark) {
    if (_team1 == null || _team2 == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.8),
            theme.primaryColor.withOpacity(0.4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Team 1
          Column(
            children: [
              Hero(
                tag: 'team1_logo',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: _team1!.teamLogo != null
                      ? CachedNetworkImage(
                          imageUrl: _team1!.teamLogo!,
                          width: 60,
                          height: 60,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.sports_soccer, size: 60),
                        )
                      : const Icon(Icons.sports_soccer, size: 60),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _team1!.teamName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          )
              .animate()
              .slideX(
                  begin: -0.5,
                  end: 0,
                  duration: const Duration(milliseconds: 500))
              .fadeIn(),

          // VS Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ).animate().scale(delay: const Duration(milliseconds: 300)).fadeIn(),

          // Team 2
          Column(
            children: [
              Hero(
                tag: 'team2_logo',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: _team2!.teamLogo != null
                      ? CachedNetworkImage(
                          imageUrl: _team2!.teamLogo!,
                          width: 60,
                          height: 60,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.sports_soccer, size: 60),
                        )
                      : const Icon(Icons.sports_soccer, size: 60),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _team2!.teamName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          )
              .animate()
              .slideX(
                  begin: 0.5,
                  end: 0,
                  duration: const Duration(milliseconds: 500))
              .fadeIn(),
        ],
      ),
    );
  }

  Widget _buildH2HStats(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_team1 == null || _team2 == null) return const SizedBox.shrink();

    final totalMatches =
        _h2hStats['team1Wins']! + _h2hStats['draws']! + _h2hStats['team2Wins']!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Storico Scontri Diretti',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Barra vittorie/pareggi/sconfitte - CORRETTA
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey[200],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                if (_h2hStats['team1Wins']! > 0)
                  Expanded(
                    flex: _h2hStats['team1Wins']!,
                    child: Container(
                      color: Colors.blue,
                      child: Center(
                        child: Text(
                          '${_h2hStats['team1Wins']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_h2hStats['draws']! > 0)
                  Expanded(
                    flex: _h2hStats['draws']!,
                    child: Container(
                      color: Colors.grey,
                      child: Center(
                        child: Text(
                          '${_h2hStats['draws']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_h2hStats['team2Wins']! > 0)
                  Expanded(
                    flex: _h2hStats['team2Wins']!,
                    child: Container(
                      color: Colors.red,
                      child: Center(
                        child: Text(
                          '${_h2hStats['team2Wins']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Statistiche dettagliate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'Vittorie\n${_team1!.teamName}',
                '${_h2hStats['team1Wins']}',
                Colors.blue,
              ),
              _buildStatColumn(
                'Pareggi',
                '${_h2hStats['draws']}',
                Colors.grey,
              ),
              _buildStatColumn(
                'Vittorie\n${_team2!.teamName}',
                '${_h2hStats['team2Wins']}',
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goal fatti/subiti
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Goal Totali',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${_h2hStats['team1Goals']}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text(' - ', style: TextStyle(fontSize: 18)),
                      Text(
                        '${_h2hStats['team2Goals']}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0).fadeIn();
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRadarComparison(ThemeData theme, bool isDark) {
    if (_team1 == null || _team2 == null) return const SizedBox.shrink();

    // Prepara dati per il grafico radar
    final team1Stats = {
      'Punti': _team1!.points.toDouble(),
      'Vittorie': _team1!.wins.toDouble(),
      'Goal Fatti': _team1!.goalsFor.toDouble(),
      'Goal Subiti': _team1!.goalsAgainst.toDouble(),
      'Partite': _team1!.played.toDouble(),
    };

    final team2Stats = {
      'Punti': _team2!.points.toDouble(),
      'Vittorie': _team2!.wins.toDouble(),
      'Goal Fatti': _team2!.goalsFor.toDouble(),
      'Goal Subiti': _team2!.goalsAgainst.toDouble(),
      'Partite': _team2!.played.toDouble(),
    };

    return Container(
      margin: const EdgeInsets.all(16),
      child: StatsChartWidget(
        homeStats: team1Stats,
        awayStats: team2Stats,
        homeTeamName: _team1!.teamName,
        awayTeamName: _team2!.teamName,
        homeColor: Colors.blue,
        awayColor: Colors.red,
      ),
    );
  }

  Widget _buildDetailedComparison(ThemeData theme, bool isDark) {
    if (_team1 == null || _team2 == null) return const SizedBox.shrink();

    final comparisons = [
      {
        'label': 'Posizione',
        'team1': '${_team1!.position}°',
        'team2': '${_team2!.position}°'
      },
      {
        'label': 'Punti',
        'team1': '${_team1!.points}',
        'team2': '${_team2!.points}'
      },
      {
        'label': 'Partite Giocate',
        'team1': '${_team1!.played}',
        'team2': '${_team2!.played}'
      },
      {
        'label': 'Vittorie',
        'team1': '${_team1!.wins}',
        'team2': '${_team2!.wins}'
      },
      {
        'label': 'Pareggi',
        'team1': '${_team1!.draws}',
        'team2': '${_team2!.draws}'
      },
      {
        'label': 'Sconfitte',
        'team1': '${_team1!.losses}',
        'team2': '${_team2!.losses}'
      },
      {
        'label': 'Goal Fatti',
        'team1': '${_team1!.goalsFor}',
        'team2': '${_team2!.goalsFor}'
      },
      {
        'label': 'Goal Subiti',
        'team1': '${_team1!.goalsAgainst}',
        'team2': '${_team2!.goalsAgainst}'
      },
      {
        'label': 'Differenza Reti',
        'team1': '${_team1!.goalsDiff}',
        'team2': '${_team2!.goalsDiff}'
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confronto Stagionale',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...comparisons.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final team1Value =
                double.tryParse(item['team1']!.replaceAll('°', '')) ?? 0;
            final team2Value =
                double.tryParse(item['team2']!.replaceAll('°', '')) ?? 0;
            final isBetterTeam1 = team1Value > team2Value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['team1']!,
                      style: TextStyle(
                        fontWeight:
                            isBetterTeam1 ? FontWeight.bold : FontWeight.normal,
                        color: isBetterTeam1 ? Colors.blue : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Text(
                          item['label']!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: team1Value + team2Value > 0
                              ? team1Value / (team1Value + team2Value)
                              : 0.5,
                          backgroundColor: Colors.red.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['team2']!,
                      style: TextStyle(
                        fontWeight: !isBetterTeam1
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: !isBetterTeam1 ? Colors.red : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .slideX(
                  begin: index.isEven ? -0.1 : 0.1,
                  end: 0,
                  delay: Duration(milliseconds: index * 50),
                )
                .fadeIn();
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentMatches(ThemeData theme, bool isDark, S s) {
    if (_team1 == null || _team2 == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ultimi Scontri Diretti',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._h2hMatches.take(5).map((match) {
            final isTeam1Home = match.homeTeamId == _team1!.teamId;
            final team1Score = isTeam1Home ? match.homeScore : match.awayScore;
            final team2Score = isTeam1Home ? match.awayScore : match.homeScore;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GlassmorphicCard(
                borderRadius: 12,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _team1!.teamName,
                          style: TextStyle(
                            fontWeight: team1Score > team2Score
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$team1Score - $team2Score',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _team2!.teamName,
                          style: TextStyle(
                            fontWeight: team2Score > team1Score
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
