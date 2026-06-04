import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../models/soccer_match.dart';

class TeamComparisonScreen extends StatefulWidget {
  final String homeTeamName;
  final String awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final SoccerMatch match;

  const TeamComparisonScreen({
    Key? key,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
    required this.match,
  }) : super(key: key);

  @override
  State<TeamComparisonScreen> createState() => _TeamComparisonScreenState();
}

class _TeamComparisonScreenState extends State<TeamComparisonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(theme, isDark),
          _buildTabBar(theme, isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatsComparison(isDark),
                _buildFormComparison(isDark),
                _buildH2HComparison(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  tr(context, 'Confronto Squadre'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (widget.homeTeamLogo != null)
                      Image.network(
                        widget.homeTeamLogo!,
                        height: 60,
                        width: 60,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.shield,
                                color: Colors.white, size: 60),
                      )
                    else
                      const Icon(Icons.shield, color: Colors.white, size: 60),
                    const SizedBox(height: 12),
                    Text(
                      widget.homeTeamName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (widget.awayTeamLogo != null)
                      Image.network(
                        widget.awayTeamLogo!,
                        height: 60,
                        width: 60,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.shield,
                                color: Colors.white, size: 60),
                      )
                    else
                      const Icon(Icons.shield, color: Colors.white, size: 60),
                    const SizedBox(height: 12),
                    Text(
                      widget.awayTeamName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, bool isDark) {
    return Container(
      color: isDark ? Colors.grey[850] : Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: theme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: theme.primaryColor,
        indicatorWeight: 3,
        tabs: [
          Tab(text: tr(context, 'Statistiche')),
          Tab(text: 'Forma'),
          Tab(text: 'Testa a Testa'),
        ],
      ),
    );
  }

  Widget _buildStatsComparison(bool isDark) {
    final stats = [
      {'label': 'Possesso Palla', 'home': 58, 'away': 42, 'suffix': '%'},
      {'label': 'Tiri Totali', 'home': 15, 'away': 8, 'suffix': ''},
      {'label': 'Tiri in Porta', 'home': 7, 'away': 3, 'suffix': ''},
      {'label': 'Precisione Passaggi', 'home': 87, 'away': 79, 'suffix': '%'},
      {'label': 'Calci d\'Angolo', 'home': 6, 'away': 4, 'suffix': ''},
      {'label': 'Falli', 'home': 12, 'away': 15, 'suffix': ''},
      {'label': 'Cartellini Gialli', 'home': 2, 'away': 3, 'suffix': ''},
      {'label': 'Fuorigioco', 'home': 3, 'away': 1, 'suffix': ''},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: stats.map((stat) => _buildStatBar(stat, isDark)).toList(),
      ),
    );
  }

  Widget _buildStatBar(Map<String, dynamic> stat, bool isDark) {
    final homeValue = stat['home'] as int;
    final awayValue = stat['away'] as int;
    final total = homeValue + awayValue;
    final homePercent = total > 0 ? homeValue / total : 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            stat['label'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$homeValue${stat['suffix']}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
              Text(
                '$awayValue${stat['suffix']}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  flex: (homePercent * 100).round(),
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - homePercent) * 100).round(),
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFC62828)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormComparison(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFormCard(
            widget.homeTeamName,
            ['V', 'V', 'P', 'V', 'P'],
            const Color(0xFF2196F3),
            isDark,
          ),
          const SizedBox(height: 16),
          _buildFormCard(
            widget.awayTeamName,
            ['P', 'V', 'V', 'P', 'V'],
            const Color(0xFFE53935),
            isDark,
          ),
          const SizedBox(height: 24),
          _buildRadarChart(isDark),
        ],
      ),
    );
  }

  Widget _buildFormCard(
      String teamName, List<String> form, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
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
          Text(
            teamName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Ultimi 5:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              ...form.map((result) {
                Color resultColor;
                if (result == 'V') {
                  resultColor = Colors.green;
                } else if (result == 'P') {
                  resultColor = Colors.red;
                } else {
                  resultColor = Colors.grey;
                }

                return Container(
                  margin: const EdgeInsets.only(left: 6),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: resultColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: resultColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      result,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            tr(context, 'Confronto Statistiche'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 5,
                radarBorderData: const BorderSide(color: Colors.grey, width: 1),
                gridBorderData: const BorderSide(color: Colors.grey, width: 1),
                getTitle: (index, angle) {
                  final titles = [
                    'Attacco',
                    tr(context, 'Difesa'),
                    'Possesso',
                    'Disciplina',
                    tr(context, 'Precisione')
                  ];
                  return RadarChartTitle(text: titles[index]);
                },
                dataSets: [
                  RadarDataSet(
                    fillColor: const Color(0xFF2196F3).withOpacity(0.2),
                    borderColor: const Color(0xFF2196F3),
                    dataEntries: [
                      const RadarEntry(value: 85),
                      const RadarEntry(value: 70),
                      const RadarEntry(value: 90),
                      const RadarEntry(value: 75),
                      const RadarEntry(value: 88),
                    ],
                  ),
                  RadarDataSet(
                    fillColor: const Color(0xFFE53935).withOpacity(0.2),
                    borderColor: const Color(0xFFE53935),
                    dataEntries: [
                      const RadarEntry(value: 70),
                      const RadarEntry(value: 85),
                      const RadarEntry(value: 65),
                      const RadarEntry(value: 80),
                      const RadarEntry(value: 75),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(widget.homeTeamName, const Color(0xFF2196F3)),
              const SizedBox(width: 24),
              _buildLegendItem(widget.awayTeamName, const Color(0xFFE53935)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildH2HComparison(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildH2HSummary(isDark),
          const SizedBox(height: 24),
          _buildRecentMatches(isDark),
        ],
      ),
    );
  }

  Widget _buildH2HSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Ultimi 10 Incontri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildH2HStat('4', 'Vittorie\n${widget.homeTeamName}'),
              _buildH2HStat('2', tr(context, 'Pareggi')),
              _buildH2HStat('4', 'Vittorie\n${widget.awayTeamName}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildH2HStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentMatches(bool isDark) {
    final matches = [
      {'date': '15 Gen 2026', 'home': 2, 'away': 1},
      {'date': '10 Ott 2025', 'home': 1, 'away': 1},
      {'date': '05 Mag 2025', 'home': 0, 'away': 2},
      {'date': '20 Gen 2025', 'home': 3, 'away': 1},
      {'date': '15 Set 2024', 'home': 1, 'away': 2},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'Ultimi Risultati'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...matches.map((match) => _buildMatchCard(match, isDark)).toList(),
      ],
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, bool isDark) {
    final homeScore = match['home'] as int;
    final awayScore = match['away'] as int;
    final isHomeWin = homeScore > awayScore;
    final isAwayWin = awayScore > homeScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              match['date'],
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isHomeWin
                        ? Colors.green.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    homeScore.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isHomeWin ? Colors.green : null,
                    ),
                  ),
                ),
                const Text(
                  '-',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAwayWin
                        ? Colors.green.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    awayScore.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isAwayWin ? Colors.green : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
