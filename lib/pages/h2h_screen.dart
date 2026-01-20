// lib/pages/h2h_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../generated/l10n.dart';
import '../models/soccer_match.dart';
import '../models/team_standing.dart';
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/loading_state_widget.dart';
import 'match_detail_screen.dart';
import 'h2h_team_selector_screen.dart';

class H2HScreen extends StatefulWidget {
  final TeamStanding? team1;
  final TeamStanding? team2;

  const H2HScreen({
    Key? key,
    this.team1,
    this.team2,
  }) : super(key: key);

  @override
  State<H2HScreen> createState() => _H2HScreenState();
}

class _H2HScreenState extends State<H2HScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();

  // Selected teams
  TeamStanding? _team1;
  TeamStanding? _team2;

  // Data
  List<SoccerMatch> _h2hMatches = [];
  Map<String, dynamic> _h2hStats = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _team1 = widget.team1;
    _team2 = widget.team2;
    _initAnimations();

    if (_team1 != null && _team2 != null) {
      _loadH2HData();
    }
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _loadH2HData() async {
    if (_team1 == null || _team2 == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.fetchHeadToHead(
        _team1!.teamId,
        _team2!.teamId,
      );

      if (mounted) {
        setState(() {
          _h2hStats = data;
          _h2hMatches = data['matches'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Errore nel caricamento dei dati H2H';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectTeam(bool isTeam1) async {
    final selectedTeam = await Navigator.push<TeamStanding>(
      context,
      MaterialPageRoute(
        builder: (context) => H2HTeamSelectorScreen(
          excludeTeam: isTeam1 ? _team2 : _team1,
        ),
      ),
    );

    if (selectedTeam != null) {
      setState(() {
        if (isTeam1) {
          _team1 = selectedTeam;
        } else {
          _team2 = selectedTeam;
        }
      });

      if (_team1 != null && _team2 != null) {
        _loadH2HData();
      }
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
        title: Text(s.headToHead),
        backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(theme, isDark, s),
            if (_team1 != null && _team2 != null) ...[
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: LoadingStateWidget(
                      message: 'Caricamento confronto...',
                      style: LoadingStyle.pulse,
                    ),
                  ),
                )
              else if (_errorMessage != null)
                _buildErrorState(s)
              else ...[
                _buildStatsSection(theme, isDark, s),
                _buildRecentMatchesSection(theme, isDark, s),
              ],
            ] else
              _buildEmptyState(s, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, S s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [Colors.grey[900]!, Colors.grey[850]!]
              : [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
        ),
      ),
      child: Row(
        children: [
          // Team 1
          Expanded(
            child: _buildTeamSelector(
              team: _team1,
              isTeam1: true,
              isDark: isDark,
            ),
          ),

          // VS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),

          // Team 2
          Expanded(
            child: _buildTeamSelector(
              team: _team2,
              isTeam1: false,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelector({
    TeamStanding? team,
    required bool isTeam1,
    required bool isDark,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: InkWell(
        onTap: () => _selectTeam(isTeam1),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              if (team != null) ...[
                if (team.teamLogo != null)
                  CachedNetworkImage(
                    imageUrl: team.teamLogo!,
                    width: 60,
                    height: 60,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(color: Colors.white),
                    errorWidget: (context, url, error) => const Icon(
                        Icons.sports_soccer,
                        size: 60,
                        color: Colors.white),
                  )
                else
                  const Icon(Icons.sports_soccer,
                      size: 60, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  team.teamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else ...[
                const Icon(
                  Icons.add_circle_outline,
                  size: 60,
                  color: Colors.white70,
                ),
                const SizedBox(height: 8),
                Text(
                  isTeam1 ? 'Seleziona Squadra 1' : 'Seleziona Squadra 2',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildStatsSection(ThemeData theme, bool isDark, S s) {
    if (_h2hStats.isEmpty) return const SizedBox.shrink();

    final team1Wins = _h2hStats['team1Wins'] ?? 0;
    final team2Wins = _h2hStats['team2Wins'] ?? 0;
    final draws = _h2hStats['draws'] ?? 0;
    final totalMeetings = _h2hStats['totalMeetings'] ?? 0;

    if (totalMeetings == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistiche Confronto Diretto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Total meetings
              Center(
                child: Text(
                  '$totalMeetings Incontri Totali',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Wins bar chart
              Row(
                children: [
                  // Team 1 wins
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          team1Wins.toString(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        Text(
                          'Vittorie',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _team1?.teamName ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Draws
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                draws.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const Text(
                                'Pareggi',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Team 2 wins
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          team2Wins.toString(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          'Vittorie',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _team2?.teamName ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Win percentage bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 24,
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      if (team1Wins > 0)
                        Container(
                          width: MediaQuery.of(context).size.width *
                                  (team1Wins / totalMeetings) -
                              32,
                          color: theme.primaryColor,
                        ),
                      if (draws > 0)
                        Container(
                          width: MediaQuery.of(context).size.width *
                                  (draws / totalMeetings) -
                              32,
                          color: Colors.orange,
                        ),
                      if (team2Wins > 0)
                        Container(
                          width: MediaQuery.of(context).size.width *
                                  (team2Wins / totalMeetings) -
                              32,
                          color: Colors.red,
                        ),
                    ],
                  ),
                ),
              ).animate().scaleX(
                    duration: 800.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildRecentMatchesSection(ThemeData theme, bool isDark, S s) {
    if (_h2hMatches.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nessun confronto diretto recente',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ultimi Confronti Diretti',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ..._h2hMatches.take(10).map((match) {
            final index = _h2hMatches.indexOf(match);
            return _buildMatchCard(match, isDark, theme)
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 100))
                .slideX(begin: 0.2, end: 0);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMatchCard(SoccerMatch match, bool isDark, ThemeData theme) {
    // Determina il vincitore
    Color? resultColor;
    String? resultText;

    if (match.isFinished) {
      if (match.homeScore > match.awayScore) {
        if (match.homeTeamId == _team1?.teamId) {
          resultColor = theme.primaryColor;
          resultText = 'V';
        } else {
          resultColor = Colors.red;
          resultText = 'S';
        }
      } else if (match.homeScore < match.awayScore) {
        if (match.awayTeamId == _team1?.teamId) {
          resultColor = theme.primaryColor;
          resultText = 'V';
        } else {
          resultColor = Colors.red;
          resultText = 'S';
        }
      } else {
        resultColor = Colors.orange;
        resultText = 'P';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        child: InkWell(
          onTap: () {
            _haptic.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchDetailScreen(match: match),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date
                Container(
                  width: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd/MM').format(match.date),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy').format(match.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Teams
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (match.homeTeamLogo != null)
                            CachedNetworkImage(
                              imageUrl: match.homeTeamLogo!,
                              width: 20,
                              height: 20,
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              match.homeTeamName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: match.homeTeamId == _team1?.teamId
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (match.isFinished)
                            Text(
                              match.homeScore.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (match.awayTeamLogo != null)
                            CachedNetworkImage(
                              imageUrl: match.awayTeamLogo!,
                              width: 20,
                              height: 20,
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              match.awayTeamName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: match.awayTeamId == _team1?.teamId
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (match.isFinished)
                            Text(
                              match.awayScore.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Result indicator
                if (resultColor != null && resultText != null)
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: resultColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: resultColor.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        resultText,
                        style: TextStyle(
                          color: resultColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(S s, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 100,
            color: Colors.grey[400],
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            'Seleziona due squadre per vedere il confronto diretto',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectTeam(true),
                  icon: const Icon(Icons.add),
                  label: const Text('Squadra 1'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectTeam(false),
                  icon: const Icon(Icons.add),
                  label: const Text('Squadra 2'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(S s) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Errore sconosciuto',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _haptic.lightImpact();
              _loadH2HData();
            },
            icon: const Icon(Icons.refresh),
            label: Text(s.retry),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
