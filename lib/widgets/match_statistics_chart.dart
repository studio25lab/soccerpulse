import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../generated/l10n.dart';

class MatchStatisticsChart extends StatelessWidget {
  final Map<String, dynamic> homeStats;
  final Map<String, dynamic> awayStats;
  final String homeTeamName;
  final String awayTeamName;

  const MatchStatisticsChart({
    super.key,
    required this.homeStats,
    required this.awayStats,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Column(
      children: [
        _buildStatChart(
          s.possession,
          _getStatValue(homeStats, 'Ball Possession'),
          _getStatValue(awayStats, 'Ball Possession'),
          Colors.blue,
          context,
        ),
        const SizedBox(height: 24),
        _buildStatChart(
          s.shots,
          _getStatValue(homeStats, 'Total Shots'),
          _getStatValue(awayStats, 'Total Shots'),
          Colors.orange,
          context,
        ),
        const SizedBox(height: 24),
        _buildStatChart(
          s.shotsOnTarget,
          _getStatValue(homeStats, 'Shots on Goal'),
          _getStatValue(awayStats, 'Shots on Goal'),
          Colors.green,
          context,
        ),
        const SizedBox(height: 24),
        _buildStatChart(
          s.corners,
          _getStatValue(homeStats, 'Corner Kicks'),
          _getStatValue(awayStats, 'Corner Kicks'),
          Colors.purple,
          context,
        ),
        const SizedBox(height: 24),
        _buildCardsChart(context),
      ],
    );
  }

  double _getStatValue(Map<String, dynamic> stats, String statType) {
    final statList = stats['statistics'] as List?;
    if (statList == null) return 0;

    for (var stat in statList) {
      if (stat['type'] == statType) {
        final value = stat['value'];
        if (value == null) return 0;
        if (value is int) return value.toDouble();
        if (value is double) return value;
        if (value is String) {
          final cleaned = value.replaceAll('%', '').trim();
          return double.tryParse(cleaned) ?? 0;
        }
      }
    }
    return 0;
  }

  Widget _buildStatChart(
    String label,
    double homeValue,
    double awayValue,
    Color color,
    BuildContext context,
  ) {
    final total = homeValue + awayValue;
    final homePercent =
        total > 0 ? ((homeValue / total * 100).toDouble()) : 50.0;
    final awayPercent = (100.0 - homePercent).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${homeValue.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${awayValue.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 40,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: homePercent,
                        color: color.withOpacity(0.8),
                        width: 60,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: awayPercent,
                        color: color.withOpacity(0.4),
                        width: 60,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsChart(BuildContext context) {
    final s = S.of(context)!;

    final homeYellow = _getStatValue(homeStats, 'Yellow Cards');
    final awayYellow = _getStatValue(awayStats, 'Yellow Cards');
    final homeRed = _getStatValue(homeStats, 'Red Cards');
    final awayRed = _getStatValue(awayStats, 'Red Cards');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildCardStat(
              s.yellowCards,
              homeYellow,
              awayYellow,
              Colors.yellow[700]!,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCardStat(
              s.redCards,
              homeRed,
              awayRed,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStat(String label, double home, double away, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.card_membership, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                '${home.toInt()}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '-',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                '${away.toInt()}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
