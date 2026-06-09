// lib/pages/head_to_head_screen.dart

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../generated/l10n.dart';
import '../models/soccer_match.dart';
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/loading_state_widget.dart';
import 'match_detail_screen.dart';

class HeadToHeadScreen extends StatefulWidget {
  final int team1Id;
  final int team2Id;
  final String? team1Name;
  final String? team2Name;
  final String? team1Logo;
  final String? team2Logo;

  const HeadToHeadScreen({
    Key? key,
    required this.team1Id,
    required this.team2Id,
    this.team1Name,
    this.team2Name,
    this.team1Logo,
    this.team2Logo,
  }) : super(key: key);

  @override
  State<HeadToHeadScreen> createState() => _HeadToHeadScreenState();
}

class _HeadToHeadScreenState extends State<HeadToHeadScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();

  // Data
  List<SoccerMatch> _h2hMatches = [];
  Map<String, dynamic> _h2hStats = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadHeadToHeadData();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadHeadToHeadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.fetchHeadToHead(
        widget.team1Id,
        widget.team2Id,
      );

      if (mounted) {
        setState(() {
          // TODO: fetchHeadToHead ritorna solo la lista. Quando
          // l-API esponera anche statistiche aggregate, popolare
          // _h2hStats con team1Wins/team2Wins/draws/totalMeetings.
          _h2hStats = {};
          _h2hMatches = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = tr(context, 'Errore nel caricamento dei dati');
          _isLoading = false;
        });
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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme, isDark, s),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: LoadingStateWidget(
                  message: tr(context, 'Caricamento confronto diretto...'),
                  style: LoadingStyle.pulse,
                ),
              ),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: _buildErrorState(s),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                _buildStatsOverview(theme, isDark, s),
                _buildFormComparison(theme, isDark, s),
                _buildRecentMatchesList(theme, isDark, s),
                const SizedBox(height: 32),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, bool isDark, S s) {
    return SliverAppBar(
      expandedHeight: 250,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          s.headToHead,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [Colors.grey[900]!, Colors.grey[850]!]
                  : [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Team 1
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.team1Logo != null)
                          CachedNetworkImage(
                            imageUrl: widget.team1Logo!,
                            width: 80,
                            height: 80,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(
                                    color: Colors.white),
                            errorWidget: (context, url, error) => const Icon(
                                Icons.sports_soccer,
                                size: 80,
                                color: Colors.white),
                          )
                        else
                          const Icon(Icons.sports_soccer,
                              size: 80, color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          widget.team1Name ?? tr(context, 'Squadra 1'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: -0.2, end: 0),
                  ),

                  // VS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                  // Team 2
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.team2Logo != null)
                          CachedNetworkImage(
                            imageUrl: widget.team2Logo!,
                            width: 80,
                            height: 80,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(
                                    color: Colors.white),
                            errorWidget: (context, url, error) => const Icon(
                                Icons.sports_soccer,
                                size: 80,
                                color: Colors.white),
                          )
                        else
                          const Icon(Icons.sports_soccer,
                              size: 80, color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          widget.team2Name ?? 'Squadra 2',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: 0.2, end: 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview(ThemeData theme, bool isDark, S s) {
    final team1Wins = _h2hStats['team1Wins'] ?? 0;
    final team2Wins = _h2hStats['team2Wins'] ?? 0;
    final draws = _h2hStats['draws'] ?? 0;
    final totalMeetings = _h2hStats['totalMeetings'] ?? 0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr(context, 'Riepilogo Statistiche'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$totalMeetings partite',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Statistiche vittorie
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(
                        value: team1Wins.toString(),
                        label: tr(context, 'Vittorie'),
                        subtitle: widget.team1Name ?? tr(context, 'Squadra 1'),
                        color: theme.primaryColor,
                      ),
                      _buildStatColumn(
                        value: draws.toString(),
                        label: tr(context, 'Pareggi'),
                        subtitle: '',
                        color: Colors.orange,
                      ),
                      _buildStatColumn(
                        value: team2Wins.toString(),
                        label: tr(context, 'Vittorie'),
                        subtitle: widget.team2Name ?? tr(context, 'Squadra 2'),
                        color: Colors.red,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Barra percentuale
                  if (totalMeetings > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 32,
                        color: Colors.grey[200],
                        child: Row(
                          children: [
                            if (team1Wins > 0)
                              Expanded(
                                flex: team1Wins,
                                child: Container(
                                  color: theme.primaryColor,
                                  child: Center(
                                    child: Text(
                                      '${(team1Wins / totalMeetings * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (draws > 0)
                              Expanded(
                                flex: draws,
                                child: Container(
                                  color: Colors.orange,
                                  child: Center(
                                    child: Text(
                                      '${(draws / totalMeetings * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (team2Wins > 0)
                              Expanded(
                                flex: team2Wins,
                                child: Container(
                                  color: Colors.red,
                                  child: Center(
                                    child: Text(
                                      '${(team2Wins / totalMeetings * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ).animate().scaleX(
                          duration: 1.seconds,
                          curve: Curves.easeOutCubic,
                        ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String value,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildFormComparison(ThemeData theme, bool isDark, S s) {
    if (_h2hMatches.isEmpty) return const SizedBox.shrink();

    // Calcola la forma delle ultime 5 partite per ogni squadra
    final team1Form = _calculateTeamForm(widget.team1Id, 5);
    final team2Form = _calculateTeamForm(widget.team2Id, 5);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'Forma Recente (ultime 5)'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Team 1 form
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.team1Name ?? tr(context, 'Squadra 1'),
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...team1Form.map((result) => _buildFormIndicator(result)),
                ],
              ),
              const SizedBox(height: 12),

              // Team 2 form
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.team2Name ?? tr(context, 'Squadra 2'),
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...team2Form.map((result) => _buildFormIndicator(result)),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
    );
  }

  List<String> _calculateTeamForm(int teamId, int count) {
    final teamMatches = _h2hMatches
        .where((match) =>
            match.isFinished &&
            (match.homeTeamId == teamId || match.awayTeamId == teamId))
        .take(count)
        .toList();

    return teamMatches.map((match) {
      if (match.homeTeamId == teamId) {
        if (match.homeScore > match.awayScore) return 'W';
        if (match.homeScore < match.awayScore) return 'L';
        return 'D';
      } else {
        if (match.awayScore > match.homeScore) return 'W';
        if (match.awayScore < match.homeScore) return 'L';
        return 'D';
      }
    }).toList();
  }

  Widget _buildFormIndicator(String result) {
    Color color;
    IconData icon;

    switch (result) {
      case 'W':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'D':
        color = Colors.orange;
        icon = Icons.remove_circle;
        break;
      case 'L':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(left: 4),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }

  Widget _buildRecentMatchesList(ThemeData theme, bool isDark, S s) {
    if (_h2hMatches.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  tr(context, 'Nessun confronto diretto trovato'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Ultimi Confronti Diretti',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._h2hMatches.take(10).map((match) {
            final index = _h2hMatches.indexOf(match);
            return _buildMatchTile(match, theme, isDark)
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 * index))
                .slideX(begin: 0.2, end: 0);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMatchTile(SoccerMatch match, ThemeData theme, bool isDark) {
    // Determina chi ha vinto
    String? winner;
    if (match.isFinished) {
      if (match.homeScore > match.awayScore) {
        winner = match.homeTeamId == widget.team1Id ? 'team1' : 'team2';
      } else if (match.homeScore < match.awayScore) {
        winner = match.awayTeamId == widget.team1Id ? 'team1' : 'team2';
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
            child: Column(
              children: [
                // Date and competition
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(match.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (match.leagueName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          match.leagueName!,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Match info
                Row(
                  children: [
                    // Home team
                    Expanded(
                      child: Row(
                        children: [
                          if (match.homeTeamLogo != null)
                            CachedNetworkImage(
                              imageUrl: match.homeTeamLogo!,
                              width: 24,
                              height: 24,
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              match.homeTeamName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: match.homeTeamId == widget.team1Id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: winner != null
                            ? (winner == 'team1'
                                ? theme.primaryColor.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1))
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        match.isFinished
                            ? '${match.homeScore} - ${match.awayScore}'
                            : match.time,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: winner != null
                              ? (winner == 'team1'
                                  ? theme.primaryColor
                                  : Colors.red)
                              : Colors.orange,
                        ),
                      ),
                    ),

                    // Away team
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              match.awayTeamName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: match.awayTeamId == widget.team1Id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (match.awayTeamLogo != null)
                            CachedNetworkImage(
                              imageUrl: match.awayTeamLogo!,
                              width: 24,
                              height: 24,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Venue
                if (match.venue != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.stadium,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match.venue!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(S s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            _errorMessage ?? tr(context, 'Errore sconosciuto'),
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _haptic.lightImpact();
              _loadHeadToHeadData();
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
    _animationController.dispose();
    super.dispose();
  }
}
