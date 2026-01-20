// lib/widgets/enhanced_match_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/soccer_match.dart';
import 'glassmorphic_card.dart';

class EnhancedMatchCard extends StatelessWidget {
  final SoccerMatch match;
  final VoidCallback? onTap;
  final bool showLeague;
  final bool showVenue;
  final bool showDate;
  final bool isCompact;

  const EnhancedMatchCard({
    Key? key,
    required this.match,
    this.onTap,
    this.showLeague = true,
    this.showVenue = false,
    this.showDate = false,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassmorphicCard(
      borderColor: match.isLive ? Colors.red : null,
      borderWidth: match.isLive ? 2 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Column(
            children: [
              // League info if shown
              if (showLeague && match.leagueName != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (match.leagueLogo != null)
                        CachedNetworkImage(
                          imageUrl: match.leagueLogo!,
                          width: 20,
                          height: 20,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        match.leagueName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (match.round != null)
                        Text(
                          ' • ${match.round}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),

              // Main match content
              Row(
                children: [
                  // Home team
                  Expanded(
                    child: Column(
                      children: [
                        if (match.homeTeamLogo != null)
                          CachedNetworkImage(
                            imageUrl: match.homeTeamLogo!,
                            width: isCompact ? 40 : 50,
                            height: isCompact ? 40 : 50,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.sports_soccer, size: 40),
                          )
                        else
                          const Icon(Icons.sports_soccer, size: 50),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeamName,
                          style: TextStyle(
                            fontSize: isCompact ? 12 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Score/Time
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getScoreBackgroundColor(match, isDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (match.isLive) _buildLiveBadge(match),
                        Text(
                          _getScoreText(match),
                          style: TextStyle(
                            fontSize: isCompact ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: match.isScheduled
                                ? (isDark ? Colors.white70 : Colors.black87)
                                : Colors.white,
                          ),
                        ),
                        if (match.isLive && match.elapsed != null)
                          Text(
                            "${match.elapsed}'",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (match.isHalfTime)
                          const Text(
                            'HT',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Away team
                  Expanded(
                    child: Column(
                      children: [
                        if (match.awayTeamLogo != null)
                          CachedNetworkImage(
                            imageUrl: match.awayTeamLogo!,
                            width: isCompact ? 40 : 50,
                            height: isCompact ? 40 : 50,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.sports_soccer, size: 40),
                          )
                        else
                          const Icon(Icons.sports_soccer, size: 50),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeamName,
                          style: TextStyle(
                            fontSize: isCompact ? 12 : 14,
                            fontWeight: FontWeight.w500,
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

              // Additional info
              if (showVenue || showDate || match.referee != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showVenue && match.venue.isNotEmpty) ...[
                        const Icon(Icons.stadium, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            match.venue,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (showDate) ...[
                        if (showVenue)
                          const Text(' • ', style: TextStyle(fontSize: 11)),
                        const Icon(Icons.calendar_today, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${match.date.day}/${match.date.month}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                      if (match.referee != null) ...[
                        if (showVenue || showDate)
                          const Text(' • ', style: TextStyle(fontSize: 11)),
                        const Icon(Icons.sports, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            match.referee!,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Status indicators
              if (match.isPostponed || match.isCancelled)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: match.isPostponed ? Colors.orange : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    match.isPostponed ? 'RINVIATA' : 'CANCELLATA',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge(SoccerMatch match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .scale(
                duration: const Duration(seconds: 1),
                begin: const Offset(1, 1),
                end: const Offset(1.3, 1.3),
              ),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreBackgroundColor(SoccerMatch match, bool isDark) {
    if (match.isLive) return Colors.red;
    if (match.isFinished) return Colors.green;
    if (match.isScheduled)
      return isDark ? Colors.grey[800]! : Colors.grey[300]!;
    return Colors.orange;
  }

  String _getScoreText(SoccerMatch match) {
    if (match.isScheduled) return match.time;
    return '${match.homeScore} - ${match.awayScore}';
  }
}
