import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/player_detail.dart';
import '../models/soccer_match.dart';
import '../services/haptic_service.dart';
import 'player_match_comparison_screen.dart';
import '../widgets/player_performance_widgets.dart';

class PlayerFinishedMatchScreen extends StatefulWidget {
  final String playerName;
  final int playerNumber;
  final String teamName;
  final Color teamColor;
  final SoccerMatch match;

  const PlayerFinishedMatchScreen({
    Key? key,
    required this.playerName,
    required this.playerNumber,
    required this.teamName,
    required this.teamColor,
    required this.match,
  }) : super(key: key);

  @override
  State<PlayerFinishedMatchScreen> createState() =>
      _PlayerFinishedMatchScreenState();
}

class _PlayerFinishedMatchScreenState extends State<PlayerFinishedMatchScreen>
    with SingleTickerProviderStateMixin {
  final HapticService _haptic = HapticService();
  late TabController _tabController;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(isDark),
          _buildTabBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMatchStatsTab(isDark),
                _buildSeasonStatsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.teamColor, widget.teamColor.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              // CAMPANELLA NOTIFICHE
              IconButton(
                icon: Icon(
                  _notificationsEnabled
                      ? Icons.notifications
                      : Icons.notifications_none,
                  color: Colors.white,
                ),
                onPressed: () {
                  _haptic.lightImpact();
                  _showNotificationDialog();
                },
              ),
              IconButton(
                icon: const Icon(Icons.star_border, color: Colors.white),
                onPressed: () {
                  _haptic.lightImpact();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.playerName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${widget.playerNumber} • ${widget.teamName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // PULSANTE CONFRONTA - GRANDE E VISIBILE
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _haptic.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerMatchComparisonScreen(
                            match: widget.match,
                            player1Name: widget.playerName,
                            player1Number: widget.playerNumber,
                            player1Team: widget.teamName,
                            player1Color: widget.teamColor,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.compare_arrows,
                            color: widget.teamColor,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Confronta',
                            style: TextStyle(
                              color: widget.teamColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.match.homeTeamName} ${widget.match.homeScore} - ${widget.match.awayScore} ${widget.match.awayTeamName}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      color: isDark ? Colors.grey[850] : Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: widget.teamColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: widget.teamColor,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 18),
                SizedBox(width: 8),
                Text('Questa Partita', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 18),
                SizedBox(width: 8),
                Text('Stagione', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchStatsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRatingCard(isDark),
          const SizedBox(height: 16),
          _buildMatchInfoCard(isDark),
          const SizedBox(height: 16),
          _buildStatsCard('Statistiche Partita', isDark, [
            _buildStatRow('Minuti giocati', '90\'', isDark),
            _buildStatRow('Goal', '1', isDark),
            _buildStatRow('Assist', '0', isDark),
            _buildStatRow('xG (Expected Goals)', '0.82', isDark,
                isHighlight: true),
            _buildStatRow('xA (Expected Assists)', '0.14', isDark,
                isHighlight: true),
            _buildStatRow('Tiri', '4', isDark),
            _buildStatRow('Tiri in porta', '2', isDark),
            _buildStatRow('Passaggi', '45/52', isDark),
            _buildStatRow('Precisione passaggi', '87%', isDark),
            _buildStatRow('Dribbling', '3/5', isDark),
            _buildStatRow('Duelli vinti', '7/12', isDark),
            _buildStatRow('Contrasti', '2', isDark),
            _buildStatRow('Intercetti', '1', isDark),
            _buildStatRow('Fuorigioco', '1', isDark),
            _buildStatRow('Falli fatti', '2', isDark),
            _buildStatRow('Falli subiti', '3', isDark),
          ]),
          const SizedBox(height: 16),
          // FASE 1 - NUOVI WIDGET STILE SOFASCORE
          RadarPerformanceWidget(
            teamColor: widget.teamColor,
            isDark: isDark,
            playerName: widget.playerName,
          ),
          MatchTimelineWidget(
            teamColor: widget.teamColor,
            isDark: isDark,
            playerName: widget.playerName,
          ),
          ColoredStatsBarWidget(
            teamColor: widget.teamColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonStatsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCard('Statistiche Stagionali', isDark, [
            _buildStatRow('Presenze', '25', isDark),
            _buildStatRow('Goal', '8', isDark),
            _buildStatRow('Assist', '5', isDark),
            _buildStatRow('Minuti giocati', '2.100', isDark),
            _buildStatRow('Media voto', '7.5', isDark),
            _buildStatRow('Cartellini gialli', '2', isDark),
            _buildStatRow('Cartellini rossi', '0', isDark),
          ]),
          const SizedBox(height: 16),
          _buildStatsCard('Ultimi 5 Match', isDark, [
            _buildFormRow(['7.5', '8.0', '6.8', '7.9', '7.2'], isDark),
          ]),
        ],
      ),
    );
  }

  Widget _buildRatingCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.teamColor, widget.teamColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.teamColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text(
                'Valutazione',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '7.8',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: widget.teamColor,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 2,
            height: 60,
            color: Colors.white.withOpacity(0.3),
          ),
          Column(
            children: [
              const Text(
                'Minuti',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '90\'',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchInfoCard(bool isDark) {
    return Container(
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
          Row(
            children: [
              Icon(Icons.calendar_today, color: widget.teamColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Informazioni Partita',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Competizione', 'Serie A', isDark),
          const SizedBox(height: 8),
          _buildInfoRow('Data', '21 Gennaio 2026', isDark),
          const SizedBox(height: 8),
          _buildInfoRow('Stadio', 'Stadio Olimpico', isDark),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, bool isDark, List<Widget> stats) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...stats,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isHighlight
                      ? (isDark ? Colors.purple[300] : Colors.purple[700])
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isHighlight) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Container(
            padding: isHighlight
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                : EdgeInsets.zero,
            decoration: isHighlight
                ? BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.3),
                      width: 1,
                    ),
                  )
                : null,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isHighlight ? Colors.purple : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFormRow(List<String> ratings, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ratings.map((rating) {
        final ratingValue = double.parse(rating);
        Color color;
        if (ratingValue >= 7.5) {
          color = Colors.green;
        } else if (ratingValue >= 6.5) {
          color = Colors.orange;
        } else {
          color = Colors.red;
        }

        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              rating,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showNotificationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications, color: widget.teamColor),
            const SizedBox(width: 12),
            const Text('Notifiche Giocatore'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationOption('Goal segnati', true, isDark),
              _buildNotificationOption('Assist forniti', true, isDark),
              _buildNotificationOption('Cartellino giallo', false, isDark),
              _buildNotificationOption('Cartellino rosso', false, isDark),
              _buildNotificationOption('Tiri totali', true, isDark),
              _buildNotificationOption('Tiri in porta', true, isDark),
              _buildNotificationOption('Falli fatti', false, isDark),
              _buildNotificationOption('Falli subiti', false, isDark),
              _buildNotificationOption('Fuorigioco', false, isDark),
              _buildNotificationOption(
                  'Voto fine primo tempo (Fantacalcio)', true, isDark),
              _buildNotificationOption(
                  'Voto finale partita (Fantacalcio)', true, isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _notificationsEnabled = true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notifiche attivate per ${widget.playerName}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.teamColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationOption(String label, bool enabled, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) {},
            activeColor: widget.teamColor,
          ),
        ],
      ),
    );
  }
}
