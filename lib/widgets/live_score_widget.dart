// lib/widgets/live_score_widget.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/soccer_match.dart';
import '../widgets/glassmorphic_card.dart';

class LiveScoreWidget extends StatelessWidget {
  final SoccerMatch match;
  final VoidCallback? onTap;
  final bool showLeague;
  final bool compact;

  const LiveScoreWidget({
    Key? key,
    required this.match,
    this.onTap,
    this.showLeague = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassmorphicCard(
      borderRadius: 16.0,
      borderWidth: 2,
      borderColor: Colors.red,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.withOpacity(0.05),
                Colors.red.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // League name (se richiesto)
                if (showLeague && match.leagueName != null) ...[
                  Text(
                    match.leagueName!,
                    style: TextStyle(
                      fontSize: compact ? 10 : 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Teams and score
                Row(
                  children: [
                    // Home team
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (match.homeTeamLogo != null)
                            CachedNetworkImage(
                              imageUrl: match.homeTeamLogo!,
                              width: compact ? 40 : 50,
                              height: compact ? 40 : 50,
                            )
                          else
                            Icon(
                              Icons.sports_soccer,
                              size: compact ? 40 : 50,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            match.homeTeamName,
                            style: TextStyle(
                              fontSize: compact ? 12 : 13,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Live indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: Colors.white,
                                )
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(),
                                    )
                                    .fadeIn(duration: 600.ms)
                                    .then()
                                    .fadeOut(duration: 600.ms),
                                const SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 10 : 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Score display
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Home score
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  '${match.homeScore}',
                                  style: TextStyle(
                                    fontSize: compact ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: compact ? 32 : 36,
                                color: Colors.grey[400],
                              ),
                              // Away score
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  '${match.awayScore}',
                                  style: TextStyle(
                                    fontSize: compact ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Elapsed time
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              match.elapsed != null
                                  ? "${match.elapsed}'"
                                  : match.status,
                              style: TextStyle(
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Away team
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (match.awayTeamLogo != null)
                            CachedNetworkImage(
                              imageUrl: match.awayTeamLogo!,
                              width: compact ? 40 : 50,
                              height: compact ? 40 : 50,
                            )
                          else
                            Icon(
                              Icons.sports_soccer,
                              size: compact ? 40 : 50,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            match.awayTeamName,
                            style: TextStyle(
                              fontSize: compact ? 12 : 13,
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

                // Venue (se non compact)
                if (!compact) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
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
                      Flexible(
                        child: Text(
                          match.venue,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Match events indicator (goal, cards)
                if (!compact && _hasEvents()) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_hasGoals())
                        _buildEventIndicator(
                          Icons.sports_soccer,
                          Colors.green,
                          '⚽',
                        ),
                      if (_hasYellowCards())
                        _buildEventIndicator(
                          Icons.rectangle,
                          Colors.yellow[700]!,
                          '🟨',
                        ),
                      if (_hasRedCards())
                        _buildEventIndicator(
                          Icons.rectangle,
                          Colors.red,
                          '🟥',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildEventIndicator(IconData icon, Color color, String emoji) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  bool _hasEvents() {
    return _hasGoals() || _hasYellowCards() || _hasRedCards();
  }

  bool _hasGoals() {
    // Logica per determinare se ci sono stati goal
    return match.homeScore > 0 || match.awayScore > 0;
  }

  bool _hasYellowCards() {
    // Placeholder - dovrebbe essere basato su dati reali degli eventi
    return false;
  }

  bool _hasRedCards() {
    // Placeholder - dovrebbe essere basato su dati reali degli eventi
    return false;
  }
}
