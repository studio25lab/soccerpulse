// lib/widgets/live_match_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/soccer_match.dart';
import '../services/live_match_simulator.dart';
import '../services/haptic_service.dart';

class LiveMatchWidget extends StatefulWidget {
  final SoccerMatch match;
  final VoidCallback? onTap;

  const LiveMatchWidget({
    Key? key,
    required this.match,
    this.onTap,
  }) : super(key: key);

  @override
  State<LiveMatchWidget> createState() => _LiveMatchWidgetState();
}

class _LiveMatchWidgetState extends State<LiveMatchWidget>
    with SingleTickerProviderStateMixin {
  final LiveMatchSimulator _simulator = LiveMatchSimulator();
  final HapticService _haptic = HapticService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Stream<SoccerMatch>? _matchStream;
  SoccerMatch? _currentMatch;
  int _lastHomeGoals = 0;
  int _lastAwayGoals = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _currentMatch = widget.match;
    _lastHomeGoals = widget.match.homeScore; // ✅ CORRETTO: homeScore
    _lastAwayGoals = widget.match.awayScore; // ✅ CORRETTO: awayScore

    if (widget.match.status == 'NS') {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _simulator.startLiveSimulation(widget.match);
        }
      });
    }

    _matchStream = _simulator.getLiveMatchStream(widget.match.id);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleGoalScored(bool isHome) {
    _haptic.heavyImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sports_soccer, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                  'GOAL! ${isHome ? _currentMatch!.homeTeamName : _currentMatch!.awayTeamName}'), // ✅ CORRETTO
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<SoccerMatch>(
      stream: _matchStream,
      initialData: widget.match,
      builder: (context, snapshot) {
        final match = snapshot.data ?? widget.match;
        _currentMatch = match;

        if (match.homeScore > _lastHomeGoals) {
          // ✅ CORRETTO: homeScore
          _lastHomeGoals = match.homeScore;
          Future.microtask(() => _handleGoalScored(true));
        }
        if (match.awayScore > _lastAwayGoals) {
          // ✅ CORRETTO: awayScore
          _lastAwayGoals = match.awayScore;
          Future.microtask(() => _handleGoalScored(false));
        }

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: match.status == 'LIVE'
                    ? [
                        Colors.green.withOpacity(0.2),
                        Colors.green.withOpacity(0.05),
                      ]
                    : [
                        isDark ? Colors.grey[850]! : Colors.white,
                        isDark ? Colors.grey[850]! : Colors.white,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: match.status == 'LIVE'
                      ? Colors.green.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: match.status == 'LIVE' ? 20 : 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: match.status == 'LIVE'
                    ? Colors.green.withOpacity(0.5)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header con stato partita
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLeagueInfo(match),
                      _buildMatchStatus(match),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Teams and Score
                  Row(
                    children: [
                      // Home Team
                      Expanded(
                        child: Column(
                          children: [
                            _buildTeamLogo(match.homeTeamName,
                                match.homeTeamLogo, true), // ✅ CORRETTO
                            const SizedBox(height: 8),
                            Text(
                              match.homeTeamName, // ✅ CORRETTO: homeTeamName
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Score
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              match.homeScore
                                  .toString(), // ✅ CORRETTO: homeScore
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: match.status == 'LIVE' &&
                                        match.homeScore > _lastHomeGoals
                                    ? Colors.green
                                    : null,
                              ),
                            ).animate(
                              onPlay: (controller) {
                                if (match.homeScore > _lastHomeGoals) {
                                  controller.forward();
                                }
                              },
                            ).scale(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                            ),
                            const Text(
                              ' - ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              match.awayScore
                                  .toString(), // ✅ CORRETTO: awayScore
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: match.status == 'LIVE' &&
                                        match.awayScore > _lastAwayGoals
                                    ? Colors.green
                                    : null,
                              ),
                            ).animate(
                              onPlay: (controller) {
                                if (match.awayScore > _lastAwayGoals) {
                                  controller.forward();
                                }
                              },
                            ).scale(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                            ),
                          ],
                        ),
                      ),

                      // Away Team
                      Expanded(
                        child: Column(
                          children: [
                            _buildTeamLogo(match.awayTeamName,
                                match.awayTeamLogo, false), // ✅ CORRETTO
                            const SizedBox(height: 8),
                            Text(
                              match.awayTeamName, // ✅ CORRETTO: awayTeamName
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (match.status == 'LIVE') ...[
                    const SizedBox(height: 16),
                    _buildRecentEvents(match),
                  ],

                  if (match.venue.isNotEmpty) ...[
                    // ✅ CORRETTO: venue non è nullable
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.stadium,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          match.venue,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        );
      },
    );
  }

  Widget _buildTeamLogo(String teamName, String? logoUrl, bool isHome) {
    // Mappa team names ai loro loghi (fallback se logoUrl è null)
    final teamLogos = {
      'Inter': 'https://media.api-sports.io/football/teams/505.png',
      'Milan': 'https://media.api-sports.io/football/teams/489.png',
      'Napoli': 'https://media.api-sports.io/football/teams/492.png',
      'Juventus': 'https://media.api-sports.io/football/teams/496.png',
      'Roma': 'https://media.api-sports.io/football/teams/497.png',
      'Lazio': 'https://media.api-sports.io/football/teams/487.png',
    };

    final effectiveLogoUrl = logoUrl ?? teamLogos[teamName];

    if (effectiveLogoUrl != null) {
      return CachedNetworkImage(
        imageUrl: effectiveLogoUrl,
        width: 60,
        height: 60,
        errorWidget: (context, url, error) =>
            const Icon(Icons.shield, size: 60),
      );
    }

    return const Icon(Icons.shield, size: 60);
  }

  Widget _buildLeagueInfo(SoccerMatch match) {
    return Row(
      children: [
        if (match.leagueLogo != null)
          CachedNetworkImage(
            imageUrl: match.leagueLogo!,
            width: 20,
            height: 20,
            errorWidget: (context, url, error) =>
                const Icon(Icons.sports_soccer, size: 20),
          ),
        const SizedBox(width: 8),
        Text(
          match.leagueName ?? 'Serie A',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchStatus(SoccerMatch match) {
    if (match.status == 'LIVE') {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(
                        onPlay: (controller) => controller.repeat(),
                      )
                      .fadeIn(duration: const Duration(milliseconds: 500))
                      .then()
                      .fadeOut(duration: const Duration(milliseconds: 500)),
                  const SizedBox(width: 6),
                  Text(
                    '${match.elapsed ?? 0}\'', // ✅ CORRETTO: elapsed può essere null
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (match.status == 'FT') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'FINALE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          match.time, // ✅ CORRETTO: time non è nullable
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
  }

  Widget _buildRecentEvents(SoccerMatch match) {
    final events = _simulator.getMatchEvents(match.id);
    if (events.isEmpty) return const SizedBox.shrink();

    final recentEvents = events.reversed.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: recentEvents.map((event) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  _getEventIcon(event.type),
                  size: 16,
                  color: _getEventColor(event.type),
                ),
                const SizedBox(width: 8),
                Text(
                  '${event.minute}\' ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${event.playerName}${event.assistBy != null ? ' (${event.assistBy})' : ''}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'goal':
      case 'penalty':
        return Icons.sports_soccer;
      case 'yellowCard':
        return Icons.square;
      case 'redCard':
        return Icons.square;
      case 'var':
        return Icons.tv;
      default:
        return Icons.info;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'goal':
      case 'penalty':
        return Colors.green;
      case 'yellowCard':
        return Colors.yellow[700]!;
      case 'redCard':
        return Colors.red;
      case 'var':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
