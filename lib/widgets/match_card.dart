// lib/widgets/match_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/soccer_match.dart';
import '../widgets/glassmorphic_card.dart';

class MatchCard extends StatelessWidget {
  final SoccerMatch match;
  final VoidCallback? onTap;
  final bool showLeague;
  final bool showVenue;
  final bool showDate;

  const MatchCard({
    Key? key,
    required this.match,
    this.onTap,
    this.showLeague = true,
    this.showVenue = false,
    this.showDate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassmorphicCard(
      borderRadius: 16.0,
      borderWidth: match.isLive ? 2 : 0.5,
      borderColor: match.isLive ? Colors.red : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // League info (se richiesto)
              if (showLeague && match.leagueName != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                        match.leagueName ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Main match info
              Row(
                children: [
                  // Home team
                  Expanded(
                    child: Column(
                      children: [
                        if (match.homeTeamLogo != null)
                          CachedNetworkImage(
                            imageUrl: match.homeTeamLogo!,
                            width: 50,
                            height: 50,
                          )
                        else
                          const Icon(Icons.sports_soccer, size: 50),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeamName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreBackgroundColor(isDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (match.status == 'LIVE' || match.isLive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              match.elapsed != null
                                  ? "${match.elapsed}'"
                                  : 'LIVE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          _getScoreText(),
                          style: TextStyle(
                            fontSize: match.isScheduled ? 16 : 24,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : (match.isLive
                                    ? Colors.red
                                    : theme.primaryColor),
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
                            width: 50,
                            height: 50,
                          )
                        else
                          const Icon(Icons.sports_soccer, size: 50),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeamName,
                          style: const TextStyle(
                            fontSize: 13,
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

              // Match details (se richiesti)
              if (showDate || showVenue) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showDate) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM', 'it').format(match.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (showDate && showVenue && match.venue != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (showVenue && match.venue != null) ...[
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          match.venue!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Status indicator
              if (_shouldShowStatus()) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreBackgroundColor(bool isDark) {
    if (match.isLive) {
      return Colors.red.withOpacity(0.1);
    } else if (match.isFinished) {
      return Colors.green.withOpacity(0.1);
    } else {
      return isDark ? Colors.grey[800]! : Colors.grey[200]!;
    }
  }

  Color _getStatusColor() {
    if (match.isLive) return Colors.red;
    if (match.isFinished) return Colors.green;
    if (match.isPostponed) return Colors.orange;
    if (match.isCancelled) return Colors.grey;
    return Colors.blue;
  }

  String _getScoreText() {
    if (match.isScheduled) {
      return match.time;
    }
    return '${match.homeScore} - ${match.awayScore}';
  }

  String _getStatusText() {
    if (match.isLive) {
      if (match.elapsed != null) {
        return "${match.elapsed}'";
      }
      return 'LIVE';
    }
    if (match.isScheduled) {
      return 'Da giocare';
    }
    if (match.isFinished) {
      return 'Terminata';
    }
    return match.status;
  }

  bool _shouldShowStatus() {
    return match.isPostponed ||
        match.isCancelled ||
        match.status == 'SUSP' ||
        match.status == 'INT' ||
        match.status == 'ABD' ||
        match.status == 'AWD' ||
        match.status == 'WO';
  }
}
